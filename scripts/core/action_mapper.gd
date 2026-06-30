class_name SignalActionMapper
extends Node

signal actions_changed(actions: Dictionary)

@export var input_bridge_path: NodePath
@export_range(0.0, 1.0, 0.01) var move_deadzone: float = 0.15

var input_bridge: Variant = null
var actions: Dictionary = {
	"move": Vector2.ZERO,
	"primary": false,
	"primary_just_pressed": false,
	"secondary": false,
	"secondary_just_pressed": false,
	"modifier": false,
	"modifier_just_pressed": false,
	"restart_just_pressed": false,
}
var _pending_move_steps: Array[Vector2i] = []


func _ready() -> void:
	if input_bridge_path != NodePath():
		input_bridge = get_node_or_null(input_bridge_path)


func _process(_delta: float) -> void:
	if input_bridge == null:
		return

	var raw_state: Dictionary = input_bridge.sample()
	for step in raw_state.get("move_steps", []):
		if step is Vector2i:
			_pending_move_steps.append(step)

	var move_axis: Vector2 = raw_state.get("move_axis", Vector2.ZERO)
	if move_axis.length() < move_deadzone:
		move_axis = Vector2.ZERO

	actions = {
		"move": move_axis.limit_length(1.0),
		"move_step_count": _pending_move_steps.size(),
		"primary": raw_state.get("primary", false),
		"primary_just_pressed": raw_state.get("primary_just_pressed", false),
		"secondary": raw_state.get("secondary", false),
		"secondary_just_pressed": raw_state.get("secondary_just_pressed", false),
		"modifier": raw_state.get("modifier", false),
		"modifier_just_pressed": raw_state.get("modifier_just_pressed", false),
		"restart_just_pressed": raw_state.get("restart_just_pressed", false),
	}
	actions_changed.emit(actions)


func get_move_vector() -> Vector2:
	return actions.get("move", Vector2.ZERO)


func pop_move_step() -> Vector2i:
	if _pending_move_steps.is_empty():
		return Vector2i.ZERO

	return _pending_move_steps.pop_front()


func is_primary_pressed() -> bool:
	return actions.get("primary", false)


func is_secondary_pressed() -> bool:
	return actions.get("secondary", false)


func is_modifier_pressed() -> bool:
	return actions.get("modifier", false)


func is_primary_just_pressed() -> bool:
	return actions.get("primary_just_pressed", false)


func is_secondary_just_pressed() -> bool:
	return actions.get("secondary_just_pressed", false)


func is_modifier_just_pressed() -> bool:
	return actions.get("modifier_just_pressed", false)


func is_restart_just_pressed() -> bool:
	return actions.get("restart_just_pressed", false)
