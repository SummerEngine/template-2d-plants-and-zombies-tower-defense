class_name GrassBackground
extends Node2D

## A simple painted grass field behind the board: two-tone horizontal bands
## with scattered blades. Purely decorative — it draws itself to fill the
## viewport and redraws on resize, touching no game state.

@export var band_top: Color = Color(0.35, 0.60, 0.28)
@export var band_bottom: Color = Color(0.28, 0.50, 0.22)
@export var stripe_tint: Color = Color(0.0, 0.0, 0.0, 0.06)
@export var blade_color: Color = Color(0.22, 0.44, 0.18, 0.55)
@export var band_height: float = 34.0
@export var blade_count: int = 220

var _size: Vector2 = Vector2(960, 540)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20260630
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _on_viewport_resized() -> void:
	_size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	# Vertical gradient approximated with a stack of horizontal bands, plus a
	# faint stripe every other band so the field reads as mown grass.
	var rows: int = int(ceil(_size.y / band_height)) + 1
	for i in range(rows):
		var y := float(i) * band_height
		var t: float = clampf(y / max(1.0, _size.y), 0.0, 1.0)
		var base := band_top.lerp(band_bottom, t)
		draw_rect(Rect2(0.0, y, _size.x, band_height), base)
		if i % 2 == 0:
			draw_rect(Rect2(0.0, y, _size.x, band_height), stripe_tint)

	# Scattered blades — deterministic so they do not shimmer between frames.
	_rng.seed = 20260630
	for _b in range(blade_count):
		var x := _rng.randf_range(0.0, _size.x)
		var y := _rng.randf_range(0.0, _size.y)
		var h := _rng.randf_range(5.0, 11.0)
		var lean := _rng.randf_range(-2.5, 2.5)
		draw_line(Vector2(x, y), Vector2(x + lean, y - h), blade_color, 1.5)
