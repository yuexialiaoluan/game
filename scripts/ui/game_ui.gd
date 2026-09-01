class_name GameUI
extends CanvasLayer

signal dialogue_closed
signal combat_finished(result: String, rewards: Dictionary)
signal dialogue_action_requested(action: String, dialogue_id: String, choice_id: String)
signal tavern_recruit_requested(npc_id: String)
signal dungeon_requested(level: int)
signal party_member_dismissed(actor: Actor)
signal rest_requested(option: String)
signal guild_quest_accept_requested(quest_id: String)
signal pause_save_requested(slot_id: String)
signal pause_load_requested(slot_id: String)
signal pause_slots_refresh_requested
signal pause_return_to_menu_requested
signal pause_quit_requested

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
var inspect_context := CharacterInspectContext.new()
var _terminal_refresh_queued: bool = false
var _terminal_refreshing: bool = false
var preview_visual: CharacterVisual = null
var inventory_tooltip: PanelContainer
var inventory_tooltip_content: VBoxContainer
var skill_tree_service: SkillTreeService
var talent_service: TalentService
var enchantment_service: EnchantmentService
var crafting_service: EquipmentCraftingService
var crafting_generator: EquipmentGenerator
var crafting_rng: RNGService
var profession_service: ProfessionService
var feat_progress_service: FeatProgressService

var party_panel: PanelContainer
var party_content: VBoxContainer

var inventory_panel: PanelContainer
var inventory_content: VBoxContainer
var inventory_actor: Actor = null
var inventory_filter: String = "all"
var inventory_sort: String = "type"

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
var combat_enemy_hp: ProgressBar
var combat_enemy_hp_label: Label
var combat_enemy_target_id: String = ""
var combat_movement_label: Label
var tactical_grid_visual: CombatGrid3D
var selected_tactical_unit: Combatant = null
var _combat_rewards_granted: bool = false
var settings_service: SettingsService

var settings_panel: PanelContainer
var settings_content: VBoxContainer
var combat_mode_label: Label
var _keybind_capture_action: String = ""

var pause_panel: PanelContainer
var pause_content: VBoxContainer
var pause_slot_panel: PanelContainer
var pause_slot_content: VBoxContainer
var _pause_save_slots: Array = []
var _pause_slot_picker_for_save: bool = true
var _paused_tree_before: bool = false
var _paused_time_before: bool = false

var dungeon_panel: PanelContainer
var dungeon_content: VBoxContainer
var blacksmith_panel: PanelContainer
var blacksmith_content: VBoxContainer
var mage_panel: PanelContainer
var mage_content: VBoxContainer
const EQUIPMENT_SLOTS := ["helmet", "chest", "legs", "boots", "necklace", "gloves", "ring_1", "ring_2", "ring_3", "ring_4", "mainhand", "offhand"]

func setup(p_gdb: GameplayDB, p_content: ContentDB, p_cdb: CharacterVisualDB, p_ctx: EvaluatorContext, p_bus: EventBus) -> void:
	gdb = p_gdb
	content = p_content
	cdb = p_cdb
	ctx = p_ctx
	inspect_context.clear()
	gs = p_ctx.game_state
	settings_service = p_ctx.settings_service if p_ctx.settings_service != null else SettingsService.new()
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
	skill_tree_service = SkillTreeService.new()
	skill_tree_service.setup(gdb)
	profession_service = ProfessionService.new()
	profession_service.setup(gdb)
	feat_progress_service = FeatProgressService.new()
	feat_progress_service.setup(gdb)
	talent_service = TalentService.new()
	talent_service.setup(gdb)
	enchantment_service = EnchantmentService.new()
	enchantment_service.setup(gdb.enchantments)
	crafting_rng = RNGService.new()
	crafting_generator = EquipmentGenerator.new()
	crafting_generator.setup(crafting_rng)
	crafting_service = EquipmentCraftingService.new()
	crafting_service.setup(gdb, crafting_generator, crafting_rng, p_bus)
	InputService.apply_keybinds(settings_service.get_keybinds())
	if p_bus != null:
		p_bus.subscribe("attack_resolved", _on_combat_attack_resolved)
		p_bus.subscribe("enemy_xp_awarded", _on_enemy_xp_awarded)
	_build()

func _on_combat_attack_resolved(payload) -> void:
	if combat_instance == null or not payload is Dictionary:
		return
	var target := _combatant_by_id(str(payload.get("target", "")))
	if target != null and target.team == "enemy":
		combat_enemy_target_id = target.actor.id
		_refresh_combat_enemy_health()

func _on_enemy_xp_awarded(payload) -> void:
	if not payload is Dictionary:
		return
	var xp := int(payload.get("xp", 0))
	if xp > 0:
		set_feedback("击败敌人，获得 %d XP。" % xp)

func handle_realtime_skill_slot(slot_index: int) -> bool:
	if combat_instance == null or not combat_instance is RealTimeCombatController or not combat_instance.is_active():
		return false
	if ctx == null or ctx.player == null or slot_index < 0 or slot_index >= ctx.player.skill_bar.size():
		return false
	var skill_id := str(ctx.player.skill_bar[slot_index])
	if skill_id == "":
		set_feedback("技能栏 %d 为空。" % (slot_index + 1))
		return true
	var realtime := combat_instance as RealTimeCombatController
	var definition := gdb.get_skill(skill_id)
	var target := _first_alive_combatant(realtime.enemy_team)
	if str(definition.get("target_type", "enemy")) == "ally":
		target = _most_injured_player_combatant(realtime)
	if target == null:
		set_battle_log("没有可用目标。")
		return true
	var result := realtime.use_realtime_skill_for(ctx.player.id, skill_id, target)
	if bool(result.get("blocked", false)):
		set_battle_log("无法施放 %s：%s" % [str(definition.get("name", skill_id)), str(result.get("reason", "unknown"))])
		return true
	set_battle_log("施放 %s，%s %d。" % [str(definition.get("name", skill_id)), "治疗" if int(result.get("healed", 0)) > 0 else "造成伤害", int(result.get("healed", result.get("damage", 0)))])
	if combat_instance.battle_state != "Active":
		_finish_combat(combat_instance.battle_state)
	else:
		_refresh_combat()
	return true

func _most_injured_player_combatant(realtime: RealTimeCombatController) -> Combatant:
	var selected: Combatant = null
	var lowest_ratio := INF
	for combatant in realtime.player_team:
		if not combatant is Combatant or not combatant.alive or combatant.actor == null:
			continue
		var ratio: float = combatant.actor.get_hp() / maxf(1.0, combatant.actor.max_hp())
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			selected = combatant
	return selected

func _refresh_combat_enemy_health() -> void:
	if combat_instance == null or combat_enemy_hp == null or combat_enemy_hp_label == null:
		return
	var enemy := _combatant_by_id(combat_enemy_target_id)
	if enemy == null or enemy.team != "enemy":
		return
	combat_enemy_hp.max_value = maxf(1.0, enemy.actor.max_hp())
	combat_enemy_hp.value = clampf(enemy.actor.get_hp(), 0.0, combat_enemy_hp.max_value)
	combat_enemy_hp_label.text = "%d / %d" % [int(enemy.actor.get_hp()), int(enemy.actor.max_hp())]

func set_services(p_quest_service: QuestService, p_party_service: PartyService, p_shop_service: ShopService) -> void:
	if p_quest_service != null:
		quest_service = p_quest_service
	if p_party_service != null:
		party_service = p_party_service
	if p_shop_service != null:
		shop_service = p_shop_service

func _build() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_build_pause()
	_build_dungeon()
	_build_blacksmith()
	_build_mage()
	_build_inventory_tooltip()

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
	var shortcuts := UITheme.label("[B] 背包   [T] 队伍   [J] 任务   [M] 地图   [F] 互动   [Esc] 关闭/设置", 13, Color(0.72, 0.85, 1.0))
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
	character_panel = _make_modal(Vector2(1200, 680), Vector2(40, 30))
	character_panel.name = "CharacterPanel"
	character_content = character_panel.get_node("Margin/Content")
	var close = character_content.get_meta("close_button")
	if close != null:
		close.text = "B 关闭"

func _build_inventory_tooltip() -> void:
	inventory_tooltip = UITheme.panel()
	inventory_tooltip.name = "InventoryTooltip"
	inventory_tooltip.visible = false
	inventory_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_tooltip.z_index = 100
	inventory_tooltip.custom_minimum_size = Vector2(250, 0)
	root.add_child(inventory_tooltip)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	inventory_tooltip.add_child(margin)
	inventory_tooltip_content = VBoxContainer.new()
	inventory_tooltip_content.add_theme_constant_override("separation", 3)
	margin.add_child(inventory_tooltip_content)

func _build_party() -> void:
	party_panel = _make_modal(Vector2(700, 520), Vector2(290, 100))
	party_panel.name = "PartyPanel"
	party_content = party_panel.get_node("Margin/Content")

func _build_inventory() -> void:
	# Inventory is a compatibility alias for the unified Character Terminal.
	inventory_panel = character_panel
	inventory_panel.name = "InventoryPanel"
	inventory_content = character_content

func _build_equipment() -> void:
	# Equipment is a compatibility alias for the unified Character Terminal.
	equipment_panel = character_panel
	equipment_panel.name = "EquipmentPanel"
	equipment_content = character_content

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
	combat_panel = _make_modal(Vector2(760, 180), Vector2(260, 18))
	combat_panel.name = "CombatPanel"
	combat_content = combat_panel.get_node("Margin/Content")
	var close = combat_content.get_meta("close_button")
	if close != null:
		close.visible = false
	combat_log_label = _label(combat_content, "", 14)
	combat_result_label = _label(combat_content, "", 16, Color(0.95, 0.9, 0.6))

func _build_settings() -> void:
	settings_panel = _make_modal(Vector2(560, 620), Vector2(360, 55))
	settings_panel.name = "SettingsPanel"
	settings_content = settings_panel.get_node("Margin/Content")
	_refresh_settings()

func _refresh_settings() -> void:
	if settings_content == null:
		return
	var close = settings_content.get_meta("close_button")
	for child in settings_content.get_children():
		if child != close:
			child.queue_free()
	_label(settings_content, "设置 / 快捷键", 22)
	combat_mode_label = _label(settings_content, "战斗方式：即时战斗（默认）", 14, Color(0.72, 0.85, 1.0))
	_label(settings_content, "点击“更改”后按下新的按键。", 12, Color(0.62, 0.74, 0.76))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_content.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(490, 0)
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	for action in InputService.get_rebindable_actions():
		var current_action: String = action
		var row := HBoxContainer.new()
		list.add_child(row)
		var label := _label(row, InputService.action_label(current_action), 13)
		label.custom_minimum_size = Vector2(220, 0)
		var key_label := _label(row, InputService.action_event_label(current_action), 13, Color(0.45, 0.76, 0.78))
		key_label.custom_minimum_size = Vector2(120, 0)
		_button(row, "更改", func(): _begin_keybind_capture(current_action), Vector2(80, 24))
	_button(settings_content, "继续", func(): settings_panel.visible = false, Vector2(150, 34))

func _begin_keybind_capture(action: String) -> void:
	_keybind_capture_action = action
	set_feedback("请按下“%s”的新按键，Esc 取消。" % InputService.action_label(action))

func _build_pause() -> void:
	pause_panel = _make_modal(Vector2(420, 360), Vector2(430, 160))
	pause_panel.name = "PausePanel"
	pause_content = pause_panel.get_node("Margin/Content")
	var close = pause_content.get_meta("close_button")
	if close != null:
		close.text = "继续"
		close.pressed.connect(close_pause_menu)
	_label(pause_content, "游戏暂停", 22)
	_label(pause_content, "保存会记录当前队伍、位置与世界进度。", 13, Color(0.72, 0.85, 1.0))
	_button(pause_content, "保存游戏", func(): _show_pause_slot_picker(true), Vector2(220, 34))
	_button(pause_content, "读取存档", func(): _show_pause_slot_picker(false), Vector2(220, 34))
	_button(pause_content, "返回主菜单", func(): pause_return_to_menu_requested.emit(), Vector2(220, 34))
	_button(pause_content, "退出游戏", func(): pause_quit_requested.emit(), Vector2(220, 34))
	pause_slot_panel = _make_modal(Vector2(460, 390), Vector2(410, 145))
	pause_slot_panel.name = "PauseSlotPanel"
	pause_slot_content = pause_slot_panel.get_node("Margin/Content")
	var slot_close = pause_slot_content.get_meta("close_button")
	if slot_close != null:
		slot_close.text = "返回暂停菜单"
		slot_close.pressed.connect(_show_pause_root)

