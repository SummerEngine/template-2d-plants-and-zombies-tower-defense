class_name PopEffect
extends Node2D

@export var lifetime: float = 0.28
@export var color: Color = Color(1.0, 0.92, 0.62, 0.9)

var _age: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 1000


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var ratio: float = clampf(_age / lifetime, 0.0, 1.0)
	var alpha: float = 1.0 - ratio
	var puff_color := Color(color.r, color.g, color.b, color.a * alpha)
	var radius: float = lerpf(8.0, 30.0, ratio)

	for index in range(6):
		var angle: float = TAU * float(index) / 6.0
		var center := Vector2(cos(angle), sin(angle)) * radius * 0.55
		draw_circle(center, lerpf(7.0, 2.0, ratio), puff_color)

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, puff_color, 2.0)
