class_name PlacementController
extends Node

signal selection_changed(name: String, cost: int)
signal message_requested(message: String)

const ChickenScript := preload("res://scripts/defense/chicken_defender.gd")
const GoldenGooseScript := preload("res://scripts/defense/golden_goose_defender.gd")
const BlockerScript := preload("res://scripts/defense/blocker_defender.gd")

const DEFENDER_TYPES := [
	{"id": "hen", "name": "Hen", "cost": 50, "script": ChickenScript},
	{"id": "goose", "name": "Golden Goose", "cost": 75, "script": GoldenGooseScript},
	{"id": "blocker", "name": "Blocker", "cost": 35, "script": BlockerScript},
]

@export var move_repeat_delay: float = 0.18
@export var move_threshold: float = 0.45

var action_mapper: Node = null
var grid: Node = null
var resource_system: Node = null
var defenders_parent: Node = null
var cursor_cell: Vector2i = Vector2i(0, 1)
var selected_index: int = 0

var _move_cooldown: float = 0.0


func configure(action_mapper_ref: Node, grid_ref: Node, resource_ref: Node, defenders_parent_ref: Node) -> void:
	action_mapper = action_mapper_ref
	grid = grid_ref
	resource_system = resource_ref
	defenders_parent = defenders_parent_ref
	reset_cursor()


func reset_cursor() -> void:
	if grid != null:
		cursor_cell = grid.call("get_default_cursor_cell")
	else:
		cursor_cell = Vector2i(2, 5)
	selected_index = 0
	_emit_selection()
	if grid != null:
		grid.call("set_cursor", cursor_cell)


func _process(delta: float) -> void:
	if action_mapper == null or grid == null:
		return

	_move_cooldown = max(0.0, _move_cooldown - delta)
	_handle_cursor_movement()

	if bool(action_mapper.call("is_secondary_just_pressed")):
		_select_next_defender()
	if bool(action_mapper.call("is_modifier_just_pressed")):
		_remove_at_cursor()
	if bool(action_mapper.call("is_primary_just_pressed")):
		_place_selected_defender()


func get_selected_name() -> String:
	return str(DEFENDER_TYPES[selected_index]["name"])


func get_selected_cost() -> int:
	return int(DEFENDER_TYPES[selected_index]["cost"])


func _handle_cursor_movement() -> void:
	if _move_cooldown > 0.0:
		return

	var move_step := Vector2i.ZERO
	if action_mapper.has_method("pop_move_step"):
		move_step = action_mapper.call("pop_move_step")
	if move_step != Vector2i.ZERO:
		cursor_cell += move_step
		cursor_cell = grid.call("clamp_placement_cell", cursor_cell)
		grid.call("set_cursor", cursor_cell)
		_move_cooldown = move_repeat_delay
		return

	var move: Vector2 = action_mapper.call("get_move_vector")
	if move.length() < move_threshold:
		return

	if absf(move.x) >= absf(move.y):
		cursor_cell.x += 1 if move.x > 0.0 else -1
	else:
		cursor_cell.y += 1 if move.y > 0.0 else -1

	cursor_cell = grid.call("clamp_placement_cell", cursor_cell)
	grid.call("set_cursor", cursor_cell)
	_move_cooldown = move_repeat_delay


func _select_next_defender() -> void:
	selected_index = (selected_index + 1) % DEFENDER_TYPES.size()
	_emit_selection()
	message_requested.emit("Selected %s" % get_selected_name())


func _place_selected_defender() -> void:
	if not bool(grid.call("can_place_at", cursor_cell)):
		message_requested.emit("That tile is occupied.")
		return

	var cost := get_selected_cost()
	if not bool(resource_system.call("spend", cost)):
		message_requested.emit("Need %s energy." % cost)
		return

	var defender: Node2D = DEFENDER_TYPES[selected_index]["script"].new()
	if defender.has_method("configure_resource_system"):
		defender.call("configure_resource_system", resource_system)
	defenders_parent.add_child(defender)
	if not bool(grid.call("place_defender", defender, cursor_cell)):
		resource_system.call("add_energy", cost)
		defender.queue_free()
		message_requested.emit("Could not place there.")
		return

	message_requested.emit("Placed %s." % get_selected_name())


func _remove_at_cursor() -> void:
	var defender: Node = grid.call("remove_defender_at", cursor_cell)
	if defender == null:
		message_requested.emit("Nothing to remove.")
		return

	defender.queue_free()
	message_requested.emit("Removed defender.")


func _emit_selection() -> void:
	selection_changed.emit(get_selected_name(), get_selected_cost())
