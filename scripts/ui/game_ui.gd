class_name GameUI
extends CanvasLayer

signal dialogue_closed
signal combat_finished(result: String, rewards: Dictionary)
signal dialogue_action_requested(action: String, dialogue_id: String, choice_id: String)
signal tavern_recruit_requested(npc_id: String)
signal dungeon_requested(level: int)
signal party_member_dismissed(actor: Actor)

var gdb: GameplayDB
var content: ContentDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var dialogue_service: DialogueService
var quest_service: QuestService
var inventory_service: InventoryService
var equipment_service: EquipmentService
var party_service: PartyService
var shop_service: ShopService
var character_service: CharacterService
var localization: LocalizationService
var theme: UITheme

var root: Control
var hud_root: Control
var prompt_label: Label
var feedback_label: Label

var hud_portrait: PortraitView
var hud_name: Label
var hud_hp: ProgressBar
var hud_gold: Label
var hud_time: Label
var hud_weather: Label
var hud_party: HBoxContainer

var dialogue_panel: PanelContainer
var dialogue_portrait: PortraitView
var dialogue_name: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var dialogue_continue: Label
var _dialogue_timer: Timer
var _dialogue_full: String = ""
var _dialogue_shown: String = ""
var _dialogue_choices_raw: Array = []
var _dialogue_choice_widgets: Array = []
var _dialogue_choice_index: int = 0

var character_panel: PanelContainer
var character_content: VBoxContainer
var character_actor: Actor = null

var party_panel: PanelContainer
var party_content: VBoxContainer

var inventory_panel: PanelContainer
var inventory_content: VBoxContainer
var inventory_actor: Actor = null
var inventory_filter: String = "all"

var equipment_panel: PanelContainer
var equipment_content: VBoxContainer
var equipment_actor: Actor = null

var quest_panel: PanelContainer
var quest_content: VBoxContainer

var shop_panel: PanelContainer
var shop_content: VBoxContainer
var shop_actor: Actor = null

var tavern_panel: PanelContainer
var tavern_content: VBoxContainer
var tavern_actor: Actor = null
var tavern_recruits: Array = []

var profile_panel: PanelContainer
var profile_content: VBoxContainer

var combat_panel: PanelContainer
var combat_content: VBoxContainer
var combat_instance: CombatInstance = null
var combat_log_label: Label
var combat_result_label: Label
var _combat_rewards_granted: bool = false

var settings_panel: PanelContainer
var settings_content: VBoxContainer

var dungeon_panel: PanelContainer
var dungeon_content: VBoxContainer
const EQUIPMENT_SLOTS := ["helmet", "chest", "legs", "boots", "necklace", "gloves", "ring_1", "ring_2", "ring_3", "ring_4", "mainhand", "offhand"]

func setup(p_gdb: GameplayDB, p_content: ContentDB, p_cdb: CharacterVisualDB, p_ctx: EvaluatorContext, p_bus: EventBus) -> void:
	gdb = p_gdb
	content = p_content
	cdb = p_cdb
	ctx = p_ctx
	gs = p_ctx.game_state
	localization = LocalizationService.new()
	theme = UITheme.new()

	dialogue_service = DialogueService.new()
	dialogue_service.setup(content)
	quest_service = QuestService.new()
	quest_service.setup(content, p_bus)
	inventory_service = InventoryService.new()
	inventory_service.setup(gdb, p_bus)
	equipment_service = EquipmentService.new()
	equipment_service.setup(gdb, p_bus)
	party_service = PartyService.new()
	party_service.setup(p_bus)
	shop_service = ShopService.new()
	shop_service.setup(p_bus)
	character_service = CharacterService.new()
	character_service.setup(p_bus)
	_build()

func set_services(p_quest_service: QuestService, p_party_service: PartyService, p_shop_service: ShopService) -> void:
	if p_quest_service != null:
		quest_service = p_quest_service
	if p_party_service != null:
		party_service = p_party_service
	if p_shop_service != null:
		shop_service = p_shop_service

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var font_path := UIAssetRegistry.new().get_path("font.ui.bold_pixels")
	if font_path != "" and ResourceLoader.exists(font_path):
		root.add_theme_font_override("font", load(font_path))
	_build_hud()
	_build_dialogue()
	_build_character()
	_build_party()
	_build_inventory()
	_build_equipment()
	_build_quest()
	_build_shop()
	_build_tavern()
	_build_profile()
	_build_combat()
	_build_settings()
	_build_dungeon()

func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_root)

	var left := UITheme.panel()
	left.position = Vector2(16, 16)
	left.custom_minimum_size = Vector2(250, 110)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	var top := HBoxContainer.new()
	lv.add_child(top)
	hud_portrait = PortraitView.new()
	hud_portrait.custom_minimum_size = Vector2(64, 64)
	hud_portrait.set_portrait("portrait.default")
	top.add_child(hud_portrait)
	var name_box := VBoxContainer.new()
	top.add_child(name_box)
	hud_name = UITheme.label("", 18)
	name_box.add_child(hud_name)
	hud_hp = ProgressBar.new()
	hud_hp.custom_minimum_size = Vector2(160, 12)
	hud_hp.max_value = 100.0
	hud_hp.value = 100.0
	name_box.add_child(hud_hp)

	var right := UITheme.panel()
	right.position = Vector2(1010, 16)
	right.custom_minimum_size = Vector2(250, 90)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(right)
	var rv := VBoxContainer.new()
	right.add_child(rv)
	var gold_row := HBoxContainer.new()
	rv.add_child(gold_row)
	_add_ui_icon(gold_row, "icon.gold")
	hud_gold = UITheme.label("", 16)
	gold_row.add_child(hud_gold)
	hud_time = UITheme.label("", 16)
	rv.add_child(hud_time)
	hud_weather = UITheme.label("", 16)
	rv.add_child(hud_weather)

	var bottom := HBoxContainer.new()
	bottom.position = Vector2(320, 682)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(bottom)
	hud_party = HBoxContainer.new()
	bottom.add_child(hud_party)

	prompt_label = UITheme.label("", 18, Color(0.85, 0.95, 1.0))
	prompt_label.position = Vector2(540, 640)
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(prompt_label)

	feedback_label = UITheme.label("", 16, Color(0.6, 0.9, 1.0))
	feedback_label.position = Vector2(16, 136)
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(feedback_label)
	var shortcuts := UITheme.label("[B] 背包   [T] 队伍   [J] 任务   [M] 地图   [E] 互动   [Esc] 关闭/设置", 13, Color(0.72, 0.85, 1.0))
	shortcuts.position = Vector2(16, 690)
	shortcuts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(shortcuts)

