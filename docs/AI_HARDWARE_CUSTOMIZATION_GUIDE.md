# AI Hardware Customization Guide

This document is for Summer Engine or another AI assistant customizing the handmade Arduino controller support for this project.

The goal is to help a beginner describe their physical controller, choose key bindings, and receive updated hardware bridge files without rewriting the game.

## Core Principle

Keep hardware input outside the gameplay modules.

Default data flow:

```text
Arduino hardware
        -> serial commands, one per line
        -> hardware/serial_keyboard_bridge.py
        -> keyboard taps
        -> scripts/core/input_bridge.gd
        -> scripts/core/action_mapper.gd
        -> gameplay systems
```

Most controller changes should only touch:

- `hardware/joystick_button_controller/joystick_button_controller.ino`
- `hardware/serial_keyboard_bridge.py`
- `hardware/README.md`
- `docs/CONTROLLER_INPUT.md`
- `README.md`

Only edit `scripts/core/input_bridge.gd` when the user needs a brand-new in-game action that cannot be represented by the existing keyboard actions.

## Current Game Actions

The game currently understands these keyboard-facing actions:

| Game action | Default key | Purpose |
| --- | --- | --- |
| Move up | `W` | Move cursor up one grid cell |
| Move down | `S` | Move cursor down one grid cell |
| Move left | `A` | Move cursor left one grid cell |
| Move right | `D` | Move cursor right one grid cell |
| Place | `Space` | Place the selected defender |
| Switch defender | `E` | Cycle selected defender type |
| Remove | `Shift` or `Backspace` | Remove defender on selected tile |
| Restart | `R` | Restart the game |

The default Arduino controller uses movement plus four action buttons:

```text
UP
DOWN
LEFT
RIGHT
SPACE
E
SHIFT
R
```

## Interview The User First

Ask short, concrete questions. Do not ask for code first.

Use this exact checklist:

1. What Arduino board are you using? Examples: Uno, Nano, Leonardo, Micro, Pro Micro.
2. What physical inputs are on the controller? Examples: analog joystick, four direction buttons, arcade buttons, toggle switches, potentiometers.
3. Which Arduino pin is each input connected to? If they do not know, suggest a default wiring plan.
4. What should each input do in the game? Use plain names: move up, move down, move left, move right, place, switch, remove, restart.
5. What keyboard key should each action send? Recommend `W/A/S/D` for movement and `Space/E/Shift/R` for place, switch, remove, and restart unless they request otherwise.
6. Should held movement repeat while held, or should each joystick push/button press move only once?
7. Are any directions reversed when testing? If yes, flip the relevant axis or button mapping.

If the user has one analog joystick and four buttons, use the default mapping:

| Hardware input | Serial command | Keyboard tap |
| --- | --- | --- |
| Joystick up | `UP` | `W` |
| Joystick down | `DOWN` | `S` |
| Joystick left | `LEFT` | `A` |
| Joystick right | `RIGHT` | `D` |
| Place button on `D2` | `SPACE` | `Space` |
| Switch button on `D3` | `E` | `E` |
| Remove button on `D4` | `SHIFT` | `Shift` |
| Restart button on `D5` | `R` | `R` |

## Serial Command Contract

The Arduino sketch should print one command per line.

Good:

```text
UP
SPACE
LEFT
```

Bad:

```text
x=513 y=515 dir=CENTER buttonA=released
```

Debug text is useful while wiring, but it should not be sent to the real bridge unless `hardware/serial_keyboard_bridge.py` is updated to parse it.

Prefer simple uppercase command tokens:

- `UP`
- `DOWN`
- `LEFT`
- `RIGHT`
- `SPACE`
- `E`
- `SWITCH`
- `SHIFT`
- `REMOVE`
- `R`
- `RESTART`

## Arduino Rewrite Rules

When rewriting `hardware/joystick_button_controller/joystick_button_controller.ino`:

- Keep `Serial.begin(115200)` unless the user has a reason to change baud rate.
- Use `INPUT_PULLUP` for simple buttons wired to `GND`.
- For analog joysticks, calibrate the resting center at startup.
- Use a deadzone so the cursor does not drift.
- For movement, repeat at a readable interval such as `150-220 ms`.
- For action buttons, send one command when the button becomes pressed.
- Debounce buttons with a delay or timestamp check around `30-60 ms`.
- If a direction is reversed, change `INVERT_X`, `INVERT_Y`, or the mapping rather than changing game code.
- Do not print continuous center/debug lines during normal play.

Recommended defaults:

```cpp
const long BAUD_RATE = 115200;
const int DEADZONE = 170;
const unsigned long MOVE_REPEAT_MS = 180;
const unsigned long BUTTON_DEBOUNCE_MS = 45;
```

