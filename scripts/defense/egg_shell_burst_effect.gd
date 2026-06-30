class_name EggShellBurstEffect
extends Node2D

const EGG_ANIMATION_SHEET: Texture2D = preload("res://assets/summer/a6ed92e2-6167-49fc-b8bf-3b2446486ab3/2026-06-30/spritesheet-256-b1616d7f-c6f0-4fc3-83ba-4395cfb079fa.png")
const FRAME_SIZE := Vector2(256.0, 217.0)
const IMPACT_START_FRAME := 1
const IMPACT_FRAME_COUNT := 7
const FRAMES_PER_SECOND := 12.0
const IMPACT_DRAW_SIZE := Vector2(118.0, 100.0)

@export var lifetime: float = float(IMPACT_FRAME_COUNT) / FRAMES_PER_SECOND

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
	var frame_index := _get_current_frame_index()
	var frame_region := Rect2(Vector2(FRAME_SIZE.x * float(frame_index), 0.0), FRAME_SIZE)
	draw_texture_rect_region(
		EGG_ANIMATION_SHEET,
		Rect2(-IMPACT_DRAW_SIZE * 0.5, IMPACT_DRAW_SIZE),
		frame_region
	)


func _get_current_frame_index() -> int:
	var local_frame := clampi(int(floorf(_age * FRAMES_PER_SECOND)), 0, IMPACT_FRAME_COUNT - 1)
	return IMPACT_START_FRAME + local_frame