func _build_dialogue() -> void:
	dialogue_panel = _make_modal(Vector2(760, 250), Vector2(260, 380))
	dialogue_panel.name = "DialoguePanel"
	var row := HBoxContainer.new()
	dialogue_panel.get_node("Margin/Content").add_child(row)
	dialogue_portrait = PortraitView.new()
	dialogue_portrait.custom_minimum_size = Vector2(150, 150)
	row.add_child(dialogue_portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	dialogue_name = UITheme.label("", 20, Color(0.75, 0.9, 1.0))
	body.add_child(dialogue_name)
	var quest_icon := _make_icon("icon.quest")
	quest_icon.custom_minimum_size = Vector2(18, 18)
	body.add_child(quest_icon)
	dialogue_text = UITheme.label("", 17)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size = Vector2(540, 100)
	body.add_child(dialogue_text)
	dialogue_choices = VBoxContainer.new()
	body.add_child(dialogue_choices)
	dialogue_continue = UITheme.label(localization.t("ui.dialogue.continue"), 16, Color(0.6, 0.9, 1.0))
	dialogue_continue.visible = false
	body.add_child(dialogue_continue)
	_dialogue_timer = Timer.new()
	_dialogue_timer.wait_time = 0.02
	_dialogue_timer.one_shot = true
	_dialogue_timer.timeout.connect(_on_typewriter_tick)
	add_child(_dialogue_timer)

func _build_character() -> void:
	character_panel = _make_modal(Vector2(680, 500), Vector2(300, 110))
	character_panel.name = "CharacterPanel"
	character_content = character_panel.get_node("Margin/Content")

func _build_party() -> void:
	party_panel = _make_modal(Vector2(700, 520), Vector2(290, 100))
	party_panel.name = "PartyPanel"
	party_content = party_panel.get_node("Margin/Content")

func _build_inventory() -> void:
	inventory_panel = _make_modal(Vector2(760, 540), Vector2(260, 90))
	inventory_panel.name = "InventoryPanel"
	inventory_content = inventory_panel.get_node("Margin/Content")

func _build_equipment() -> void:
	equipment_panel = _make_modal(Vector2(620, 520), Vector2(330, 100))
	equipment_panel.name = "EquipmentPanel"
	equipment_content = equipment_panel.get_node("Margin/Content")

func _build_quest() -> void:
	quest_panel = _make_modal(Vector2(720, 520), Vector2(280, 100))
	quest_panel.name = "QuestPanel"
	quest_content = quest_panel.get_node("Margin/Content")

func _build_shop() -> void:
	shop_panel = _make_modal(Vector2(680, 520), Vector2(300, 100))
	shop_panel.name = "ShopPanel"
	shop_content = shop_panel.get_node("Margin/Content")

func _build_tavern() -> void:
	tavern_panel = _make_modal(Vector2(520, 360), Vector2(380, 160))
	tavern_panel.name = "TavernPanel"
	tavern_content = tavern_panel.get_node("Margin/Content")

func _build_profile() -> void:
	profile_panel = _make_modal(Vector2(560, 480), Vector2(360, 120))
	profile_panel.name = "ProfilePanel"
	profile_content = profile_panel.get_node("Margin/Content")

func _build_combat() -> void:
	combat_panel = _make_modal(Vector2(680, 420), Vector2(300, 150))
	combat_panel.name = "CombatPanel"
	combat_content = combat_panel.get_node("Margin/Content")
	combat_log_label = _label(combat_content, "", 14)
	combat_result_label = _label(combat_content, "", 16, Color(0.95, 0.9, 0.6))

func _build_settings() -> void:
	settings_panel = _make_modal(Vector2(420, 260), Vector2(430, 210))
	settings_panel.name = "SettingsPanel"
	settings_content = settings_panel.get_node("Margin/Content")
	_label(settings_content, "设置", 22)
	_label(settings_content, "原型设置：游戏继续在当前世界运行。", 14, Color(0.72, 0.85, 1.0))
	_button(settings_content, "继续", func(): settings_panel.visible = false, Vector2(150, 34))

func _build_dungeon() -> void:
	dungeon_panel = _make_modal(Vector2(540, 410), Vector2(370, 155))
	dungeon_panel.name = "DungeonPanel"
	dungeon_content = dungeon_panel.get_node("Margin/Content")

func _make_modal(size: Vector2, pos: Vector2) -> PanelContainer:
	var p := UITheme.panel()
	p.position = pos
	p.custom_minimum_size = size
	p.visible = false
	root.add_child(p)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	p.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var close := UITheme.styled_button(localization.t("ui.panel.close"), Vector2(90, 30))
	close.pressed.connect(func(): p.visible = false)
	content.add_child(close)
	content.set_meta("close_button", close)
	return p

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.free()

func _clear_panel_content(panel: PanelContainer) -> void:
	var content: Node = panel.get_node("Margin/Content")
	var close = content.get_meta("close_button")
	for child in content.get_children():
		if child != close:
			child.free()

func _label(parent: Node, text: String, size: int = 16, color: Color = Color(0.85, 0.92, 1.0)) -> Label:
	var l := UITheme.label(text, size, color)
	parent.add_child(l)
	return l

func _make_icon(asset_id: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = UIAssetRegistry.new().get_texture(asset_id, Rect2(0, 0, 16, 16))
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon

func _add_ui_icon(parent: Node, asset_id: String) -> void:
	parent.add_child(_make_icon(asset_id))

func _button(parent: Node, text: String, cb: Callable, min_size: Vector2 = Vector2(150, 34)) -> Button:
	var b := UITheme.styled_button(text, min_size)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func set_prompt(text: String) -> void:
	prompt_label.text = text

func set_feedback(text: String) -> void:
	feedback_label.text = text

func set_hud(text: String) -> void:
	feedback_label.text = text

func update_hud(actor: Actor, gold: int, time_text: String, weather_text: String, party: PartyService = null) -> void:
	if actor == null:
		return
	hud_name.text = actor.identity.display_name + "  Lv" + str(actor.progression.level)
	hud_hp.max_value = maxf(1.0, actor.max_hp())
	hud_hp.value = clampf(actor.get_hp(), 0.0, hud_hp.max_value)
	hud_portrait.set_actor_portrait(actor)
	hud_gold.text = localization.t("ui.hud.gold") + "  " + str(gold)
	hud_time.text = localization.t("ui.hud.time") + "  " + time_text
	hud_weather.text = localization.t("ui.hud.weather") + "  " + weather_text
	if party != null and hud_party.get_child_count() != party.active.size():
		_refresh_hud_party(party)

func _refresh_hud_party(party: PartyService) -> void:
	for child in hud_party.get_children():
		child.queue_free()
	if party == null:
		return
	for actor in party.active:
		var item := VBoxContainer.new()
		hud_party.add_child(item)
		var pv := PortraitView.new()
		pv.custom_minimum_size = Vector2(38, 38)
		pv.set_actor_portrait(actor)
		item.add_child(pv)
		_label(item, actor.identity.display_name.substr(0, 4), 11)

func start_dialogue(dialogue_id: String, speaker_name: String = "", speaker_actor: Actor = null) -> void:
	var def := content.get_dialogue(dialogue_id)
	if def.is_empty():
		show_dialogue(speaker_name + "：" + dialogue_id)
		return
	dialogue_panel.visible = true
	dialogue_name.text = speaker_name
	if speaker_name == "":
		dialogue_name.text = str(def.get("speaker", ""))
	if speaker_actor != null:
		dialogue_name.text = speaker_actor.identity.display_name
		dialogue_portrait.set_actor_portrait(speaker_actor)
	else:
		dialogue_portrait.set_portrait("portrait.default")
	_dialogue_choices_raw = def.get("choices", []) as Array
	_dialogue_choices_raw = _dialogue_choices_raw.duplicate()
	_start_typewriter(localization.t(str(def.get("text", ""))))

func _start_typewriter(text: String) -> void:
	_dialogue_full = text
	_dialogue_shown = ""
	dialogue_text.text = ""
	_clear(dialogue_choices)
	dialogue_continue.visible = false
	_dialogue_timer.start()

func _on_typewriter_tick() -> void:
	var next_len: int = mini(_dialogue_shown.length() + 1, _dialogue_full.length())
	_dialogue_shown = _dialogue_full.substr(0, next_len)
	dialogue_text.text = _dialogue_shown
	if _dialogue_shown.length() >= _dialogue_full.length():
		_show_dialogue_choices()
	else:
		_dialogue_timer.start()

func _show_dialogue_choices() -> void:
	_clear(dialogue_choices)
	_dialogue_choice_widgets.clear()
	_dialogue_choice_index = 0
	if _dialogue_choices_raw.is_empty():
		dialogue_continue.visible = true
		dialogue_continue.text = localization.t("ui.dialogue.continue") + "  [E]"
		return
	dialogue_continue.visible = false
	for i in range(_dialogue_choices_raw.size()):
		var idx := i
		var choice: Dictionary = _dialogue_choices_raw[i] as Dictionary
		var allowed: bool = ConditionEvaluator.evaluate(choice.get("conditions", {}), ctx)
		var text: String = localization.t(str(choice.get("text", "")))
		if not allowed:
			text += "  [" + localization.t("ui.dialogue.locked") + "]"
		var b := _button(dialogue_choices, text, func(): _on_choice_pressed(idx), Vector2(520, 34))
		b.disabled = not allowed
		_dialogue_choice_widgets.append(b)
	_update_dialogue_choice_focus()

func _update_dialogue_choice_focus() -> void:
	if _dialogue_choice_widgets.is_empty():
		return
	_dialogue_choice_index = clampi(_dialogue_choice_index, 0, _dialogue_choice_widgets.size() - 1)
	for i in range(_dialogue_choice_widgets.size()):
		var button: Button = _dialogue_choice_widgets[i] as Button
		button.button_pressed = false
		button.modulate = Color(1.0, 1.0, 1.0) if i == _dialogue_choice_index else Color(0.72, 0.78, 0.9)
	var selected: Button = _dialogue_choice_widgets[_dialogue_choice_index] as Button
	selected.grab_focus()

func move_dialogue_selection(direction: int) -> bool:
	if not dialogue_panel.visible or _dialogue_shown.length() < _dialogue_full.length() or _dialogue_choice_widgets.is_empty():
		return false
	var count := _dialogue_choice_widgets.size()
	for offset in range(1, count + 1):
		var candidate := posmod(_dialogue_choice_index + direction * offset, count)
		var button: Button = _dialogue_choice_widgets[candidate] as Button
		if not button.disabled:
			_dialogue_choice_index = candidate
			_update_dialogue_choice_focus()
			return true
	return false

func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= _dialogue_choices_raw.size():
		return
	var choice: Dictionary = _dialogue_choices_raw[index] as Dictionary
	var choice_id: String = str(choice.get("id", ""))
	var world_action: String = str(choice.get("world_action", ""))
	if world_action != "":
		dialogue_action_requested.emit(world_action, _current_dialogue_id(), choice_id)
		_close_dialogue()
		return
	if dialogue_service.execute_choice(_current_dialogue_id(), choice_id, ctx):
		_close_dialogue()

func _current_dialogue_id() -> String:
	# The active dialogue id is tracked by start_dialogue callers through this UI.
	return str(_active_dialogue_id)

var _active_dialogue_id: String = ""

func start_dialogue_id(id: String, speaker_name: String = "", speaker_actor: Actor = null) -> void:
	_active_dialogue_id = id
	start_dialogue(id, speaker_name, speaker_actor)

func start_dialogue_text(text: String, speaker_name: String = "", speaker_actor: Actor = null) -> void:
	_active_dialogue_id = ""
	_dialogue_choices_raw = []
	dialogue_panel.visible = true
	dialogue_name.text = speaker_name
	if speaker_actor != null:
		dialogue_portrait.set_actor_portrait(speaker_actor)
	else:
		dialogue_portrait.set_portrait("portrait.default")
	_start_typewriter(text)

func skip_dialogue() -> void:
	if _dialogue_shown.length() < _dialogue_full.length():
		_dialogue_shown = _dialogue_full
		dialogue_text.text = _dialogue_full
		_show_dialogue_choices()

func handle_dialogue_input() -> bool:
	if not dialogue_panel.visible:
		return false
	if _dialogue_shown.length() < _dialogue_full.length():
		skip_dialogue()
		return true
	if _dialogue_choices_raw.is_empty():
		_close_dialogue()
		return true
	if _dialogue_choice_index >= 0 and _dialogue_choice_index < _dialogue_choices_raw.size():
		var choice: Dictionary = _dialogue_choices_raw[_dialogue_choice_index] as Dictionary
		if ConditionEvaluator.evaluate(choice.get("conditions", {}), ctx):
			_on_choice_pressed(_dialogue_choice_index)
	return true

func show_dialogue(text: String) -> void:
	dialogue_panel.visible = true
	dialogue_name.text = ""
	dialogue_portrait.set_portrait("portrait.default")
	_start_typewriter(text)

func close_dialogue() -> void:
	_close_dialogue()

func _close_dialogue() -> void:
	dialogue_panel.visible = false
	_dialogue_timer.stop()
	dialogue_closed.emit()

func has_open_modal() -> bool:
	for panel in _modal_panels():
		if panel.visible:
			return true
	return false

func close_top_modal() -> bool:
	var panels := _modal_panels()
	for index in range(panels.size() - 1, -1, -1):
		var panel: PanelContainer = panels[index]
		if panel.visible:
			if panel == dialogue_panel:
				_close_dialogue()
			else:
				panel.visible = false
			return true
	return false

func handle_cancel() -> bool:
	if combat_panel.visible and combat_instance != null and combat_instance.battle_state == "Active":
		set_feedback("战斗仍在进行，请使用战斗面板完成回合。")
		return true
	if close_top_modal():
		return true
	open_settings()
	return true

func open_settings() -> void:
	settings_panel.visible = true

func _modal_panels() -> Array:
	return [dialogue_panel, character_panel, party_panel, inventory_panel, equipment_panel, quest_panel, shop_panel, tavern_panel, profile_panel, combat_panel, settings_panel, dungeon_panel]

func show_profile(actor: Actor) -> void:
	if actor == null:
		return
	profile_panel.visible = true
	_clear_panel_content(profile_panel)
	var row := HBoxContainer.new()
	profile_content.add_child(row)
	var pv := PortraitView.new()
	pv.custom_minimum_size = Vector2(120, 120)
	pv.set_actor_portrait(actor)
	row.add_child(pv)
	var info := VBoxContainer.new()
	row.add_child(info)
	_label(info, actor.identity.display_name, 20)
	var bg := content.get_background(actor.background_id)
	_label(info, str(bg.get("occupation", "")), 15, Color(0.7, 0.85, 1.0))
	_label(info, str(bg.get("short_description", "")), 14)
	_label(info, localization.t("ui.profile.personality") + ": " + str(bg.get("personality", "")), 13)
	_label(info, localization.t("ui.profile.motivation") + ": " + str(bg.get("motivation", "")), 13)

func open_character(actor: Actor) -> void:
	if actor == null:
		return
	character_actor = actor
	character_panel.visible = true
	_refresh_character()

func _refresh_character() -> void:
	if character_actor == null:
		return
	_clear_panel_content(character_panel)
	var head := HBoxContainer.new()
	character_content.add_child(head)
	var pv := PortraitView.new()
	pv.custom_minimum_size = Vector2(110, 110)
	pv.set_actor_portrait(character_actor)
	head.add_child(pv)
	var info := VBoxContainer.new()
	head.add_child(info)
	_label(info, character_actor.identity.display_name, 22)
	_label(info, "%s %d   %s %d" % [localization.t("ui.character.level"), character_actor.progression.level, localization.t("ui.character.xp"), character_actor.progression.xp])
	_label(info, "%s %s" % [localization.t("ui.character.race"), character_actor.race_id])
	var cls := ""
	for c in character_actor.classes:
		cls += str(c) + " "
	_label(info, "%s %s" % [localization.t("ui.character.class"), cls])
	_label(info, "%s %d / %d    %s %d / %d" % [localization.t("ui.character.hp"), int(character_actor.get_hp()), int(character_actor.max_hp()), localization.t("ui.character.mp"), int(character_actor.current_mp), int(character_actor.get_stat("max_mp"))])
	_label(info, localization.t("ui.character.feats") + ": " + (" ".join(character_actor.feats) if not character_actor.feats.is_empty() else "-"), 13)
	_label(info, localization.t("ui.character.talents") + ": " + (" ".join(character_actor.talents) if not character_actor.talents.is_empty() else "-"), 13)
	_label(character_content, localization.t("ui.character.attributes"), 18)
	for stat in ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]:
		var stat_name: String = stat
		var row := HBoxContainer.new()
		character_content.add_child(row)
		_label(row, stat + "  " + str(int(character_actor.get_base_stat(stat))), 15)
		var btn := _button(row, "+", func(): _allocate(stat_name), Vector2(40, 26))
		btn.disabled = character_actor.progression.attribute_points <= 0
	_label(character_content, "%s AP %d" % [localization.t("ui.character.allocate"), character_actor.progression.attribute_points], 14)
	_label(character_content, localization.t("ui.character.equipment"), 18)
	var eq_box := VBoxContainer.new()
	character_content.add_child(eq_box)
	for slot in EQUIPMENT_SLOTS:
		var item_id := str(character_actor.equipment.get(slot, ""))
		var display: String = slot + ": " + (gdb.get_equipment(item_id).get("name", item_id) if item_id != "" else "-")
		_label(eq_box, display, 14)
	_button(character_content, "打开装备栏", func(): open_equipment(character_actor), Vector2(160, 32))

func _allocate(stat: String) -> void:
	if character_actor != null:
		character_service.allocate_attribute(character_actor, stat)
		_refresh_character()

func open_party() -> void:
	party_panel.visible = true
	_refresh_party()

func toggle_party() -> void:
	if party_panel.visible:
		party_panel.visible = false
	else:
		open_party()

func _refresh_party() -> void:
	_clear_panel_content(party_panel)
	_label(party_content, localization.t("ui.party.active"), 18)
	for i in range(party_service.active.size()):
		var idx := i
		var member: Actor = party_service.active[i]
		var row := HBoxContainer.new()
		party_content.add_child(row)
		_button(row, "%d  %s  Lv%d" % [idx + 1, member.identity.display_name, member.progression.level], func(): open_character(member), Vector2(230, 30))
		if member != ctx.player:
			_button(row, "遣退", func(): _dismiss_party_member(member), Vector2(70, 30))
	_label(party_content, localization.t("ui.party.reserve"), 18)
	for i in range(party_service.reserve.size()):
		var idx := i
		var member: Actor = party_service.reserve[i]
		var reserve_row := HBoxContainer.new()
		party_content.add_child(reserve_row)
		_button(reserve_row, "%d  %s  Lv%d" % [idx + 1, member.identity.display_name, member.progression.level], func(): open_character(member), Vector2(230, 30))
		_button(reserve_row, "遣退", func(): _dismiss_party_member(member), Vector2(70, 30))

func _dismiss_party_member(member: Actor) -> void:
	if member == null or member == ctx.player:
		return
	party_service.remove(member)
	party_member_dismissed.emit(member)
	set_feedback(member.identity.display_name + " 已离开队伍。")
	_refresh_party()

func open_inventory(actor: Actor) -> void:
	if actor == null:
		return
	inventory_actor = actor
	inventory_filter = "all"
	inventory_panel.visible = true
	_refresh_inventory()

func _refresh_inventory() -> void:
	if inventory_actor == null:
		return
	var storage_owner := _inventory_storage_owner()
	if storage_owner == null:
		return
	_clear_panel_content(inventory_panel)
	_label(inventory_content, "队伍共享背包 - 装备给：" + inventory_actor.identity.display_name, 20)
	var layout := HBoxContainer.new()
	inventory_content.add_child(layout)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(175, 430)
	layout.add_child(sidebar)
	_label(sidebar, "队伍与装备", 17)
	for member in party_service.active:
		var actor_ref: Actor = member
		_button(sidebar, actor_ref.identity.display_name, func(): _open_inventory_for(actor_ref), Vector2(160, 26))
	_add_inventory_equipment_slots(sidebar)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	var filters := ["all", "consumable", "material", "weapon", "armor", "misc"]
	var filter_row := HBoxContainer.new()
	right.add_child(filter_row)
	for f in filters:
		var filter_name: String = f
		var btn := _button(filter_row, localization.t("ui.inventory." + f), func(): _set_inventory_filter(filter_name), Vector2(86, 28))
		btn.toggle_mode = true
		btn.button_pressed = (inventory_filter == f)
	var items: Array = []
	for item_id in storage_owner.inventory:
		var qty := int(storage_owner.inventory[item_id])
		var def := gdb.get_item(item_id)
		var itype := str(def.get("type", "misc"))
		if inventory_filter != "all" and itype != inventory_filter:
			continue
		items.append({ "id": item_id, "name": str(def.get("name", item_id)), "qty": qty, "type": itype })
	if items.is_empty():
		_label(right, localization.t("ui.inventory.empty"))
	else:
		var item_scroll := ScrollContainer.new()
		item_scroll.name = "ItemScroll"
		item_scroll.custom_minimum_size = Vector2(535, 382)
		item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		item_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		right.add_child(item_scroll)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.custom_minimum_size = Vector2(532, 0)
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		item_scroll.add_child(grid)
		for item in items:
			var item_id := str(item.get("id"))
			var card := InventoryDragItem.new()
			card.item_id = item_id
			card.set_meta("display_name", str(item.get("name")))
			card.custom_minimum_size = Vector2(172, 142)
			grid.add_child(card)
			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 6)
			margin.add_theme_constant_override("margin_right", 6)
			margin.add_theme_constant_override("margin_top", 5)
			margin.add_theme_constant_override("margin_bottom", 5)
			card.add_child(margin)
			var content_box := VBoxContainer.new()
			content_box.add_theme_constant_override("separation", 2)
			margin.add_child(content_box)
			var icon_row := HBoxContainer.new()
			content_box.add_child(icon_row)
			var icon := _item_icon(item_id)
			icon_row.add_child(icon)
			_label(icon_row, "x%d" % int(item.get("qty")), 14, Color(0.95, 0.88, 0.55))
			_label(content_box, str(item.get("name")), 12)
			var def := gdb.get_item(item_id)
			var actions := HBoxContainer.new()
			content_box.add_child(actions)
			if not def.get("effects", []).is_empty():
				_button(actions, localization.t("ui.inventory.use"), func(): _use_item(item_id), Vector2(68, 25))
			var eq := gdb.get_equipment(item_id)
			if not eq.is_empty():
				_button(actions, localization.t("ui.inventory.equip"), func(): _equip_item(item_id), Vector2(68, 25))
			_button(actions, localization.t("ui.inventory.discard"), func(): _discard_item(item_id), Vector2(68, 25))
			if not eq.is_empty():
				_label(content_box, "[%s] Lv%d" % [_quality_label(str(eq.get("quality", "common"))), int(eq.get("level", 1))], 10, Color(_quality_color(str(eq.get("quality", "common")))))
				var affixes: Array = eq.get("affixes", []) as Array
				if not affixes.is_empty() and affixes[0] is Dictionary:
					var affix: Dictionary = affixes[0] as Dictionary
					var affix_text := str(affix.get("description", ""))
					if affix_text == "":
						affix_text = "+%s %s" % [str(affix.get("value", 0)), _stat_label(str(affix.get("stat", "")))]
					_label(content_box, "【%s】%s" % [str(affix.get("name", "词条")), affix_text], 10, Color(_quality_color(str(eq.get("quality", "common")))))
			var detail := str(def.get("description", ""))
			if detail == "":
				detail = str(def.get("type", "item"))
			_label(content_box, detail.substr(0, 24), 10, Color(0.65, 0.78, 0.9))

