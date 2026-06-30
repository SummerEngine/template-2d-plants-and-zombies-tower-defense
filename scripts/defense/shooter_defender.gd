extends "res://scripts/defense/defender_base.gd"

@export var attack_interval: float = 0.9
@export var damage: int = 25
@export var range_columns: int = 6

var _attack_timer: float = 0.0
var _flash_time_left: float = 0.0


func _ready() -> void:
	display_name = "Shooter"
	kind = "shooter"
	cost = 50
	max_health = 90
	health = max_health
	body_color = Color(0.22, 0.65, 1.0, 1.0)


func _process(delta: float) -> void:
	if _flash_time_left <= 0.0:
		return

	_flash_time_left = max(0.0, _flash_time_left - delta)
	queue_redraw()


func tick_attack(delta: float, enemies: Array[Node]) -> void:
	_attack_timer = max(0.0, _attack_timer - delta)
	if _attack_timer > 0.0:
		return

	var target := _find_target(enemies)
	if target == null:
		return

	target.call("take_damage", damage)
	_attack_timer = attack_interval
	_flash_time_left = 0.12
	queue_redraw()


func _draw() -> void:
	super._draw()
	draw_circle(Vector2(18, -6), 8.0, Color(0.95, 1.0, 1.0, 1.0))
	if _flash_time_left > 0.0:
		draw_line(Vector2(0, -24), Vector2(0, -62), Color(1.0, 0.9, 0.2, 1.0), 4.0)


func _find_target(enemies: Array[Node]) -> Node:
	var best_target: Node = null
	var best_y := -INF
	for enemy in enemies:
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		if int(enemy.get("lane")) != lane:
			continue

		var enemy_y: float = (enemy as Node2D).global_position.y
		if enemy_y >= global_position.y:
			continue
		if enemy_y > best_y:
			best_y = enemy_y
			best_target = enemy

	return best_target
