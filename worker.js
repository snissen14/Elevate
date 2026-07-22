// Cloudflare Worker entry point.
//
// Serves the static site from ./web (via the ASSETS binding) and handles the
// dynamic checkout endpoint at POST /api/checkout.
//
// Totals are computed from the SERVER-SIDE price tables below, never from prices
// sent by the browser, so they cannot be tampered with client-side.
//
// Requires an environment variable STRIPE_SECRET_KEY (Settings -> Variables and
// secrets). Use sk_test_… for testing and sk_live_… for live payments.

// ── Accessories catalog (cart page) — amounts in cents (USD). Keys MUST match
//    the product names used by the cart (productCatalog in web/index.html). ──
const CATALOG = {
  'Carpeted Bunk Boards':    32000,
  'Guide Poles':             28000,
  'Wireless Remote Control': 19500,
  'Solar Charging Kit':      38500,
  'Underwater LED Kit':      47500,
  'Cathodic Protection':     14500,
  'Boat Canopy Frame':      185000,
  'Remote Cover':             4599,
};

// ── Remote configurator pricing. Mirrors the data + total() in web/index.html.
//    Base model / finish / limit switch / accessory prices are in DOLLARS;
//    membership deltas are already in CENTS (matching the source data). ──
const CFG = {
  models: {
    'mono':   { name: 'Elevate Mono',   price: 599 },
    'mono-s': { name: 'Elevate Mono S', price: 615 },
    'duo':    { name: 'Elevate Duo',    price: 625 },
    'duo-s':  { name: 'Elevate Duo S',  price: 645 },
  },
  memberships: {
    '1year':    { name: '1 Year',   cents: 12999 },
    '3year':    { name: '3 Years',  cents: 32999 },
  },
  finishes: {
    'inlet':    { name: 'Inlet Green',    price: 0 },
    'offshore': { name: 'Offshore Black', price: 0 },
    'harbour':  { name: 'Harbour Mist',   price: 0 },
  },
  limitSwitches: {
    'rotary':    { name: 'Rotary',     price: 299 },
    'flatplate': { name: 'Flat Plate', price: 325 },
    'kels':      { name: 'Kels',       price: 325 },
  },
  accessories: {
    'led':   { name: 'Underwater LED Kit', price: 375.99 },
    'cover': { name: 'Remote Cover',       price: 45.99 },
  },
};

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Build line items from the cart (accessories). Returns { items } or { error }.
function buildCartLineItems(cartItems) {
  const items = Array.isArray(cartItems) ? cartItems : [];
  if (items.length === 0) return { error: 'Your cart is empty.' };
  const lineItems = [];
  for (const item of items) {
    const name = item && item.name;
    const qty = Math.max(1, Math.min(99, parseInt(item && item.qty, 10) || 1));
    const amount = CATALOG[name];
    if (!Number.isInteger(amount)) return { error: 'Unknown item in cart: ' + name };
    lineItems.push({ name: name, amount: amount, qty: qty });
  }
  return { items: lineItems };
}

// Build a single line item for a configured remote system. The total is
// recomputed here from the selection ids; any client-sent price is ignored.
function buildConfigLineItems(config) {
  const c = config || {};
  const model = CFG.models[c.model];
  const membership = c.motor ? CFG.memberships[c.motor] : null;
  const finish = c.finish ? CFG.finishes[c.finish] : null;
  if (!model) return { error: 'Invalid model selection.' };

  let cents = model.price * 100;
  const details = [];

  if (membership) {
    cents += membership.cents;
    details.push('Membership: ' + membership.name);
  }
  if (finish) {
    cents += finish.price * 100;
    details.push('Finish: ' + finish.name);
  }

  const isS = c.model === 'mono-s' || c.model === 'duo-s';
  if (isS && c.limitSwitch) {
    const ls = CFG.limitSwitches[c.limitSwitch];
    if (ls) {
      cents += ls.price * 100;
      details.push('Limit switch: ' + ls.name);
    }
  }

  const accIds = Array.isArray(c.acc) ? c.acc : [];
  const accNames = [];
  for (const id of accIds) {
    const a = CFG.accessories[id];
    if (!a) return { error: 'Invalid accessory selection.' };
    cents += Math.round(a.price * 100);
    accNames.push(a.name);
  }
  if (accNames.length) details.push('Add-ons: ' + accNames.join(', '));

  return { items: [{
    name: model.name + ' — Custom Configuration',
    description: details.join(' · '),
    amount: Math.round(cents),
    qty: 1,
  }] };
}

async function handleCheckout(request, env) {
  // Accept the standard name or the shorthand "Stripe" set in the dashboard.
  const stripeKey = env.STRIPE_SECRET_KEY || env.Stripe || env.STRIPE;
  if (!stripeKey) {
    return json({ error: 'Checkout is not configured yet.' }, 500);
  }

  let body;
  try {
    body = await request.json();
  } catch (e) {
    return json({ error: 'Invalid request.' }, 400);
  }

  const built = body && body.config
    ? buildConfigLineItems(body.config)
    : buildCartLineItems(body && body.items);
  if (built.error) return json({ error: built.error }, 400);

  const origin = new URL(request.url).origin;
  const params = new URLSearchParams();
  params.set('mode', 'payment');
  params.set('success_url', origin + '/?checkout=success');
  params.set('cancel_url', origin + '/?checkout=cancel#cart');
  params.append('shipping_address_collection[allowed_countries][]', 'US');
  params.append('shipping_address_collection[allowed_countries][]', 'CA');

  built.items.forEach(function (li, i) {
    params.set('line_items[' + i + '][price_data][currency]', 'usd');
    params.set('line_items[' + i + '][price_data][product_data][name]', li.name);
    if (li.description) {
      params.set('line_items[' + i + '][price_data][product_data][description]', li.description);
    }
    params.set('line_items[' + i + '][price_data][unit_amount]', String(li.amount));
    params.set('line_items[' + i + '][quantity]', String(li.qty));
  });

  let resp, data;
  try {
    resp = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + stripeKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });
    data = await resp.json();
  } catch (e) {
    return json({ error: 'Could not reach the payment processor.' }, 502);
  }

  if (!resp.ok) {
    return json({ error: (data && data.error && data.error.message) || 'Payment error.' }, 502);
  }

  return json({ url: data.url }, 200);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/checkout') {
      if (request.method !== 'POST') {
        return json({ error: 'Method not allowed.' }, 405);
      }
      return handleCheckout(request, env);
    }

    // Everything else: serve the static site.
    return env.ASSETS.fetch(request);
  },
};
