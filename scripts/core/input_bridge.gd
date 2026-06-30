class_name SignalInputBridge
extends Node

signal raw_input_changed(raw_state: Dictionary)

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_MOVE_UP := "move_up"
const ACTION_MOVE_DOWN := "move_down"
const ACTION_PRIMARY := "primary"
const ACTION_SECONDARY := "secondary"
const ACTION_MODIFIER := "modifier"
const ACTION_RESTART := "restart"

@export var use_keyboard_fallback: bool = true
@export var use_joypad_fallback: bool = true
@export_range(0.0, 1.0, 0.01) var analog_deadzone: float = 0.18

var raw_state: Dictionary = {
	"move_axis": Vector2.ZERO,
	"move_steps": [],
	"primary": false,
	"primary_just_pressed": false,
	"secondary": false,
	"secondary_just_pressed": false,
	"modifier": false,
	"modifier_just_pressed": false,
	"restart_just_pressed": false,
}

var simulated_axis: Vector2 = Vector2.ZERO
var simulated_primary: bool = false
var simulated_secondary: bool = false
var simulated_modifier: bool = false
var simulated_restart: bool = false
var _previous_primary: bool = false
var _previous_secondary: bool = false
var _previous_modifier: bool = false
var _previous_restart: bool = false
var _queued_move_steps: Array[Vector2i] = []
var _queued_primary_just_pressed: bool = false
var _queued_secondary_just_pressed: bool = false
var _queued_modifier_just_pressed: bool = false
var _queued_restart_just_pressed: bool = false


func _ready() -> void:
	if use_keyboard_fallback:
		_ensure_default_actions()
		_install_web_keyboard_guard()
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not use_keyboard_fallback:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed:
		return

	if _is_browser_guard_key(key_event):
		get_viewport().set_input_as_handled()

	if key_event.echo:
		return

	if _key_event_matches(key_event, [KEY_LEFT, KEY_A]):
		_queued_move_steps.append(Vector2i.LEFT)
	elif _key_event_matches(key_event, [KEY_RIGHT, KEY_D]):
		_queued_move_steps.append(Vector2i.RIGHT)
	elif _key_event_matches(key_event, [KEY_UP, KEY_W]):
		_queued_move_steps.append(Vector2i.UP)
	elif _key_event_matches(key_event, [KEY_DOWN, KEY_S]):
		_queued_move_steps.append(Vector2i.DOWN)
	elif _key_event_matches(key_event, [KEY_SPACE]):
		_queued_primary_just_pressed = true
	elif _key_event_matches(key_event, [KEY_E, KEY_TAB]):
		_queued_secondary_just_pressed = true
	elif _key_event_matches(key_event, [KEY_BACKSPACE, KEY_SHIFT]):
		_queued_modifier_just_pressed = true
	elif _key_event_matches(key_event, [KEY_R]):
		_queued_restart_just_pressed = true


func sample() -> Dictionary:
	var move_axis := Vector2.ZERO
	var queued_move_steps := _queued_move_steps.duplicate()
	var queued_primary_just_pressed := _queued_primary_just_pressed
	var queued_secondary_just_pressed := _queued_secondary_just_pressed
	var queued_modifier_just_pressed := _queued_modifier_just_pressed
	var queued_restart_just_pressed := _queued_restart_just_pressed
	_clear_queued_keydown_actions()

	if use_keyboard_fallback:
		move_axis += Input.get_vector(
			ACTION_MOVE_LEFT,
			ACTION_MOVE_RIGHT,
			ACTION_MOVE_UP,
			ACTION_MOVE_DOWN
		)

	if use_joypad_fallback:
		move_axis += _read_joypad_axis()

	move_axis += simulated_axis
	move_axis = move_axis.limit_length(1.0)

	if move_axis.length() < analog_deadzone:
		move_axis = Vector2.ZERO

	var primary_pressed := Input.is_action_pressed(ACTION_PRIMARY) or _is_joy_button_pressed(JOY_BUTTON_A) or simulated_primary or queued_primary_just_pressed
	var secondary_pressed := Input.is_action_pressed(ACTION_SECONDARY) or _is_joy_button_pressed(JOY_BUTTON_B) or simulated_secondary or queued_secondary_just_pressed
	var modifier_pressed := Input.is_action_pressed(ACTION_MODIFIER) or _is_joy_button_pressed(JOY_BUTTON_X) or simulated_modifier or queued_modifier_just_pressed
	var restart_pressed := Input.is_action_pressed(ACTION_RESTART) or _is_joy_button_pressed(JOY_BUTTON_START) or simulated_restart or queued_restart_just_pressed

	raw_state = {
		"move_axis": move_axis,
		"move_steps": queued_move_steps,
		"primary": primary_pressed,
		"primary_just_pressed": queued_primary_just_pressed or Input.is_action_just_pressed(ACTION_PRIMARY) or (primary_pressed and not _previous_primary),
		"secondary": secondary_pressed,
		"secondary_just_pressed": queued_secondary_just_pressed or Input.is_action_just_pressed(ACTION_SECONDARY) or (secondary_pressed and not _previous_secondary),
		"modifier": modifier_pressed,
		"modifier_just_pressed": queued_modifier_just_pressed or Input.is_action_just_pressed(ACTION_MODIFIER) or (modifier_pressed and not _previous_modifier),
		"restart_just_pressed": queued_restart_just_pressed or Input.is_action_just_pressed(ACTION_RESTART) or (restart_pressed and not _previous_restart),
	}
	_previous_primary = primary_pressed
	_previous_secondary = secondary_pressed
	_previous_modifier = modifier_pressed
	_previous_restart = restart_pressed
	raw_input_changed.emit(raw_state)
	return raw_state


