/*
 * lift_cycler_direct.ino  —  ESP32 as the GEM keypad, NO RELAYS
 *
 * The ESP32 GPIO pins connect straight to the membrane-button pads and emulate
 * a press by shorting the pad to ground (open-drain):
 *     press   -> pin = OUTPUT LOW   (shorts pad to ground, like a finger)
 *     release -> pin = INPUT (Hi-Z) (pad floats back up via its own pull-up)
 * The pin is NEVER driven HIGH.
 *
 * ===========================================================================
 *  USE THIS VERSION ONLY IF:
 *   1) each button pad idles at <= 3.3 V   (MEASURE IT — 5 V will damage the ESP)
 *   2) ESP GND is tied to the GEM's ground  (shared ground is REQUIRED)
 *   3) the button is active-low (pressing shorts the pad to ground — the norm)
 *  If the pad is 5 V, use the relay version (lift_cycler.ino) instead.
 * ===========================================================================
 *
 * Cycle:
 *     UP 3 min -> STOP 10 min -> DOWN 3 min -> STOP 10 min -> repeat
 * Each completed UP+DOWN counts as one cycle; the count persists in flash (NVS).
 *
 * ---------------------------------------------------------------------------
 * PIN MAP  (safe output GPIOs — do NOT use 34/35/36/39, they are input-only)
 *
 *     Function   ESP32 pin   Wire to
 *     --------   ---------   -------------------------------------------
 *     UP         GPIO 26     UP button "signal" pad
 *     DOWN       GPIO 27     DOWN button "signal" pad
 *     STOP       GPIO 25     STOP button "signal" pad  (latching mode only)
 *     GROUND     GND         the GEM board ground / the buttons' common pad
 * ---------------------------------------------------------------------------
 */

#include <Preferences.h>

// ----------------------------- Pin configuration -----------------------------
const int PIN_UP   = 26;
const int PIN_DOWN = 27;
const int PIN_STOP = 25;   // used only in LATCHING mode

// Keypad behavior:
//   true  = HOLD-TO-RUN (momentary): moves only while held; stop = release.
//           Uses UP + DOWN (STOP pin unused).
//   false = LATCHING: a quick tap starts motion; a STOP tap halts it.
//           Uses UP + DOWN + STOP.
const bool HOLD_TO_RUN = true;

// ------------------------------ Timing settings ------------------------------
const unsigned long RUN_MS  = 3UL  * 60UL * 1000UL;   // 3 minutes moving
const unsigned long STOP_MS = 10UL * 60UL * 1000UL;   // 10 minutes stopped
const unsigned long PULSE_MS = 400UL;                 // tap length (latching)
const unsigned long HEARTBEAT_MS = 60UL * 1000UL;     // status print every 60 s

// ------------------------------- State machine -------------------------------
enum Phase { RUN_UP, STOP_AFTER_UP, RUN_DOWN, STOP_AFTER_DOWN };
Phase         phase       = RUN_UP;
unsigned long phaseStart  = 0;
unsigned long lastBeat    = 0;

unsigned long cycleCount  = 0;
Preferences   prefs;

// ------------------------- Open-drain press / release ------------------------
// Press = drive the pad LOW (short to ground). Set the latch LOW *before*
// switching to OUTPUT so the pin never glitches HIGH.
inline void pressPin(int pin)   { digitalWrite(pin, LOW); pinMode(pin, OUTPUT); }
// Release = high-impedance input; the pad's own pull-up floats it back up.
inline void releasePin(int pin) { pinMode(pin, INPUT); }

void releaseAll() {
  releasePin(PIN_UP);
  releasePin(PIN_DOWN);
  releasePin(PIN_STOP);
}

// Hold one direction (HOLD-TO-RUN), other directions released.
void hold(int pin) {
  releaseAll();
  pressPin(pin);
}

// Quick tap of one button (LATCHING).
void tap(int pin) {
  releaseAll();
  pressPin(pin);
  delay(PULSE_MS);
  releasePin(pin);
}

unsigned long phaseLength(Phase p) {
  return (p == RUN_UP || p == RUN_DOWN) ? RUN_MS : STOP_MS;
}

void enterPhase(Phase p) {
  phase      = p;
  phaseStart = millis();
  switch (p) {
    case RUN_UP:
      HOLD_TO_RUN ? hold(PIN_UP) : tap(PIN_UP);
      Serial.println(F("[UP]   moving UP for 3 min"));
      break;
    case STOP_AFTER_UP:
      HOLD_TO_RUN ? (void)releaseAll() : tap(PIN_STOP);
      Serial.println(F("[STOP] stopped, 10 min (after up)"));
      break;
    case RUN_DOWN:
      HOLD_TO_RUN ? hold(PIN_DOWN) : tap(PIN_DOWN);
      Serial.println(F("[DOWN] moving DOWN for 3 min"));
      break;
    case STOP_AFTER_DOWN:
      HOLD_TO_RUN ? (void)releaseAll() : tap(PIN_STOP);
      Serial.println(F("[STOP] stopped, 10 min (after down)"));
      break;
  }
}

// ---------------------------------- Setup ------------------------------------
void setup() {
  Serial.begin(115200);
  delay(200);

  // Start with every pin RELEASED (high-Z) so a reset never presses a button.
  releaseAll();

  prefs.begin("lift", false);
  cycleCount = prefs.getULong("cycles", 0);

  Serial.println(F("\n=== Lift cycler (direct / no relay) ==="));
  Serial.printf("Mode: %s\n", HOLD_TO_RUN ? "HOLD-TO-RUN" : "LATCHING");
  Serial.printf("Cycles completed so far: %lu\n", cycleCount);

  lastBeat = millis();
  enterPhase(RUN_UP);
}

// ----------------------------------- Loop ------------------------------------
void loop() {
  const unsigned long now     = millis();
  const unsigned long elapsed = now - phaseStart;          // rollover-safe

  switch (phase) {
    case RUN_UP:
      if (elapsed >= RUN_MS)  enterPhase(STOP_AFTER_UP);
      break;
    case STOP_AFTER_UP:
      if (elapsed >= STOP_MS) enterPhase(RUN_DOWN);
      break;
    case RUN_DOWN:
      if (elapsed >= RUN_MS)  enterPhase(STOP_AFTER_DOWN);
      break;
    case STOP_AFTER_DOWN:
      if (elapsed >= STOP_MS) {
        cycleCount++;
        prefs.putULong("cycles", cycleCount);
        Serial.printf(">>> Cycle complete. Total cycles: %lu\n", cycleCount);
        enterPhase(RUN_UP);
      }
      break;
  }

  if (now - lastBeat >= HEARTBEAT_MS) {
    lastBeat = now;
    unsigned long remaining = phaseLength(phase) - elapsed;
    const char* name = (phase == RUN_UP)   ? "UP"   :
                       (phase == RUN_DOWN) ? "DOWN" : "STOP";
    Serial.printf("   %-4s  %lu s left   (cycles: %lu)\n",
                  name, remaining / 1000UL, cycleCount);
  }
}