func _item_icon(item_id: String) -> TextureRect:
	var icon := TextureRect.new()
	var texture := AssetRegistry.new(cdb).get_equipment_icon(item_id)
	if texture == null:
		texture = UIAssetRegistry.new().get_texture("icon.inventory", Rect2(0, 0, 16, 16))
	icon.texture = texture
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon

func _set_inventory_filter(f: String) -> void:
	inventory_filter = f
	_refresh_inventory()

func _open_inventory_for(actor: Actor) -> void:
	inventory_actor = actor
	_refresh_inventory()

func _inventory_storage_owner() -> Actor:
	if party_service != null:
		return party_service.get_shared_inventory_owner(inventory_actor)
	return inventory_actor

func _add_inventory_equipment_slots(parent: Node) -> void:
	if inventory_actor == null:
		return
	_label(parent, "拖动物品至槽位", 12, Color(0.7, 0.82, 0.95))
	for slot in EQUIPMENT_SLOTS:
		var item_id := str(inventory_actor.equipment.get(slot, ""))
		var drop := EquipmentDropSlot.new()
		drop.slot = slot
		drop.db = gdb
		drop.text = _slot_label(slot) + ": " + (str(gdb.get_equipment(item_id).get("name", item_id)) if item_id != "" else "空")
		drop.custom_minimum_size = Vector2(165, 25)
		drop.equipment_dropped.connect(func(new_item_id: String, target_slot: String): _equip_item_to_slot(new_item_id, target_slot))
		drop.pressed.connect(func(): _unequip_inventory_slot(slot))
		parent.add_child(drop)

