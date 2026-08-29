class_name MainMenuController
extends Node

var nav: MenuNavigator
var localization: LocalizationService
var settings: SettingsService
var creation: CharacterCreationService
var save_service: SaveService
var preview: CharacterVisual = null

var root: Control
var panels: Dictionary = {}
var status_label: Label

func _ready() -> void:
	nav = MenuNavigator.new()
	localization = LocalizationService.new()
	settings = SettingsService.new()
	creation = CharacterCreationService.new()
	save_service = SaveService.new()
	_build_ui()
	_refresh()
	call_deferred("_focus_current_panel")

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color("101827")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	var horizon := ColorRect.new()
	horizon.color = Color("193b4a")
	horizon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	horizon.offset_top = -210.0
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(horizon)
	_add_title_art()

	var title_label := Label.new()
	title_label.text = "《灰烬之上的勇者》"
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 80.0
	title_label.offset_bottom = 132.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = "ASHES OF THE BRAVE - PLAYABLE PROTOTYPE 0.3.0"
	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub_label.offset_top = 140.0
	sub_label.offset_bottom = 168.0
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub_label)

	panels["Title"] = _make_panel("Title")
	panels["MainMenu"] = _make_panel("MainMenu")
	panels["ModeSelect"] = _make_panel("ModeSelect")
	panels["StoryCreation"] = _make_panel("StoryCreation")
	panels["FreeCreation"] = _make_panel("FreeCreation")
	panels["LoadGame"] = _make_panel("LoadGame")
	panels["Settings"] = _make_panel("Settings")
	panels["ConfirmDialog"] = _make_panel("ConfirmDialog")

	_add_button(panels["Title"], "开始游戏", func(): nav.goto("MainMenu"))
	_add_button(panels["MainMenu"], "开始游戏", func(): nav.goto("ModeSelect"))
	_add_button(panels["MainMenu"], "读取存档", func(): nav.goto("LoadGame"))
	_add_button(panels["MainMenu"], "设置", func(): nav.goto("Settings"))
	_add_button(panels["MainMenu"], "退出游戏", func(): exit_game())
	_add_button(panels["ModeSelect"], "故事模式", func(): select_mode("story"))
	_add_button(panels["ModeSelect"], "自由模式", func(): select_mode("free"))
	_add_button(panels["ModeSelect"], "返回", func(): nav.back())
	_add_button(panels["StoryCreation"], "确认开始", func(): _start_game())
	_add_button(panels["StoryCreation"], "返回", func(): nav.back())
	_add_button(panels["FreeCreation"], "确认开始", func(): _start_game())
	_add_button(panels["FreeCreation"], "返回", func(): nav.back())
	_add_button(panels["LoadGame"], "返回", func(): nav.back())
	_add_button(panels["Settings"], "返回", func(): nav.back())
	_add_button(panels["ConfirmDialog"], "确定退出", func(): get_tree().quit())
	_add_button(panels["ConfirmDialog"], "取消", func(): nav.back())

	status_label = Label.new()
	status_label.visible = false
	root.add_child(status_label)

func _make_panel(id: String) -> VBoxContainer:
	var p := VBoxContainer.new()
	p.name = id
	p.add_theme_constant_override("separation", 8)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.position = Vector2(-140, 40)
	root.add_child(p)
	return p

func _add_title_art() -> void:
	var registry := UIAssetRegistry.new()
	var village_path := registry.get_path("title.village")
	if ResourceLoader.exists(village_path):
		var village := TextureRect.new()
		village.texture = load(village_path) as Texture2D
		village.position = Vector2(860, 128)
		village.size = Vector2(360, 392)
		village.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		village.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		village.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		village.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(village)
	var hero_path := registry.get_path("title.hero")
	if ResourceLoader.exists(hero_path):
		var hero := TextureRect.new()
		hero.texture = load(hero_path) as Texture2D
		hero.position = Vector2(700, 394)
		hero.size = Vector2(128, 128)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(hero)

func _add_button(parent: Control, text: String, cb: Callable) -> void:
	var b := UITheme.styled_button(text, Vector2(280, 46))
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func():
		cb.call()
		_refresh()
		call_deferred("_focus_current_panel")
	)
	parent.add_child(b)

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/demo/prototype_village.tscn")

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") and not event.is_action_pressed("interaction_confirm"):
		return
	match nav.state:
		"Title":
			nav.goto("MainMenu")
		"MainMenu":
			nav.goto("ModeSelect")
		"ModeSelect":
			select_mode("story")
		"StoryCreation", "FreeCreation":
			_start_game()
		_:
			return
	_refresh()
	call_deferred("_focus_current_panel")
	get_viewport().set_input_as_handled()

func _focus_current_panel() -> void:
	var panel: VBoxContainer = panels.get(nav.state) as VBoxContainer
	if panel == null:
		return
	for child in panel.get_children():
		if child is Button and child.visible and not child.disabled:
			child.grab_focus()
			return

func get_state() -> String:
	return nav.state

func start_game() -> void:
	nav.goto("ModeSelect")

func select_mode(mode: String) -> void:
	creation.setup(mode)
	nav.goto("StoryCreation" if mode == "story" else "FreeCreation")

func set_player_name(n: String) -> void:
	creation.set_value("name", n)

func set_gender(g: String) -> void:
	creation.set_value("gender", g)
	creation.set_value("face_id", "human_male" if g == "male" else "human_female")

func set_race(r: String) -> void:
	creation.set_value("race", r)

func set_hair(h: String) -> void:
	creation.set_value("hair_id", h)

func set_clothing(c: String) -> void:
	creation.set_value("clothing_id", c)

func set_class(cls: String) -> void:
	creation.set_value("initial_class", cls)

func confirm_creation() -> Dictionary:
	return creation.get_data()

func open_load() -> void:
	nav.goto("LoadGame")

func load_slot(slot: String) -> bool:
	return save_service.load_game(slot).success

func delete_slot(slot: String) -> void:
	save_service.delete_save(slot)

func open_settings() -> void:
	nav.goto("Settings")

func back() -> void:
	nav.back()

func exit_game() -> void:
	nav.goto("ConfirmDialog")

func _refresh() -> void:
	for id in panels:
		panels[id].visible = (id == nav.state)
