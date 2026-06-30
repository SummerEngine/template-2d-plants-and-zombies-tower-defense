extends SceneTree

const CASES: Array[Dictionary] = [
	{"name": "wide", "size": Vector2i(960, 540), "right_panel_visible": true},
	{"name": "medium", "size": Vector2i(640, 480), "right_panel_visible": false},
	{"name": "portrait", "size": Vector2i(480, 640), "right_panel_visible": false},
]
const MAX_BOARD_HEIGHT_RATIO := 0.72
const MAX_APPROACH_HEIGHT_RATIO := 0.80

var case_index: int = -1
var frames: int = 0
var game: Node = null


func _init() -> void:
	_start_next_case()


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false

	if not _check_current_case():
		return true

	_start_next_case()
	return false


func _start_next_case() -> void:
	if game != null:
		root.remove_child(game)
		game.queue_free()

	case_index += 1
	if case_index >= CASES.size():
		print("responsive_layout_smoke_test: passed")
		quit(0)
		return

	var case_data: Dictionary = CASES[case_index]
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	frames = 0


func _check_current_case() -> bool:
	var case_data: Dictionary = CASES[case_index]
	var case_name: String = str(case_data["name"])
	var viewport_size := Vector2(case_data["size"])
	var top_left: Control = game.get_node("HUD/Root/TopLeft")
	var energy_meter: Control = game.get_node("HUD/Root/EnergyMeter")
	var bottom_left: Control = game.get_node("HUD/Root/BottomLeft")
	var bottom_center: Control = game.get_node("HUD/Root/BottomCenter")
	var right_panel: Control = game.get_node("HUD/Root/RightPanel")
	var game_over_panel: Control = game.get_node("HUD/Root/GameOverPanel")
	var grid: Node = game.get_node("Board/LaneGrid")
	var hud: Node = game.get_node("HUD")

	grid.call("_fit_to_viewport", viewport_size)
	hud.call("_apply_responsive_layout", viewport_size)

	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)

	if right_panel.visible != bool(case_data["right_panel_visible"]):
		return _fail("%s expected right panel visibility to be %s." % [case_name, case_data["right_panel_visible"]])

	var top_left_rect := _control_rect(top_left)
	var energy_meter_rect := _control_rect(energy_meter)
	var bottom_center_rect := _control_rect(bottom_center)
	var game_over_rect := _control_rect(game_over_panel)
	if not _rect_inside(top_left_rect, viewport_rect):
		return _fail("%s top-left HUD is outside the viewport." % case_name)
	if not _rect_inside(energy_meter_rect, viewport_rect):
		return _fail("%s energy meter is outside the viewport." % case_name)
	if not _rect_inside(bottom_center_rect, viewport_rect):
		return _fail("%s message HUD is outside the viewport." % case_name)
	if not _rect_inside(game_over_rect, viewport_rect):
		return _fail("%s game-over panel is outside the viewport." % case_name)

	var origin: Vector2 = grid.get("origin")
	var cell_size: Vector2 = grid.get("cell_size")
	var columns: int = int(grid.get("columns"))
	var rows: int = int(grid.get("rows"))
	if columns != 7 or rows != 7:
		return _fail("%s expected a 7 by 7 grid." % case_name)
	var board_rect := Rect2(origin, Vector2(cell_size.x * columns, cell_size.y * rows))
	var drawn_board_rect := Rect2(origin, Vector2(cell_size.x * columns - 8.0, cell_size.y * rows - 8.0))
	var first_spawn_rect: Rect2 = grid.call("get_enemy_spawn_cell_rect", 0)
	var approach_top_y := minf(first_spawn_rect.position.y, drawn_board_rect.position.y)
	var approach_height_ratio := (drawn_board_rect.end.y - approach_top_y) / viewport_size.y
	var board_height_ratio := drawn_board_rect.size.y / viewport_size.y
	if not _rect_inside(board_rect, viewport_rect.grow(8.0)):
		return _fail("%s board does not fit inside the viewport." % case_name)
	if board_height_ratio > MAX_BOARD_HEIGHT_RATIO:
		return _fail("%s board uses too much viewport height." % case_name)
	if approach_height_ratio > MAX_APPROACH_HEIGHT_RATIO:
		return _fail("%s board plus virtual spawn row uses too much viewport height." % case_name)
	if board_rect.intersects(top_left_rect):
		return _fail("%s top-left HUD overlaps the board." % case_name)
	if board_rect.intersects(energy_meter_rect):
		return _fail("%s energy meter overlaps the board." % case_name)
	if board_rect.intersects(bottom_center_rect):
		return _fail("%s message HUD overlaps the board." % case_name)
	if energy_meter_rect.intersects(bottom_center_rect):
		return _fail("%s energy meter overlaps the message HUD." % case_name)
	if absf(energy_meter_rect.get_center().x - viewport_size.x * 0.5) > 1.0:
		return _fail("%s energy meter is not centered horizontally." % case_name)
	var energy_bottom_ratio := (viewport_size.y - energy_meter_rect.get_center().y) / viewport_size.y
	if energy_bottom_ratio < 0.12 or energy_bottom_ratio > 0.30:
		return _fail("%s energy meter is not around the lower fifth of the screen." % case_name)

	if bottom_left.visible:
		var bottom_left_rect := _control_rect(bottom_left)
		if not _rect_inside(bottom_left_rect, viewport_rect):
			return _fail("%s controls HUD is outside the viewport." % case_name)
		if bottom_left_rect.intersects(bottom_center_rect):
			return _fail("%s controls HUD overlaps the message HUD." % case_name)
		if board_rect.intersects(bottom_left_rect):
			return _fail("%s controls HUD overlaps the board." % case_name)
		if bottom_left_rect.intersects(energy_meter_rect):
			return _fail("%s controls HUD overlaps the energy meter." % case_name)

	for lane in range(columns):
		var actor_scale: float = grid.call("get_actor_scale")
		var enemy_position: Vector2 = grid.call("get_enemy_spawn_position", lane)
		var spawn_rect: Rect2 = grid.call("get_enemy_spawn_cell_rect", lane)
		var enemy_half_width := 29.0 * actor_scale
		if not spawn_rect.grow(1.0).has_point(enemy_position):
			return _fail("%s enemy spawn for lane %s is not in the virtual top row." % [case_name, lane])
		if enemy_position.y >= origin.y:
			return _fail("%s enemy spawn for lane %s should be above the grid." % [case_name, lane])
		if enemy_position.x - enemy_half_width < origin.x or enemy_position.x + enemy_half_width > origin.x + cell_size.x * columns - 8.0:
			return _fail("%s enemy spawn for lane %s is horizontally outside the grid." % [case_name, lane])

	return true


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return outer.has_point(inner.position) and outer.has_point(inner.end)


func _control_rect(control: Control) -> Rect2:
	return Rect2(
		Vector2(control.offset_left, control.offset_top),
		Vector2(control.offset_right - control.offset_left, control.offset_bottom - control.offset_top)
	)


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
