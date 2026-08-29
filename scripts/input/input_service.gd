extends Node

## 正式 Input Action 层：在启动时注册项目输入动作，避免在脚本里散落 KeyCode。
func _ready() -> void:
	_register()

func _register() -> void:
	_key_action("move_up", KEY_W, KEY_UP)
	_key_action("move_down", KEY_S, KEY_DOWN)
	_key_action("move_left", KEY_A, KEY_LEFT)
	_key_action("move_right", KEY_D, KEY_RIGHT)
	_key_action("interact", KEY_E, 0)
	_key_action("interaction_confirm", KEY_ENTER, 0)
	_key_action("interaction_cancel", KEY_ESCAPE, 0)
	_key_action("attack", KEY_SPACE, 0)
	_key_action("cancel", KEY_ESCAPE, 0)
	_key_action("open_inventory", KEY_B, 0)
	_key_action("open_map", KEY_M, 0)
	_key_action("open_quest", KEY_J, 0)
	_key_action("open_party", KEY_T, 0)
	_key_action("quick_save", KEY_F5, 0)
	_key_action("quick_load", KEY_F9, 0)
	_mouse_wheel_action("camera_zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_mouse_wheel_action("camera_zoom_out", MOUSE_BUTTON_WHEEL_DOWN)

func _key_action(action: String, key: int, alt: int = 0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
	if alt != 0:
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = alt
		InputMap.action_add_event(action, ev2)

func _mouse_wheel_action(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	InputMap.action_add_event(action, ev)
