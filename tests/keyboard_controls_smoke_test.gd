extends SceneTree

var frames: int = 0
var game: Node
var starting_cursor: Vector2i = Vector2i.ZERO


func _init() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1

	var input_bridge := game.get_node("Systems/InputBridge")
	var placement := game.get_node("Systems/PlacementController")
	var grid := game.get_node("Board/LaneGrid")
	var defenders := game.get_node("Actors/Defenders")

	if frames == 3:
		starting_cursor = placement.get("cursor_cell")
		_send_keydown(input_bridge, KEY_W)

	if frames == 8:
		var cursor_after_w: Vector2i = placement.get("cursor_cell")
		if cursor_after_w != starting_cursor + Vector2i.UP:
			return _fail("Expected W keydown to move the cursor up one grid cell.")
		_send_keydown(input_bridge, KEY_SPACE)

	if frames == 13:
		if defenders.get_child_count() != 1:
			return _fail("Expected Space keydown to place the selected defender.")
		var placed_defender: Node = defenders.get_child(0)
		if str(placed_defender.get("kind")) != "hen":
			return _fail("Expected Space to place the currently selected Hen defender.")
		_send_keydown(input_bridge, KEY_E)

	if frames == 18:
		if int(placement.get("selected_index")) != 1:
			return _fail("Expected E keydown to switch to the next defender.")
		_send_keydown(input_bridge, KEY_TAB)

	if frames == 23:
		if int(placement.get("selected_index")) != 2:
			return _fail("Expected Tab keydown to switch to the next defender.")
		_send_keydown(input_bridge, KEY_BACKSPACE)

	if frames == 28:
		if defenders.get_child_count() != 0:
			return _fail("Expected Backspace keydown to remove the defender on the selected tile.")
		_send_keydown(input_bridge, KEY_R)

	if frames == 34:
		if defenders.get_child_count() != 0:
			return _fail("Expected R keydown restart to clear defenders.")
		if int(placement.get("selected_index")) != 0:
			return _fail("Expected R keydown restart to reset selected defender type.")
		if Vector2i(placement.get("cursor_cell")) != Vector2i(grid.call("get_default_cursor_cell")):
			return _fail("Expected R keydown restart to reset the cursor.")

		print("keyboard_controls_smoke_test: passed")
		quit(0)
		return true

	return false


func _send_keydown(input_bridge: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	input_bridge.call("_input", event)


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return true
