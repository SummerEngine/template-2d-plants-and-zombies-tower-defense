extends "res://scripts/defense/defender_base.gd"


func _ready() -> void:
	display_name = "Blocker"
	kind = "blocker"
	cost = 35
	max_health = 220
	health = max_health
	body_color = Color(0.35, 0.92, 0.56, 1.0)


func _draw() -> void:
	super._draw()
	draw_rect(Rect2(Vector2(-18, -18), Vector2(36, 36)), Color(0.1, 0.28, 0.18, 1.0), false, 4.0)
