class_name LaneGrid
extends Node2D

const GRASS_TILE_TEXTURE: Texture2D = preload("res://assets/art/grid_grass_tile.png")
const PEBBLE_TILE_TEXTURE: Texture2D = preload("res://assets/art/grid_pebble_tile.png")

signal layout_changed(previous_board_rect: Rect2, current_board_rect: Rect2)

@export var rows: int = 7
@export var columns: int = 7
@export var origin: Vector2 = Vector2(110, 145)
@export var cell_size: Vector2 = Vector2(56, 56)
@export var cell_gap: float = 8.0
@export var placement_start_row: int = 4
@export var actor_base_cell_size: float = 56.0
@export var player_domain_tile_texture: Texture2D = GRASS_TILE_TEXTURE
@export var farmer_domain_tile_texture: Texture2D = PEBBLE_TILE_TEXTURE

var cursor_cell: Vector2i = Vector2i(3, 6)
var occupied_cells: Dictionary = {}


func _ready() -> void:
	placement_start_row = clampi(placement_start_row, 0, rows - 1)
	cursor_cell = clamp_placement_cell(cursor_cell)
	_fit_to_viewport()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _draw() -> void:
	for row in range(rows):
		for column in range(columns):
			var rect := Rect2(
				origin + Vector2(column * cell_size.x, row * cell_size.y),
				cell_size - Vector2(cell_gap, cell_gap)
			)
			var texture := player_domain_tile_texture if row >= placement_start_row else farmer_domain_tile_texture
			if texture != null:
				draw_texture_rect(texture, rect, false)
			else:
				var fill := Color(0.14, 0.17, 0.22, 1.0)
				if row >= placement_start_row:
					fill = Color(0.15, 0.24, 0.18, 1.0)
				if (row + column) % 2 == 0:
					fill = Color(0.17, 0.20, 0.26, 1.0)
					if row >= placement_start_row:
						fill = Color(0.18, 0.29, 0.21, 1.0)
				draw_rect(rect, fill, true)
			draw_rect(rect, Color(0.22, 0.10, 0.13, 0.9), false, 2.0)

	var board_rect := Rect2(origin, Vector2(columns * cell_size.x - cell_gap, rows * cell_size.y - cell_gap))
	draw_line(
		Vector2(board_rect.position.x, origin.y + placement_start_row * cell_size.y - cell_gap * 0.5),
		Vector2(board_rect.end.x, origin.y + placement_start_row * cell_size.y - cell_gap * 0.5),
		Color(0.9, 0.76, 0.32, 1.0),
		3.0
	)
	draw_line(
		Vector2(board_rect.position.x, board_rect.end.y + 12.0),
		Vector2(board_rect.end.x, board_rect.end.y + 12.0),
		Color(0.8, 0.24, 0.18, 1.0),
		5.0
	)

	var cursor_rect := Rect2(
		origin + Vector2(cursor_cell.x * cell_size.x, cursor_cell.y * cell_size.y),
		cell_size - Vector2(cell_gap, cell_gap)
	)
	draw_rect(cursor_rect.grow(4.0), Color(1.0, 0.82, 0.25, 1.0), false, 4.0)


func set_cursor(cell: Vector2i) -> void:
	cursor_cell = clamp_placement_cell(cell)
	queue_redraw()


func clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, columns - 1),
		clampi(cell.y, 0, rows - 1)
	)


func clamp_placement_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, columns - 1),
		clampi(cell.y, placement_start_row, rows - 1)
	)


func get_default_cursor_cell() -> Vector2i:
	return Vector2i(int(columns / 2), rows - 1)


func can_place_at(cell: Vector2i) -> bool:
	var clamped := clamp_cell(cell)
	return clamped.y >= placement_start_row and is_cell_empty(clamped)


func grid_to_world(cell: Vector2i) -> Vector2:
	var clamped := clamp_cell(cell)
	return origin + Vector2(
		clamped.x * cell_size.x + (cell_size.x - cell_gap) * 0.5,
		clamped.y * cell_size.y + (cell_size.y - cell_gap) * 0.5
	)


func get_board_rect() -> Rect2:
	return Rect2(origin, Vector2(columns * cell_size.x - cell_gap, rows * cell_size.y - cell_gap))


func get_actor_scale() -> float:
	if actor_base_cell_size <= 0.0:
		return 1.0

	return cell_size.x / actor_base_cell_size


func apply_actor_scale(actor: Node2D) -> void:
	var actor_scale := get_actor_scale()
	actor.scale = Vector2(actor_scale, actor_scale)


func get_enemy_spawn_position(lane: int) -> Vector2:
	var column := clampi(lane, 0, columns - 1)
	var board_rect := get_board_rect()
	var lane_position := grid_to_world(Vector2i(column, 0))
	var actor_scale := get_actor_scale()
	var enemy_half_width := 29.0 * actor_scale
	var enemy_top_clearance := 58.0 * actor_scale
	var safe_inset := 1.0
	return Vector2(
		clampf(
			lane_position.x,
			board_rect.position.x + enemy_half_width + safe_inset,
			board_rect.end.x - enemy_half_width - safe_inset
		),
		board_rect.position.y + enemy_top_clearance + safe_inset
	)


