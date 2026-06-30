# Controller Input Notes

The starter is designed around simple handmade Arduino controllers: one joystick or D-pad plus 2-3 buttons.

## Current Flow

```text
Keyboard / joystick / D-pad / Arduino keyboard bridge
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
- Remove/cancel: `Backspace` or Button X.
- Restart: `R` or gamepad Start.

The Arduino controller is expected to reach the game as normal keyboard input through a serial-to-keyboard bridge. The recommended bridge output is `W` for up, `S` for down, `A` for left, `D` for right, and `Space` for the main button. `InputBridge` listens to keydown-style `InputEventKey.pressed` events and queues one action per keydown. Held movement keys can still repeat through the placement movement cooldown.

For web/browser builds, `InputBridge` installs a small keydown guard through `JavaScriptBridge` when available. It calls `preventDefault()` for arrow keys, `Space`, `Tab`, `Backspace`, and `R` so the page does not scroll, move focus, or navigate away. The game canvas still needs focus; click/tap the game once before sending Arduino bridge input if the browser is not already focused on it.

## Connecting A Serial-To-Keyboard Bridge

If your Python bridge prints Arduino input in the terminal but the game does not react, the missing step is usually OS keyboard injection. Terminal output does not reach the game by itself. After your bridge parses a serial message, it must send a real key tap to the currently focused game window or browser canvas.

On macOS, allow the terminal app or Python in **System Settings > Privacy & Security > Accessibility**, otherwise the bridge can read serial input but cannot press keys for another app.

Before testing, click the running Summer game window or browser canvas once so it has focus. The bridge sends keys to whichever app is focused.

The bridge should read one command per serial line, such as `UP`, `DOWN`, `LEFT`, `RIGHT`, `W`, `A`, `S`, `D`, `SPACE`, `PLACE`, `BUTTON`, `SWITCH`, `REMOVE`, or `RESTART`. Convert movement to `W/A/S/D`, and convert `SPACE`, `PLACE`, `BUTTON`, `BUTTON1`, `BTN`, `BTN1`, or `BTNA` to the Space key. If your existing bridge already prints those words, replace the `print(...)` line with a real key tap using the same mapping.

## Where Arduino Code Should Go

Start in `scripts/core/input_bridge.gd`.

Add serial parsing or joystick/button calibration there, then output the same raw state keys that keyboard and gamepad fallback already use. The rest of the game should continue reading named actions from `scripts/core/action_mapper.gd`.

## AI Prompt For Hardware Mapping

> Add Arduino joystick-and-buttons input support to `InputBridge`. Preserve keyboard fallback. Convert the controller values into the existing action vocabulary. Do not put placement, defender, enemy, wave, or resource rules in the input layer.