## Python Bridge Rewrite Rules

When rewriting `hardware/serial_keyboard_bridge.py`:

- Keep `--dry-run`; it is the safest first test.
- Keep `--list`; it helps users find the serial port.
- Keep `--stdin`; it allows computer-only verification.
- Update `COMMAND_MAP` when adding or renaming serial commands.
- The `label` should be human-readable output such as `w` or `space`.
- The `key_name` should be the value pressed by `pynput`.
- For letter keys, use lowercase names like `"w"`, `"a"`, `"e"`.
- For special keys, handle them in `press_key`, such as `space` or `backspace`.
- Print ignored commands to stderr so bad serial output is visible.

Example mapping entry:

```python
"PLACE": KeyTap("space", "space"),
```

If the user wants different key bindings, change the Python bridge first. Only change Godot/Summer input code if the game itself must support a new action.

## Game Input Rewrite Rules

When editing `scripts/core/input_bridge.gd`:

- Preserve keyboard fallback.
- Preserve existing controls unless the user explicitly asks to change them.
- Listen for keydown-style pressed events, not keypress.
- Treat each keydown as one action.
- For browser builds, keep preventing default behavior for keys that scroll, change focus, or navigate.
- Keep raw hardware state separate from gameplay rules.

Do not put defender placement, wave, enemy, score, or resource logic in the input layer.

## Documentation Rewrite Rules

After changing hardware support:

- Update `hardware/README.md` with the exact wiring.
- Update `docs/CONTROLLER_INPUT.md` with the new command/key mapping.
- Update `README.md` if player-facing controls changed.
- If new game actions were added, update `docs/AI_EXTENSION_GUIDE.md`.

Keep beginner instructions concrete. Prefer:

```text
Button on D3 sends E, which taps E.
```

Instead of:

```text
Bind the secondary action to the configured event.
```

## Verification Checklist

Before saying the controller setup is ready, verify as much as possible:

1. Arduino Serial Monitor shows clean command lines only.
2. Serial Monitor is closed before running the Python bridge.
3. `python3 hardware/serial_keyboard_bridge.py --list` shows the board port.
4. `python3 hardware/serial_keyboard_bridge.py --port PORT --dry-run` prints expected mappings.
5. Computer-only test works:

```bash
printf "UP\nDOWN\nLEFT\nRIGHT\nSPACE\nE\nSHIFT\nR\n" | python3 hardware/serial_keyboard_bridge.py --stdin --dry-run
```

Expected output:

```text
UP -> w
DOWN -> s
LEFT -> a
RIGHT -> d
SPACE -> space
E -> e
SHIFT -> shift
R -> r
```

6. macOS Accessibility permission is enabled for Terminal or Python if real key taps do not reach the game.
7. Summer game window has focus before testing live input.

## Common Fixes

If the bridge prints `Ignored unknown command`:

- The Arduino is sending debug text or unsupported command names.
- Fix the sketch to print one command per line, or add parser support to the Python bridge.

If dry-run works but the game does not move:

- The bridge may still be running with `--dry-run`.
- The Summer game window may not be focused.
- macOS Accessibility permission may be missing.
- Another app may be receiving the key taps.

If directions are reversed:

- Flip `INVERT_X` or `INVERT_Y` in the Arduino sketch.
- For four-button D-pads, swap the serial command printed by the affected pin.

If movement repeats too fast:

- Increase `MOVE_REPEAT_MS`.

If movement feels sluggish:

- Decrease `MOVE_REPEAT_MS`, but avoid values below about `100 ms` for grid cursor movement.

If the joystick drifts:

- Increase `DEADZONE`.
- Reconnect/reset the Arduino while the joystick is centered so startup calibration samples the correct center.

## Example AI Prompt

The user may ask:

> Customize the Arduino controller for my game. I have an analog joystick on A0/A1, buttons on D2, D3, D4, and D5. I want D2 to place with Space, D3 to switch with E, D4 to remove with Shift, and D5 to restart with R.

The AI should:

1. Confirm or infer the mapping:

```text
A0/A1 joystick -> UP/DOWN/LEFT/RIGHT -> W/A/S/D
D2 button -> SPACE -> Space
D3 button -> E -> E
D4 button -> SHIFT -> Shift
D5 button -> R -> R
```

2. Rewrite the Arduino sketch to read all four buttons.
3. Ensure `hardware/serial_keyboard_bridge.py` maps `E`, `SHIFT`, and `R`.
4. Update `hardware/README.md` and `docs/CONTROLLER_INPUT.md`.
5. Run the computer-only bridge test.

Do not rewrite gameplay modules for this case.