func set_pause_save_slots(slots: Array) -> void:
	_pause_save_slots = slots.duplicate(true)
	if pause_slot_panel != null and pause_slot_panel.visible:
		call_deferred("_refresh_pause_slot_picker")

func _show_pause_slot_picker(for_save: bool) -> void:
	if pause_panel == null or pause_slot_panel == null:
		return
	_pause_slot_picker_for_save = for_save
	pause_panel.visible = false
	pause_slot_panel.visible = true
	_clear_pause_slot_content()
	_label(pause_slot_content, "选择存档位置" if for_save else "选择要读取的存档", 22)
	_label(pause_slot_content, "手动存档可覆盖；自动与地点存档仅用于读取。", 12, Color(0.72, 0.85, 1.0))
	var eligible_slots: Array = []
	for raw_slot in _pause_save_slots:
		if not raw_slot is Dictionary:
			continue
		var slot: Dictionary = raw_slot
		if for_save and not bool(slot.get("can_save", true)):
			continue
		if not for_save and not bool(slot.get("exists", false)):
			continue
		eligible_slots.append(slot)
	if eligible_slots.is_empty():
		_label(pause_slot_content, "没有可读取的存档。" if not for_save else "没有可用的存档槽位。", 14)
		return
	for slot in eligible_slots:
		var slot_id := str(slot.get("id", ""))
		var title := str(slot.get("title", slot_id))
		var detail := str(slot.get("detail", "空"))
		_button(pause_slot_content, title + "  |  " + detail, func(): _request_pause_slot(slot_id, for_save), Vector2(300, 38))

func _refresh_pause_slot_picker() -> void:
	if pause_slot_panel != null and pause_slot_panel.visible:
		_show_pause_slot_picker(_pause_slot_picker_for_save)

func _request_pause_slot(slot_id: String, for_save: bool) -> void:
	if slot_id == "":
		return
	if for_save:
		pause_save_requested.emit(slot_id)
	else:
		pause_load_requested.emit(slot_id)

func _show_pause_root() -> void:
	if pause_slot_panel != null:
		pause_slot_panel.visible = false
	if pause_panel != null:
		pause_panel.visible = true

func _clear_pause_slot_content() -> void:
	if pause_slot_content == null:
		return
	var close = pause_slot_content.get_meta("close_button")
	for child in pause_slot_content.get_children():
		if child != close:
			child.free()

func _toggle_combat_mode() -> void:
	set_feedback("战斗方式由世界状态决定：平时即时，按 R 进入战棋。")

func _refresh_combat_mode_label() -> void:
	if combat_mode_label != null and settings_service != null:
		combat_mode_label.text = "战斗模式：" + CombatMode.display_name(settings_service.get_combat_mode())

func _process(delta: float) -> void:
	if combat_instance is TacticalCombatController and combat_instance.is_active():
		_handle_tactical_keyboard()
		if Input.is_action_just_pressed("combat_end_turn"):
			_end_tactical_turn()
	if combat_instance is RealTimeCombatController and combat_instance.is_active():
		(combat_instance as RealTimeCombatController).advance_realtime(delta)
		if combat_instance.battle_state != "Active":
			_finish_combat(combat_instance.battle_state)

func _unhandled_input(event: InputEvent) -> void:
	if not combat_instance is TacticalCombatController or not combat_instance.is_active():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tactical_click(event.position)
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _keybind_capture_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				_keybind_capture_action = ""
				set_feedback("已取消快捷键修改。")
			elif InputService.rebind_key(_keybind_capture_action, event.physical_keycode):
				settings_service.set_keybinds(InputService.export_keybinds())
				set_feedback("快捷键已更新。")
				_keybind_capture_action = ""
				call_deferred("_refresh_settings")
			get_viewport().set_input_as_handled()
		return
	if pause_slot_panel != null and pause_slot_panel.visible and event.is_action_pressed("interaction_cancel"):
		_show_pause_root()
		get_viewport().set_input_as_handled()
	elif pause_panel != null and pause_panel.visible and event.is_action_pressed("interaction_cancel"):
		close_pause_menu()
		get_viewport().set_input_as_handled()

func _build_dungeon() -> void:
	dungeon_panel = _make_modal(Vector2(540, 410), Vector2(370, 155))
	dungeon_panel.name = "DungeonPanel"
	dungeon_content = dungeon_panel.get_node("Margin/Content")

func _build_blacksmith() -> void:
	blacksmith_panel = _make_modal(Vector2(700, 500), Vector2(290, 110))
	blacksmith_panel.name = "BlacksmithPanel"
	blacksmith_content = blacksmith_panel.get_node("Margin/Content")

func _build_mage() -> void:
	mage_panel = _make_modal(Vector2(700, 500), Vector2(290, 110))
	mage_panel.name = "MagePanel"
	mage_content = mage_panel.get_node("Margin/Content")

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
	var modal_content := VBoxContainer.new()
	modal_content.name = "Content"
	modal_content.add_theme_constant_override("separation", 8)
	margin.add_child(modal_content)
	var close := UITheme.styled_button(localization.t("ui.panel.close"), Vector2(90, 30))
	close.pressed.connect(func(): p.visible = false)
	modal_content.add_child(close)
	modal_content.set_meta("close_button", close)
	return p

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.free()

func _clear_panel_content(panel: PanelContainer) -> void:
	var panel_content: Node = panel.get_node("Margin/Content")
	var close = panel_content.get_meta("close_button")
	for child in panel_content.get_children():
		if child != close:
			if panel == character_panel:
				child.queue_free()
			else:
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
		dialogue_continue.text = localization.t("ui.dialogue.continue") + "  [F]"
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
	for selection_offset in range(1, count + 1):
		var candidate := posmod(_dialogue_choice_index + direction * selection_offset, count)
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

func close_after_recruitment() -> void:
	_close_dialogue()
	tavern_panel.visible = false
	party_panel.visible = false

func _close_dialogue() -> void:
	dialogue_panel.visible = false
	_dialogue_timer.stop()
	dialogue_closed.emit()

func has_open_modal() -> bool:
	for panel in _modal_panels():
		if panel.visible:
			if panel == combat_panel and combat_instance is RealTimeCombatController and combat_instance.is_active():
				continue
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
	if pause_slot_panel != null and pause_slot_panel.visible:
		_show_pause_root()
		return true
	if pause_panel != null and pause_panel.visible:
		close_pause_menu()
		return true
	if combat_panel.visible and combat_instance != null and combat_instance.battle_state == "Active":
		set_feedback("战斗仍在进行，请使用战斗面板完成回合。")
		return true
	if close_top_modal():
		return true
	open_pause_menu()
	return true

func open_settings() -> void:
	settings_panel.visible = true

func open_pause_menu() -> void:
	if pause_panel == null or pause_panel.visible:
		return
	pause_slots_refresh_requested.emit()
	var tree := get_tree()
	_paused_tree_before = tree.paused
	_paused_time_before = ctx != null and ctx.time_service != null and ctx.time_service.is_paused()
	if ctx != null and ctx.time_service != null:
		ctx.time_service.set_paused(true)
	pause_panel.visible = true
	if pause_slot_panel != null:
		pause_slot_panel.visible = false
	tree.paused = true

func close_pause_menu() -> void:
	if pause_panel == null:
		return
	pause_panel.visible = false
	if pause_slot_panel != null:
		pause_slot_panel.visible = false
	if ctx != null and ctx.time_service != null:
		ctx.time_service.set_paused(_paused_time_before)
	get_tree().paused = _paused_tree_before

func _modal_panels() -> Array:
	var panels: Array = []
	for panel in [dialogue_panel, character_panel, party_panel, inventory_panel, equipment_panel, quest_panel, shop_panel, tavern_panel, profile_panel, combat_panel, settings_panel, pause_panel, pause_slot_panel, dungeon_panel, blacksmith_panel, mage_panel]:
		if panel != null and not panels.has(panel):
			panels.append(panel)
	return panels

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
	_open_terminal(actor, "attributes")

func open_skills_terminal(actor: Actor) -> void:
	if actor != null:
		_open_terminal(actor, "skills")

func open_profession_trainer(actor: Actor) -> void:
	if actor == null or not is_instance_valid(actor) or profile_panel == null or profession_service == null:
		return
	profile_panel.visible = true
	_clear_panel_content(profile_panel)
	_label(profile_content, "乔安娜的转职训练", 22)
	_label(profile_content, "选择要接受训练的队伍成员。转职会保留等级、属性和背包。", 12, Color(0.62, 0.74, 0.76))
	var members := _profession_training_members(actor)
	var member_row := HBoxContainer.new()
	member_row.add_theme_constant_override("separation", 6)
	profile_content.add_child(member_row)
	for member in members:
		var member_ref: Actor = member
		var member_button := _button(member_row, "%s\nLv.%d" % [member_ref.identity.display_name, member_ref.progression.level], func(): open_profession_trainer(member_ref), Vector2(96, 42))
		member_button.button_pressed = member_ref == actor
		if member_ref == actor:
			member_button.modulate = Color(0.65, 0.95, 0.95)
	_add_terminal_line(profile_content)
	_label(profile_content, "%s 当前职业：%s" % [actor.identity.display_name, _class_name(actor)], 13, Color(0.62, 0.74, 0.76))
	for class_id in ["warrior", "ranger", "knight", "priest", "mage", "bard"]:
		var current_class: String = class_id
		var definition := gdb.get_class_def(current_class)
		_button(profile_content, str(definition.get("name", current_class)), func(): _change_profession_from_trainer(actor, current_class), Vector2(230, 30))

func _profession_training_members(fallback: Actor) -> Array:
	var members: Array = []
	for member in _terminal_members():
		if member != null and not members.has(member):
			members.append(member)
	if party_service != null:
		for member in party_service.reserve:
			if member != null and not members.has(member):
				members.append(member)
	if fallback != null and not members.has(fallback):
		members.append(fallback)
	return members

func _change_profession_from_trainer(actor: Actor, class_id: String) -> void:
	if actor == null or not is_instance_valid(actor) or profession_service == null:
		return
	var result := profession_service.change_profession(actor, class_id)
	if bool(result.get("success", false)):
		set_feedback("已转职为 " + str(gdb.get_class_def(class_id).get("name", class_id)) + "。")
		call_deferred("open_profession_trainer", actor)
	else:
		set_feedback(str(result.get("reason", "转职失败")))

func _refresh_character() -> void:
	_queue_terminal_refresh()

func _open_terminal(actor: Actor, tab: String) -> void:
	if actor == null or not is_instance_valid(actor) or character_panel == null:
		return
	var was_visible := character_panel.visible
	inspect_context.select_actor(actor)
	inspect_context.selected_tab = tab
	character_actor = actor
	inventory_actor = actor
	equipment_actor = actor
	character_panel.visible = true
	if was_visible:
		if not _terminal_refreshing:
			_refresh_terminal()
		else:
			_queue_terminal_refresh()
	else:
		_refresh_terminal()

func _terminal_members() -> Array:
	if party_service != null and not party_service.active.is_empty():
		return party_service.active
	return [ctx.player] if ctx != null and ctx.player != null else []

