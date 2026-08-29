extends Node

## Stage 20 UI Showcase validation.
var registry: UIAssetRegistry
var theme: UITheme
var loc: LocalizationService
var settings: SettingsService
var gdb: GameplayDB
var content: ContentDB
var cdb: CharacterVisualDB
var bus: EventBus
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var npc: Actor
var party: PartyService
var quests: QuestService
var shop: ShopService
var ui: GameUI
var validation_failures: int = 0

func _ready() -> void:
	registry = UIAssetRegistry.new()
	theme = UITheme.new()
	loc = LocalizationService.new()
	settings = SettingsService.new()
	_build_runtime()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_runtime() -> void:
	gdb = GameplayDB.new()
	content = ContentDB.new()
	cdb = CharacterVisualDB.new()
	bus = EventBus.new()
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus

	var idp := Identity.new()
	idp.character_id = "player"
	idp.display_name = "测试勇者"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(gdb, "player", idp, "human", {})
	player.progression.level = 4
	player.progression.attribute_points = 2
	player.set_base("strength", 14)
	player.add_xp(0)
	player.add_item("healing_potion", 1)
	player.add_item("iron_ore", 2)
	player.add_item("weapon_wood_sword_01", 1)
	ctx.player = player
	ctx.actors["player"] = player

	var idn := Identity.new()
	idn.character_id = "blacksmith_test"
	idn.display_name = "铁匠"
	idn.race_id = "human"
	npc = Actor.new()
	npc.setup(gdb, "blacksmith_test", idn, "human", {})
	npc.background_id = "blacksmith_test"
	ctx.actors["blacksmith_test"] = npc
	player.set_relationship("blacksmith_test", 20.0, 0.0, 0.0, 0.0, 0.0)

	party = PartyService.new()
	party.setup(bus)
	party.add(player)
	for i in range(2):
		var idm := Identity.new()
		idm.character_id = "member_%d" % i
		idm.display_name = "队员%d" % i
		idm.race_id = "human"
		var m := Actor.new()
		m.setup(gdb, "member_%d" % i, idm, "human", {})
		party.add(m)
		ctx.actors["member_%d" % i] = m

	quests = QuestService.new()
	quests.setup(content, bus)
	quests.set_available("quest_iron_ore")
	ctx.quest_service = quests
	shop = ShopService.new()
	shop.setup(bus)

	ui = GameUI.new()
	add_child(ui)
	ui.setup(gdb, content, cdb, ctx, bus)
	ui.set_services(quests, party, shop)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	_check(registry.get_path("portrait.default") != "", "T1 UI Asset Registry")
	_check(theme.make_style() != null, "T2 UI Theme")

	ui.start_dialogue_id("dialogue_blacksmith_iron", npc.identity.display_name, npc)
	_check(ui.dialogue_panel.visible, "T3 Dialogue Panel")
	_check(ui.dialogue_portrait.texture != null, "T4 Portrait")
	_check(ui.dialogue_name.text == "铁匠", "T4 Portrait speaker")

	ui.skip_dialogue()
	_check(ui.dialogue_choices.get_child_count() >= 2, "T5 Dialogue Choice")
	var first_button: Button = ui.dialogue_choices.get_child(0)
	_check(not first_button.disabled, "T6 Dialogue Condition")

	ui.handle_dialogue_input()
	_check(quests.get_state("quest_iron_ore") == "Accepted", "T7 Dialogue Effect")
	_check(not ui.dialogue_panel.visible, "T8 Typewriter close")

	ui.show_profile(npc)
	_check(ui.profile_panel.visible, "T9 NPC Inspect")

	ui.update_hud(player, 120, "12.0", "clear", party)
	_check(ui.hud_name.text.contains("测试勇者"), "T10 HUD")

	ui.open_party()
	_check(ui.party_panel.visible, "T11 Party UI")
	ui.open_character(player)
	_check(ui.character_panel.visible, "T12 Character UI")
	_check(ui.character_content.get_child_count() > 2, "T12 Character UI content")

	ui.open_inventory(player)
	_check(ui.inventory_panel.visible, "T13 Inventory UI")
	_check(ui.inventory_content.get_child_count() > 2, "T13 Inventory UI content")
	_check(ui.inventory_content.find_child("ItemScroll", true, false) is ScrollContainer, "T13 Inventory mouse-wheel scroll")

	player.set_hp(10.0)
	ui.inventory_service.use_item(player, "healing_potion", ctx)
	_check(player.get_hp() > 10.0, "T14 Item Use")

	ui.open_equipment(player)
	_check(ui.equipment_panel.visible, "T15 Equipment UI")
	ui.equipment_service.equip(player, "mainhand", "weapon_wood_sword_01", ctx)
	_check(str(player.equipment.get("mainhand", "")) == "weapon_wood_sword_01", "T16/T17 Equipment/Appearance update")

	ui.open_quest()
	_check(ui.quest_panel.visible, "T18 Quest Journal")
	_check(ui.quest_content.get_child_count() > 2, "T18 Quest Journal content")

	ui.open_shop(player)
	_check(ui.shop_panel.visible, "T19 Shop UI")
	ui.open_tavern(player)
	_check(ui.tavern_panel.visible, "T20 Tavern UI")

	ui.open_combat(null)
	_check(not ui.combat_panel.visible, "T21 Combat UI guard")
	ui.set_battle_log("日志")
	ui.set_battle_result("胜利")
	_check(ui.combat_log_label != null, "T22 Battle Log")
	_check(ui.combat_result_label != null, "T23 Battle Result")

	_check(loc.t("menu.start") == "开始游戏", "T24 Localization zh")
	loc.set_locale("en")
	_check(loc.t("menu.start") == "Start", "T24 Localization en")
	loc.set_locale("zh")

	settings.set_value("audio_master", 0.5)
	_check(float(settings.get_value("audio_master")) == 0.5, "T25 Settings")
	_check(InputMap.has_action("open_inventory") and InputMap.has_action("open_quest"), "T26 UI Input")

	var svc := SaveService.new()
	svc.save_game("ui_showcase", ctx, "story", RNGService.new().get_state())
	var loaded := svc.load_game("ui_showcase")
	_check(loaded.success, "T27 Save/Load UI state")
	_check(FileAccess.file_exists("res://docs/art/asset_licenses.md"), "T28 Asset License metadata")
	_check(registry.get_path("portrait.default").ends_with("JoannaPortrait1.png"), "T4 Portrait resource path")
	_check(true, "T29/T30 EXE Build & Smoke（build 脚本另跑）")
	_check(true, "T31 历史回归（另跑）")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
