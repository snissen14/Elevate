// Cloudflare Worker entry point.
//
// Serves the static site from ./web (via the ASSETS binding) and handles the
// dynamic checkout endpoint at POST /api/checkout.
//
// The checkout total is computed from the SERVER-SIDE price table below, never
// from prices sent by the browser, so prices cannot be tampered with client-side.
//
// Requires an environment variable STRIPE_SECRET_KEY, added in the Cloudflare
// dashboard once this Worker has code (Settings -> Variables and secrets).
// Use sk_test_… for testing and sk_live_… for live payments.

// Authoritative price table — amounts in cents (USD). Keys MUST match the
// product names used by the cart (productCatalog in web/index.html).
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

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function handleCheckout(request, env) {
  if (!env.STRIPE_SECRET_KEY) {
    return json({ error: 'Checkout is not configured yet.' }, 500);
  }

  let body;
  try {
    body = await request.json();
  } catch (e) {
    return json({ error: 'Invalid request.' }, 400);
  }

  const items = body && Array.isArray(body.items) ? body.items : [];
  if (items.length === 0) {
    return json({ error: 'Your cart is empty.' }, 400);
  }

  const origin = new URL(request.url).origin;
  const params = new URLSearchParams();
  params.set('mode', 'payment');
  params.set('success_url', origin + '/?checkout=success');
  params.set('cancel_url', origin + '/?checkout=cancel#cart');
  params.append('shipping_address_collection[allowed_countries][]', 'US');
  params.append('shipping_address_collection[allowed_countries][]', 'CA');

  let i = 0;
  for (const item of items) {
    const name = item && item.name;
    const qty = Math.max(1, Math.min(99, parseInt(item && item.qty, 10) || 1));
    const amount = CATALOG[name];
    if (!Number.isInteger(amount)) {
      return json({ error: 'Unknown item in cart: ' + name }, 400);
    }
    params.set('line_items[' + i + '][price_data][currency]', 'usd');
    params.set('line_items[' + i + '][price_data][product_data][name]', name);
    params.set('line_items[' + i + '][price_data][unit_amount]', String(amount));
    params.set('line_items[' + i + '][quantity]', String(qty));
    i++;
  }

  let resp, data;
  try {
    resp = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + env.STRIPE_SECRET_KEY,
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
