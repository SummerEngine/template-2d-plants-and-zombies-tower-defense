class_name DefenseHUD
extends CanvasLayer

@onready var energy_label: Label = $Root/TopLeft/Stats/EnergyLabel
@onready var energy_meter: MarginContainer = $Root/EnergyMeter
@onready var energy_bar: ProgressBar = $Root/EnergyMeter/EnergyBar
@onready var base_label: Label = $Root/TopLeft/Stats/BaseLabel
@onready var wave_label: Label = $Root/TopLeft/Stats/WaveLabel
@onready var selected_label: Label = $Root/TopLeft/Stats/SelectedLabel
@onready var right_panel: MarginContainer = $Root/RightPanel
@onready var right_title_label: Label = $Root/RightPanel/Stack/TitleLabel
@onready var right_hint_label: Label = $Root/RightPanel/Stack/HintLabel
@onready var top_left: MarginContainer = $Root/TopLeft
@onready var bottom_left: MarginContainer = $Root/BottomLeft
@onready var bottom_center: MarginContainer = $Root/BottomCenter
@onready var message_label: Label = $Root/BottomCenter/MessageLabel
@onready var controls_label: Label = $Root/BottomLeft/ControlsLabel
@onready var game_over_panel: Panel = $Root/GameOverPanel
@onready var game_over_title_label: Label = $Root/GameOverPanel/Margin/Stack/TitleLabel
@onready var game_over_results_label: Label = $Root/GameOverPanel/Margin/Stack/ResultsLabel

var _message_time_left: float = 0.0
var _max_energy: int = 1
var _grid: Node = null


func _ready() -> void:
	energy_bar.show_percentage = false
	controls_label.text = "Move: WASD/arrows   Place: Space   Switch: E/Tab   Remove: Backspace   Restart: R"
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_panel.visible = false
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _process(delta: float) -> void:
	if _message_time_left <= 0.0:
		return

	_message_time_left = max(0.0, _message_time_left - delta)
	if _message_time_left == 0.0:
		message_label.text = ""


func set_grid(grid_ref: Node) -> void:
	_grid = grid_ref
	if _grid != null and _grid.has_signal("layout_changed"):
		var callback := Callable(self, "_on_grid_layout_changed")
		if not _grid.is_connected("layout_changed", callback):
			_grid.connect("layout_changed", callback)
	_apply_responsive_layout()


func set_energy(amount: int, max_amount: int = -1) -> void:
	if max_amount > 0:
		_max_energy = max_amount

	energy_label.text = "Energy: %s / %s" % [amount, _max_energy]
	energy_bar.max_value = float(_max_energy)
	energy_bar.value = float(clampi(amount, 0, _max_energy))


func set_base_health(health: int) -> void:
	base_label.text = "Base: %s" % health


func set_wave(wave_number: int, remaining: int) -> void:
	if wave_number <= 0:
		wave_label.text = "Wave: ready"
	else:
		wave_label.text = "Wave: %s  queued: %s" % [wave_number, remaining]


func set_selected_defender(name: String, cost: int) -> void:
	selected_label.text = "Selected: %s (%s)" % [name, cost]


func show_message(message: String, duration: float = 2.0) -> void:
	message_label.text = message
	_message_time_left = duration


func show_game_over(summary_lines: PackedStringArray) -> void:
	game_over_results_label.text = "\n".join(summary_lines) + "\n\nPress R to restart."
	game_over_panel.visible = true
	show_message("Base overrun.", 5.0)


func hide_game_over() -> void:
	game_over_panel.visible = false


