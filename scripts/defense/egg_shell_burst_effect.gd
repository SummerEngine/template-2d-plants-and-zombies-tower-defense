class_name EggShellBurstEffect
extends Node2D

const GRAVITY := 58.0
const SHARDS: Array[Dictionary] = [
	{"velocity": Vector2(-42, -58), "size": Vector2(9, 6), "spin": -5.4},
	{"velocity": Vector2(-18, -72), "size": Vector2(7, 5), "spin": 6.2},
	{"velocity": Vector2(20, -68), "size": Vector2(8, 5), "spin": -4.8},
	{"velocity": Vector2(45, -48), "size": Vector2(10, 6), "spin": 5.8},
	{"velocity": Vector2(-8, -34), "size": Vector2(6, 4), "spin": 3.6},
]

@export var lifetime: float = 0.42

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var ratio: float = clampf(_age / lifetime, 0.0, 1.0)
	var alpha: float = 1.0 - ratio
	var yolk_color := Color(1.0, 0.72, 0.12, 0.42 * alpha)
	var shell_color := Color(1.0, 0.94, 0.74, alpha)
	var shell_outline := Color(0.26, 0.14, 0.08, 0.82 * alpha)

	draw_circle(Vector2.ZERO, lerpf(5.0, 17.0, ratio), yolk_color)
	draw_arc(Vector2.ZERO, lerpf(8.0, 24.0, ratio), 0.0, TAU, 20, Color(1.0, 0.86, 0.24, 0.55 * alpha), 2.0)

	for shard in SHARDS:
		var velocity: Vector2 = shard["velocity"]
		var size: Vector2 = shard["size"]
		var position := velocity * ratio + Vector2(0.0, GRAVITY * ratio * ratio)
		var rotation := float(shard["spin"]) * ratio
		_draw_shell_shard(position, size, rotation, shell_color, shell_outline)


func _draw_shell_shard(position: Vector2, size: Vector2, rotation: float, fill: Color, outline: Color) -> void:
	var points := PackedVector2Array([
		Vector2(-size.x, -size.y * 0.35),
		Vector2(-size.x * 0.15, -size.y),
		Vector2(size.x, -size.y * 0.2),
		Vector2(size.x * 0.25, size.y),
		Vector2(-size.x * 0.65, size.y * 0.55),
	])

	draw_set_transform(position, rotation, Vector2.ONE)
	draw_colored_polygon(points, fill)
	for index in range(points.size()):
		draw_line(points[index], points[(index + 1) % points.size()], outline, 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
