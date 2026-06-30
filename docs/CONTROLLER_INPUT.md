# Controller Input Notes

The starter is designed around simple handmade Arduino controllers: one joystick or D-pad plus a few buttons.

## Current Flow

```text
Keyboard / joystick / D-pad / Arduino serial-to-keyboard bridge
        ↓
InputBridge
        ↓
ActionMapper
        ↓
PlacementController, DefenseGame, modules
```

## Default Action Vocabulary

- `move`: `Vector2`, used for grid cursor movement.
- `primary`: place the selected defender.
- `secondary`: switch defender type.
- `modifier`: remove/cancel on the selected tile.
- `restart`: restart the prototype after game over or during play.

## Keyboard And Gamepad Fallback

- Move: `W`, `A`, `S`, `D`, arrow keys, joystick, or D-pad.
- Place: `Space` or Button A.
- Switch defender type: `E`, `Tab`, or Button B.
- Remove/cancel: `Shift`, `Backspace`, or Button X.
- Restart: `R` or gamepad Start.

The Arduino controller is expected to reach the game as normal keyboard input through a serial-to-keyboard bridge. The included starter bridge lives in `hardware/`. The recommended game-facing output is `W` for up, `S` for down, `A` for left, `D` for right, `Space` for place, `E` for switch, `Shift` for remove, and `R` for restart. `InputBridge` listens to keydown-style `InputEventKey.pressed` events and queues one action per keydown. Held movement keys can still repeat through the placement movement cooldown.

For web/browser builds, `InputBridge` installs a small keydown guard through `JavaScriptBridge` when available. It calls `preventDefault()` for arrow keys, `Space`, `Tab`, `Backspace`, and `R` so the page does not scroll, move focus, or navigate away. The game canvas still needs focus; click/tap the game once before sending Arduino bridge input if the browser is not already focused on it.

## Connecting A Serial-To-Keyboard Bridge

If your Python bridge prints Arduino input in the terminal but the game does not react, the missing step is usually OS keyboard injection. Terminal output does not reach the game by itself. After your bridge parses a serial message, it must send a real key tap to the currently focused game window or browser canvas.

This template includes a minimal bridge:

```bash
python3 -m pip install pyserial pynput
python3 hardware/serial_keyboard_bridge.py --list
python3 hardware/serial_keyboard_bridge.py --port /dev/cu.usbmodemXXXX --dry-run
python3 hardware/serial_keyboard_bridge.py --port /dev/cu.usbmodemXXXX
```

Use `--dry-run` first. It should print mappings like `UP -> w`, `SPACE -> space`, `E -> e`, `SHIFT -> shift`, and `R -> r` without pressing keys.

On macOS, allow the terminal app or Python in **System Settings > Privacy & Security > Accessibility**, otherwise the bridge can read serial input but cannot press keys for another app.

Before testing, click the running Summer game window or browser canvas once so it has focus. The bridge sends keys to whichever app is focused.

The bridge should read one command per serial line, such as `UP`, `DOWN`, `LEFT`, `RIGHT`, `W`, `A`, `S`, `D`, `SPACE`, `PLACE`, `BUTTON`, `E`, `SWITCH`, `SHIFT`, `REMOVE`, `R`, or `RESTART`. Convert movement to `W/A/S/D`, convert place commands to `Space`, convert switch commands to `E`, convert remove commands to `Shift` or `Backspace`, and convert restart commands to `R`. If your existing bridge already prints those words, replace the `print(...)` line with a real key tap using the same mapping.

## Where Hardware Code Should Go

For a normal Arduino controller, start in `hardware/`:

- Put Arduino firmware changes in `hardware/joystick_button_controller/joystick_button_controller.ino`.
- Put computer-side serial-to-keyboard bridge changes in `hardware/serial_keyboard_bridge.py`.
- Only edit `scripts/core/input_bridge.gd` if the game itself needs to support a new keyboard/gamepad action.

The rest of the game should continue reading named actions from `scripts/core/action_mapper.gd`.

## AI Prompt For Hardware Mapping

> Add support for a new handmade Arduino controller. Keep the game-facing controls as W/A/S/D for movement and Space/E/Shift/R for place, switch, remove, and restart unless there is a strong reason to change them. Put Arduino firmware and serial bridge changes in `hardware/`. Only edit `InputBridge` if a new in-game action is needed. Do not put placement, defender, enemy, wave, or resource rules in the input layer.

For a fuller AI workflow, see `docs/AI_HARDWARE_CUSTOMIZATION_GUIDE.md`.