func set_simulated_axis(axis: Vector2) -> void:
	simulated_axis = axis.limit_length(1.0)


func set_simulated_buttons(primary: bool, secondary: bool = false, modifier: bool = false, restart: bool = false) -> void:
	simulated_primary = primary
	simulated_secondary = secondary
	simulated_modifier = modifier
	simulated_restart = restart


func _read_joypad_axis() -> Vector2:
	var axis := Vector2.ZERO
	axis.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	axis.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	return axis


func _is_joy_button_pressed(button: JoyButton) -> bool:
	return use_joypad_fallback and Input.is_joy_button_pressed(0, button)


func _ensure_default_actions() -> void:
	_ensure_action_with_keys(ACTION_MOVE_LEFT, [KEY_LEFT, KEY_A])
	_ensure_action_with_keys(ACTION_MOVE_RIGHT, [KEY_RIGHT, KEY_D])
	_ensure_action_with_keys(ACTION_MOVE_UP, [KEY_UP, KEY_W])
	_ensure_action_with_keys(ACTION_MOVE_DOWN, [KEY_DOWN, KEY_S])
	_ensure_action_with_keys(ACTION_PRIMARY, [KEY_SPACE])
	_ensure_action_with_keys(ACTION_SECONDARY, [KEY_E, KEY_TAB])
	_ensure_action_with_keys(ACTION_MODIFIER, [KEY_BACKSPACE, KEY_SHIFT])
	_ensure_action_with_keys(ACTION_RESTART, [KEY_R])


func _ensure_action_with_keys(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keycodes:
		if _action_has_key(action_name, keycode):
			continue
		var event := InputEventKey.new()
		event.keycode = keycode as Key
		InputMap.action_add_event(action_name, event)


func _action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		var key_event := event as InputEventKey
		if key_event != null and int(key_event.keycode) == keycode:
			return true
	return false


func _key_event_matches(key_event: InputEventKey, keycodes: Array[int]) -> bool:
	return keycodes.has(int(key_event.keycode)) or keycodes.has(int(key_event.physical_keycode))


func _is_browser_guard_key(key_event: InputEventKey) -> bool:
	return _key_event_matches(key_event, [
		KEY_UP,
		KEY_DOWN,
		KEY_LEFT,
		KEY_RIGHT,
		KEY_SPACE,
		KEY_TAB,
		KEY_BACKSPACE,
		KEY_R,
	])


func _clear_queued_keydown_actions() -> void:
	_queued_move_steps.clear()
	_queued_primary_just_pressed = false
	_queued_secondary_just_pressed = false
	_queued_modifier_just_pressed = false
	_queued_restart_just_pressed = false


func _install_web_keyboard_guard() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		return

	var js_bridge := Engine.get_singleton("JavaScriptBridge")
	if js_bridge == null or not js_bridge.has_method("eval"):
		return

	js_bridge.call("eval", """
		(function () {
			if (window.__signalDefenseKeyboardGuardInstalled) return;
			window.__signalDefenseKeyboardGuardInstalled = true;
			const guardedCodes = new Set([
				"ArrowUp",
				"ArrowDown",
				"ArrowLeft",
				"ArrowRight",
				"Space",
				"Tab",
				"Backspace",
				"KeyR"
			]);
			window.addEventListener("keydown", function (event) {
				if (guardedCodes.has(event.code)) {
					event.preventDefault();
				}
			}, { capture: true });
			const canvas = document.querySelector("canvas");
			if (canvas) {
				canvas.tabIndex = 0;
				canvas.addEventListener("pointerdown", function () {
					canvas.focus();
				});
			}
		})();
	""")
