extends SceneTree

const EnemyScript := preload("res://scripts/defense/enemy_base.gd")
const EggShellBurstScript := preload("res://scripts/defense/egg_shell_burst_effect.gd")

var frames: int = 0
var game: Node
var cursor_before_move: Vector2i = Vector2i.ZERO


func _init() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1

	var input_bridge := game.get_node("Systems/InputBridge")
	var placement := game.get_node("Systems/PlacementController")
	var resource := game.get_node("Systems/ResourceSystem")
	var wave := game.get_node("Systems/WaveDirector")
	var grid := game.get_node("Board/LaneGrid")
	var defenders := game.get_node("Actors/Defenders")
	var enemies := game.get_node("Actors/Enemies")
	var energy_bar: ProgressBar = game.get_node("HUD/Root/EnergyMeter/EnergyBar")

	if frames == 3:
		input_bridge.call("set_simulated_buttons", true)
	if frames == 5:
		input_bridge.call("set_simulated_buttons", false)

	if frames == 12:
		if defenders.get_child_count() != 1:
			return _fail("Expected primary button to place the first defender.")
		var first_defender: Node = defenders.get_child(0)
		if str(first_defender.get("kind")) != "hen":
			return _fail("Expected first defender type to be the animated hen.")
		if not _defender_visual_bottom_stays_inside_cell(grid, first_defender):
			return _fail("Expected hen feet to stay inside the placement cell during idle animation.")
		input_bridge.call("set_simulated_buttons", false, true)
	if frames == 14:
		input_bridge.call("set_simulated_buttons", false, false)

	if frames == 20:
		if int(placement.get("selected_index")) != 1:
			return _fail("Expected secondary button to switch defender type.")
		if str(placement.call("get_selected_name")) != "Golden Goose":
			return _fail("Expected the second defender option to be the Golden Goose producer.")
		cursor_before_move = placement.get("cursor_cell")
		input_bridge.call("set_simulated_axis", Vector2.RIGHT)

	if frames == 42:
		input_bridge.call("set_simulated_axis", Vector2.ZERO)
		var cursor_cell: Vector2i = placement.get("cursor_cell")
		if cursor_cell.x <= cursor_before_move.x:
			return _fail("Expected joystick axis to move the placement cursor.")
		input_bridge.call("set_simulated_buttons", true)

	if frames == 44:
		input_bridge.call("set_simulated_buttons", false)

	if frames == 58:
		if defenders.get_child_count() < 2:
			return _fail("Expected second primary press to place another defender.")
		var goose: Node = defenders.get_child(1)
		if str(goose.get("kind")) != "goose":
			return _fail("Expected second placed defender to be the Golden Goose.")
		var energy_before_production := int(resource.get("energy"))
		goose.call("tick_economy", float(goose.get("production_interval")) + 0.1)
		if int(resource.get("energy")) <= energy_before_production:
			return _fail("Expected Golden Goose to produce energy after its timer completes.")
		if energy_bar.max_value != float(resource.get("max_energy")):
			return _fail("Expected HUD energy bar to use ResourceSystem max energy.")
		wave.call("stop")
		wave.call("_begin_next_wave")
		var hen: Node = defenders.get_child(0)
		var enemy: Node2D = EnemyScript.new()
		enemies.add_child(enemy)
		enemy.call("configure", grid, int(hen.get("lane")), 1)
		enemy.defeated.connect(Callable(game, "_on_enemy_defeated"))
		if not _enemy_spawn_is_inside_grid(grid, enemy.global_position):
			return _fail("Expected enemy to spawn fully inside the grid.")
		var enemy_start_y := enemy.global_position.y
		var enemy_walk_time_before := float(enemy.get("_walk_time"))
		var enemy_frame_before := int(enemy.call("_get_walk_frame_index"))
		enemy.call("_process", 0.25)
		if enemy.global_position.y <= enemy_start_y:
			return _fail("Expected farmer enemy to walk downward on the grid.")
		if float(enemy.get("_walk_time")) <= enemy_walk_time_before:
			return _fail("Expected farmer enemy walk animation to advance while moving.")
		if int(enemy.call("_get_walk_frame_index")) == enemy_frame_before:
			return _fail("Expected farmer enemy to switch sprite frames while walking.")
		var enemy_health_before_shot := int(enemy.get("health"))
		var hen_damage := int(hen.get("damage"))
		hen.call("tick_attack", 1.0, enemies.get_children())
		if int(enemy.get("health")) != enemy_health_before_shot:
			return _fail("Expected hen shot to delay enemy damage until egg impact.")
		if float(hen.get("_throw_time_left")) < 0.35:
			return _fail("Expected hen attack to trigger a slower egg throw animation.")
		var egg_start: Vector2 = hen.get("_egg_start")
		var egg_end: Vector2 = hen.get("_egg_end")
		if absf(egg_start.x - egg_end.x) > 0.01:
			return _fail("Expected bazooka egg shot to travel straight upward.")
		if not bool(hen.get("_pending_shell_burst")):
			return _fail("Expected egg impact to queue broken shell VFX.")
		var shell_bursts_before := _count_egg_shell_bursts(root)
		hen.call("_process", 0.4)
		if int(enemy.get("health")) != enemy_health_before_shot - hen_damage:
			return _fail("Expected enemy damage to land at the same time as broken shell VFX.")
		if _count_egg_shell_bursts(root) <= shell_bursts_before:
			return _fail("Expected broken egg shell VFX to spawn at impact time.")

	if frames == 64:
		if enemies.get_child_count() == 0:
			return _fail("Expected test enemy to be present.")
		var enemy: Node = enemies.get_child(0)
		enemy.call("take_damage", 999)

	if frames == 70:
		if int(resource.get("energy")) <= 40:
			return _fail("Expected defeated enemy to reward energy.")
		game.call("_on_base_breached", null)
		game.call("_on_base_breached", null)
		game.call("_on_base_breached", null)

	if frames == 74:
		var game_over_panel: Control = game.get_node("HUD/Root/GameOverPanel")
		var results_label: Label = game.get_node("HUD/Root/GameOverPanel/Margin/Stack/ResultsLabel")
		if not game_over_panel.visible:
			return _fail("Expected game over panel to appear after base health reaches zero.")
		if not results_label.text.contains("Farmers chased off: 1"):
			return _fail("Expected game over panel to show defeated enemy totals.")
		input_bridge.call("set_simulated_buttons", false, false, false, true)

	if frames == 78:
		input_bridge.call("set_simulated_buttons", false, false, false, false)

	if frames == 84:
		var game_over_panel_after_restart: Control = game.get_node("HUD/Root/GameOverPanel")
		if game_over_panel_after_restart.visible:
			return _fail("Expected restart action to hide the game over panel.")
		print("lane_defense_smoke_test: passed")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return true


