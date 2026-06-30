class_name WaveDirector
extends Node

signal wave_changed(wave_number: int, enemies_remaining: int)
signal base_breached(enemy: Node)
signal enemy_defeated(enemy: Node)

const EnemyScript := preload("res://scripts/defense/enemy_base.gd")

@export var first_wave_delay: float = 1.0
@export var spawn_interval: float = 2.2
@export var next_wave_delay: float = 3.0

var grid: Node = null
var enemies_parent: Node = null
var wave_number: int = 0
var enemies_remaining_to_spawn: int = 0
var active_enemy_count: int = 0
var running: bool = false

var _spawn_timer: float = 0.0
var _between_wave_timer: float = 0.0


func configure(grid_ref: Node, enemies_parent_ref: Node) -> void:
	grid = grid_ref
	enemies_parent = enemies_parent_ref


func reset_and_start() -> void:
	wave_number = 0
	enemies_remaining_to_spawn = 0
	active_enemy_count = 0
	running = true
	_between_wave_timer = first_wave_delay
	_spawn_timer = 0.0
	wave_changed.emit(wave_number, enemies_remaining_to_spawn)


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running or grid == null or enemies_parent == null:
		return

	if wave_number == 0 or (enemies_remaining_to_spawn == 0 and active_enemy_count == 0):
		_between_wave_timer = max(0.0, _between_wave_timer - delta)
		if _between_wave_timer == 0.0:
			_begin_next_wave()
		return

	if enemies_remaining_to_spawn <= 0:
		return

	_spawn_timer = max(0.0, _spawn_timer - delta)
	if _spawn_timer == 0.0:
		_spawn_enemy()
		_spawn_timer = max(0.7, spawn_interval - float(wave_number) * 0.12)


func _begin_next_wave() -> void:
	wave_number += 1
	enemies_remaining_to_spawn = 2 + wave_number
	_spawn_timer = 0.0
	_between_wave_timer = next_wave_delay
	wave_changed.emit(wave_number, enemies_remaining_to_spawn)


func _spawn_enemy() -> void:
	if enemies_remaining_to_spawn <= 0:
		return

	var lane := randi_range(0, int(grid.get("columns")) - 1)
	var enemy: Node2D = EnemyScript.new()
	enemies_parent.add_child(enemy)
	enemy.call("configure", grid, lane, wave_number)
	enemy.breached.connect(_on_enemy_breached)
	enemy.defeated.connect(_on_enemy_defeated)

	enemies_remaining_to_spawn -= 1
	active_enemy_count += 1
	wave_changed.emit(wave_number, enemies_remaining_to_spawn)


func _on_enemy_breached(enemy: Node) -> void:
	active_enemy_count = max(0, active_enemy_count - 1)
	base_breached.emit(enemy)


func _on_enemy_defeated(enemy: Node) -> void:
	active_enemy_count = max(0, active_enemy_count - 1)
	enemy_defeated.emit(enemy)
