class_name EnemyBase
extends Node2D

signal breached(enemy: Node)
signal defeated(enemy: Node)

const FARMER_WALK_SHEET: Texture2D = preload("res://assets/art/farmer_walk_sheet.png")
const FARMER_WALK_FRAME_COUNT := 4

var lane: int = 0
var kind: String = "farmer"
var display_name: String = "Farmer"
var max_health: int = 90
var health: int = 90
var speed: float = 36.0
var damage: int = 18
var attack_interval: float = 0.8
var walk_cycle_speed: float = 6.0
var grid: Node = null

var _attack_timer: float = 0.0
var _walk_time: float = 0.0


func configure(grid_ref: Node, lane_index: int, wave_number: int) -> void:
	_disconnect_grid_layout_signal()
	grid = grid_ref
	lane = lane_index
	_connect_grid_layout_signal()
	max_health = 80 + wave_number * 12
	health = max_health
	speed = 34.0 + wave_number * 2.0
	grid.call("apply_actor_scale", self)
	global_position = grid.call("get_enemy_spawn_position", lane)
	queue_redraw()


func _process(delta: float) -> void:
	if grid == null:
		return

	var defender: Node = grid.call("find_defender_for_enemy", lane, global_position.y)
	if defender != null and defender.has_method("take_damage"):
		_attack_timer = max(0.0, _attack_timer - delta)
		if _attack_timer == 0.0:
			defender.call("take_damage", damage)
			_attack_timer = attack_interval
	else:
		global_position.y += speed * delta
		_walk_time += delta * walk_cycle_speed

	if global_position.y >= float(grid.call("get_breach_y")):
		breached.emit(self)
		queue_free()

	queue_redraw()


func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health <= 0:
		defeated.emit(self)
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	_draw_farmer_frame()
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-24, -56), Vector2(48, 5)), Color(0.12, 0.12, 0.14, 1.0), true)
	draw_rect(Rect2(Vector2(-24, -56), Vector2(48 * health_ratio, 5)), Color(1.0, 0.75, 0.18, 1.0), true)


func _draw_farmer_frame() -> void:
	var texture_size := FARMER_WALK_SHEET.get_size()
	var frame_width := texture_size.x / float(FARMER_WALK_FRAME_COUNT)
	var source_rect := Rect2(
		Vector2(frame_width * float(_get_walk_frame_index()), 0.0),
		Vector2(frame_width, texture_size.y)
	)
	var draw_rect := Rect2(Vector2(-29, -48), Vector2(58, 84))
	draw_texture_rect_region(FARMER_WALK_SHEET, draw_rect, source_rect)


func _get_walk_frame_index() -> int:
	return int(floor(_walk_time)) % FARMER_WALK_FRAME_COUNT


func _connect_grid_layout_signal() -> void:
	if grid == null or not grid.has_signal("layout_changed"):
		return

	var callback := Callable(self, "_on_grid_layout_changed")
	if not grid.is_connected("layout_changed", callback):
		grid.connect("layout_changed", callback)


func _disconnect_grid_layout_signal() -> void:
	if grid == null or not grid.has_signal("layout_changed"):
		return

	var callback := Callable(self, "_on_grid_layout_changed")
	if grid.is_connected("layout_changed", callback):
		grid.disconnect("layout_changed", callback)


func _on_grid_layout_changed(previous_board_rect: Rect2, current_board_rect: Rect2) -> void:
	grid.call("apply_actor_scale", self)
	if previous_board_rect.size.y <= 0.0:
		global_position = grid.call("get_enemy_spawn_position", lane)
		queue_redraw()
		return

	var progress := clampf(
		(global_position.y - previous_board_rect.position.y) / previous_board_rect.size.y,
		0.0,
		1.0
	)
	var lane_position: Vector2 = grid.call("get_enemy_spawn_position", lane)
	global_position = Vector2(
		lane_position.x,
		lerpf(current_board_rect.position.y, current_board_rect.end.y, progress)
	)
	queue_redraw()
