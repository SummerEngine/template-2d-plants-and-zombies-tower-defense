extends RefCounted

const ACTOR_BASE_CELL_SIZE := 56.0
const ACTOR_HEALTH_BAR_WIDTH := ACTOR_BASE_CELL_SIZE * 0.8


static func draw_rounded_bar(
	canvas: CanvasItem,
	rect: Rect2,
	fill_ratio: float,
	fill_color: Color,
	background_color: Color,
	corner_radius: float = -1.0
) -> void:
	var clamped_ratio := clampf(fill_ratio, 0.0, 1.0)
	var radius := corner_radius
	if radius < 0.0:
		radius = rect.size.y * 0.5
	radius = minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5))

	canvas.draw_style_box(_make_style_box(background_color, radius), rect)

	if clamped_ratio <= 0.0:
		return

	var fill_rect := Rect2(rect.position, Vector2(rect.size.x * clamped_ratio, rect.size.y))
	var fill_radius := minf(radius, minf(fill_rect.size.x * 0.5, fill_rect.size.y * 0.5))
	canvas.draw_style_box(_make_style_box(fill_color, fill_radius), fill_rect)


static func centered_actor_health_bar_rect(y: float, height: float) -> Rect2:
	return Rect2(
		Vector2(-ACTOR_HEALTH_BAR_WIDTH * 0.5, y),
		Vector2(ACTOR_HEALTH_BAR_WIDTH, height)
	)


static func _make_style_box(color: Color, radius: float) -> StyleBoxFlat:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.set_corner_radius_all(int(round(radius)))
	return style_box
