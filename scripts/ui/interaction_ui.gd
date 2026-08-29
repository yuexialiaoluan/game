class_name InteractionUI
extends CanvasLayer

## 极简 HUD + 交互提示 + 对话框 + 背包/地图/任务面板。
var prompt: Label
var feedback: Label
var hud: Label
var menu: VBoxContainer
var menu_buttons: Array = []

var dialogue_panel: PanelContainer
var dialogue_label: Label

var inventory_panel: PanelContainer
var inventory_label: Label

var map_panel: PanelContainer
var map_label: Label

var quest_panel: PanelContainer
var quest_label: Label

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

	dialogue_panel = _make_panel(Vector2(80, 440), Vector2(700, 160))
	var dv := VBoxContainer.new()
	dialogue_panel.add_child(dv)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(dialogue_label)
	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(func(): dialogue_panel.visible = false)
	dv.add_child(close)

	inventory_panel = _make_panel(Vector2(80, 80), Vector2(500, 360))
	var iv := VBoxContainer.new()
	inventory_panel.add_child(iv)
	inventory_label = Label.new()
	iv.add_child(inventory_label)
	var iclose := Button.new()
	iclose.text = "关闭"
	iclose.pressed.connect(func(): inventory_panel.visible = false)
	iv.add_child(iclose)

	map_panel = _make_panel(Vector2(600, 80), Vector2(400, 320))
	var mv := VBoxContainer.new()
	map_panel.add_child(mv)
	map_label = Label.new()
	mv.add_child(map_label)
	var mclose := Button.new()
	mclose.text = "关闭"
	mclose.pressed.connect(func(): map_panel.visible = false)
	mv.add_child(mclose)

	quest_panel = _make_panel(Vector2(200, 120), Vector2(600, 360))
	var qv := VBoxContainer.new()
	quest_panel.add_child(qv)
	quest_label = Label.new()
	qv.add_child(quest_label)
	var qclose := Button.new()
	qclose.text = "关闭"
	qclose.pressed.connect(func(): quest_panel.visible = false)
	qv.add_child(qclose)

func _make_panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.custom_minimum_size = size
	p.visible = false
	add_child(p)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.20, 0.85)
	style.border_color = Color(0.45, 0.75, 1.0, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", style)
	return p

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

func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	dialogue_panel.visible = true

func close_dialogue() -> void:
	dialogue_panel.visible = false

func toggle_inventory(actor: Actor) -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible and actor != null:
		var lines: Array[String] = ["背包："]
		for id in actor.inventory:
			lines.append(str(id) + " x" + str(actor.inventory[id]))
		inventory_label.text = "\n".join(lines)

func toggle_map(player_pos: Vector3) -> void:
	map_panel.visible = not map_panel.visible
	if map_panel.visible:
		map_label.text = "世界地图\n\n玩家位置：" + str(player_pos.round()) + "\n\n已发现：\nFrontier Village\nForest\nGoblin Camp\nCave"

func toggle_quest(journal: Array) -> void:
	quest_panel.visible = not quest_panel.visible
	if quest_panel.visible:
		var lines: Array[String] = ["任务日志："]
		for q in journal:
			var title := str(q.get("title", ""))
			var state := str(q.get("state", ""))
			var prog := int(q.get("progress", 0))
			lines.append(title + " [" + state + "] " + str(prog))
		quest_label.text = "\n".join(lines)
