class_name EnemyBase
extends Node2D

signal breached(enemy: Node)
signal defeated(enemy: Node)

const FARMER_WALK_FRAME_COUNT := 8
const FARMER_ATTACK_FRAME_COUNT := 8

class HealthBar extends Node2D:
	const RoundedBarDrawer := preload("res://scripts/defense/rounded_bar_drawer.gd")

	var enemy: EnemyBase = null

	func _draw() -> void:
		if enemy == null:
			return
		var health_ratio := 0.0
		if enemy.max_health > 0:
			health_ratio = float(enemy.health) / float(enemy.max_health)
		RoundedBarDrawer.draw_rounded_bar(
			self,
			RoundedBarDrawer.centered_actor_health_bar_rect(-34.0, 4.0),
			health_ratio,
			Color(0.95, 0.18, 0.16, 1.0),
			Color(0.12, 0.12, 0.14, 1.0)
		)

var lane: int = 0
var kind: String = "farmer"
var display_name: String = "Farmer"
var max_health: int = 90
var health: int = 90
var speed: float = 36.0
var base_speed: float = 36.0
var _slowed: bool = false
var damage: int = 18
var attack_interval: float = 0.8
var grid: Node = null

var _attack_timer: float = 0.0
var _health_bar: Node2D = null
var _sprite: AnimatedSprite2D = null
var _walk_sprite_pos: Vector2 = Vector2.ZERO
var _walk_sprite_scale: Vector2 = Vector2.ONE
var _attack_sprite_pos: Vector2 = Vector2.ZERO
var _attack_sprite_scale: Vector2 = Vector2.ONE
var _walk_time: float = 0.0
var base_attack_interval: float = 0.8


func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.centered = false
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 12.0)
	frames.set_animation_loop("walk", true)
	var first_tex: Texture2D = null
	for i in range(1, FARMER_WALK_FRAME_COUNT + 1):
		var padded := "%02d" % i
		var tex := load("res://assets/sprites/farmer_walk/frame_%s.png" % padded) as Texture2D
		if tex != null:
			frames.add_frame("walk", tex)
			if first_tex == null:
				first_tex = tex
	frames.add_animation("attack")
	frames.set_animation_speed("attack", 12.0)
	frames.set_animation_loop("attack", true)
	var first_attack_tex: Texture2D = null
	for i in range(1, FARMER_ATTACK_FRAME_COUNT + 1):
		var padded := "%02d" % i
		var tex := load("res://assets/sprites/farmer_attack/frame_%s.png" % padded) as Texture2D
		if tex != null:
			frames.add_frame("attack", tex)
			if first_attack_tex == null:
				first_attack_tex = tex
	sprite.sprite_frames = frames
	if first_tex != null and first_tex.get_size().y > 0.0:
		var tex_scale := 100.0 / first_tex.get_size().y
		_walk_sprite_scale = Vector2(tex_scale, tex_scale)
		_walk_sprite_pos = Vector2(
			-first_tex.get_size().x * tex_scale * 0.5,
			-first_tex.get_size().y * tex_scale * 0.5
		)
	if first_attack_tex != null and first_attack_tex.get_size().y > 0.0:
		var atk_scale := 100.0 / first_attack_tex.get_size().y
		_attack_sprite_scale = Vector2(atk_scale, atk_scale)
		_attack_sprite_pos = Vector2(
			-first_attack_tex.get_size().x * atk_scale * 0.5,
			-first_attack_tex.get_size().y * atk_scale * 0.5
		)
	sprite.centered = false
	sprite.scale = _walk_sprite_scale
	sprite.position = _walk_sprite_pos
	sprite.play("walk")
	add_child(sprite)
	_sprite = sprite

	var hb := HealthBar.new()
	hb.enemy = self
	hb.name = "HealthBar"
	add_child(hb)
	_health_bar = hb