func _refresh_terminal() -> void:
	if _terminal_refreshing or character_actor == null or not is_instance_valid(character_actor) or character_panel == null:
		return
	_terminal_refreshing = true
	_hide_inventory_tooltip()
	_clear_panel_content(character_panel)
	var title_row := HBoxContainer.new()
	character_content.add_child(title_row)
	var title := _label(title_row, "CHARACTER TERMINAL", 22, theme.text_color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(title_row, "%s  /  %s" % [character_actor.identity.display_name, _class_name(character_actor)], 14, Color(0.58, 0.72, 0.76))
	var terminal_body := HBoxContainer.new()
	terminal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	terminal_body.add_theme_constant_override("separation", 16)
	character_content.add_child(terminal_body)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(255, 0)
	sidebar.add_theme_constant_override("separation", 6)
	terminal_body.add_child(sidebar)
	_add_character_tabs(sidebar)
	_add_terminal_line(sidebar)
	_build_identity_column(sidebar)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	terminal_body.add_child(page)
	_add_terminal_tabs(page)
	_add_terminal_line(page)
	var page_scroll := ScrollContainer.new()
	page_scroll.name = "TerminalPageScroll"
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(page_scroll)
	var page_content := VBoxContainer.new()
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_content.add_theme_constant_override("separation", 8)
	page_scroll.add_child(page_content)
	_build_terminal_page(page_content)
	_terminal_refreshing = false

func _queue_terminal_refresh() -> void:
	if character_actor == null or not is_instance_valid(character_actor) or _terminal_refresh_queued:
		return
	_terminal_refresh_queued = true
	call_deferred("_flush_terminal_refresh")

func _flush_terminal_refresh() -> void:
	_terminal_refresh_queued = false
	if character_actor == null or not is_instance_valid(character_actor) or not character_panel.visible:
		return
	_refresh_terminal()

func _add_terminal_line(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = Color(0.45, 0.62, 0.66, 0.45)
	line.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line)

func _add_character_tabs(parent: Node) -> void:
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	parent.add_child(tabs)
	for member in _terminal_members():
		if member == null:
			continue
		var actor_ref: Actor = member
		var tab := _button(tabs, "   %s\n   Lv.%d  %s" % [actor_ref.identity.display_name, actor_ref.progression.level, _class_name(actor_ref)], func(): _open_terminal(actor_ref, inspect_context.selected_tab), Vector2(235, 42))
		var portrait_id := "portrait.eleonore" if actor_ref.identity.gender == "female" else "portrait.default"
		var mini_portrait := TextureRect.new()
		mini_portrait.texture = UIAssetRegistry.new().get_texture(portrait_id)
		mini_portrait.position = Vector2(6, 11)
		mini_portrait.size = Vector2(18, 18)
		mini_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mini_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mini_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mini_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(mini_portrait)
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.add_theme_font_size_override("font_size", 11)
		tab.button_pressed = actor_ref == character_actor
		if actor_ref == character_actor:
			tab.modulate = Color(0.65, 0.95, 0.95)

func _build_identity_column(parent: Node) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "AttributeScroll"
	scroll.custom_minimum_size = Vector2(245, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(245, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	scroll.add_child(column)
	var identity_row := HBoxContainer.new()
	column.add_child(identity_row)
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(46, 46)
	portrait.set_actor_portrait(character_actor)
	identity_row.add_child(portrait)
	var identity := VBoxContainer.new()
	identity_row.add_child(identity)
	_label(identity, character_actor.identity.display_name, 19)
	_label(identity, "Lv.%d  %s" % [character_actor.progression.level, _class_name(character_actor)], 13, Color(0.62, 0.78, 0.82))
	_label(identity, "HP %d / %d   MP %d / %d" % [int(character_actor.get_hp()), int(character_actor.max_hp()), int(character_actor.current_mp), int(character_actor.get_stat("max_mp"))], 12)
	var xp := ProgressBar.new()
	xp.custom_minimum_size = Vector2(220, 8)
	xp.max_value = maxf(float(character_actor.progression.get_xp_to_next()), 1.0)
	xp.value = character_actor.progression.xp
	xp.show_percentage = false
	column.add_child(xp)
	_label(column, "EXP  %d / %d" % [character_actor.progression.xp, character_actor.progression.get_xp_to_next()], 11, Color(0.55, 0.68, 0.71))
	_add_terminal_line(column)
	_label(column, "BASIC ATTRIBUTES", 12, Color(0.45, 0.76, 0.78))
	for stat in Attributes.BASE_STATS:
		var stat_name: String = stat
		var row := HBoxContainer.new()
		column.add_child(row)
		var stat_button := _button(row, _stat_label(stat), func(): _terminal_select_stat(stat_name), Vector2(132, 22))
		stat_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_label(row, "%d  →  %d" % [int(character_actor.get_base_stat(stat)), int(character_actor.get_stat(stat))], 13)
		var add_button := _button(row, "+", func(): _allocate(stat_name), Vector2(24, 22))
		add_button.tooltip_text = "分配 1 点到" + _stat_label(stat_name)
		add_button.disabled = character_actor.progression.attribute_points <= 0
	_label(column, "属性点  %d" % character_actor.progression.attribute_points, 11, Color(0.55, 0.68, 0.71))
	_add_terminal_line(column)
	_label(column, "COMBAT", 12, Color(0.45, 0.76, 0.78))
	for stat in ["attack", "magic_attack", "defense", "max_hp", "accuracy", "critical", "evasion", "movement", "initiative"]:
		var row := HBoxContainer.new()
		column.add_child(row)
		var name_label := _label(row, _stat_label(stat), 12, Color(0.65, 0.72, 0.74))
		name_label.custom_minimum_size = Vector2(132, 0)
		_label(row, _format_stat_value(stat, character_actor.get_stat(stat)), 13)

func _build_preview_column(parent: Node) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(430, 0)
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	_label(column, "CHARACTER / EQUIPMENT", 12, Color(0.45, 0.76, 0.78))
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 6)
	column.add_child(equipment_row)
	var left_slots := VBoxContainer.new()
	left_slots.custom_minimum_size = Vector2(82, 0)
	left_slots.add_theme_constant_override("separation", 3)
	equipment_row.add_child(left_slots)
	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(250, 260)
	viewport_container.stretch = true
	equipment_row.add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(250, 260)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	preview_visual = CharacterVisual.new()
	var source := character_actor.visual
	var body_id := str(character_actor.appearance.get("body_id", "human_male"))
	var hair_id := str(character_actor.appearance.get("hair_id", "hair_short_01"))
	var clothing_id := str(character_actor.appearance.get("clothing_id", "clothing_peasant_01"))
	var face_id := str(character_actor.appearance.get("face_id", body_id))
	var eyes_id := str(character_actor.appearance.get("eyes_id", "eyes_default_01"))
	var source_id := str(source.world_sprite_id) if source != null else ""
	preview_visual.setup(cdb, body_id, hair_id, clothing_id, face_id, eyes_id, source_id)
	for slot in character_actor.equipment:
		var item_id := str(character_actor.equipment[slot])
		var definition := _equipment_definition_for_actor(character_actor, item_id)
		var visual_id := str(definition.get("visual", {}).get("asset_id", item_id)) if definition.get("visual", {}) is Dictionary else item_id
		preview_visual.set_equipment(str(slot), visual_id)
	viewport.add_child(preview_visual)
	preview_visual.position = Vector2(125, 235)
	preview_visual.scale = Vector2(2.2, 2.2)
	var right_slots := VBoxContainer.new()
	right_slots.custom_minimum_size = Vector2(82, 0)
	right_slots.add_theme_constant_override("separation", 3)
	equipment_row.add_child(right_slots)
	var left_visual_slots := ["helmet", "mainhand", "gloves", "legs", "ring_1", "ring_3"]
	var right_visual_slots := ["chest", "offhand", "boots", "necklace", "ring_2", "ring_4"]
	for slot in left_visual_slots:
		_add_equipment_slot(left_slots, slot)
	for slot in right_visual_slots:
		_add_equipment_slot(right_slots, slot)

func _add_equipment_slot(parent: Node, slot: String) -> void:
	var drop := EquipmentDropSlot.new()
	drop.slot = slot
	drop.item_id = str(character_actor.equipment.get(slot, ""))
	drop.db = gdb
	var slot_actor: Actor = character_actor
	drop.definition_provider = func(item_id: String): return _equipment_definition_for_actor(slot_actor, item_id)
	var definition := _equipment_definition_for_actor(slot_actor, drop.item_id)
	var quality := str(definition.get("quality", "common"))
	drop.text = _slot_label(slot) + ("\n" + str(definition.get("name", drop.item_id)) if drop.item_id != "" else "")
	drop.custom_minimum_size = Vector2(82, 34)
	drop.add_theme_font_size_override("font_size", 10)
	drop.add_theme_color_override("font_color", Color(_quality_color(quality)) if drop.item_id != "" else Color(0.45, 0.52, 0.54))
	drop.equipment_dropped.connect(func(new_item_id: String, target_slot: String): _equip_item_to_slot(new_item_id, target_slot))
	drop.pressed.connect(func(): _unequip_terminal_slot(slot))
	parent.add_child(drop)

func _build_inventory_column(parent: Node) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size = Vector2(390, 0)
	column.add_theme_constant_override("separation", 5)
	parent.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var inventory_title := _label(heading, "INVENTORY", 12, Color(0.45, 0.76, 0.78))
	inventory_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(heading, "共享背包", 11, Color(0.55, 0.68, 0.71))
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 2)
	column.add_child(filter_row)
	for filter_id in ["all", "weapon", "armor", "accessory", "consumable", "material", "misc"]:
		var current_filter: String = filter_id
		var button := _button(filter_row, _inventory_filter_label(current_filter), func(): _set_inventory_filter(current_filter), Vector2(52, 23))
		button.button_pressed = inventory_filter == current_filter
	var sort_row := HBoxContainer.new()
	column.add_child(sort_row)
	_label(sort_row, "排序", 11, Color(0.55, 0.68, 0.71))
	for sort_id in ["type", "quality", "level", "name", "value"]:
		var current_sort: String = sort_id
		var button := _button(sort_row, _inventory_sort_label(current_sort), func(): _set_inventory_sort(current_sort), Vector2(48, 22))
		button.button_pressed = inventory_sort == current_sort
	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(380, 255)
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	var storage_owner := _inventory_storage_owner()
	var items := _terminal_inventory_items(storage_owner)
	if items.is_empty():
		_label(grid, "背包为空", 13, Color(0.55, 0.68, 0.71))
	for item in items:
		_add_inventory_item(grid, item, storage_owner)

func _terminal_inventory_items(storage_owner: Actor) -> Array:
	var items: Array = []
	if storage_owner == null:
		return items
	for item_id in storage_owner.inventory:
		var id := str(item_id)
		var definition := gdb.get_item(id)
		var item_type := str(definition.get("type", "misc"))
		if not _inventory_type_matches(item_type, inventory_filter):
			continue
		items.append({"id": id, "name": str(definition.get("name", id)), "qty": int(storage_owner.inventory[item_id]), "type": item_type, "definition": definition})
	for instance_id in storage_owner.equipment_inventory:
		var id := str(instance_id)
		var definition := _equipment_definition_for_actor(storage_owner, id)
		if definition.is_empty():
			continue
		var item_type := "weapon" if str(definition.get("slot", "")) in ["weapon", "mainhand", "shield", "offhand"] else ("accessory" if str(definition.get("slot", "")) in ["necklace", "ring"] else "armor")
		if _inventory_type_matches(item_type, inventory_filter):
			items.append({"id": id, "name": str(definition.get("name", id)), "qty": 1, "type": item_type, "definition": definition})
	items.sort_custom(func(a: Dictionary, b: Dictionary): return _inventory_item_less(a, b))
	return items

func _add_inventory_item(parent: Node, item: Dictionary, storage_owner: Actor) -> void:
	var item_id := str(item.get("id", ""))
	var card := InventoryDragItem.new()
	card.item_id = item_id
	card.set_meta("display_name", str(item.get("name", item_id)))
	card.custom_minimum_size = Vector2(122, 94)
	var card_style := theme.make_style()
	card_style.bg_color = Color(0.08, 0.11, 0.12, 0.55)
	card_style.border_color = Color(0.35, 0.46, 0.49, 0.55)
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)
	card.item_selected.connect(_terminal_select_item)
	card.item_drop_requested.connect(_unequip_dragged_item)
	card.mouse_entered.connect(func(): _show_inventory_tooltip(item_id, storage_owner, card))
	card.mouse_exited.connect(_hide_inventory_tooltip)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var icon_row := HBoxContainer.new()
	box.add_child(icon_row)
	icon_row.add_child(_item_icon(item_id, storage_owner))
	_label(icon_row, "x%d" % int(item.get("qty", 1)), 11, Color(0.66, 0.76, 0.76))
	var name_label := _label(box, str(item.get("name", item_id)), 11)
	name_label.clip_text = true
	var definition: Dictionary = item.get("definition", {}) as Dictionary
	if not definition.is_empty():
		var quality := str(definition.get("quality", "common"))
		_label(box, "%s  Lv.%d" % [_quality_label(quality), int(definition.get("level", 1))], 10, Color(_quality_color(quality)))
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var item_def := gdb.get_item(item_id)
	if not (item_def.get("effects", []) as Array).is_empty():
		_button(actions, "使用", func(): _use_item(item_id), Vector2(50, 21))
	if not definition.is_empty():
		_button(actions, "装备", func(): _equip_item(item_id), Vector2(50, 21))
	_button(actions, "详情", func(): _terminal_select_item(item_id), Vector2(50, 21))

