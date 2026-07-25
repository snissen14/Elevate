/*
 * Elevate Boat Lift — Cycle Endurance Tester (ESP32)
 * ---------------------------------------------------
 * Replaces the membrane keypad on a GEM lift control board. The ESP32
 * "presses" the UP and DOWN buttons on a timer to run an endurance cycle:
 *
 *     UP  for 3 min  ->  stop 10 min  ->  DOWN for 3 min  ->  stop 10 min  -> repeat
 *
 * It counts every completed UP+DOWN as one cycle and stores the running
 * total in flash (NVS), so the count survives power loss.
 *
 * ================= HARDWARE INTERFACE (read this) =================
 * Do NOT wire ESP32 GPIO directly into the keypad traces. The keypad may
 * run at a different voltage and share a scan matrix — direct wiring can
 * damage the board or the ESP. Instead, put an OPTOCOUPLER (e.g. PC817)
 * or a small RELAY ACROSS the two pads of each button, so the ESP presses
 * a button by momentarily shorting its contacts:
 *
 *     ESP32 GPIO --[330 ohm]--> opto LED (+)      opto out --\
 *                    opto LED (-) --> ESP GND               |--> across UP button pads
 *                                                           /
 *     (second identical opto for the DOWN button)
 *
 * Using optocouplers keeps the ESP electrically ISOLATED from the GEM
 * board and works no matter what voltage/logic the keypad uses. A relay
 * module works too (see ACTIVE_LOW below).
 * =================================================================
 */

#include <Preferences.h>

// ---- Pin assignments (match these to your wiring) ----
const int PIN_UP   = 25;   // drives the opto/relay across the UP button
const int PIN_DOWN = 26;   // drives the opto/relay across the DOWN button
const int PIN_LED  = 2;    // onboard LED: ON while the motor is being driven

// ---- Output polarity ----
// Optocoupler driven from GPIO (HIGH = pressed): keep false.
// Typical blue relay boards are active-LOW (LOW = energized): set true.
const bool ACTIVE_LOW = false;

// ---- Keypad behavior ----
// true  = HOLD-TO-RUN: motor runs only while the button is held (most lift
//         remotes with limit switches). The ESP holds the line for the whole
//         3-minute run. <-- default.
// false = LATCHING: one short press starts, another stops. The ESP sends a
//         ~350 ms pulse to start and another to stop.
const bool HOLD_TO_RUN = true;
const unsigned long PULSE_MS = 350UL;   // used only when HOLD_TO_RUN == false

// ---- Timing (milliseconds) ----
const unsigned long RUN_MS        = 3UL  * 60UL * 1000UL;   // 3 minutes running
const unsigned long REST_MS       = 10UL * 60UL * 1000UL;   // 10 minutes stopped
const unsigned long BOOT_DELAY_MS = 5UL  * 1000UL;          // settle before first move
const unsigned long DEAD_TIME_MS  = 1000UL;                 // both off between directions

// ---- State machine ----
enum Phase { BOOT, RUN_UP, REST_AFTER_UP, RUN_DOWN, REST_AFTER_DOWN };
Phase phase = BOOT;
unsigned long phaseStart = 0;
unsigned long totalCycles = 0;      // one full UP + DOWN == one cycle

Preferences prefs;

// Drive a single output honoring the active-level setting.
void writeOutput(int pin, bool on) {
  bool level = ACTIVE_LOW ? !on : on;
  digitalWrite(pin, level ? HIGH : LOW);
}

// Enforce that UP and DOWN are NEVER energized at the same time.
void setDirection(bool up, bool down) {
  if (up && down) { up = false; down = false; }   // safety: never both
  writeOutput(PIN_UP, up);
  writeOutput(PIN_DOWN, down);
  digitalWrite(PIN_LED, (up || down) ? HIGH : LOW);
}

void allStop() { setDirection(false, false); }

// Start moving in a direction. For HOLD_TO_RUN we leave the line asserted for
// the whole run; for latching boards we send one short start pulse.
void startMove(bool up) {
  allStop();
  delay(DEAD_TIME_MS);                 // guarantee a gap between directions
  setDirection(up, !up);               // assert exactly one direction
  if (!HOLD_TO_RUN) {                  // latching board: pulse to start, then release
    delay(PULSE_MS);
    allStop();
    digitalWrite(PIN_LED, HIGH);       // keep indicator on: commanded running
  }
}

// Stop moving. For latching boards this means pressing the same button again.
void stopMove(bool up) {
  if (!HOLD_TO_RUN) {                  // latching: pulse the same button to stop
    setDirection(up, !up);
    delay(PULSE_MS);
  }
  allStop();
}

void saveCycles() { prefs.putULong("cycles", totalCycles); }

void enterPhase(Phase p) {
  phase = p;
  phaseStart = millis();
  switch (p) {
    case BOOT:
      allStop();
      Serial.println("[BOOT] settling, motor stopped...");
      break;
    case RUN_UP:
      startMove(true);
      Serial.println("[UP]   running UP for 3 min");
      break;
    case REST_AFTER_UP:
      stopMove(true);
      Serial.println("[REST] stopped for 10 min");
      break;
    case RUN_DOWN:
      startMove(false);
      Serial.println("[DOWN] running DOWN for 3 min");
      break;
    case REST_AFTER_DOWN:
      stopMove(false);
      Serial.println("[REST] stopped for 10 min");
      break;
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_UP, OUTPUT);
  pinMode(PIN_DOWN, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  allStop();                          // ensure motor is OFF on boot / brownout

  prefs.begin("lift", false);
  totalCycles = prefs.getULong("cycles", 0);

  Serial.println("\n=== Elevate Lift Cycle Tester ===");
  Serial.printf("Resuming total cycles: %lu\n", totalCycles);
  Serial.println("Serial commands:  p = print count   r = reset count");

  enterPhase(BOOT);
}

void loop() {
  unsigned long now = millis();
  unsigned long elapsed = now - phaseStart;    // rollover-safe

  switch (phase) {
    case BOOT:
      if (elapsed >= BOOT_DELAY_MS) enterPhase(RUN_UP);
      break;
    case RUN_UP:
      if (elapsed >= RUN_MS) enterPhase(REST_AFTER_UP);
      break;
    case REST_AFTER_UP:
      if (elapsed >= REST_MS) enterPhase(RUN_DOWN);
      break;
    case RUN_DOWN:
      if (elapsed >= RUN_MS) enterPhase(REST_AFTER_DOWN);
      break;
    case REST_AFTER_DOWN:
      if (elapsed >= REST_MS) {
        totalCycles++;                 // one full up+down completed
        saveCycles();
        Serial.printf(">>> CYCLE %lu COMPLETE\n", totalCycles);
        enterPhase(RUN_UP);
      }
      break;
  }

  // Serial commands: print / reset the cycle count.
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 'r' || c == 'R') { totalCycles = 0; saveCycles(); Serial.println("cycle count RESET to 0"); }
    if (c == 'p' || c == 'P') { Serial.printf("total cycles: %lu\n", totalCycles); }
  }

  // Heartbeat every 30 s so you can see it's alive and where it is.
  static unsigned long lastBeat = 0;
  if (now - lastBeat >= 30000UL) {
    lastBeat = now;
    const char* names[] = {"BOOT","RUN_UP","REST","RUN_DOWN","REST"};
    Serial.printf("   [%s] %lus elapsed | total cycles: %lu\n",
                  names[(int)phase], elapsed / 1000UL, totalCycles);
  }
}