func _enemy_spawn_is_inside_grid(grid: Node, enemy_position: Vector2) -> bool:
	var board_rect: Rect2 = grid.call("get_board_rect")
	var actor_scale: float = grid.call("get_actor_scale")
	var enemy_top_left := enemy_position - Vector2(29.0, 58.0) * actor_scale
	var enemy_bottom_right := enemy_position + Vector2(29.0, 36.0) * actor_scale
	return board_rect.has_point(enemy_top_left) and board_rect.has_point(enemy_bottom_right)


func _defender_visual_bottom_stays_inside_cell(grid: Node, defender: Node) -> bool:
	if not defender.has_method("_get_chicken_draw_rect"):
		return false

	var defender_node := defender as Node2D
	if defender_node == null:
		return false

	var idle_time_before := float(defender.get("_idle_time"))
	var cell := Vector2i(int(defender.get("column")), int(defender.get("row")))
	var origin: Vector2 = grid.get("origin")
	var cell_size: Vector2 = grid.get("cell_size")
	var cell_gap := float(grid.get("cell_gap"))
	var cell_bottom := origin.y + float(cell.y) * cell_size.y + cell_size.y - cell_gap

	for step in range(24):
		defender.set("_idle_time", float(step) / 12.0)
		var visual_rect: Rect2 = defender.call("_get_chicken_draw_rect")
		var visual_bottom := defender_node.global_position.y + visual_rect.end.y * defender_node.scale.y
		if visual_bottom > cell_bottom + 0.5:
			defender.set("_idle_time", idle_time_before)
			return false

	defender.set("_idle_time", idle_time_before)
	return true


func _count_egg_shell_bursts(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child.get_script() == EggShellBurstScript:
			count += 1
		count += _count_egg_shell_bursts(child)
	return count
