class_name InteractionUI
extends CanvasLayer

## 极简 HUD + 交互提示 + Action 菜单，只读服务/发意图，不直接改状态。
var prompt: Label
var feedback: Label
var hud: Label
var menu: VBoxContainer
var menu_buttons: Array = []

func _ready() -> void:
	var root := VBoxContainer.new()
	root.position = Vector2(12, 12)
	add_child(root)

	hud = Label.new()
	root.add_child(hud)

	prompt = Label.new()
	prompt.visible = false
	root.add_child(prompt)

	feedback = Label.new()
	feedback.modulate = Color(0.6, 0.9, 1.0)
	root.add_child(feedback)

	menu = VBoxContainer.new()
	root.add_child(menu)

func set_prompt(text: String) -> void:
	prompt.text = text
	prompt.visible = text != ""

func set_feedback(text: String) -> void:
	feedback.text = text

func set_hud(text: String) -> void:
	hud.text = text

func show_menu(actions: Array, on_choose: Callable) -> void:
	clear_menu()
	for a in actions:
		var b := Button.new()
		b.text = str(a.get("display_name", ""))
		b.pressed.connect(func(): on_choose.call(a))
		menu.add_child(b)
		menu_buttons.append(b)

func clear_menu() -> void:
	for b in menu_buttons:
		if is_instance_valid(b):
			b.queue_free()
	menu_buttons.clear()

func hide_menu() -> void:
	clear_menu()