func get_breach_y() -> float:
	return get_board_rect().end.y + 54.0 * get_actor_scale()


func is_cell_empty(cell: Vector2i) -> bool:
	return not occupied_cells.has(_cell_key(clamp_cell(cell)))


func get_defender(cell: Vector2i) -> Node:
	return occupied_cells.get(_cell_key(clamp_cell(cell)), null)


func place_defender(defender: Node2D, cell: Vector2i) -> bool:
	var clamped := clamp_placement_cell(cell)
	var key := _cell_key(clamped)
	if occupied_cells.has(key):
		return false

	occupied_cells[key] = defender
	defender.set("lane", clamped.x)
	defender.set("column", clamped.x)
	defender.set("row", clamped.y)
	apply_actor_scale(defender)
	defender.global_position = grid_to_world(clamped)
	if defender.has_signal("destroyed"):
		defender.destroyed.connect(_on_defender_destroyed)
	queue_redraw()
	return true


func remove_defender_at(cell: Vector2i) -> Node:
	var clamped := clamp_cell(cell)
	var key := _cell_key(clamped)
	var defender: Node = occupied_cells.get(key, null)
	if defender != null:
		occupied_cells.erase(key)
		queue_redraw()
	return defender


func clear_occupancy() -> void:
	occupied_cells.clear()
	queue_redraw()


func find_defender_for_enemy(lane: int, enemy_y: float) -> Node:
	var column := clampi(lane, 0, columns - 1)
	for row in range(placement_start_row, rows):
		var defender := get_defender(Vector2i(column, row))
		if defender == null:
			continue

		var actor_scale := get_actor_scale()
		var defender_y: float = (defender as Node2D).global_position.y
		if enemy_y >= defender_y - 46.0 * actor_scale and enemy_y <= defender_y + 34.0 * actor_scale:
			return defender

	return null


func _on_defender_destroyed(defender: Node) -> void:
	for key in occupied_cells.keys():
		if occupied_cells[key] == defender:
			occupied_cells.erase(key)
			queue_redraw()
			return


func _reposition_occupied_defenders() -> void:
	for key in occupied_cells.keys():
		var defender: Node = occupied_cells.get(key, null)
		if not is_instance_valid(defender):
			occupied_cells.erase(key)
			continue

		var cell := _cell_from_key(str(key))
		defender.set("lane", cell.x)
		defender.set("column", cell.x)
		defender.set("row", cell.y)
		var defender_node := defender as Node2D
		apply_actor_scale(defender_node)
		defender_node.global_position = grid_to_world(cell)


func _cell_key(cell: Vector2i) -> String:
	return "%s:%s" % [cell.y, cell.x]


func _cell_from_key(key: String) -> Vector2i:
	var parts := key.split(":")
	if parts.size() != 2:
		return clamp_cell(Vector2i.ZERO)

	return clamp_cell(Vector2i(int(parts[1]), int(parts[0])))


func _on_viewport_size_changed() -> void:
	_fit_to_viewport()


func _fit_to_viewport(size_override: Vector2 = Vector2.ZERO) -> void:
	var previous_board_rect: Rect2 = get_board_rect()
	var viewport_size: Vector2 = size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
	var wide_layout: bool = viewport_size.x >= 860.0 and viewport_size.y >= 500.0
	var side_reserve: float = 250.0 if wide_layout else 28.0
	var hud_margin: float = clampf(viewport_size.x * 0.025, 10.0, 22.0)
	var top_margin: float = 44.0 if wide_layout else hud_margin + 150.0
	var bottom_margin: float = 126.0 if wide_layout else hud_margin + 116.0
	var available_width: float = maxf(180.0, viewport_size.x - side_reserve * 2.0)
	var min_side: float = 42.0
	if viewport_size.x < 520.0 or viewport_size.y < 540.0:
		min_side = 24.0
	if viewport_size.x < 460.0 or viewport_size.y < 420.0:
		min_side = 20.0
	var available_height: float = maxf(float(rows) * min_side, viewport_size.y - top_margin - bottom_margin)
	var side: float = floorf(minf(available_width / float(columns), available_height / float(rows)))
	side = clampf(side, min_side, 112.0)
	cell_size = Vector2(side, side)
	origin = Vector2(
		maxf(10.0, (viewport_size.x - side * float(columns)) * 0.5),
		maxf(top_margin, top_margin + (available_height - side * float(rows)) * 0.5)
	)
	cursor_cell = clamp_placement_cell(cursor_cell)
	_reposition_occupied_defenders()
	queue_redraw()
	var current_board_rect: Rect2 = get_board_rect()
	if previous_board_rect != current_board_rect:
		layout_changed.emit(previous_board_rect, current_board_rect)
