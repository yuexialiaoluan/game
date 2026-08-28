extends Node2D

## Character / Party / Inventory / Equipment 游戏化与 UI 测试。
var gdb: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var visual: CharacterVisual
var bus: EventBus
var ps: PartyService
var isvc: InventoryService
var esvc: EquipmentService
var csvc: CharacterService
var ui: RPGUI
var validation_failures: int = 0

func _ready() -> void:
	gdb = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	bus = EventBus.new()
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus

	var idp := Identity.new()
	idp.character_id = "player"
	idp.display_name = "主角"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(gdb, "player", idp, "human", {})
	player.progression.level = 3
	player.progression.attribute_points = 5
	player.set_base("strength", 12)
	player.add_xp(0)
	ctx.player = player
	ctx.actors["player"] = player
	player.set_hp(20.0)

	visual = CharacterVisual.new()
	visual.name = "PlayerVisual"
	visual.position = Vector2(0, -16)
	add_child(visual)
	visual.setup(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "human_male", "eyes_default_01")
	player.visual = visual

	ps = PartyService.new()
	ps.setup(bus)
	isvc = InventoryService.new()
	isvc.setup(gdb, bus)
	esvc = EquipmentService.new()
	esvc.setup(gdb, bus)
	csvc = CharacterService.new()
	csvc.setup(bus)

	_build_party()
	player.add_item("healing_potion", 2)

	ui = RPGUI.new()
	add_child(ui)

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_party() -> void:
	for i in range(4):
		var a := _make_actor("active_%d" % i, "队员%d" % i)
		ps.add(a)
		ctx.actors[a.id] = a
	for i in range(4):
		var a := _make_actor("reserve_%d" % i, "备用%d" % i)
		ps.add(a)
		ctx.actors[a.id] = a

func _make_actor(id: String, display: String) -> Actor:
	var idn := Identity.new()
	idn.character_id = id
	idn.display_name = display
	idn.race_id = "human"
	var a := Actor.new()
	a.setup(gdb, id, idn, "human", {})
	return a

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# Character UI / 属性加点
	ui.refresh_character(player)
	_check(ui.character_label.text.contains("主角"), "Character UI")
	var str0 := int(player.get_base_stat("strength"))
	_check(csvc.allocate_attribute(player, "strength"), "属性加点")
	_check(int(player.get_base_stat("strength")) == str0 + 1 and player.progression.attribute_points == 4, "属性变化与点数消耗")
	ui.refresh_character(player)

	# Inventory UI / Tooltip
	ui.refresh_inventory(player)
	_check(ui.inventory_label.text.contains("healing_potion"), "Inventory UI")
	var item_def := gdb.get_item("healing_potion")
	ui.set_tooltip(str(item_def.get("description", "")))
	_check(ui.tooltip_label.text != "", "Item Tooltip")

	# Equipment Requirement 阻止
	player.set_base("strength", 8)
	player.progression.level = 1
	player.recalculate()
	var blocked := esvc.can_equip(player, "armor_iron_01", ctx)
	_check(not bool(blocked.get("allowed", false)), "Equipment Requirement 阻止")
	ui.set_feedback(str(blocked.get("reason", "")))
	_check(ui.feedback_label.text != "", "Blocked Reason")

	# 满足条件后装备 + 外观更新
	player.set_base("strength", 12)
	player.progression.level = 3
	player.recalculate()
	_check(esvc.equip(player, "body", "armor_iron_01", ctx), "装备 Iron Armor")
	_check(visual.resolver.parts.has("torso") and not visual.resolver.parts.has("clothing"), "Iron Armor 外观变化")

	_check(esvc.equip(player, "head", "helmet_iron_01", ctx), "装备 Helmet")
	_check(visual.resolver.parts.has("helmet") and not visual.resolver.parts.has("hair"), "Helmet 外观变化")

	_check(esvc.equip(player, "mainhand", "weapon_iron_sword_01", ctx), "装备 Sword")
	_check(visual.resolver.parts.get("weapon") != null and visual.resolver.parts.get("weapon").get_parent() == visual.get_bone("Hand_R"), "Sword 跟随 Hand_R")

	_check(esvc.equip(player, "offhand", "shield_wood_01", ctx), "装备 Shield")
	_check(visual.resolver.parts.get("shield") != null and visual.resolver.parts.get("shield").get_parent() == visual.get_bone("Hand_L"), "Shield 跟随 Hand_L")

	# 卸下恢复
	esvc.equip(player, "body", "", ctx)
	esvc.equip(player, "head", "", ctx)
	esvc.equip(player, "mainhand", "", ctx)
	esvc.equip(player, "offhand", "", ctx)
	_check(not visual.resolver.parts.has("torso") and not visual.resolver.parts.has("weapon"), "卸下装备外观恢复")

	# Item Use
	var hp0 := player.get_hp()
	_check(isvc.use_item(player, "healing_potion", ctx), "使用 Health Potion")
	_check(player.get_hp() > hp0 and int(player.inventory.get("healing_potion", 0)) == 1, "HP 变化与数量减少")

	# Party
	ui.refresh_party(ps)
	_check(ps.total() == 8 and ps.is_full(), "Party 8人/容量")
	_check(not ps.add(_make_actor("extra", "额外")), "Party 容量限制")
	var first_active = ps.active[0]
	var first_reserve = ps.reserve[0]
	_check(ps.swap(0, 0), "Party 交换")
	_check(ps.active[0] == first_reserve and ps.reserve[0] == first_active, "Party 交换结果")

	# Save / Load
	# 重新装备一套用于保存
	esvc.equip(player, "body", "armor_iron_01", ctx)
	esvc.equip(player, "mainhand", "weapon_iron_sword_01", ctx)
	ctx.party = ps.active.duplicate()
	ctx.reserve_party = ps.reserve.duplicate()
	var svc := SaveService.new()
	svc.save_game("rpg", ctx, "story", 0)
	var lr := svc.load_game("rpg")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(lr.data.actors.has("player"), "Save Character")
	var p2 := Actor.new()
	p2.apply_save_data(lr.data.actors["player"], gdb)
	_check(p2.equipment.get("body", "") == "armor_iron_01", "Load Equipment")
	_check(int(p2.inventory.get("healing_potion", 0)) == 1, "Load Inventory")
	_check(lr.data.party.size() + lr.data.reserve_party.size() == 8, "Load Party")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1


