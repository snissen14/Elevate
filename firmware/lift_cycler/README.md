# Lift Cycler — ESP32 keypad emulator

The ESP32 emulates the GEM membrane keypad by using relay dry contacts to
"press" the UP / DOWN (and optionally STOP) buttons on a timed cycle.

## Cycle
`UP 3 min → STOP 10 min → DOWN 3 min → STOP 10 min → repeat`

Each completed **UP + DOWN** counts as one cycle. The count is saved in flash
(NVS), so it survives resets and power loss.

## Pin map

| Function | ESP32 pin | Wire to |
|----------|-----------|---------|
| UP       | GPIO 26   | Relay 1 `IN` |
| DOWN     | GPIO 27   | Relay 2 `IN` |
| STOP     | GPIO 25   | Relay 3 `IN` *(latching mode only)* |

Every relay module: `DC+` → **5V / VIN**, `DC-` → **GND**.
Relay output: `COM` + `NO` across the two pads of that membrane button.

> ⚠️ Do **not** use GPIO 34, 35, 36 (VP) or 39 (VN) for relays — they are
> **input-only** and cannot drive an output.

## Settings to check (top of `lift_cycler.ino`)

- `RELAY_ACTIVE_LOW` — most opto relay boards are active-low (IN LOW = pressed).
  Toggle a pin, watch the board LED, and flip this if yours is active-high.
- `HOLD_TO_RUN` —
  - `true`  = **hold-to-run** keypad: moves only while held; stop = release.
    Needs **2 relays** (UP, DOWN).
  - `false` = **latching** keypad: a tap starts motion, a STOP tap halts it.
    Needs **3 relays** (UP, DOWN, STOP).
- `RUN_MS` / `STOP_MS` — movement / rest durations (default 3 min / 10 min).

## Flashing
Arduino IDE → ESP32 Dev Module → open `lift_cycler.ino` → Upload.
Open Serial Monitor at **115200** to watch phase changes and the cycle count.
