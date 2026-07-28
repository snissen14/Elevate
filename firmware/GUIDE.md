# Lift Cycler — Firmware, Logic & Flashing Guide

ESP32 automates the GEM lift by emulating the membrane keypad, running a timed
up/down cycle and counting completed cycles.

> **Cycle:** `UP 3 min → STOP 10 min → DOWN 3 min → STOP 10 min → repeat`

---

## 1. Which firmware to use

Measure across an **Up** button pad (multimeter on **DC volts**, button not pressed):

| Pad reads | Use | Sketch |
|-----------|-----|--------|
| **≤ 3.3 V** | Direct — ESP pins wire straight to the pads (no relays) | `lift_cycler_direct/lift_cycler_direct.ino` |
| **5 V**, or you want isolation | Relays — ESP drives relay modules, contacts bridge the pads | `lift_cycler/lift_cycler.ino` |

Both run the identical cycle and cycle counter. Pick one.

---

## 2. Wiring

### Direct (no relay) — pads ≤ 3.3 V
```
ESP GND  ──── GEM ground / buttons' common pad     ← REQUIRED (shared ground)
GPIO 26  ──── UP    button signal pad
GPIO 27  ──── DOWN  button signal pad
GPIO 25  ──── STOP  button signal pad   (latching keypad only)
```

### Relay version
```
Each relay:  DC+ → 5V/VIN   DC- → GND   IN → GPIO (26 up, 27 down, 25 stop)
Relay output: COM + NO  →  across the two pads of that button
```

> ⚠️ Never use GPIO **34, 35, 36, 39** — they are **input-only** and cannot drive an output.

---

## 3. Logic (how it works)

- **State machine, non-blocking.** Four phases run off `millis()`:
  `RUN_UP → STOP_AFTER_UP → RUN_DOWN → STOP_AFTER_DOWN →` (repeat). No `delay()`
  in the timing, so the count and serial output stay live and timers are rollover-safe.
- **Pressing a button:**
  - *Direct:* `press = pin OUTPUT LOW` (shorts pad to ground), `release = pin INPUT / Hi-Z`
    (pad floats back up). The pin is never driven HIGH.
  - *Relay:* `press = energize relay`, `release = de-energize`.
- **Stop handling (set by `HOLD_TO_RUN`):**
  - `true`  = **hold-to-run** keypad → move only while held; stop = release both.
    Needs UP + DOWN only.
  - `false` = **latching** keypad → a quick *tap* starts motion, a *tap* on STOP halts it.
    Needs UP + DOWN + STOP.
- **Safety:** on boot every pin is forced to the released state *before* going active,
  so a reset or power-up never lurches the lift. Only one direction is ever active at once.
- **Cycle counting:** one completed **UP + DOWN** = one cycle. The count is written to
  flash (NVS), so it survives resets and power loss. A normal re-upload keeps the count;
  only a full `erase_flash` resets it to 0.
- **Settings** (top of the sketch): `RUN_MS` / `STOP_MS` (durations), `HOLD_TO_RUN`,
  the three pin numbers, and — relay version only — `RELAY_ACTIVE_LOW`.

---

## 4. Terminal commands (macOS)

### One-time setup
```bash
brew install arduino-cli esptool
arduino-cli config init
arduino-cli core update-index --additional-urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
arduino-cli core install esp32:esp32 --additional-urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
```

### Find the board's port
```bash
arduino-cli board list          # note e.g. /dev/cu.usbserial-0001
```

### Erase the old firmware (clears everything, incl. cycle count)
```bash
python3 -m esptool --chip esp32 --port /dev/cu.usbserial-0001 erase_flash
```

### Compile + upload  (point the path at whichever sketch folder you chose)
```bash
arduino-cli compile  --fqbn esp32:esp32:esp32 ~/lift_cycler_direct
arduino-cli upload -p /dev/cu.usbserial-0001 --fqbn esp32:esp32:esp32 ~/lift_cycler_direct
```

### Watch it run
```bash
arduino-cli monitor -p /dev/cu.usbserial-0001 -c baudrate=115200
```

**Notes**
- Keep each `.ino` in a folder of the **same name** (Arduino requirement).
- Swap in the port from `board list`. Linux: `/dev/ttyUSB0`; Windows: `COM3`.
- Upload stuck at "Connecting…"? Hold the **BOOT** button as it starts, then release.
- Port missing on macOS? Install the Silicon Labs **CP210x VCP driver**, re-plug.
- **GUI alternative:** Arduino IDE → *Tools ▸ Erase All Flash Before Sketch Upload ▸ Enabled* → select **ESP32 Dev Module** + port → **Upload**.

---

## 5. Bench test before wiring to the lift
1. Flash, open the Serial Monitor (115200).
2. Confirm the phase log cycles `UP → STOP → DOWN → STOP` and `Total cycles` increments.
3. Relay version: confirm the relay LEDs click in that pattern; verify `RELAY_ACTIVE_LOW`.
4. Verify `HOLD_TO_RUN` matches your keypad (press Up on the real pad: stops on release =
   hold-to-run; keeps going = latching).

> Tip: temporarily set `RUN_MS`/`STOP_MS` to a few seconds to watch a whole cycle fast,
> then restore 3 min / 10 min.
