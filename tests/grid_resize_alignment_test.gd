extends SceneTree

const ChickenScript := preload("res://scripts/defense/chicken_defender.gd")
const EnemyScript := preload("res://scripts/defense/enemy_base.gd")

var game: Node


func _init() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)

	var grid: Node = game.get_node("Board/LaneGrid")
	var defenders: Node = game.get_node("Actors/Defenders")
	var enemies: Node = game.get_node("Actors/Enemies")

	grid.call("_fit_to_viewport", Vector2(960, 540))
	var initial_actor_scale: float = grid.call("get_actor_scale")

	var defender_cell := Vector2i(3, 6)
	var defender: Node2D = ChickenScript.new()
	defenders.add_child(defender)
	if not bool(grid.call("place_defender", defender, defender_cell)):
		_fail("Could not place defender for resize alignment test.")
		return
	if absf(defender.scale.x - initial_actor_scale) > 0.001 or absf(defender.scale.y - initial_actor_scale) > 0.001:
		_fail("Defender did not scale to the initial grid cell size.")
		return

	var enemy: Node2D = EnemyScript.new()
	enemies.add_child(enemy)
	enemy.call("configure", grid, 3, 1)
	if absf(enemy.scale.x - initial_actor_scale) > 0.001 or absf(enemy.scale.y - initial_actor_scale) > 0.001:
		_fail("Enemy did not scale to the initial grid cell size.")
		return
	var start_board_rect: Rect2 = grid.call("get_board_rect")
	enemy.global_position.y = start_board_rect.position.y + start_board_rect.size.y * 0.45
	var enemy_progress := _vertical_progress(start_board_rect, enemy.global_position.y)

	var approaching_enemy: Node2D = EnemyScript.new()
	enemies.add_child(approaching_enemy)
	approaching_enemy.call("configure", grid, 4, 1)
	var approaching_spawn_position: Vector2 = grid.call("get_enemy_spawn_position", 4)
	approaching_enemy.global_position.y = lerpf(approaching_spawn_position.y, start_board_rect.position.y, 0.35)
	var approaching_progress := _approach_progress(
		approaching_spawn_position.y,
		start_board_rect.position.y,
		approaching_enemy.global_position.y
	)

	grid.call("_fit_to_viewport", Vector2(480, 640))
	var resized_actor_scale: float = grid.call("get_actor_scale")

	var expected_defender_position: Vector2 = grid.call("grid_to_world", defender_cell)
	if defender.global_position.distance_to(expected_defender_position) > 0.1:
		_fail("Defender did not stay aligned to its grid cell after resize.")
		return
	if absf(defender.scale.x - resized_actor_scale) > 0.001 or absf(defender.scale.y - resized_actor_scale) > 0.001:
		_fail("Defender did not rescale with the grid cell after resize.")
		return

	var resized_board_rect: Rect2 = grid.call("get_board_rect")
	var expected_enemy_spawn_x: float = float(grid.call("get_enemy_spawn_position", 3).x)
	var expected_enemy_y := lerpf(resized_board_rect.position.y, resized_board_rect.end.y, enemy_progress)
	if absf(enemy.global_position.x - expected_enemy_spawn_x) > 0.1:
		_fail("Enemy did not stay aligned to its lane after resize.")
		return
	if absf(enemy.global_position.y - expected_enemy_y) > 0.1:
		_fail("Enemy did not preserve board progress after resize.")
		return
	if absf(enemy.scale.x - resized_actor_scale) > 0.001 or absf(enemy.scale.y - resized_actor_scale) > 0.001:
		_fail("Enemy did not rescale with the grid cell after resize.")
		return

	var expected_approaching_spawn_position: Vector2 = grid.call("get_enemy_spawn_position", 4)
	var expected_approaching_y := lerpf(expected_approaching_spawn_position.y, resized_board_rect.position.y, approaching_progress)
	if absf(approaching_enemy.global_position.x - expected_approaching_spawn_position.x) > 0.1:
		_fail("Approaching enemy did not stay aligned to its lane after resize.")
		return
	if absf(approaching_enemy.global_position.y - expected_approaching_y) > 0.1:
		_fail("Approaching enemy did not preserve off-grid approach progress after resize.")
		return
	if absf(approaching_enemy.scale.x - resized_actor_scale) > 0.001 or absf(approaching_enemy.scale.y - resized_actor_scale) > 0.001:
		_fail("Approaching enemy did not rescale with the grid cell after resize.")
		return

	print("grid_resize_alignment_test: passed")
	quit(0)


func _vertical_progress(board_rect: Rect2, y_position: float) -> float:
	return clampf((y_position - board_rect.position.y) / board_rect.size.y, 0.0, 1.0)


func _approach_progress(spawn_y: float, board_top_y: float, y_position: float) -> float:
	if board_top_y <= spawn_y:
		return 1.0

	return clampf((y_position - spawn_y) / (board_top_y - spawn_y), 0.0, 1.0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
