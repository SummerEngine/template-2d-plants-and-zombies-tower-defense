extends "res://scripts/defense/defender_base.gd"

const HAY_TEXTURE: Texture2D = preload("res://assets/art/hay_bale_defender.png")
const HAY_DRAW_BASE_SIZE := Vector2(64.0, 47.0)
const HAY_FEET_LOCAL_Y := 8.0

var _hit_time_left: float = 0.0


func _ready() -> void:
	display_name = "Hay Bale"
	kind = "blocker"
	cost = 35
	max_health = 220
	health = max_health
	body_color = Color(0.86, 0.72, 0.30, 1.0)


func _process(delta: float) -> void:
	if _hit_time_left > 0.0:
		_hit_time_left = maxf(0.0, _hit_time_left - delta)
		queue_redraw()


func take_damage(amount: int) -> void:
	_hit_time_left = 0.18
	super.take_damage(amount)


func _draw() -> void:
	var tint := Color(1.0, 0.64, 0.64, 1.0) if _hit_time_left > 0.0 else Color.WHITE
	var draw_size := HAY_DRAW_BASE_SIZE
	var draw_position := Vector2(-draw_size.x * 0.5, -draw_size.y + HAY_FEET_LOCAL_Y)
	draw_texture_rect(HAY_TEXTURE, Rect2(draw_position, draw_size), false, tint)

	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	_draw_health_bar_rect(RoundedBarDrawer.centered_actor_health_bar_rect(-34.0, 6.0), health_ratio)