func _build_terminal_detail(parent: Node) -> void:
	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(0, 125)
	detail.add_theme_constant_override("separation", 3)
	parent.add_child(detail)
	match inspect_context.selected_tab:
		"attributes": _build_attribute_detail(detail)
		"equipment": _build_equipment_detail(detail)
		"skills": _build_skill_detail(detail)
		"talents": _build_talent_detail(detail)
		"feats": _build_feat_detail(detail)
		_: _build_attribute_detail(detail)

func _build_terminal_page(parent: Node) -> void:
	match inspect_context.selected_tab:
		"attributes": _build_attributes_page(parent)
		"equipment": _build_equipment_page(parent)
		"inventory": _build_inventory_column(parent)
		"skills", "talents", "feats": _build_terminal_detail(parent)
		_: _build_attributes_page(parent)

func _build_attributes_page(parent: Node) -> void:
	_label(parent, "ATTRIBUTES", 14, Color(0.45, 0.76, 0.78))
	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 24)
	table.add_theme_constant_override("v_separation", 4)
	parent.add_child(table)
	for stat in Attributes.BASE_STATS + ["attack", "magic_attack", "defense", "max_hp", "accuracy", "critical", "evasion", "movement", "initiative"]:
		var stat_id: String = stat
		var stat_button := _button(table, _stat_label(stat_id), func(): _terminal_select_stat(stat_id), Vector2(130, 24))
		stat_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_label(table, _format_stat_value(stat_id, character_actor.get_base_stat(stat_id)) if Attributes.BASE_STATS.has(stat_id) else "-", 12, Color(0.55, 0.68, 0.71))
		var value_row := HBoxContainer.new()
		table.add_child(value_row)
		_label(value_row, _format_stat_value(stat_id, character_actor.get_stat(stat_id)), 13)
		if Attributes.BASE_STATS.has(stat_id):
			var add_button := _button(value_row, "+", func(): _allocate(stat_id), Vector2(24, 22))
			add_button.tooltip_text = "分配 1 点到" + _stat_label(stat_id)
			add_button.disabled = character_actor.progression.attribute_points <= 0
	_add_terminal_line(parent)
	_build_attribute_detail(parent)

func _build_equipment_page(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)
	_build_preview_column(row)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 5)
	row.add_child(detail)
	_build_weapon_equipment_panel(detail)
	_add_terminal_line(detail)
	_build_equipment_detail(detail)

func _build_weapon_equipment_panel(parent: Node) -> void:
	var heading := HBoxContainer.new()
	parent.add_child(heading)
	var title := _label(heading, "EQUIPMENT FROM INVENTORY", 12, Color(0.45, 0.76, 0.78))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(heading, "选择后直接穿戴", 11, Color(0.55, 0.68, 0.71))
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryEquipmentScroll"
	scroll.custom_minimum_size = Vector2(0, 132)
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	var storage_owner := _inventory_storage_owner()
	var candidates: Array = []
	if storage_owner != null:
		for raw_item_id in storage_owner.inventory:
			var item_id := str(raw_item_id)
			var definition := _equipment_definition_for_actor(storage_owner, item_id)
			var target_slot := _slot_for_definition(definition)
			if target_slot in EQUIPMENT_SLOTS:
				candidates.append({"id": item_id, "definition": definition, "target_slot": target_slot, "qty": int(storage_owner.inventory[raw_item_id])})
		for raw_instance_id in storage_owner.equipment_inventory:
			var instance_id := str(raw_instance_id)
			var instance_definition := _equipment_definition_for_actor(storage_owner, instance_id)
			var instance_slot := _slot_for_definition(instance_definition)
			if instance_slot in EQUIPMENT_SLOTS:
				candidates.append({"id": instance_id, "definition": instance_definition, "target_slot": instance_slot, "qty": 1})
	if candidates.is_empty():
		_label(list, "共享背包中没有可穿戴装备。", 11, Color(0.55, 0.68, 0.71))
		return
	for candidate in candidates:
		var item_id := str(candidate.get("id", ""))
		var definition: Dictionary = candidate.get("definition", {}) as Dictionary
		var target_slot := str(candidate.get("target_slot", "mainhand"))
		var item_row := HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 5)
		list.add_child(item_row)
		var quality := str(definition.get("quality", definition.get("rarity", "common")))
		var item_label := _label(item_row, "%s  %s  Lv.%d  x%d" % [str(definition.get("name", item_id)), _slot_label(target_slot), int(definition.get("level", 1)), int(candidate.get("qty", 1))], 11, Color(_quality_color(quality)))
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item_ref := item_id
		var slot_ref := target_slot
		_button(item_row, "装备", func(): _equip_item_to_slot(item_ref, slot_ref), Vector2(54, 23))

func _show_inventory_tooltip(item_id: String, storage_owner: Actor, source: Control) -> void:
	if inventory_tooltip == null or not is_instance_valid(source):
		return
	var equipment_definition := _equipment_definition_for_actor(storage_owner, item_id)
	var item_definition := gdb.get_item(item_id) if gdb != null else {}
	if equipment_definition.is_empty() and item_definition.is_empty():
		return
	for child in inventory_tooltip_content.get_children():
		child.queue_free()
	var definition := equipment_definition if not equipment_definition.is_empty() else item_definition
	var display_name := str(definition.get("name", item_id))
	_label(inventory_tooltip_content, display_name, 15, Color(0.90, 0.96, 0.96))
	if not equipment_definition.is_empty():
		var quality := str(equipment_definition.get("quality", equipment_definition.get("rarity", "common")))
		_label(inventory_tooltip_content, "%s  Lv.%d  %s" % [_quality_label(quality), int(equipment_definition.get("level", 1)), _slot_label(_slot_for_definition(equipment_definition))], 11, Color(_quality_color(quality)))
		var gameplay := equipment_definition.get("gameplay", {}) as Dictionary
		for stat in gameplay:
			_label(inventory_tooltip_content, "%s  %+s" % [_stat_label(str(stat)), str(gameplay[stat])], 11, Color(0.72, 0.84, 0.84))
		for affix in equipment_definition.get("affixes", []) as Array:
			if affix is Dictionary:
				var affix_text := str(affix.get("description", ""))
				if affix_text == "":
					affix_text = "+%s %s" % [str(affix.get("value", 0)), _stat_label(str(affix.get("stat", "")))]
				_label(inventory_tooltip_content, "【%s】%s" % [str(affix.get("name", "词条")), affix_text], 11, Color(_quality_color(quality)))
	else:
		_label(inventory_tooltip_content, "%s  数量 %d" % [str(item_definition.get("type", "物品")), int(storage_owner.inventory.get(item_id, 1))], 11, Color(0.72, 0.84, 0.84))
		_label(inventory_tooltip_content, str(item_definition.get("description", "暂无说明")), 11, Color(0.68, 0.78, 0.80))
		_label(inventory_tooltip_content, "价值  %d" % int(item_definition.get("value", 0)), 11, Color(0.68, 0.78, 0.80))
	inventory_tooltip.visible = true
	call_deferred("_position_inventory_tooltip", source)

func _position_inventory_tooltip(source: Control) -> void:
	if inventory_tooltip == null or not inventory_tooltip.visible or not is_instance_valid(source):
		return
	var source_rect := source.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	var x := source_rect.position.x + source_rect.size.x + 8.0
	if x + inventory_tooltip.size.x > viewport_size.x:
		x = source_rect.position.x - inventory_tooltip.size.x - 8.0
	var y := clampf(source_rect.position.y, 8.0, maxf(8.0, viewport_size.y - inventory_tooltip.size.y - 8.0))
	inventory_tooltip.position = Vector2(maxf(8.0, x), y)

func _hide_inventory_tooltip() -> void:
	if inventory_tooltip != null:
		inventory_tooltip.visible = false

func _add_terminal_tabs(parent: Node) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 18)
	parent.add_child(tabs)
	for tab_id in ["attributes", "equipment", "inventory", "skills", "talents", "feats"]:
		var current_tab: String = tab_id
		var button := _button(tabs, _terminal_tab_label(current_tab), func(): _terminal_select_tab(current_tab), Vector2(100, 25))
		button.button_pressed = inspect_context.selected_tab == current_tab

func _build_attribute_detail(parent: Node) -> void:
	_label(parent, "ATTRIBUTE SOURCE" if inspect_context.selected_stat != "" else "SELECT AN ATTRIBUTE", 11, Color(0.45, 0.76, 0.78))
	if inspect_context.selected_stat == "":
		_label(parent, "选择左侧属性以查看基础、种族、职业、装备、词条和天赋来源。", 12, Color(0.55, 0.68, 0.71))
		return
	var result: Variant = character_actor.attributes.get_calculation_result(inspect_context.selected_stat)
	_label(parent, "%s  %s" % [_stat_label(inspect_context.selected_stat), _format_stat_value(inspect_context.selected_stat, character_actor.get_stat(inspect_context.selected_stat))], 16)
	if Attributes.BASE_STATS.has(inspect_context.selected_stat):
		var allocation := HBoxContainer.new()
		parent.add_child(allocation)
		_label(allocation, "可用属性点  %d" % character_actor.progression.attribute_points, 12, Color(0.55, 0.68, 0.71))
		var allocate_button := _button(allocation, "分配 1 点", func(): _allocate(inspect_context.selected_stat), Vector2(110, 24))
		allocate_button.disabled = character_actor.progression.attribute_points <= 0
	if result == null:
		return
	var sources := HBoxContainer.new()
	parent.add_child(sources)
	_label(sources, "基础 %s" % result.base_value, 12)
	for modifier in result.modifiers:
		if modifier is Dictionary:
			_label(sources, "%s %+g" % [str(modifier.get("source_type", "OTHER")), float(modifier.get("value", 0.0))], 11, Color(0.62, 0.74, 0.75))

func _build_equipment_detail(parent: Node) -> void:
	_label(parent, "EQUIPMENT DETAIL", 11, Color(0.45, 0.76, 0.78))
	var storage_owner := _inventory_storage_owner()
	var definition := _equipment_definition_for_actor(storage_owner, inspect_context.selected_equipment_id)
	if definition.is_empty():
		var item_definition := gdb.get_item(inspect_context.selected_equipment_id) if gdb != null else {}
		if item_definition.is_empty():
			_label(parent, "选择装备查看属性、品质、等级与词条。", 12, Color(0.55, 0.68, 0.71))
			return
		_label(parent, str(item_definition.get("name", inspect_context.selected_equipment_id)), 16)
		_label(parent, str(item_definition.get("description", "暂无说明")), 12, Color(0.62, 0.74, 0.75))
		_label(parent, "类型 %s   数量 %d   价值 %d" % [str(item_definition.get("type", "misc")), int(storage_owner.inventory.get(inspect_context.selected_equipment_id, 1)), int(item_definition.get("value", 0))], 11, Color(0.55, 0.68, 0.71))
		return
	var quality := str(definition.get("quality", "common"))
	_label(parent, "%s  Lv.%d  %s" % [str(definition.get("name", inspect_context.selected_equipment_id)), int(definition.get("level", 1)), _quality_label(quality)], 16, Color(_quality_color(quality)))
	if quality in ["artifact", "transcendent"]:
		_label(parent, "UNIQUE / TRANSCENDENT  唯一装备", 11, Color(0.94, 0.38, 0.42))
	var stats := definition.get("gameplay", {}) as Dictionary
	var stat_parts: Array[String] = []
	for key in stats:
		stat_parts.append("%s %+s" % [_stat_label(str(key)), str(stats[key])])
	var stat_line := "  ".join(stat_parts)
	_label(parent, stat_line if stat_line != "" else "无基础属性", 12)
	_append_equipment_affixes(parent, definition)
	var slot := _slot_for_definition(definition)
	var equipped := str(character_actor.equipment.get(slot, "")) == inspect_context.selected_equipment_id
	if not equipped:
		var current_id := str(character_actor.equipment.get(slot, ""))
		var current_definition := _equipment_definition_for_actor(character_actor, current_id)
		_build_equipment_comparison(parent, current_definition, definition)
	var instance: Variant = _equipment_instance_for_actor(storage_owner, inspect_context.selected_equipment_id)
	if instance != null:
		_build_upgrade_preview(parent, instance)
		_build_enchantment_panel(parent, instance)
	_label(parent, "已装备" if equipped else "可拖动到中间装备槽，或点击装备", 11, Color(0.55, 0.68, 0.71))

