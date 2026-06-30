class_name DefenseGame
extends Node2D

@export var starting_base_health: int = 3
@export var enemy_defeat_energy: int = 15

@onready var background: ColorRect = $Background
@onready var input_bridge: Node = $Systems/InputBridge
@onready var action_mapper: Node = $Systems/ActionMapper
@onready var grid: Node = $Board/LaneGrid
@onready var defenders_parent: Node = $Actors/Defenders
@onready var enemies_parent: Node = $Actors/Enemies
@onready var resource_system: Node = $Systems/ResourceSystem
@onready var placement_controller: Node = $Systems/PlacementController
@onready var wave_director: Node = $Systems/WaveDirector
@onready var run_stats: Node = $Systems/RunStats
@onready var hud: Node = $HUD

var base_health: int = 3
var game_is_over: bool = false


func _ready() -> void:
	randomize()
	get_viewport().size_changed.connect(_fit_background_to_viewport)
	_fit_background_to_viewport()

	action_mapper.set("input_bridge", input_bridge)
	placement_controller.call("configure", action_mapper, grid, resource_system, defenders_parent)
	wave_director.call("configure", grid, enemies_parent)
	hud.call("set_grid", grid)

	resource_system.changed.connect(_on_energy_changed)
	placement_controller.selection_changed.connect(_on_selection_changed)
	placement_controller.message_requested.connect(_on_message_requested)
	wave_director.wave_changed.connect(_on_wave_changed)
	wave_director.base_breached.connect(_on_base_breached)
	wave_director.enemy_defeated.connect(_on_enemy_defeated)

	restart_game()


func _process(delta: float) -> void:
	if bool(action_mapper.call("is_restart_just_pressed")):
		restart_game()

	if game_is_over:
		return

	for defender in defenders_parent.get_children():
		if defender.has_method("tick_economy"):
			defender.call("tick_economy", delta)
		if defender.has_method("tick_attack"):
			defender.call("tick_attack", delta, enemies_parent.get_children())


func restart_game() -> void:
	_clear_actor_parent(defenders_parent)
	_clear_actor_parent(enemies_parent)
	grid.call("clear_occupancy")

	base_health = starting_base_health
	game_is_over = false
	run_stats.call("reset")
	resource_system.call("reset")
	placement_controller.call("reset_cursor")
	wave_director.call("reset_and_start")
	hud.call("set_base_health", base_health)
	hud.call("hide_game_over")
	hud.call("show_message", "Place defenders before the wave arrives.")


func _clear_actor_parent(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _fit_background_to_viewport() -> void:
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size


func _on_energy_changed(amount: int) -> void:
	hud.call("set_energy", amount, int(resource_system.get("max_energy")))


func _on_selection_changed(name: String, cost: int) -> void:
	hud.call("set_selected_defender", name, cost)


func _on_message_requested(message: String) -> void:
	hud.call("show_message", message)


func _on_wave_changed(wave_number: int, enemies_remaining: int) -> void:
	run_stats.call("record_wave_started", wave_number)
	hud.call("set_wave", wave_number, enemies_remaining)


func _on_enemy_defeated(enemy: Node) -> void:
	run_stats.call("record_enemy_defeated", str(enemy.get("kind")))
	resource_system.call("add_energy", enemy_defeat_energy)


func _on_base_breached(_enemy: Node) -> void:
	if game_is_over:
		return

	base_health -= 1
	hud.call("set_base_health", base_health)
	if base_health <= 0:
		game_is_over = true
		wave_director.call("stop")
		hud.call("show_game_over", run_stats.call("get_summary_lines"))
	else:
		hud.call("show_message", "An enemy slipped through.")
