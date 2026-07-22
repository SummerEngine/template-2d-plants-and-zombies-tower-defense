extends "res://scripts/defense/defender_base.gd"

const GOOSE_TEXTURE: Texture2D = preload("res://assets/art/golden_goose_defender.png")
const GOOSE_DRAW_BASE_SIZE := Vector2(60.0, 66.8)
const GOOSE_FEET_LOCAL_Y := 20.0

@export var production_interval: float = 6.0
@export var energy_per_cycle: int = 25

var resource_system: Node = null
var _production_timer: float = 0.0
var _idle_time: float = 0.0
var _pulse_time_left: float = 0.0
var _hit_time_left: float = 0.0


func _ready() -> void:
	display_name = "Golden Goose"
	kind = "goose"
	cost = 75
	max_health = 80
	health = max_health
	body_color = Color(1.0, 0.86, 0.28, 1.0)
	_production_timer = production_interval


func configure_resource_system(resource_ref: Node) -> void:
	resource_system = resource_ref


func _process(delta: float) -> void:
	_idle_time += delta
	_pulse_time_left = maxf(0.0, _pulse_time_left - delta)
	_hit_time_left = maxf(0.0, _hit_time_left - delta)
	queue_redraw()


func take_damage(amount: int) -> void:
	_hit_time_left = 0.18
	super.take_damage(amount)


func tick_economy(delta: float) -> void:
	if resource_system == null:
		return

	_production_timer = maxf(0.0, _production_timer - delta)
	if _production_timer > 0.0:
		return

	_production_timer += production_interval
	var energy_before := int(resource_system.get("energy"))
	resource_system.call("add_energy", energy_per_cycle)
	if int(resource_system.get("energy")) > energy_before:
		_pulse_time_left = 0.5
	queue_redraw()


func _draw() -> void:
	_draw_shadow()
	_draw_goose()
	_draw_production_meter()
	_draw_health_bar()


func _draw_shadow() -> void:
	draw_ellipse(Vector2(0, 28), 44.0, 10.0, Color(0.0, 0.0, 0.0, 0.2), true)


func _draw_goose() -> void:
	var bob: float = sin(_idle_time * TAU * 1.25) * 2.0
	var pulse_ratio: float = clampf(_pulse_time_left / 0.5, 0.0, 1.0)

	# Golden glow ring when it pays out energy.
	if pulse_ratio > 0.0:
		var pulse_color := Color(1.0, 0.82, 0.2, 0.22 * pulse_ratio)
		draw_circle(Vector2(0, bob - 4), 46.0 + 8.0 * pulse_ratio, pulse_color, true)

	var tint := Color(1.0, 0.64, 0.64, 1.0) if _hit_time_left > 0.0 else Color.WHITE
	var draw_size := GOOSE_DRAW_BASE_SIZE
	var draw_position := Vector2(-draw_size.x * 0.5, -draw_size.y + GOOSE_FEET_LOCAL_Y + bob)
	draw_texture_rect(GOOSE_TEXTURE, Rect2(draw_position, draw_size), false, tint)


func _draw_production_meter() -> void:
	var progress := 0.0
	if production_interval > 0.0:
		progress = 1.0 - clampf(_production_timer / production_interval, 0.0, 1.0)

	draw_rect(Rect2(Vector2(-26, 38), Vector2(52, 6)), Color(0.12, 0.12, 0.14, 1.0), true)
	draw_rect(Rect2(Vector2(-26, 38), Vector2(52 * progress, 6)), Color(1.0, 0.78, 0.2, 1.0), true)


func _draw_health_bar() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)

	_draw_health_bar_rect(RoundedBarDrawer.centered_actor_health_bar_rect(-52.0, 6.0), health_ratio)