func _build_equipment_comparison(parent: Node, current: Dictionary, incoming: Dictionary) -> void:
	_label(parent, "EQUIPMENT COMPARISON", 11, Color(0.45, 0.76, 0.78))
	var table := GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", 16)
	table.add_theme_constant_override("v_separation", 2)
	parent.add_child(table)
	_label(table, "属性", 11, Color(0.55, 0.68, 0.71))
	_label(table, "CURRENT", 11, Color(0.55, 0.68, 0.71))
	_label(table, "NEW", 11, Color(0.55, 0.68, 0.71))
	_label(table, "Δ", 11, Color(0.55, 0.68, 0.71))
	var keys: Array[String] = []
	var current_stats := current.get("gameplay", {}) as Dictionary
	var incoming_stats := incoming.get("gameplay", {}) as Dictionary
	for key in current_stats:
		if not keys.has(str(key)):
			keys.append(str(key))
	for key in incoming_stats:
		if not keys.has(str(key)):
			keys.append(str(key))
	for key in keys:
		var old_value := float(current_stats.get(key, 0.0))
		var new_value := float(incoming_stats.get(key, 0.0))
		var difference := new_value - old_value
		_label(table, _stat_label(key), 11)
		_label(table, _compact_number(old_value), 11)
		_label(table, _compact_number(new_value), 11)
		_label(table, ("+" if difference > 0.0 else "") + _compact_number(difference), 11, Color(0.38, 0.84, 0.68) if difference >= 0.0 else Color(0.93, 0.45, 0.45))

func _build_upgrade_preview(parent: Node, instance: EquipmentInstance) -> void:
	var upgraded := EquipmentInstance.from_dict(instance.to_dict())
	if not equipment_service.can_upgrade(upgraded):
		return
	var before := equipment_service.get_instance_stats(instance)
	equipment_service.upgrade(upgraded)
	var after := equipment_service.get_instance_stats(upgraded)
	_label(parent, "UPGRADE PREVIEW   Lv.%d → Lv.%d" % [instance.level, upgraded.level], 11, Color(0.45, 0.76, 0.78))
	var changes: Array[String] = []
	for stat in after:
		var difference := float(after[stat]) - float(before.get(stat, 0.0))
		if difference != 0.0:
			changes.append("%s %s" % [_stat_label(str(stat)), "+" + _compact_number(difference)])
	_label(parent, "强化后：" + ("  ".join(changes) if not changes.is_empty() else "属性不变"), 11, Color(0.72, 0.82, 0.83))

func _build_enchantment_panel(parent: Node, instance: EquipmentInstance) -> void:
	var capacity := instance.enchantment_capacity
	_label(parent, "MAGIC ENCHANTMENT   %d / %d" % [instance.enchantment_used, capacity], 11, Color(0.45, 0.76, 0.78))
	if instance.enchantments.is_empty():
		_label(parent, "未注魔", 11, Color(0.55, 0.68, 0.71))
		return
	for enchantment in instance.enchantments:
		if enchantment is Dictionary:
			_label(parent, "%s  %s" % [str(enchantment.get("name", "铭文")), str(enchantment.get("description", ""))], 11)

func _compact_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(snappedf(value, 0.1))

func _build_skill_detail(parent: Node) -> void:
	_label(parent, "SKILL TREE", 11, Color(0.45, 0.76, 0.78))
	var tree := skill_tree_service.get_tree(character_actor) if skill_tree_service != null else []
	if tree.is_empty():
		_label(parent, "当前职业暂无技能树数据。", 12, Color(0.55, 0.68, 0.71))
		return
	_label(parent, "技能点 %d  |  每条分支需按层级解锁" % character_actor.progression.skill_points, 11, Color(0.55, 0.68, 0.71))
	var branches: Dictionary = {}
	for node in tree:
		if node is Dictionary:
			var branch_name := str(node.get("branch", "未分类"))
			if not branches.has(branch_name):
				branches[branch_name] = []
			(branches[branch_name] as Array).append(node)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	parent.add_child(columns)
	for branch_name in branches:
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(170, 0)
		columns.add_child(column)
		_label(column, str(branch_name), 13, Color(0.62, 0.85, 0.9))
		for raw_node in branches[branch_name] as Array:
			var node: Dictionary = raw_node as Dictionary
			var node_id := str(node.get("id", ""))
			var unlocked := character_actor.skills.has(node_id)
			var available := skill_tree_service.can_unlock(character_actor, node_id)
			var state := "已解锁" if unlocked else ("可解锁" if available else "锁定")
			var label := "T%d  %s  [%d]" % [int(node.get("tier", 1)), str(node.get("name", node_id)), int(node.get("cost", 1))]
			var button := _button(column, label + "\n" + state, func(): _unlock_skill(node_id), Vector2(168, 38))
			button.disabled = not available
			if unlocked:
				button.modulate = Color(0.55, 0.88, 0.88)
			var requirements: Array = node.get("attribute_requirements", []) as Array
			if not requirements.is_empty() and not unlocked:
				var requirement_text: Array[String] = []
				for requirement in requirements:
					if requirement is Dictionary:
						requirement_text.append("%s %d" % [_stat_label(str(requirement.get("stat", ""))), int(requirement.get("minimum", 0))])
				_label(column, "需求：" + ", ".join(requirement_text), 10, Color(0.62, 0.66, 0.70))
	_add_terminal_line(parent)
	_label(parent, "SKILL BAR  已学习的主动技能可配置至八个槽位", 11, Color(0.45, 0.76, 0.78))
	var skill_bar := HBoxContainer.new()
	skill_bar.add_theme_constant_override("separation", 5)
	parent.add_child(skill_bar)
	for slot_index in range(character_actor.skill_bar.size()):
		var index := slot_index
		var skill_id := str(character_actor.skill_bar[index])
		var skill_name := str(gdb.get_skill(skill_id).get("name", skill_id)) if skill_id != "" else "空"
		var slot := _button(skill_bar, "%d\n%s" % [index + 1, skill_name], func(): _clear_terminal_skill_slot(index), Vector2(78, 36))
		slot.tooltip_text = "点击清空此技能栏槽位"
	var active := skill_tree_service.active_skills(character_actor) if skill_tree_service != null else []
	if active.is_empty():
		_label(parent, "学习主动技能后可在这里配置。", 11, Color(0.55, 0.68, 0.71))
		return
	var active_row := HBoxContainer.new()
	parent.add_child(active_row)
	for raw_skill in active:
		var skill: Dictionary = raw_skill as Dictionary
		var active_id := str(skill.get("id", ""))
		_button(active_row, "配置 " + str(skill.get("name", active_id)), func(): _assign_terminal_skill(active_id), Vector2(130, 25))

func _build_talent_detail(parent: Node) -> void:
	_label(parent, "TALENTS", 11, Color(0.45, 0.76, 0.78))
	_label(parent, "天赋为角色创建时确定的先天特质：每名角色 0 至 3 个，不能升级或通过普通方式获得。", 12, Color(0.55, 0.68, 0.71))
	if character_actor.talents.is_empty():
		_label(parent, "该角色没有先天天赋。", 13, Color(0.62, 0.74, 0.75))
		return
	var row := HBoxContainer.new()
	parent.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(270, 0)
	row.add_child(list)
	var selected_name := ""
	for talent_id in character_actor.talents:
		var id := str(talent_id)
		var definition := gdb.get_talent(id)
		var button := _button(list, str(definition.get("name", id)) + "  [先天]", func(): _terminal_select_talent(id), Vector2(250, 23))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.modulate = Color(0.55, 0.88, 0.88)
		if selected_name == "" or id == inspect_context.selected_talent_id:
			selected_name = id
	var selected := gdb.get_talent(selected_name)
	var info := VBoxContainer.new()
	row.add_child(info)
	if not selected.is_empty():
		_label(info, str(selected.get("name", selected_name)), 15)
		_label(info, str(selected.get("description", "被动天赋")), 12, Color(0.62, 0.74, 0.75))
		_label(info, "先天天赋，无法升级或通过普通方式获得。", 11, Color(0.55, 0.68, 0.71))

func _build_feat_detail(parent: Node) -> void:
	_label(parent, "FEATS / 专长", 11, Color(0.45, 0.76, 0.78))
	var row := HBoxContainer.new()
	parent.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(270, 0)
	row.add_child(list)
	var selected_id := inspect_context.selected_feat_id
	for feat_id in gdb.feats:
		var id := str(feat_id)
		var definition := gdb.get_feat(id)
		if bool(definition.get("hidden", false)) and not character_actor.feats.has(id):
			continue
		var unlocked := character_actor.feats.has(id)
		var progress := feat_progress_service.progress_for(character_actor, id)
		var suffix := "已获得" if unlocked else "%d/%d" % [int(progress.get("current", 0)), int(progress.get("required", 1))]
		var button := _button(list, "%s  [%s]" % [str(definition.get("name", id)), suffix], func(): _terminal_select_feat(id), Vector2(260, 24))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if unlocked:
			button.modulate = Color(0.55, 0.88, 0.88)
		if selected_id == "":
			selected_id = id
	var info := VBoxContainer.new()
	row.add_child(info)
	var selected := gdb.get_feat(selected_id)
	if not selected.is_empty():
		var progress := feat_progress_service.progress_for(character_actor, selected_id)
		_label(info, str(selected.get("name", selected_id)), 15)
		_label(info, str(selected.get("description", "通过冒险经历获得的永久专长。")), 12, Color(0.62, 0.74, 0.75))
		_label(info, "进度：%d / %d" % [int(progress.get("current", 0)), int(progress.get("required", 1))], 12)

func _terminal_select_actor(actor: Actor) -> void:
	_open_terminal(actor, inspect_context.selected_tab)

func _terminal_select_tab(tab: String) -> void:
	inspect_context.selected_tab = tab
	_queue_terminal_refresh()

func _terminal_select_stat(stat: String) -> void:
	inspect_context.selected_stat = stat
	inspect_context.selected_tab = "attributes"
	_queue_terminal_refresh()

func _terminal_select_item(item_id: String) -> void:
	inspect_context.selected_equipment_id = item_id
	inspect_context.selected_talent_id = ""
	inspect_context.selected_tab = "equipment"
	_queue_terminal_refresh()

func _terminal_select_talent(talent_id: String) -> void:
	inspect_context.selected_talent_id = talent_id
	inspect_context.selected_equipment_id = ""
	inspect_context.selected_tab = "talents"
	_queue_terminal_refresh()

func _terminal_select_feat(feat_id: String) -> void:
	inspect_context.selected_feat_id = feat_id
	inspect_context.selected_tab = "feats"
	_queue_terminal_refresh()

func _assign_terminal_skill(skill_id: String) -> void:
	if skill_tree_service == null or character_actor == null:
		return
	var slot := skill_tree_service.assign_to_first_free_slot(character_actor, skill_id)
	if slot >= 0:
		set_feedback("已配置到技能栏 %d。" % (slot + 1))
	else:
		set_feedback("技能栏已满，请点击槽位清空后再配置。")
	_queue_terminal_refresh()

func _clear_terminal_skill_slot(index: int) -> void:
	if skill_tree_service != null and character_actor != null and skill_tree_service.clear_skill_slot(character_actor, index):
		set_feedback("已清空技能栏 %d。" % (index + 1))
		_queue_terminal_refresh()

