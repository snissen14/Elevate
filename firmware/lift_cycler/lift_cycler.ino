/*
 * lift_cycler.ino  —  ESP32 acts as the GEM membrane keypad
 *
 * The ESP32 drives relay modules whose dry contacts (COM + NO) are wired across
 * the membrane-button pads. Energizing a relay = "pressing" that button. The
 * relay contact is isolated, so there is no shared ground, polarity, or
 * voltage-matching concern with the GEM board.
 *
 * Cycle:
 *     UP    for 3  minutes
 *     STOP  for 10 minutes
 *     DOWN  for 3  minutes
 *     STOP  for 10 minutes
 *     -> repeat forever, counting each completed UP+DOWN as one cycle.
 *
 * The cycle count is stored in flash (NVS) so it survives resets / power loss.
 *
 * ---------------------------------------------------------------------------
 * PIN MAP  (all are safe output GPIOs — do NOT use 34/35/36/39, input-only!)
 *
 *     Function   ESP32 pin   Wire to
 *     --------   ---------   ------------------------------
 *     UP         GPIO 26     Relay 1  IN
 *     DOWN       GPIO 27     Relay 2  IN
 *     STOP       GPIO 25     Relay 3  IN   (latching mode only)
 *
 *     Every relay:   DC+ -> 5V / VIN     DC- -> GND
 * ---------------------------------------------------------------------------
 *
 * Relays: opto-isolated "high/low level trigger" modules, 5 V coil (SRD-05VDC).
 */

#include <Preferences.h>

// ----------------------------- Pin configuration -----------------------------
const int PIN_UP   = 26;   // relay pressing the UP button
const int PIN_DOWN = 27;   // relay pressing the DOWN button
const int PIN_STOP = 25;   // relay pressing the STOP button (LATCHING mode only)

// Most opto-isolated relay boards are ACTIVE-LOW:
//   IN = LOW  -> relay energized (button pressed)
//   IN = HIGH -> relay released
// Toggle a pin, watch the board LED, and flip this if yours is active-high.
const bool RELAY_ACTIVE_LOW = true;

// How the GEM keypad behaves:
//   true  = HOLD-TO-RUN (momentary): lift moves only while held. Stop = release.
//           Needs only UP + DOWN relays (2 relays).
//   false = LATCHING: a quick press starts motion; a Stop press halts it.
//           Needs UP + DOWN + STOP relays (3 relays).
const bool HOLD_TO_RUN = true;

// ------------------------------ Timing settings ------------------------------
const unsigned long RUN_MS  = 3UL  * 60UL * 1000UL;   // 3 minutes of movement
const unsigned long STOP_MS = 10UL * 60UL * 1000UL;   // 10 minutes stopped
const unsigned long PULSE_MS = 400UL;                 // button "tap" length (latching)
const unsigned long HEARTBEAT_MS = 60UL * 1000UL;     // status print every 60 s

// ------------------------------- State machine -------------------------------
enum Phase { RUN_UP, STOP_AFTER_UP, RUN_DOWN, STOP_AFTER_DOWN };
Phase         phase       = RUN_UP;
unsigned long phaseStart  = 0;
unsigned long lastBeat    = 0;

unsigned long cycleCount  = 0;   // completed UP+DOWN sequences
Preferences   prefs;

// ------------------------------ Relay helpers --------------------------------
inline int onLevel()  { return RELAY_ACTIVE_LOW ? LOW  : HIGH; }
inline int offLevel() { return RELAY_ACTIVE_LOW ? HIGH : LOW;  }

void releaseAll() {
  digitalWrite(PIN_UP,   offLevel());
  digitalWrite(PIN_DOWN, offLevel());
  digitalWrite(PIN_STOP, offLevel());
}

// Quick tap of one button (used in LATCHING mode).
void tap(int pin) {
  releaseAll();
  digitalWrite(pin, onLevel());
  delay(PULSE_MS);
  digitalWrite(pin, offLevel());
}

// Hold one direction, guaranteeing the other is released (used in HOLD-TO-RUN).
void hold(int pin) {
  releaseAll();
  digitalWrite(pin, onLevel());
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

  // Force relays to the RELEASED level *before* enabling outputs, so a reset or
  // power-up never briefly "presses" a button and drives the lift.
  digitalWrite(PIN_UP,   offLevel());
  digitalWrite(PIN_DOWN, offLevel());
  digitalWrite(PIN_STOP, offLevel());
  pinMode(PIN_UP,   OUTPUT);
  pinMode(PIN_DOWN, OUTPUT);
  pinMode(PIN_STOP, OUTPUT);
  releaseAll();

  prefs.begin("lift", false);
  cycleCount = prefs.getULong("cycles", 0);

  Serial.println(F("\n=== Lift cycler ==="));
  Serial.printf("Mode: %s\n", HOLD_TO_RUN ? "HOLD-TO-RUN (2 relays)" : "LATCHING (3 relays)");
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
        cycleCount++;                                       // one full UP+DOWN done
        prefs.putULong("cycles", cycleCount);
        Serial.printf(">>> Cycle complete. Total cycles: %lu\n", cycleCount);
        enterPhase(RUN_UP);
      }
      break;
  }

  // Periodic heartbeat with time remaining in the current phase.
  if (now - lastBeat >= HEARTBEAT_MS) {
    lastBeat = now;
    unsigned long remaining = phaseLength(phase) - elapsed;
    const char* name = (phase == RUN_UP)   ? "UP"   :
                       (phase == RUN_DOWN) ? "DOWN" : "STOP";
    Serial.printf("   %-4s  %lu s left   (cycles: %lu)\n",
                  name, remaining / 1000UL, cycleCount);
  }
}
