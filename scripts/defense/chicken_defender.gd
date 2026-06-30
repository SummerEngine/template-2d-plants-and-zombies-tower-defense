extends "res://scripts/defense/defender_base.gd"

const CHICKEN_TEXTURE: Texture2D = preload("res://assets/art/chicken_rear_bazooka_defender.png")
const EggShellBurstScript := preload("res://scripts/defense/egg_shell_burst_effect.gd")
const PopEffectScript := preload("res://scripts/defense/pop_effect.gd")
const EGG_THROW_DURATION := 0.38
const IDLE_BOUNCES_PER_SECOND := 0.65
const IDLE_BOB_PIXELS := 0.65
const IDLE_SQUASH_AMOUNT := 0.01
const CHICKEN_DRAW_BASE_SIZE := Vector2(50.0, 72.0)
const CHICKEN_FEET_LOCAL_Y := 17.0

@export var attack_interval: float = 0.82
@export var damage: int = 28

var _attack_timer: float = 0.0
var _idle_time: float = 0.0
var _throw_time_left: float = 0.0
var _hit_time_left: float = 0.0
var _egg_start: Vector2 = Vector2(0, -50)
var _egg_end: Vector2 = Vector2(0, -96)
var _impact_time_left: float = 0.0
var _pending_shell_burst: bool = false
var _pending_impact_position: Vector2 = Vector2.ZERO
var _pending_impact_target: Node = null
var _pending_impact_damage: int = 0


func _ready() -> void:
	display_name = "Hen"
	kind = "hen"
	cost = 50
	max_health = 95
	health = max_health
	body_color = Color(1.0, 0.96, 0.82, 1.0)


func _process(delta: float) -> void:
	_idle_time += delta
	_throw_time_left = maxf(0.0, _throw_time_left - delta)
	_hit_time_left = maxf(0.0, _hit_time_left - delta)
	_tick_pending_impact(delta)
	queue_redraw()


func tick_attack(delta: float, enemies: Array[Node]) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _attack_timer > 0.0:
		return

	var target := _find_target(enemies)
	if target == null:
		return

	var target_position: Vector2 = (target as Node2D).global_position
	var target_local_position := to_local(target_position)
	_egg_end = Vector2(_egg_start.x, target_local_position.y)
	_attack_timer = attack_interval
	_throw_time_left = EGG_THROW_DURATION
	_impact_time_left = EGG_THROW_DURATION
	_pending_shell_burst = true
	_pending_impact_position = target_position
	_pending_impact_target = target
	_pending_impact_damage = damage
	queue_redraw()


func take_damage(amount: int) -> void:
	_hit_time_left = 0.18
	var will_be_destroyed := health - amount <= 0
	if will_be_destroyed:
		_spawn_pop(global_position, Color(1.0, 0.96, 0.82, 0.9), 0.34)
	super.take_damage(amount)


func _draw() -> void:
	_draw_chicken_sprite()
	_draw_throw_egg()
	_draw_health_bar()


func _draw_chicken_sprite() -> void:
	var throw_ratio: float = clampf(_throw_time_left / EGG_THROW_DURATION, 0.0, 1.0)
	var throw_offset := Vector2(0.0, -12.0 * sin(throw_ratio * PI))
	var hit_tint := Color(1.0, 0.64, 0.64, 1.0) if _hit_time_left > 0.0 else Color.WHITE
	var sprite_rect := _get_chicken_draw_rect()
	sprite_rect.position += throw_offset

	draw_texture_rect(CHICKEN_TEXTURE, sprite_rect, false, hit_tint)


func _get_chicken_draw_rect() -> Rect2:
	var idle_wave: float = sin(_idle_time * TAU * IDLE_BOUNCES_PER_SECOND)
	var bob: float = idle_wave * IDLE_BOB_PIXELS
	var squash: float = 1.0 + idle_wave * IDLE_SQUASH_AMOUNT
	var draw_size := Vector2(CHICKEN_DRAW_BASE_SIZE.x * squash, CHICKEN_DRAW_BASE_SIZE.y / squash)
	var draw_position := Vector2(-draw_size.x * 0.5, -draw_size.y + CHICKEN_FEET_LOCAL_Y + bob)
	return Rect2(draw_position, draw_size)


func _draw_throw_egg() -> void:
	if _throw_time_left <= 0.0:
		return

	var ratio: float = 1.0 - clampf(_throw_time_left / EGG_THROW_DURATION, 0.0, 1.0)
	var eased_ratio: float = 0.5 - cos(ratio * PI) * 0.5
	var egg_position: Vector2 = _egg_start.lerp(_egg_end, eased_ratio)
	var egg_angle: float = _idle_time * 18.0

	draw_set_transform(egg_position, egg_angle, Vector2.ONE)
	draw_ellipse(Vector2.ZERO, 12.0, 16.0, Color(1.0, 0.95, 0.74, 1.0), true)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color(0.22, 0.12, 0.08, 1.0), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_health_bar() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)

	draw_rect(Rect2(Vector2(-28, -52), Vector2(56, 6)), Color(0.12, 0.12, 0.14, 1.0), true)
	draw_rect(Rect2(Vector2(-28, -52), Vector2(56 * health_ratio, 6)), Color(0.3, 0.95, 0.55, 1.0), true)


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


func _spawn_pop(spawn_position: Vector2, pop_color: Color, pop_lifetime: float) -> void:
	var pop: Node2D = PopEffectScript.new()
	pop.set("color", pop_color)
	pop.set("lifetime", pop_lifetime)
	_add_effect(pop, spawn_position)


func _tick_pending_impact(delta: float) -> void:
	if not _pending_shell_burst:
		return

	_impact_time_left = maxf(0.0, _impact_time_left - delta)
	if _impact_time_left > 0.0:
		return

	_pending_shell_burst = false
	var impact_position := _pending_impact_position
	if is_instance_valid(_pending_impact_target):
		var impact_target := _pending_impact_target as Node2D
		if impact_target != null:
			impact_position = impact_target.global_position
		if _pending_impact_target.has_method("take_damage"):
			_pending_impact_target.call("take_damage", _pending_impact_damage)

	_pending_impact_target = null
	_pending_impact_damage = 0
	_spawn_shell_burst(impact_position)


func _spawn_shell_burst(spawn_position: Vector2) -> void:
	var shell_burst: Node2D = EggShellBurstScript.new()
	_add_effect(shell_burst, spawn_position)


func _add_effect(effect: Node2D, spawn_position: Vector2) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(effect)
	effect.global_position = spawn_position