func _unlock_skill(skill_id: String) -> void:
	if skill_tree_service != null and skill_tree_service.unlock(character_actor, skill_id):
		set_feedback("已解锁技能")
		_queue_terminal_refresh()

func _unequip_terminal_slot(slot: String) -> void:
	if character_actor != null and str(character_actor.equipment.get(slot, "")) != "":
		equipment_service.unequip(character_actor, slot, ctx)
		set_feedback("已卸下 " + _slot_label(slot))
		_queue_terminal_refresh()

func _unequip_dragged_item(item_id: String) -> void:
	if character_actor == null:
		return
	for slot in character_actor.equipment:
		if str(character_actor.equipment[slot]) == item_id:
			equipment_service.unequip(character_actor, str(slot), ctx)
			set_feedback("已卸下装备")
			_queue_terminal_refresh()
			return

func _format_stat_value(stat: String, value: float) -> String:
	if stat in ["critical", "evasion", "accuracy"]:
		return ("%s" % value) + "%"
	return "%s" % value

func _class_name(actor: Actor) -> String:
	if actor == null:
		return "-"
	for class_id in actor.classes:
		return str(gdb.get_class_def(str(class_id)).get("name", class_id))
	return "-"

func _inventory_filter_label(filter_id: String) -> String:
	return {"all": "全部", "weapon": "武器", "armor": "防具", "accessory": "饰品", "consumable": "消耗", "material": "材料", "misc": "其它"}.get(filter_id, filter_id)

func _inventory_sort_label(sort_id: String) -> String:
	return {"type": "类型", "quality": "品质", "level": "等级", "name": "名称", "value": "价值"}.get(sort_id, sort_id)

func _terminal_tab_label(tab_id: String) -> String:
	return {"attributes": "属性", "equipment": "装备", "inventory": "背包", "skills": "技能树", "talents": "天赋", "feats": "专长"}.get(tab_id, tab_id)

func _inventory_type_matches(item_type: String, filter_id: String) -> bool:
	if filter_id == "all":
		return true
	if filter_id == "armor":
		return item_type in ["armor", "helmet", "chest", "legs", "boots"]
	if filter_id == "accessory":
		return item_type in ["accessory", "necklace", "ring"]
	return item_type == filter_id

func _inventory_item_less(a: Dictionary, b: Dictionary) -> bool:
	match inventory_sort:
		"name": return str(a.get("name", "")) < str(b.get("name", ""))
		"level": return int((a.get("definition", {}) as Dictionary).get("level", 0)) > int((b.get("definition", {}) as Dictionary).get("level", 0))
		"quality": return EquipmentRarity.rank(str((a.get("definition", {}) as Dictionary).get("quality", "common"))) > EquipmentRarity.rank(str((b.get("definition", {}) as Dictionary).get("quality", "common")))
		"value": return float((a.get("definition", {}) as Dictionary).get("value", 0)) > float((b.get("definition", {}) as Dictionary).get("value", 0))
	return str(a.get("type", "")) < str(b.get("type", ""))

func _allocate(stat: String) -> void:
	if character_actor == null or character_service == null:
		return
	if character_service.allocate_attribute(character_actor, stat):
		set_feedback(_stat_label(stat) + " +1")
	else:
		set_feedback("没有可分配的属性点。")
	_queue_terminal_refresh()

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
	inventory_filter = "all"
	_open_terminal(actor, "inventory")

func _refresh_inventory() -> void:
	_queue_terminal_refresh()

func _item_icon(item_id: String, actor: Actor = null) -> TextureRect:
	var icon := TextureRect.new()
	var icon_item_id := item_id
	if actor != null:
		var instance: Variant = actor.get_equipment_inventory_instance(item_id)
		if instance is EquipmentInstance:
			icon_item_id = instance.template_id
	var texture := AssetRegistry.new(cdb).get_equipment_icon(icon_item_id)
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

func _set_inventory_sort(sort_id: String) -> void:
	inventory_sort = sort_id
	_refresh_inventory()

func _open_inventory_for(actor: Actor) -> void:
	_open_terminal(actor, inspect_context.selected_tab)

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
		drop.definition_provider = func(definition_item_id: String): return _equipment_definition_for_actor(inventory_actor, definition_item_id)
		drop.text = _slot_label(slot) + ": " + (str(_equipment_definition_for_actor(inventory_actor, item_id).get("name", item_id)) if item_id != "" else "空")
		drop.custom_minimum_size = Vector2(165, 25)
		drop.equipment_dropped.connect(func(new_item_id: String, target_slot: String): _equip_item_to_slot(new_item_id, target_slot))
		drop.pressed.connect(func(): _unequip_inventory_slot(slot))
		parent.add_child(drop)