func _equip_item_to_slot(item_id: String, slot: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if inventory_actor == null or storage_owner == null or int(storage_owner.inventory.get(item_id, 0)) <= 0:
		return
	if equipment_service.equip(inventory_actor, slot, item_id, ctx):
		set_feedback("已装备 " + str(gdb.get_equipment(item_id).get("name", item_id)))
		_refresh_inventory()

func _unequip_inventory_slot(slot: String) -> void:
	if inventory_actor == null or str(inventory_actor.equipment.get(slot, "")) == "":
		return
	if equipment_service.equip(inventory_actor, slot, "", ctx):
		set_feedback("已卸下 " + _slot_label(slot) + " 装备")
		_refresh_inventory()

func _use_item(item_id: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if inventory_actor != null and storage_owner != null:
		inventory_service.use_item_from_inventory(inventory_actor, storage_owner, item_id, ctx)
		_refresh_inventory()

func _equip_item(item_id: String) -> void:
	if inventory_actor == null:
		return
	var slot := _slot_for_equipment(item_id)
	if slot == "":
		return
	_equip_item_to_slot(item_id, slot)

func _discard_item(item_id: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if storage_owner != null:
		inventory_service.remove_item(storage_owner, item_id, 1)
		_refresh_inventory()

func _slot_for_equipment(item_id: String) -> String:
	var eq := gdb.get_equipment(item_id)
	var slot := str(eq.get("slot", ""))
	match slot:
		"head": return "helmet"
		"torso": return "chest"
		"weapon":
			return "mainhand"
		"shield":
			return "offhand"
	return slot

func open_equipment(actor: Actor) -> void:
	if actor == null:
		return
	equipment_actor = actor
	equipment_panel.visible = true
	_refresh_equipment()

func _refresh_equipment() -> void:
	if equipment_actor == null:
		return
	_clear_panel_content(equipment_panel)
	_label(equipment_content, localization.t("ui.equipment.title"), 20)
	_label(equipment_content, "ATK %d    DEF %d    HP %d" % [int(equipment_actor.get_stat("attack")), int(equipment_actor.get_stat("defense")), int(equipment_actor.max_hp())], 14, Color(0.85, 0.9, 1.0))
	for slot in EQUIPMENT_SLOTS:
		var slot_name: String = slot
		var label := _slot_label(slot)
		var item_id := str(equipment_actor.equipment.get(slot, ""))
		var display: String = label + ": " + (str(gdb.get_equipment(item_id).get("name", item_id)) if item_id != "" else "-")
		var row := HBoxContainer.new()
		equipment_content.add_child(row)
		_label(row, display, 14)
		if item_id != "":
			var gp := gdb.get_equipment(item_id).get("gameplay", {}) as Dictionary
			_label(equipment_content, "    ATK %s  DEF %s  Weight %s" % [str(gp.get("attack", 0)), str(gp.get("defense", 0)), str(gp.get("weight", 0))], 12, Color(0.7, 0.82, 0.95))
			_append_equipment_affixes(equipment_content, gdb.get_equipment(item_id))
		if item_id != "":
			_button(row, localization.t("ui.equipment.unequip"), func(): _unequip(slot_name), Vector2(80, 26))

func _slot_label(slot: String) -> String:
	var labels := { "helmet": "头盔", "chest": "胸甲", "legs": "护腿", "boots": "靴子", "necklace": "项链", "gloves": "手套", "ring_1": "戒指 I", "ring_2": "戒指 II", "ring_3": "戒指 III", "ring_4": "戒指 IV", "mainhand": "主手", "offhand": "副手" }
	return str(labels.get(slot, slot))

func _unequip(slot: String) -> void:
	if equipment_actor != null:
		equipment_service.equip(equipment_actor, slot, "", ctx)
		_refresh_equipment()

func _append_equipment_affixes(parent: Node, definition: Dictionary) -> void:
	var level := int(definition.get("level", 1))
	var quality := str(definition.get("quality", definition.get("rarity", "common")))
	_label(parent, "    [%s] 等级 %d" % [_quality_label(quality), level], 12, Color(_quality_color(quality)))
	for affix in definition.get("affixes", []) as Array:
		if affix is Dictionary:
			var detail := str(affix.get("description", ""))
			if detail == "":
				detail = "+%s %s" % [str(affix.get("value", 0)), _stat_label(str(affix.get("stat", "")))]
			_label(parent, "    【%s】%s" % [str(affix.get("name", "词条")), detail], 12, Color(_quality_color(quality)))

func _quality_label(quality: String) -> String:
	var names := { "poor": "劣质", "common": "普通", "uncommon": "优秀", "rare": "精良", "epic": "大师之作", "legendary": "传说", "artifact": "神器" }
	return str(names.get(quality, quality))

func _quality_color(quality: String) -> String:
	var colors := { "poor": "8e8e8e", "common": "eeeeee", "uncommon": "5bcf67", "rare": "579cff", "epic": "b36cff", "legendary": "ff9b37", "artifact": "ef4a4a" }
	return str(colors.get(quality, "ffffff"))

func _stat_label(stat: String) -> String:
	var labels := { "strength": "力量", "dexterity": "敏捷", "constitution": "体质", "intelligence": "智力", "wisdom": "感知", "charisma": "魅力", "attack": "攻击", "defense": "防御", "magic_attack": "暗/魔法攻击", "max_hp": "最大生命" }
	return str(labels.get(stat, stat))

func open_quest() -> void:
	quest_panel.visible = true
	_refresh_quest()

func _refresh_quest() -> void:
	_clear_panel_content(quest_panel)
	_label(quest_content, localization.t("ui.quest.title"), 20)
	var journal := quest_service.get_journal()
	if journal.is_empty():
		_label(quest_content, localization.t("ui.common.no_quests"))
		return
	for entry in journal:
		var title := str(entry.get("title", ""))
		var state := str(entry.get("state", ""))
		var state_key := "ui.quest.active"
		if state == "Completed":
			state_key = "ui.quest.completed"
		elif state == "Failed":
			state_key = "ui.quest.failed"
		var objectives: Dictionary = entry.get("objectives", {}) as Dictionary
		var quest_def := content.get_quest(str(entry.get("quest_id", "")))
		var obj_text := ""
		var index := 0
		for obj_id in objectives:
			var target := 0
			var defs := quest_def.get("objectives", []) as Array
			if index < defs.size():
				target = int((defs[index] as Dictionary).get("target", 0))
			obj_text += str(obj_id) + " " + str(int(objectives[obj_id])) + "/" + str(target) + "   "
			index += 1
		_label(quest_content, localization.t(title) + "  [" + localization.t(state_key) + "]", 15)
		_label(quest_content, "    " + localization.t(str(entry.get("description", ""))), 12, Color(0.7, 0.82, 0.95))
		_label(quest_content, "    " + localization.t("ui.quest.objectives") + ": " + obj_text, 13)
		_label(quest_content, "    " + localization.t("ui.quest.reward") + ": " + str(quest_def.get("rewards", [])), 12, Color(0.85, 0.8, 0.55))

func open_shop(actor: Actor) -> void:
	if actor == null:
		return
	shop_actor = actor
	shop_panel.visible = true
	_refresh_shop()

func _refresh_shop() -> void:
	if shop_actor == null:
		return
	_clear_panel_content(shop_panel)
	var gold := int(gs.economy_state.get("gold", 0))
	_label(shop_content, localization.t("ui.shop.title") + "   " + str(gold) + " Gold", 20)
	for item_id in shop_service.catalog:
		var shop_item_id: String = item_id
		var price := int(shop_service.catalog[item_id])
		var name := str(gdb.get_item(item_id).get("name", item_id))
		var row := HBoxContainer.new()
		shop_content.add_child(row)
		_label(row, "%s  %dG" % [name, price], 14)
		var buy := _button(row, localization.t("ui.shop.buy"), func(): _buy(shop_item_id), Vector2(80, 28))
		buy.disabled = gold < price
		if int(shop_actor.inventory.get(item_id, 0)) > 0:
			_button(row, localization.t("ui.shop.sell"), func(): _sell(shop_item_id), Vector2(80, 28))

func _buy(item_id: String) -> void:
	if shop_actor != null:
		if not shop_service.buy(shop_actor, item_id, ctx):
			set_feedback(localization.t("ui.shop.insufficient"))
		_refresh_shop()

func _sell(item_id: String) -> void:
	if shop_actor != null:
		shop_service.sell(shop_actor, item_id, 1, ctx)
		_refresh_shop()

func open_combat(inst: CombatInstance) -> void:
	if inst == null:
		return
	combat_instance = inst
	_combat_rewards_granted = false
	combat_panel.visible = true
	_refresh_combat()

func _refresh_combat() -> void:
	if combat_instance == null:
		return
	_clear_panel_content(combat_panel)
	_label(combat_content, localization.t("ui.combat.round") + " " + str(combat_instance.round), 20)
	var current := combat_instance.current_combatant()
	if current != null:
		_label(combat_content, localization.t("ui.combat.turn") + ": " + current.actor.identity.display_name)
		_label(combat_content, "%s %d/%d" % [localization.t("ui.combat.hp"), int(current.actor.get_hp()), int(current.actor.max_hp())])
	var actions := HBoxContainer.new()
	combat_content.add_child(actions)
	_button(actions, localization.t("ui.combat.attack"), _combat_attack, Vector2(90, 32))
	_button(actions, localization.t("ui.combat.skill"), func(): _combat_attack(true), Vector2(90, 32))
	_button(actions, localization.t("ui.combat.wait"), _combat_wait, Vector2(90, 32))
	combat_log_label = _label(combat_content, "", 14)
	combat_result_label = _label(combat_content, "", 16, Color(0.95, 0.9, 0.6))

func set_battle_log(text: String) -> void:
	if combat_log_label != null:
		combat_log_label.text = text

func set_battle_result(text: String) -> void:
	if combat_result_label != null:
		combat_result_label.text = text

func _combat_attack(use_skill: bool = false) -> void:
	if combat_instance == null or combat_instance.battle_state != "Active":
		return
	var current := combat_instance.current_combatant()
	if current == null or current.team != "player":
		return
	var target := _first_alive_combatant(combat_instance.enemy_team)
	if target == null:
		_finish_combat("Victory")
		return
	var distance: int = abs(current.position.x - target.position.x) + abs(current.position.y - target.position.y)
	if distance > 1:
		var step := current.position + Vector2i(signi(target.position.x - current.position.x), 0)
		if not combat_instance.move(current, step):
			step = current.position + Vector2i(0, signi(target.position.y - current.position.y))
			combat_instance.move(current, step)
		set_battle_log(current.actor.identity.display_name + " 向 " + target.actor.identity.display_name + " 逼近。")
	else:
		var result: Dictionary = combat_instance.attack(current, target)
		if not bool(result.get("blocked", false)):
			set_battle_log(current.actor.identity.display_name + " 攻击 " + target.actor.identity.display_name + "，造成 " + str(int(result.get("damage", 0))) + " 点伤害。")
	if combat_instance.check_battle_end() != "Active":
		_finish_combat(combat_instance.battle_state)
		return
	combat_instance.end_turn()
	_run_enemy_turns()
	_refresh_combat()

func _combat_wait() -> void:
	if combat_instance == null or combat_instance.battle_state != "Active":
		return
	var current := combat_instance.current_combatant()
	if current == null or current.team != "player":
		return
	set_battle_log(current.actor.identity.display_name + " 选择等待。")
	combat_instance.end_turn()
	_run_enemy_turns()
	_refresh_combat()

func _run_enemy_turns() -> void:
	while combat_instance != null and combat_instance.battle_state == "Active":
		var current := combat_instance.current_combatant()
		if current == null or current.team == "player":
			break
		var target := _first_alive_combatant(combat_instance.player_team)
		if target == null:
			_finish_combat("Defeat")
			return
		var distance: int = abs(current.position.x - target.position.x) + abs(current.position.y - target.position.y)
		if distance > 1:
			var step := current.position + Vector2i(signi(target.position.x - current.position.x), 0)
			if not combat_instance.move(current, step):
				step = current.position + Vector2i(0, signi(target.position.y - current.position.y))
				combat_instance.move(current, step)
			set_battle_log(current.actor.identity.display_name + " 正在逼近。")
		else:
			var result: Dictionary = combat_instance.attack(current, target)
			if not bool(result.get("blocked", false)):
				set_battle_log(current.actor.identity.display_name + " 攻击 " + target.actor.identity.display_name + "，造成 " + str(int(result.get("damage", 0))) + " 点伤害。")
		if combat_instance.check_battle_end() != "Active":
			_finish_combat(combat_instance.battle_state)
			return
		combat_instance.end_turn()

func _first_alive_combatant(combatants: Array) -> Combatant:
	for combatant in combatants:
		if combatant is Combatant and combatant.alive:
			return combatant
	return null

func _finish_combat(result: String) -> void:
	if combat_instance == null or _combat_rewards_granted:
		return
	combat_instance.battle_state = result
	_combat_rewards_granted = true
	var rewards := {}
	if result == "Victory":
		rewards = combat_instance.resolve_rewards()
		set_battle_result("胜利！获得 %d XP 与 %d Gold。" % [int(rewards.get("xp", 0)), int(rewards.get("gold", 0))])
	else:
		set_battle_result("战斗失败。")
	combat_finished.emit(result, rewards)
	_refresh_combat()

func open_tavern(actor: Actor) -> void:
	if actor == null:
		return
	tavern_actor = actor
	tavern_panel.visible = true
	_refresh_tavern()

func _refresh_tavern() -> void:
	if tavern_actor == null:
		return
	_clear_panel_content(tavern_panel)
	_label(tavern_content, localization.t("ui.tavern.title"), 20)
	var row := HBoxContainer.new()
	tavern_content.add_child(row)
	_button(row, localization.t("ui.tavern.talk"), func(): set_feedback(localization.t("ui.feedback.tavern_talk")), Vector2(110, 32))
	_button(row, localization.t("ui.tavern.rest"), func(): _rest_party(), Vector2(110, 32))
	_button(row, localization.t("ui.tavern.recruit"), _show_tavern_recruits, Vector2(110, 32))

func set_tavern_recruits(recruits: Array) -> void:
	tavern_recruits = recruits.duplicate()

func _show_tavern_recruits() -> void:
	_clear_panel_content(tavern_panel)
	_label(tavern_content, "酒馆招募", 20)
	if tavern_recruits.is_empty():
		_label(tavern_content, "今晚没有可招募的冒险者。")
		return
	for candidate in tavern_recruits:
		if not (candidate is Actor):
			continue
		var actor: Actor = candidate
		var row := HBoxContainer.new()
		tavern_content.add_child(row)
		_label(row, "%s  Lv%d  300 Gold" % [actor.identity.display_name, actor.progression.level], 14)
		_button(row, "招募", func(): tavern_recruit_requested.emit(actor.id), Vector2(82, 28))

func open_dungeon() -> void:
	dungeon_panel.visible = true
	_clear_panel_content(dungeon_panel)
	_label(dungeon_content, "临时副本：遗迹试炼", 21)
	_label(dungeon_content, "选择挑战等级。战斗以文字结算，可重复挑战。", 14, Color(0.7, 0.82, 0.95))
	for level in [1, 3, 5, 8, 12]:
		var level_ref: int = int(level)
		_button(dungeon_content, "挑战等级 %d" % level_ref, func(): dungeon_requested.emit(level_ref), Vector2(220, 34))

func show_dungeon_result(level: int, xp: int, gold: int, item_name: String) -> void:
	open_dungeon()
	_label(dungeon_content, "结算：等级 %d 试炼完成" % level, 18, Color(0.95, 0.88, 0.55))
	_label(dungeon_content, "获得 %d XP、%d Gold" % [xp, gold], 15)
	_label(dungeon_content, "掉落：" + item_name, 15)

func _rest_party() -> void:
	if party_service == null:
		return
	for actor in party_service.active:
		actor.set_hp(actor.max_hp())
	for actor in party_service.reserve:
		actor.set_hp(actor.max_hp())
	set_feedback(localization.t("ui.feedback.party_rested"))

func toggle_inventory(actor: Actor) -> void:
	if inventory_panel.visible:
		inventory_panel.visible = false
	else:
		open_inventory(actor)

func toggle_map(player_pos: Vector3) -> void:
	set_feedback("Map: Frontier Village / Forest / Goblin Camp / Cave  @ " + str(player_pos.round()))

func toggle_quest(journal: Array) -> void:
	if quest_panel.visible:
		quest_panel.visible = false
	else:
		open_quest()

func toggle_character(actor: Actor) -> void:
	if character_panel.visible:
		character_panel.visible = false
	else:
		open_character(actor)
