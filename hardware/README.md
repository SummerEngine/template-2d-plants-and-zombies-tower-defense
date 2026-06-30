# Arduino Controller Bridge

This folder contains a minimal joystick-and-buttons controller path for the game:

```text
Arduino joystick/buttons
        -> serial text commands
        -> Python serial keyboard bridge
        -> W/A/S/D/Space/E/Shift/R key taps
        -> Summer game window
```

The game already listens for `W`, `A`, `S`, `D`, `Space`, `E`, `Shift`, and `R`, so the Arduino does not need to talk directly to Summer Engine. It only needs to send readable serial commands.

## Wiring

For a common analog joystick module:

- Joystick `VRx` -> Arduino `A0`
- Joystick `VRy` -> Arduino `A1`
- Joystick `GND` -> Arduino `GND`
- Joystick `+5V` -> Arduino `5V`
- Place button -> Arduino `D2` and `GND`, sends `SPACE`
- Switch button -> Arduino `D3` and `GND`, sends `E`
- Remove button -> Arduino `D4` and `GND`, sends `SHIFT`
- Restart button -> Arduino `D5` and `GND`, sends `R`

The sketch uses `INPUT_PULLUP`, so each button is pressed when its pin reads `LOW`.

## Upload The Arduino Sketch

Open this file in the Arduino IDE and upload it to the board:

```text
hardware/joystick_button_controller/joystick_button_controller.ino
```

Then open the Arduino Serial Monitor at `115200` baud. You should see commands like:

```text
UP
LEFT
SPACE
E
SHIFT
R
```

If pushing the joystick up prints `DOWN`, flip `INVERT_Y` in the sketch. If left and right are reversed, flip `INVERT_X`.

## Run The Keyboard Bridge

Install the Python dependencies:

```bash
python3 -m pip install pyserial pynput
```

List connected serial ports:

```bash
python3 hardware/serial_keyboard_bridge.py --list
```

First test without pressing keys:

```bash
python3 hardware/serial_keyboard_bridge.py --port /dev/cu.usbmodemXXXX --dry-run
```

Then run the real bridge:

```bash
python3 hardware/serial_keyboard_bridge.py --port /dev/cu.usbmodemXXXX
```

Before playing, click the Summer game window once so it has focus. The bridge sends keys to whichever app is focused.

On macOS, give Terminal or Python Accessibility permission in:

```text
System Settings > Privacy & Security > Accessibility
```

Without that permission, the bridge may read serial input but fail to press keys in the game.

## Quick Computer-Only Test

You can test the receiver without an Arduino:

```bash
printf "UP\nLEFT\nSPACE\nE\nSHIFT\nR\n" | python3 hardware/serial_keyboard_bridge.py --stdin --dry-run
```

That should print:

```text
UP -> w
LEFT -> a
SPACE -> space
E -> e
SHIFT -> shift
R -> r
```

## Customizing The Controller

For AI-assisted rewrites of the Arduino sketch, bridge mappings, and docs, see:

```text
docs/AI_HARDWARE_CUSTOMIZATION_GUIDE.md
```