func _equip_item_to_slot(item_id: String, slot: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if inventory_actor == null or storage_owner == null or int(storage_owner.inventory.get(item_id, 0)) <= 0:
		var instance: Variant = storage_owner.get_equipment_inventory_instance(item_id) if storage_owner != null else null
		if instance is EquipmentInstance:
			if equipment_service.equip_instance(inventory_actor, slot, instance, ctx):
				set_feedback("已装备 " + str(_equipment_definition_for_actor(storage_owner, item_id).get("name", item_id)))
				_queue_terminal_refresh()
			return
	if equipment_service.equip(inventory_actor, slot, item_id, ctx):
		set_feedback("已装备 " + str(gdb.get_equipment(item_id).get("name", item_id)))
		_queue_terminal_refresh()

func _unequip_inventory_slot(slot: String) -> void:
	if inventory_actor == null or str(inventory_actor.equipment.get(slot, "")) == "":
		return
	if equipment_service.equip(inventory_actor, slot, "", ctx):
		set_feedback("已卸下 " + _slot_label(slot) + " 装备")
		_queue_terminal_refresh()

func _use_item(item_id: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if inventory_actor != null and storage_owner != null:
		inventory_service.use_item_from_inventory(inventory_actor, storage_owner, item_id, ctx)
		_queue_terminal_refresh()

func _equip_item(item_id: String) -> void:
	if inventory_actor == null:
		return
	var definition := _equipment_definition_for_actor(_inventory_storage_owner(), item_id)
	var slot := _slot_for_definition(definition)
	if slot == "":
		return
	_equip_item_to_slot(item_id, slot)

func _discard_item(item_id: String) -> void:
	var storage_owner := _inventory_storage_owner()
	if storage_owner != null:
		if not storage_owner.remove_equipment_instance(item_id):
			inventory_service.remove_item(storage_owner, item_id, 1)
		_queue_terminal_refresh()

func _slot_for_equipment(item_id: String) -> String:
	var eq := _equipment_definition_for_actor(_inventory_storage_owner(), item_id)
	return _slot_for_definition(eq)

func _slot_for_definition(eq: Dictionary) -> String:
	var slot := str(eq.get("slot", ""))
	match slot:
		"head": return "helmet"
		"torso": return "chest"
		"weapon":
			return "mainhand"
		"shield":
			return "offhand"
	return slot

func _equipment_definition_for_actor(actor: Actor, item_id: String) -> Dictionary:
	if actor != null and item_id != "":
		var definition := actor.get_equipment_definition(item_id)
		if not definition.is_empty():
			return definition
		var inventory_instance: Variant = actor.get_equipment_inventory_instance(item_id)
		if inventory_instance is EquipmentInstance:
			var template: EquipmentTemplate = EquipmentTemplate.from_dict(gdb.get_equipment(inventory_instance.template_id))
			return inventory_instance.to_definition(template)
	return gdb.get_equipment(item_id) if gdb != null else {}

func _equipment_instance_for_actor(actor: Actor, item_id: String) -> Variant:
	if actor == null or item_id == "":
		return null
	var inventory_instance: Variant = actor.get_equipment_inventory_instance(item_id)
	if inventory_instance is EquipmentInstance:
		return inventory_instance
	var equipped_instance: Variant = actor.get_equipment_instance(item_id)
	if equipped_instance is EquipmentInstance:
		return equipped_instance
	return null

func open_blacksmith(actor: Actor) -> void:
	if actor == null or blacksmith_panel == null:
		return
	blacksmith_panel.visible = true
	_clear_panel_content(blacksmith_panel)
	_label(blacksmith_content, "BLACKSMITH / 铁匠铺", 20, Color(0.45, 0.76, 0.78))
	_label(blacksmith_content, "强化不改变装备实例、品质、词条或注魔。", 12, Color(0.62, 0.74, 0.75))
	for instance_id in actor.equipment_inventory:
		var instance: Variant = actor.get_equipment_inventory_instance(str(instance_id))
		if not instance is EquipmentInstance:
			continue
		var definition := _equipment_definition_for_actor(actor, instance.instance_id)
		var preview := equipment_service.get_upgrade_preview(instance)
		var cost: Dictionary = preview.get("cost", {}) as Dictionary
		_button(blacksmith_content, "强化 %s Lv.%d  金币%d + 碎片%d" % [str(definition.get("name", instance.template_id)), instance.level, int(cost.get("gold", 0)), int(cost.get("material_amount", 0))], func(): _blacksmith_upgrade(actor, instance.instance_id), Vector2(500, 28)).disabled = not bool(preview.get("allowed", false))
		_button(blacksmith_content, "拆解 " + str(definition.get("name", instance.template_id)), func(): _blacksmith_salvage(actor, instance.instance_id), Vector2(500, 24)).disabled = instance.rarity == EquipmentRarity.TRANSCENDENT
	_label(blacksmith_content, "锻造：主材料决定装备倾向，普通锻造不产出红色超越装备。", 12, Color(0.62, 0.74, 0.75))
	for material_id in gdb.forge_materials:
		if int(actor.inventory.get(str(material_id), 0)) > 0:
			_button(blacksmith_content, "用 " + str(gdb.get_forge_material(str(material_id)).get("name", material_id)) + " 锻造", func(): _blacksmith_forge(actor, str(material_id)), Vector2(260, 28))

func _blacksmith_upgrade(actor: Actor, instance_id: String) -> void:
	var result := equipment_service.upgrade_with_resources(actor, actor.get_equipment_inventory_instance(instance_id), ctx)
	set_feedback("强化完成。" if bool(result.get("success", false)) else str(result.get("reason", "强化失败")))
	open_blacksmith(actor)

func _blacksmith_salvage(actor: Actor, instance_id: String) -> void:
	var result := crafting_service.salvage(actor, instance_id, ctx)
	set_feedback("拆解完成，获得强化碎片。" if bool(result.get("success", false)) else str(result.get("reason", "拆解失败")))
	open_blacksmith(actor)

func _blacksmith_forge(actor: Actor, primary_id: String) -> void:
	var result := crafting_service.forge(actor, primary_id, {}, "", ctx)
	set_feedback("锻造完成。" if bool(result.get("success", false)) else str(result.get("reason", "锻造失败")))
	open_blacksmith(actor)

func open_mage_enchanting(actor: Actor) -> void:
	if actor == null or mage_panel == null:
		return
	mage_panel.visible = true
	_clear_panel_content(mage_panel)
	_label(mage_content, "ENCHANT / 魔法师", 20, Color(0.45, 0.76, 0.78))
	_label(mage_content, "消耗符文与金币。红色超越装备无法进行普通注魔。", 12, Color(0.62, 0.74, 0.75))
	for instance_id in actor.equipment_inventory:
		var instance: Variant = actor.get_equipment_inventory_instance(str(instance_id))
		if not instance is EquipmentInstance:
			continue
		var definition := _equipment_definition_for_actor(actor, instance.instance_id)
		_label(mage_content, "%s Lv.%d  Capacity %d / %d" % [str(definition.get("name", instance.template_id)), instance.level, instance.enchantment_used, instance.enchantment_capacity], 13)
		var rune_row := HBoxContainer.new()
		mage_content.add_child(rune_row)
		for rune_id in enchantment_service.templates:
			var template: EnchantmentTemplate = enchantment_service.templates[rune_id]
			if int(actor.inventory.get(template.rune_item_id, 0)) > 0:
				_button(rune_row, template.name, func(): _mage_apply(actor, instance.instance_id, template.id), Vector2(95, 24))
		for enchantment in instance.enchantments:
			if enchantment is Dictionary:
				_button(mage_content, "移除 " + str(enchantment.get("name", "符文")), func(): _mage_remove(actor, instance.instance_id, str(enchantment.get("id", ""))), Vector2(180, 23))

func _mage_apply(actor: Actor, instance_id: String, rune_id: String) -> void:
	var result := enchantment_service.apply(actor.get_equipment_inventory_instance(instance_id), rune_id, actor, ctx)
	set_feedback("注魔完成。" if bool(result.get("success", false)) else str(result.get("reason", "注魔失败")))
	open_mage_enchanting(actor)

func _mage_remove(actor: Actor, instance_id: String, rune_id: String) -> void:
	if enchantment_service.remove(actor.get_equipment_inventory_instance(instance_id), rune_id, actor, ctx):
		set_feedback("已移除符文。")
	else:
		set_feedback("移除失败。")
	open_mage_enchanting(actor)

func _format_stat_sources(result: Variant) -> String:
	var entries: Array[String] = []
	for modifier in result.modifiers:
		if modifier is Dictionary:
			entries.append("%s %+s" % [str(modifier.get("source_type", "OTHER")), str(modifier.get("value", 0.0))])
	return ", ".join(entries)

func open_equipment(actor: Actor) -> void:
	if actor == null:
		return
	_open_terminal(actor, "equipment")

func _refresh_equipment() -> void:
	_queue_terminal_refresh()

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
	var names := { "poor": "劣质", "common": "普通", "uncommon": "优秀", "rare": "精良", "epic": "大师之作", "masterwork": "大师之作", "legendary": "传说中的物品", "artifact": "神器", "transcendent": "神器" }
	return str(names.get(quality, quality))

func _quality_color(quality: String) -> String:
	var colors := { "poor": "8e8e8e", "common": "eeeeee", "uncommon": "5bcf67", "rare": "579cff", "epic": "b36cff", "masterwork": "b36cff", "legendary": "ff9b37", "artifact": "ef4a4a", "transcendent": "ef4a4a" }
	return str(colors.get(quality, "ffffff"))

func _stat_label(stat: String) -> String:
	var labels := { "strength": "力量", "dexterity": "敏捷", "constitution": "体质", "intelligence": "智力", "willpower": "意志", "wisdom": "意志", "charisma": "魅力", "attack": "攻击", "defense": "防御", "magic_attack": "暗/魔法攻击", "magic_defense": "魔法防御", "max_hp": "最大生命", "max_mp": "最大法力", "accuracy": "命中", "evasion": "闪避", "critical": "暴击", "movement": "移动", "initiative": "先攻" }
	return str(labels.get(stat, stat))

func open_quest() -> void:
	quest_panel.visible = true
	_refresh_quest()

func open_guild_quests(entries: Array) -> void:
	quest_panel.visible = true
	_clear_panel_content(quest_panel)
	_label(quest_content, "冒险者公会委托", 20)
	_label(quest_content, "每日委托会在新的一天刷新。", 13, Color(0.7, 0.82, 0.95))
	if entries.is_empty():
		_label(quest_content, "今天没有可用委托。")
		return
	for entry in entries:
		var quest_id := str(entry.get("quest_id", ""))
		_label(quest_content, str(entry.get("title", quest_id)), 16)
		_label(quest_content, str(entry.get("description", "")), 13)
		_label(quest_content, "状态：" + str(entry.get("state", "")), 12, Color(0.75, 0.85, 0.95))
		if str(entry.get("state", "")) == "Available":
			_button(quest_content, "接受委托", func(): guild_quest_accept_requested.emit(quest_id), Vector2(150, 30))

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
	_label(shop_content, "购买", 15, Color(0.65, 0.82, 0.95))
	for item_id in shop_service.catalog:
		var shop_item_id: String = item_id
		var price := int(shop_service.catalog[item_id])
		var item_name := str(gdb.get_item(item_id).get("name", item_id))
		var row := HBoxContainer.new()
		shop_content.add_child(row)
		_label(row, "%s  %dG" % [item_name, price], 14)
		var buy := _button(row, localization.t("ui.shop.buy"), func(): _buy(shop_item_id), Vector2(80, 28))
		buy.disabled = gold < price
		if int(shop_actor.inventory.get(item_id, 0)) > 0:
			_button(row, localization.t("ui.shop.sell"), func(): _sell(shop_item_id), Vector2(80, 28))
	_refresh_shop_equipment()

func _refresh_shop_equipment() -> void:
	_label(shop_content, "出售装备", 15, Color(0.65, 0.82, 0.95))
	var seller := party_service.get_shared_inventory_owner(shop_actor) if party_service != null else shop_actor
	if seller == null or seller.equipment_inventory.is_empty():
		_label(shop_content, "没有可出售的装备", 13, Color(0.55, 0.68, 0.71))
		return
	for raw_instance_id in seller.equipment_inventory:
		var instance_id := str(raw_instance_id)
		var definition := _equipment_definition_for_actor(seller, instance_id)
		if definition.is_empty():
			continue
		var row := HBoxContainer.new()
		shop_content.add_child(row)
		var quality := str(definition.get("quality", "common"))
		var price := shop_service.get_sell_price(seller, instance_id)
		var equipment_name := str(definition.get("name", instance_id))
		_label(row, "%s  [%s] Lv.%d  %dG" % [equipment_name, _quality_label(quality), int(definition.get("level", 1)), price], 13, Color(_quality_color(quality)))
		var sell := _button(row, localization.t("ui.shop.sell"), func(): _sell_equipment(instance_id), Vector2(80, 28))
		sell.disabled = shop_service.is_equipped(seller, instance_id)
		if sell.disabled:
			_label(row, "已装备", 11, Color(0.55, 0.68, 0.71))

func _buy(item_id: String) -> void:
	if shop_actor != null:
		if not shop_service.buy(shop_actor, item_id, ctx):
			set_feedback(localization.t("ui.shop.insufficient"))
		_refresh_shop()

func _sell(item_id: String) -> void:
	if shop_actor != null:
		if not shop_service.sell(shop_actor, item_id, 1, ctx):
			set_feedback("该物品无法出售，可能已装备或不在库存中。")
		_refresh_shop()

func _sell_equipment(instance_id: String) -> void:
	var seller := party_service.get_shared_inventory_owner(shop_actor) if party_service != null else shop_actor
	if seller != null and not shop_service.sell(seller, instance_id, 1, ctx):
		set_feedback("该装备无法出售，可能已装备或已不存在。")
	_refresh_shop()

func open_combat(inst: CombatInstance, p_tactical_grid: CombatGrid3D = null, show_panel: bool = true) -> void:
	if inst == null:
		return
	combat_instance = inst
	_combat_rewards_granted = false
	var first_enemy := _first_alive_combatant(inst.enemy_team)
	combat_enemy_target_id = first_enemy.actor.id if first_enemy != null else ""
	if p_tactical_grid != null:
		tactical_grid_visual = p_tactical_grid
	if inst is TacticalCombatController:
		selected_tactical_unit = _first_operable_player_unit()
	combat_panel.visible = show_panel
	_refresh_combat()

func set_tactical_grid_visual(p_grid: CombatGrid3D) -> void:
	tactical_grid_visual = p_grid
	if combat_instance is TacticalCombatController and combat_instance.is_active():
		_refresh_tactical_highlights()

func _refresh_combat() -> void:
	if combat_instance == null:
		return
	_clear_panel_content(combat_panel)
	_label(combat_content, "战斗方式：" + ("战棋回合制" if combat_instance.mode == CombatMode.TACTICAL else "即时战斗"), 14, Color(0.65, 0.85, 1.0))
	var current := _selected_tactical_unit() if combat_instance is TacticalCombatController else combat_instance.current_combatant()
	if current != null:
		var movement_total := combat_instance.movement_points_for(current.actor)
		combat_movement_label = _label(combat_content, "当前行动：%s    移动力：%d/%d    攻击范围：%d" % [current.actor.identity.display_name, current.movement_remaining, movement_total, combat_instance.attack_range_for(current.actor)], 13, Color(0.75, 0.85, 1.0))
	elif combat_instance is TacticalCombatController and _is_tactical_player_phase():
		_label(combat_content, "我方单位均已完成行动，请结束我方回合。", 13, Color(1.0, 0.82, 0.58))
	var enemy := _combatant_by_id(combat_enemy_target_id)
	if enemy == null or enemy.team != "enemy" or not enemy.alive:
		enemy = _first_alive_combatant(combat_instance.enemy_team)
		combat_enemy_target_id = enemy.actor.id if enemy != null else ""
	var enemy_row := HBoxContainer.new()
	combat_content.add_child(enemy_row)
	_label(enemy_row, "敌人" if enemy == null else enemy.actor.identity.display_name, 17, Color(1.0, 0.82, 0.72))
	combat_enemy_hp = ProgressBar.new()
	combat_enemy_hp.custom_minimum_size = Vector2(390, 22)
	combat_enemy_hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_enemy_hp.show_percentage = false
	var hp_background := StyleBoxFlat.new()
	hp_background.bg_color = Color(0.10, 0.02, 0.02, 1.0)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.12, 0.92, 0.30, 1.0)
	combat_enemy_hp.add_theme_stylebox_override("background", hp_background)
	combat_enemy_hp.add_theme_stylebox_override("fill", hp_fill)
	if enemy != null:
		combat_enemy_hp.max_value = maxf(1.0, enemy.actor.max_hp())
		combat_enemy_hp.value = clampf(enemy.actor.get_hp(), 0.0, combat_enemy_hp.max_value)
	enemy_row.add_child(combat_enemy_hp)
	combat_enemy_hp_label = _label(enemy_row, "", 13, Color(0.82, 1.0, 0.86))
	if enemy != null:
		combat_enemy_hp_label.text = "%d / %d" % [int(enemy.actor.get_hp()), int(enemy.actor.max_hp())]
	var action_row := HBoxContainer.new()
	action_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_content.add_child(action_row)
	if combat_instance is TacticalCombatController:
		var movement_row := HBoxContainer.new()
		combat_content.add_child(movement_row)
		_label(movement_row, "移动", 12, Color(0.65, 0.85, 1.0))
		_button(movement_row, "↑", func(): _move_tactical(Vector2i(0, -1)), Vector2(42, 28))
		_button(movement_row, "↓", func(): _move_tactical(Vector2i(0, 1)), Vector2(42, 28))
		_button(movement_row, "←", func(): _move_tactical(Vector2i(-1, 0)), Vector2(42, 28))
		_button(movement_row, "→", func(): _move_tactical(Vector2i(1, 0)), Vector2(42, 28))
	var log_column := VBoxContainer.new()
	log_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(log_column)
	_label(log_column, localization.t("ui.combat.round") + " " + str(combat_instance.round), 12)
	combat_log_label = _label(log_column, "", 13)
	combat_result_label = _label(log_column, "", 13, Color(0.95, 0.9, 0.6))
	var skills := VBoxContainer.new()
	_label(skills, "技能", 12, Color(0.65, 0.85, 1.0))
	var skill_buttons := HBoxContainer.new()
	skills.add_child(skill_buttons)
	_button(skill_buttons, localization.t("ui.combat.attack"), _combat_attack, Vector2(95, 30))
	_button(skill_buttons, localization.t("ui.combat.skill"), func(): _combat_attack(true), Vector2(95, 30))
	action_row.add_child(skills)
	var options := VBoxContainer.new()
	_label(options, "选项", 12, Color(0.65, 0.85, 1.0))
	if combat_instance is RealTimeCombatController:
		_button(options, localization.t("ui.combat.wait"), _combat_wait, Vector2(90, 30))
		_button(options, "逃离", _escape_realtime_combat, Vector2(90, 30))
	else:
		_button(options, "结束我方回合", _end_tactical_turn, Vector2(130, 30))
		_button(options, "逃离战术", _escape_tactical_combat, Vector2(90, 30))
	action_row.add_child(options)
	if combat_instance is TacticalCombatController:
		_refresh_tactical_highlights()

func _escape_realtime_combat() -> void:
	if combat_instance is RealTimeCombatController:
		(combat_instance as RealTimeCombatController).escape_realtime()

func _escape_tactical_combat() -> void:
	if combat_instance != null and combat_instance is TacticalCombatController and combat_instance.is_active():
		_finish_combat("Escape")

func set_battle_log(text: String) -> void:
	if combat_log_label != null:
		combat_log_label.text = text

func set_battle_result(text: String) -> void:
	if combat_result_label != null:
		combat_result_label.text = text

func _combat_attack(use_skill: bool = false) -> void:
	if combat_instance == null or combat_instance.battle_state != "Active":
		return
	var current := _selected_tactical_unit() if combat_instance is TacticalCombatController else combat_instance.current_combatant()
	if current == null or current.team != "player":
		return
	var target := _combatant_by_id(combat_enemy_target_id)
	if target == null or target.team != "enemy" or not target.alive:
		target = _first_alive_combatant(combat_instance.enemy_team)
	if target == null:
		_finish_combat("Victory")
		return
	combat_enemy_target_id = target.actor.id
	if combat_instance is RealTimeCombatController:
		var realtime := combat_instance as RealTimeCombatController
		if use_skill:
			handle_realtime_skill_slot(0)
			return
		var realtime_result := realtime.player_attack()
		if bool(realtime_result.get("blocked", false)):
			set_battle_log("无法行动：" + str(realtime_result.get("reason", "unknown")))
		else:
			_play_combat_attack_animation()
			set_battle_log("发动攻击，造成 " + str(int(realtime_result.get("damage", 0))) + "。")
		if combat_instance.battle_state != "Active":
			_finish_combat(combat_instance.battle_state)
		_refresh_combat()
		return
	var distance: int = abs(current.position.x - target.position.x) + abs(current.position.y - target.position.y)
	var attack_range := combat_instance.attack_range_for(current.actor)
	if distance > attack_range:
		set_battle_log("距离目标 %d 格，超出攻击范围 %d；请先移动。" % [distance, attack_range])
		return
	var tactical_result: Dictionary = combat_instance.attack(current, target)
	if not bool(tactical_result.get("blocked", false)):
		_play_combat_attack_animation_for(current.actor)
		set_battle_log(current.actor.identity.display_name + " 攻击 " + target.actor.identity.display_name + "，造成 " + str(int(tactical_result.get("damage", 0))) + " 点伤害。")
	if combat_instance.check_battle_end() != "Active":
		_finish_combat(combat_instance.battle_state)
		return
	_refresh_combat()

func handle_realtime_attack() -> bool:
	if combat_instance == null or not combat_instance is RealTimeCombatController:
		return false
	if not combat_instance.is_active():
		return false
	var realtime := combat_instance as RealTimeCombatController
	var result := realtime.player_attack()
	if bool(result.get("blocked", false)):
		if str(result.get("reason", "")) == "out_of_range":
			_play_combat_attack_animation()
			set_battle_log("挥动武器，未命中敌人。")
			return true
		set_battle_log("无法攻击：" + str(result.get("reason", "unknown")))
		return true
	_play_combat_attack_animation()
	set_battle_log("挥动武器，造成 %d 点伤害。" % int(result.get("damage", 0)))
	if combat_instance.battle_state != "Active":
		_finish_combat(combat_instance.battle_state)
	_refresh_combat()
	return true

func _handle_tactical_keyboard() -> void:
	if Input.is_action_just_pressed("move_up"):
		_move_tactical(Vector2i(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		_move_tactical(Vector2i(0, 1))
	elif Input.is_action_just_pressed("move_left"):
		_move_tactical(Vector2i(-1, 0))
	elif Input.is_action_just_pressed("move_right"):
		_move_tactical(Vector2i(1, 0))

func _move_tactical(direction: Vector2i) -> void:
	if combat_instance == null or not combat_instance is TacticalCombatController or not combat_instance.is_active():
		return
	var current := _selected_tactical_unit()
	if current == null or current.team != "player":
		set_feedback("当前不是玩家队伍回合。")
		return
	var destination := current.position + direction
	if combat_instance.move(current, destination):
		set_battle_log("%s 移动到 (%d, %d)，剩余移动力 %d。" % [current.actor.identity.display_name, destination.x, destination.y, current.movement_remaining])
		_refresh_combat()
	else:
		set_feedback("无法移动到该格：可能超出移动力、被占用或不可通行。")

func _refresh_tactical_highlights() -> void:
	if tactical_grid_visual == null or not is_instance_valid(tactical_grid_visual):
		return
	tactical_grid_visual.clear_highlights()
	if combat_instance == null or not combat_instance is TacticalCombatController or not combat_instance.is_active():
		return
	var current := _selected_tactical_unit()
	if current == null or current.team != "player":
		return
	var movement_tiles := CombatRangeQuery.movement_range(current, combat_instance.grid)
	for tile in movement_tiles:
		var color := Color(0.45, 1.0, 0.62, 0.42)
		if combat_instance.is_position_threatened(tile):
			color = Color(1.0, 0.25, 0.25, 0.50)
		tactical_grid_visual.set_tile_color(tile, color)

func _handle_tactical_click(screen_position: Vector2) -> void:
	if tactical_grid_visual == null or not is_instance_valid(tactical_grid_visual):
		return
	if not _is_tactical_player_phase():
		set_feedback("当前不是玩家队伍回合。")
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var picker := CombatWorldPicker.new()
	picker.setup(camera, tactical_grid_visual)
	var tile := picker.pick_tile(screen_position)
	if not combat_instance.grid.tiles.has(tile):
		return
	var target_id := str(combat_instance.grid.occupied.get(tile, ""))
	if target_id != "":
		var target := _combatant_by_id(target_id)
		if target != null and target.team == "player":
			_select_tactical_unit(target)
			return
		if target != null and target.team == "enemy":
			_tactical_attack_target(target)
		return
	var current := _selected_tactical_unit()
	if current == null or not CombatRangeQuery.movement_range(current, combat_instance.grid).has(tile):
		set_feedback("只能移动到浅绿色或红色标记的格子。")
		return
	if combat_instance.move(current, tile):
		set_battle_log("%s 移动到 (%d, %d)，剩余移动力 %d。" % [current.actor.identity.display_name, tile.x, tile.y, current.movement_remaining])
		_refresh_combat()

func _combatant_by_id(actor_id: String) -> Combatant:
	for combatant in combat_instance.all_combatants():
		if combatant != null and combatant.actor != null and combatant.actor.id == actor_id:
			return combatant
	return null

func _tactical_attack_target(target: Combatant) -> void:
	var current := _selected_tactical_unit()
	if current == null or current.team != "player":
		return
	var distance: int = abs(current.position.x - target.position.x) + abs(current.position.y - target.position.y)
	if distance > combat_instance.attack_range_for(current.actor):
		set_feedback("目标超出攻击范围，请先移动到合适位置。")
		return
	combat_enemy_target_id = target.actor.id
	var result := combat_instance.attack(current, target)
	if bool(result.get("blocked", false)):
		set_feedback("无法攻击：" + str(result.get("reason", "unknown")))
		return
	_play_combat_attack_animation_for(current.actor)
	set_battle_log("%s 攻击 %s，造成 %d 点伤害。" % [current.actor.identity.display_name, target.actor.identity.display_name, int(result.get("damage", 0))])
	if combat_instance.check_battle_end() != "Active":
		_finish_combat(combat_instance.battle_state)
		return
	_refresh_combat()

func _play_combat_attack_animation() -> void:
	if ctx == null or ctx.player == null:
		return
	_play_combat_attack_animation_for(ctx.player)

func _play_combat_attack_animation_for(actor: Actor) -> void:
	if actor == null or actor.visual == null or actor.visual.animator == null:
		return
	actor.visual.animator.play_attack()

func _end_tactical_turn() -> void:
	if combat_instance == null or not combat_instance is TacticalCombatController or combat_instance.battle_state != "Active":
		return
	if not _is_tactical_player_phase():
		return
	combat_instance.end_player_phase()
	set_battle_log("我方结束本回合。")
	selected_tactical_unit = null
	_run_enemy_turns()
	selected_tactical_unit = _first_operable_player_unit()
	_refresh_combat()

func _is_tactical_player_phase() -> bool:
	if combat_instance == null or not combat_instance is TacticalCombatController:
		return false
	return combat_instance.is_player_phase()

func _is_tactical_unit_operable(combatant: Combatant) -> bool:
	return combat_instance != null and combat_instance.can_player_control(combatant)

func _first_operable_player_unit() -> Combatant:
	if combat_instance == null:
		return null
	for combatant in combat_instance.player_team:
		if _is_tactical_unit_operable(combatant):
			return combatant
	return null

func _selected_tactical_unit() -> Combatant:
	if _is_tactical_unit_operable(selected_tactical_unit):
		return selected_tactical_unit
	selected_tactical_unit = _first_operable_player_unit()
	return selected_tactical_unit

func _select_tactical_unit(combatant: Combatant) -> void:
	if not _is_tactical_player_phase():
		set_feedback("当前不是玩家队伍回合。")
		return
	if not _is_tactical_unit_operable(combatant):
		set_feedback("该队员本回合已经完成行动。")
		return
	selected_tactical_unit = combatant
	set_battle_log("已选择 " + combatant.actor.identity.display_name + "。")
	_refresh_combat()

func _combat_wait() -> void:
	if combat_instance == null or combat_instance.battle_state != "Active":
		return
	if combat_instance is RealTimeCombatController:
		var realtime_current := combat_instance.current_combatant()
		if realtime_current == null or realtime_current.team != "player":
			return
		set_battle_log(realtime_current.actor.identity.display_name + " 选择等待。")
		combat_instance.end_turn()
		_run_enemy_turns()
		_refresh_combat()
		return
	var current := _selected_tactical_unit()
	if current == null or not combat_instance.can_player_control(current):
		return
	current.movement_remaining = 0
	current.actions_remaining = 0
	selected_tactical_unit = _first_operable_player_unit()
	set_battle_log(current.actor.identity.display_name + " 选择等待。")
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
		var attack_range := combat_instance.attack_range_for(current.actor)
		while distance > attack_range and current.movement_remaining > 0:
			var step := current.position + Vector2i(signi(target.position.x - current.position.x), 0)
			if step == current.position or not combat_instance.move(current, step):
				step = current.position + Vector2i(0, signi(target.position.y - current.position.y))
				if step == current.position or not combat_instance.move(current, step):
					break
			distance = abs(current.position.x - target.position.x) + abs(current.position.y - target.position.y)
		if distance <= attack_range:
			var result: Dictionary = combat_instance.attack(current, target)
			if not bool(result.get("blocked", false)):
				set_battle_log(current.actor.identity.display_name + " 攻击 " + target.actor.identity.display_name + "，造成 " + str(int(result.get("damage", 0))) + " 点伤害。")
		else:
			set_battle_log(current.actor.identity.display_name + " 移动后仍无法攻击。")
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
	if settings_service != null:
		settings_service.set_combat_active(false)
	combat_panel.visible = false
	tactical_grid_visual = null
	set_feedback("胜利！" if result == "Victory" else ("已逃离战斗。" if result == "Escape" else "战斗失败。"))

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
	_button(row, localization.t("ui.tavern.rest"), _show_rest_options, Vector2(110, 32))
	_button(row, localization.t("ui.tavern.recruit"), _show_tavern_recruits, Vector2(110, 32))

func _show_rest_options() -> void:
	_clear_panel_content(tavern_panel)
	_label(tavern_content, "休息", 20)
	_label(tavern_content, "选择休息时长，队伍将在休息后恢复生命。", 13, Color(0.7, 0.82, 0.95))
	var options := [
		["one_hour", "睡一个小时"],
		["noon", "睡到中午"],
		["evening", "睡到晚上"],
		["tomorrow", "睡到明天早上"]
	]
	for option in options:
		var option_id := str(option[0])
		_button(tavern_content, str(option[1]), func(): rest_requested.emit(option_id), Vector2(230, 32))
	_button(tavern_content, "返回酒馆", _return_to_tavern, Vector2(150, 30))

func _return_to_tavern() -> void:
	call_deferred("_refresh_tavern")

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

func close_dungeon() -> void:
	dungeon_panel.visible = false

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

func toggle_quest(_journal: Array) -> void:
	if quest_panel.visible:
		quest_panel.visible = false
	else:
		open_quest()

func toggle_character(actor: Actor) -> void:
	if character_panel.visible:
		character_panel.visible = false
	else:
		open_character(actor)