func _apply_responsive_layout(size_override: Vector2 = Vector2.ZERO) -> void:
	var size: Vector2 = size_override
	if size == Vector2.ZERO:
		size = get_viewport().get_visible_rect().size
	var wide: bool = size.x >= 860.0 and size.y >= 500.0
	var compact: bool = size.x < 620.0 or size.y < 460.0
	var margin: float = clampf(size.x * 0.025, 10.0, 22.0)
	var usable_width: float = maxf(180.0, size.x - margin * 2.0)
	var panel_width: float = minf(236.0 if wide else usable_width, usable_width)
	var stats_height: float = 142.0 if wide else 118.0
	var controls_height: float = 34.0 if wide else 54.0
	var message_width: float = minf(560.0, usable_width)
	var message_height: float = 50.0 if wide else 46.0
	var board_rect := _get_board_rect()
	var energy_width: float = board_rect.size.x if board_rect.size.x > 0.0 else minf(360.0, usable_width)
	var energy_height: float = 18.0 if wide else 16.0
	var energy_zone_pixels: float = maxf(energy_height, size.y * 0.10)
	var show_controls: bool = size.y >= 380.0 and size.x >= 420.0
	var board_bottom: float = margin + stats_height
	if board_rect.size != Vector2.ZERO:
		board_bottom = board_rect.end.y
	var controls_top: float = size.y - controls_height - margin
	var required_below_board_space := energy_zone_pixels + message_height + 32.0
	if show_controls and controls_top - board_bottom < required_below_board_space:
		show_controls = false

	_set_rect(top_left, Vector2(margin, margin), Vector2(panel_width, stats_height))

	if wide:
		right_panel.visible = true
		_set_rect(right_panel, Vector2(size.x - panel_width - margin, margin), Vector2(panel_width, 168.0))
	else:
		right_panel.visible = false

	bottom_left.visible = show_controls
	if show_controls:
		_set_rect(bottom_left, Vector2(margin, size.y - controls_height - margin), Vector2(usable_width, controls_height))

	var energy_zone_top: float = board_bottom + 8.0
	var latest_energy_bottom: float = size.y - message_height - 10.0
	var energy_zone_bottom: float = minf(latest_energy_bottom, energy_zone_top + energy_zone_pixels)
	var energy_y: float = energy_zone_top
	if energy_zone_bottom > energy_zone_top + energy_height:
		energy_y = energy_zone_top + (energy_zone_bottom - energy_zone_top - energy_height) * 0.5
	_set_rect(energy_meter, Vector2((size.x - energy_width) * 0.5, energy_y), Vector2(energy_width, energy_height))

	var message_y: float = energy_y + energy_height + 8.0
	var min_message_y: float = margin + stats_height + 8.0
	if wide:
		min_message_y = margin
	var max_message_y: float = maxf(0.0, size.y - message_height - 2.0)
	if max_message_y >= min_message_y:
		message_y = clampf(message_y, min_message_y, max_message_y)
	else:
		message_y = max_message_y
	_set_rect(bottom_center, Vector2((size.x - message_width) * 0.5, message_y), Vector2(message_width, message_height))

	var modal_width: float = minf(420.0, usable_width)
	var modal_height: float = minf(252.0, maxf(176.0, size.y - margin * 2.0))
	_set_rect(game_over_panel, Vector2((size.x - modal_width) * 0.5, (size.y - modal_height) * 0.5), Vector2(modal_width, modal_height))

	_set_font_size(energy_label, 22 if wide else 18)
	energy_bar.custom_minimum_size = Vector2(0, int(energy_height))
	_set_font_size(base_label, 18 if wide else 15)
	_set_font_size(wave_label, 18 if wide else 15)
	_set_font_size(selected_label, 18 if wide else 15)
	_set_font_size(controls_label, 13 if wide else 11)
	_set_font_size(message_label, 20 if wide else 15)
	_set_font_size(right_title_label, 20)
	_set_font_size(right_hint_label, 14)
	_set_font_size(game_over_title_label, 24 if not compact else 20)
	_set_font_size(game_over_results_label, 16 if not compact else 13)


func _set_rect(control: Control, position: Vector2, rect_size: Vector2) -> void:
	var safe_size := rect_size.max(Vector2(1.0, 1.0))
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = position.x
	control.offset_top = position.y
	control.offset_right = position.x + safe_size.x
	control.offset_bottom = position.y + safe_size.y


func _set_font_size(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)


func _get_board_rect() -> Rect2:
	if _grid == null:
		return Rect2()

	return _grid.call("get_board_rect")


func _on_grid_layout_changed(_previous_board_rect: Rect2, _current_board_rect: Rect2) -> void:
	_apply_responsive_layout()