func configure(grid_ref: Node, lane_index: int, wave_number: int) -> void:
	_disconnect_grid_layout_signal()
	grid = grid_ref
	lane = lane_index
	_connect_grid_layout_signal()
	max_health = 80 + wave_number * 12
	health = max_health
	speed = 34.0 + wave_number * 2.0
	base_speed = speed
	base_attack_interval = attack_interval
	_slowed = false
	_walk_time = 0.0
	grid.call("apply_actor_scale", self)
	global_position = grid.call("get_enemy_spawn_position", lane)
	grid.call("apply_depth_sort", self)
	_redraw_health()


func _process(delta: float) -> void:
	if grid == null:
		return

	var defender: Node = grid.call("find_defender_for_enemy", lane, global_position.y)
	if defender != null and defender.has_method("take_damage"):
		if _sprite != null and _sprite.animation != "attack":
			_sprite.play("attack")
			_sprite.scale = _attack_sprite_scale
			_sprite.position = _attack_sprite_pos
		_attack_timer = max(0.0, _attack_timer - delta)
		if _attack_timer == 0.0:
			defender.call("take_damage", damage)
			_attack_timer = attack_interval
	else:
		if _sprite != null and _sprite.animation != "walk":
			_sprite.play("walk")
			_sprite.scale = _walk_sprite_scale
			_sprite.position = _walk_sprite_pos
		global_position.y += speed * delta
		_walk_time += delta * 12.0
		grid.call("apply_depth_sort", self)

	if global_position.y >= float(grid.call("get_breach_y")):
		breached.emit(self)
		queue_free()


func _get_walk_frame_index() -> int:
	return int(floorf(_walk_time)) % max(1, FARMER_WALK_FRAME_COUNT)


func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health <= 0:
		defeated.emit(self)
		queue_free()
		return
	if not _slowed and max_health > 0 and float(health) / float(max_health) <= 0.3:
		_slowed = true
		speed = base_speed * 0.5
		attack_interval = base_attack_interval * 2.0
		if _sprite != null and _sprite.sprite_frames != null:
			_sprite.sprite_frames.set_animation_speed("walk", 6.0)
			_sprite.sprite_frames.set_animation_speed("attack", 6.0)
	_redraw_health()


func _draw() -> void:
	pass  # Health bar drawn by HealthBar child for correct layering


func _redraw_health() -> void:
	if _health_bar != null:
		_health_bar.queue_redraw()


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
		grid.call("apply_depth_sort", self)
		_redraw_health()
		return

	var lane_position: Vector2 = grid.call("get_enemy_spawn_position", lane)
	if global_position.y < previous_board_rect.position.y:
		var previous_spawn_y := _get_spawn_y_for_board(previous_board_rect)
		var approach_progress := 1.0
		if previous_board_rect.position.y > previous_spawn_y:
			approach_progress = clampf(
				(global_position.y - previous_spawn_y) / (previous_board_rect.position.y - previous_spawn_y),
				0.0,
				1.0
			)
		global_position = Vector2(
			lane_position.x,
			lerpf(lane_position.y, current_board_rect.position.y, approach_progress)
		)
		grid.call("apply_depth_sort", self)
		_redraw_health()
		return

	var progress := clampf(
		(global_position.y - previous_board_rect.position.y) / previous_board_rect.size.y,
		0.0,
		1.0
	)
	global_position = Vector2(
		lane_position.x,
		lerpf(current_board_rect.position.y, current_board_rect.end.y, progress)
	)
	grid.call("apply_depth_sort", self)
	_redraw_health()


func _get_spawn_y_for_board(board_rect: Rect2) -> float:
	var previous_cell_height := (board_rect.size.y + float(grid.get("cell_gap"))) / float(grid.get("rows"))
	var spawn_row_offset := float(grid.get("enemy_spawn_row_offset"))
	return board_rect.position.y + spawn_row_offset * previous_cell_height + (previous_cell_height - float(grid.get("cell_gap"))) * 0.5
