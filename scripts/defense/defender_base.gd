class_name DefenderBase
extends Node2D

signal destroyed(defender: Node)

var display_name: String = "Defender"
var kind: String = "defender"
var lane: int = 0
var column: int = 0
var row: int = 0
var cost: int = 50
var max_health: int = 100
var health: int = 100
var body_color: Color = Color(0.3, 0.75, 1.0, 1.0)


func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	queue_redraw()
	if health <= 0:
		destroyed.emit(self)
		queue_free()


func _draw() -> void:
	var body_rect := Rect2(Vector2(-28, -28), Vector2(56, 56))
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, Color(0.05, 0.06, 0.08, 1.0), false, 3.0)

	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-28, -38), Vector2(56, 6)), Color(0.12, 0.12, 0.14, 1.0), true)
	draw_rect(Rect2(Vector2(-28, -38), Vector2(56 * health_ratio, 6)), Color(0.3, 0.95, 0.55, 1.0), true)
