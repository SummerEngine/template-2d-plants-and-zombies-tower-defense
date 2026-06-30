extends "res://scripts/defense/defender_base.gd"

@export var production_interval: float = 6.0
@export var energy_per_cycle: int = 25

var resource_system: Node = null
var _production_timer: float = 0.0
var _idle_time: float = 0.0
var _pulse_time_left: float = 0.0


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
	queue_redraw()


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
	var pulse_color := Color(1.0, 0.82, 0.2, 0.22 * pulse_ratio)
	var center := Vector2(0, bob)

	if pulse_ratio > 0.0:
		draw_circle(center + Vector2(0, -4), 46.0 + 8.0 * pulse_ratio, pulse_color, true)

	draw_ellipse(center + Vector2(0, 8), 24.0, 31.0, Color(1.0, 0.93, 0.62, 1.0), true)
	draw_ellipse(center + Vector2(-11, 10), 13.0, 20.0, Color(0.96, 0.78, 0.28, 1.0), true)
	draw_ellipse(center + Vector2(12, 10), 12.0, 19.0, Color(0.96, 0.78, 0.28, 1.0), true)
	draw_ellipse(center + Vector2(0, -21), 18.0, 17.0, Color(1.0, 0.95, 0.72, 1.0), true)
	draw_rect(Rect2(center + Vector2(-14, -9), Vector2(28, 22)), Color(1.0, 0.91, 0.52, 1.0), true)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(0, -20),
			center + Vector2(20, -16),
			center + Vector2(0, -11),
		]),
		PackedColorArray([Color(1.0, 0.55, 0.18, 1.0)])
	)
	draw_circle(center + Vector2(-6, -24), 2.6, Color(0.1, 0.06, 0.02, 1.0), true)
	draw_circle(center + Vector2(6, -24), 2.6, Color(0.1, 0.06, 0.02, 1.0), true)
	draw_ellipse(center + Vector2(0, 7), 11.0, 15.0, Color(1.0, 0.98, 0.82, 1.0), true)


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

	draw_rect(Rect2(Vector2(-28, -52), Vector2(56, 6)), Color(0.12, 0.12, 0.14, 1.0), true)
	draw_rect(Rect2(Vector2(-28, -52), Vector2(56 * health_ratio, 6)), Color(0.3, 0.95, 0.55, 1.0), true)
