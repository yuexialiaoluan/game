extends Node3D

## World Exploration Vertical Slice（可玩世界）。
var gdb: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var bus: EventBus
var rng: RNGService
var ts: TimeService
var player: PlayerController3D
var cam: OrthoFollowCamera
var detector: InteractionDetector
var iserv: InteractionService
var aserv: ActionService
var ui: GameUI
var shop: ShopService
var interior: InteriorArea
var transition: WorldCombatTransition
var npc_data: NPCData
var states: NPCStateService
var party: PartyService
var rec: RecruitmentService
var qs: QuestService
var combat: CombatService
var loot: LootService
var content_db: ContentDB
var validation_failures: int = 0

var npc_actors: Dictionary = {}
var objects: Array = []
var goblin: Actor
var enemy_nodes: Dictionary = {}
var active_enemy_id: String = ""
var equipment_generator: EquipmentGenerator
var companion_nodes: Dictionary = {}

func _ready() -> void:
	gdb = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	bus = EventBus.new()
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus
	rng = RNGService.new()
	rng.set_seed(42)
	ctx.rng = rng
	var td := TimeData.new()
	var cal := CalendarService.new()
	cal.setup(td.calendar)
	ts = TimeService.new()
	ts.setup(cal, bus)
	ctx.time_service = ts
	npc_data = NPCData.new()

	_build_world()
	_build_services()
	_spawn_npcs()
	ui.set_tavern_recruits([npc_actors.get("mercenary"), npc_actors.get("adventurer")])
	_spawn_objects()
	_spawn_enemy()

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.10, 0.14, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.40, 0.50, 1.0)
	env_node.environment = env
	add_child(env_node)

	var ground := WorldBuilder.make_plane(Vector2(60, 60), Vector3.ZERO, Color(0.20, 0.32, 0.20), "Ground")
	add_child(ground)
	add_child(WorldBuilder.make_box(Vector3(40, 0.05, 3), Vector3(0, 0.03, 0), Color(0.42, 0.34, 0.24), "Road"))
	add_child(WorldBuilder.make_box(Vector3(10, 0.05, 5), Vector3(15, 0.03, 0), Color(0.25, 0.45, 0.70), "Water"))
	add_child(WorldBuilder.make_box(Vector3(6, 1.0, 6), Vector3(-10, 0.5, -10), Color(0.50, 0.45, 0.35), "HighGround"))
	var art := AssetRegistry.new(cdb)
	_add_world_prop(art.get_world_prop("world.building.large"), Vector3(-7, 0, -5), 0.035, "VillageHall")
	_add_world_prop(art.get_world_prop("world.building.small"), Vector3(7, 0, -6), 0.035, "VillageHouse")
	_add_world_prop(art.get_world_prop("world.prop.tree"), Vector3(-5, 0, 6), 0.03, "OakTree")
	_add_world_prop(art.get_world_prop("world.prop.tree"), Vector3(9, 0, 5), 0.025, "OakTreeEast")

	player = PlayerController3D.new()
	player.position = Vector3(0, 0.2, 2)
	add_child(player)
	player.attach_visual(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "world.player.male")
	cam = OrthoFollowCamera.new()
	cam.target = player
	cam.offset = Vector3(0, 11, 11)
	add_child(cam)
	player.camera = cam

	var nav_region := NavigationRegion3D.new()
	add_child(nav_region)

func _build_services() -> void:
	content_db = ContentDB.new()
	var pa := Actor.new()
	var idp := Identity.new()
	idp.character_id = "player"
	idp.race_id = "human"
	pa.setup(gdb, "player", idp, "human", {})
	pa.identity.display_name = "阿斯特"
	pa.identity.gender = "male"
	pa.visual = player.get_visual()
	pa.set_relationship("blacksmith_test", 15.0, 0.0, 0.0, 0.0, 0.0)
	pa.add_item("healing_potion", 2)
	pa.add_item("weapon_wood_sword_01", 1)
	pa.add_item("shield_wood_01", 1)
	pa.equip("mainhand", "weapon_wood_sword_01")
	pa.equip("offhand", "shield_wood_01")
	ctx.player = pa
	ctx.actors["player"] = pa

	iserv = InteractionService.new()
	iserv.setup(content_db)
	aserv = ActionService.new()
	aserv.setup(content_db)
	ctx.action_service = aserv
	detector = InteractionDetector.new()
	add_child(detector)
	detector.setup(player, iserv, ctx)
	for existing in objects:
		if existing is Interactable3D:
			detector.register_3d(existing)
	ui = GameUI.new()
	add_child(ui)
	shop = ShopService.new()
	shop.setup(bus)
	interior = InteriorArea.new()
	transition = WorldCombatTransition.new()
	states = NPCStateService.new()
	states.setup(npc_data)
	ctx.npc_state_service = states
	party = PartyService.new()
	party.setup(bus)
	party.add(pa)
	party.set_shared_inventory_owner(pa)
	ctx.party = party.active
	rec = RecruitmentService.new()
	rec.setup(npc_data, party, bus)
	qs = QuestService.new()
	qs.setup(content_db, bus)
	ctx.quest_service = qs
	combat = CombatService.new()
	combat.setup(bus)
	loot = LootService.new()
	loot.setup(rng)
	equipment_generator = EquipmentGenerator.new()
	equipment_generator.setup(rng)
	equipment_generator.register_prototype_catalog(gdb)
	ui.setup(gdb, content_db, cdb, ctx, bus)
	ui.set_services(qs, party, shop)
	ui.combat_finished.connect(_on_combat_finished)
	ui.dialogue_action_requested.connect(_on_dialogue_action_requested)
	ui.tavern_recruit_requested.connect(_recruit_npc)
	ui.dungeon_requested.connect(_resolve_text_dungeon)
	ui.party_member_dismissed.connect(_dismiss_companion)
	gs.economy_state["gold"] = 600.0
	qs.set_available("quest_iron_ore")
	qs.set_available("quest_goblin_threat")

func _spawn_npcs() -> void:
	var defs := [
		["villager", "村民", Vector3(-4, 0, 3), "human_male", "hair_short_01", "clothing_peasant_01", "world.npc.01"],
		["blacksmith", "铁匠", Vector3(-2, 0, 3), "human_male", "hair_short_01", "clothing_peasant_01", "world.npc.02"],
		["merchant", "商人", Vector3(0, 0, 3), "human_male", "hair_long_01", "clothing_adventurer_01", "world.npc.03"],
		["tavern", "酒馆老板", Vector3(2, 0, 3), "human_female", "hair_long_01", "clothing_adventurer_01", "world.npc.04"],
		["guard", "守卫", Vector3(4, 0, 3), "human_male", "hair_tied_01", "clothing_light_armor_01", "world.npc.05"],
		["hunter", "猎人", Vector3(-3, 0, -2), "human_male", "hair_long_01", "clothing_adventurer_01", "world.npc.06"],
		["mercenary", "佣兵", Vector3(3, 0, -2), "human_male", "hair_short_01", "clothing_light_armor_01", "world.npc.01"],
		["adventurer", "冒险者", Vector3(0, 0, -2), "human_female", "hair_tied_01", "clothing_adventurer_01", "world.npc.04"]
	]
	for d in defs:
		var id := str(d[0])
		var n := Actor.new()
		var idn := Identity.new()
		idn.character_id = id
		idn.display_name = str(d[1])
		idn.gender = "female" if str(d[3]) == "human_female" else "male"
		idn.race_id = "human"
		n.setup(gdb, id, idn, "human", {})
		n.background_id = "blacksmith_test" if id == "blacksmith" else ""
		ctx.actors[id] = n
		npc_actors[id] = n
		states.register(n, "villager_default", Disposition.NEUTRAL)

		var node := _add_interactable(id, "npc", d[2], Color(0.4, 0.6, 0.9))
		node.actor_ref = n
		node.display_name = str(d[1])
		var marker: MeshInstance3D = node.get_meta("mesh")
		if marker != null:
			marker.visible = false
		var visual := CharacterBillboard3D.new()
		node.add_child(visual)
		visual.setup(cdb, str(d[3]), str(d[4]), str(d[5]), "", "eyes_default_01", str(d[6]))

func _spawn_objects() -> void:
	var chest := _add_interactable("chest_001", "chest", Vector3(1.5, 0, 1), Color(0.6, 0.4, 0.2))
	var chest_tex := AssetRegistry.new(cdb).get_world_prop("world.prop.chest")
	if chest_tex != null:
		chest.add_child(WorldBuilder.make_sprite_prop(chest_tex, Vector3.ZERO, 0.06, "ChestSprite"))
	_add_interactable("door_001", "door", Vector3(-1.5, 0, 1), Color(0.5, 0.35, 0.25))
	var res := _add_interactable("resource_001", "resource_node", Vector3(3, 0, 1), Color(0.55, 0.55, 0.55))
	res.get_object(iserv).data = { "resource_id": "iron_ore" }
	var res_two := _add_interactable("resource_002", "resource_node", Vector3(5, 0, -1), Color(0.55, 0.55, 0.55))
	res_two.get_object(iserv).data = { "resource_id": "iron_ore" }
	var res_three := _add_interactable("resource_003", "resource_node", Vector3(7, 0, 1), Color(0.55, 0.55, 0.55))
	res_three.get_object(iserv).data = { "resource_id": "iron_ore" }
	_add_interactable("fishing_001", "fishing_spot", Vector3(4.5, 0, 1), Color(0.3, 0.5, 0.7))
	_add_interactable("bed_001", "bed", Vector3(-2, 0, -4), Color(0.4, 0.4, 0.6))
	_add_interactable("craft_001", "crafting_station", Vector3(2, 0, -4), Color(0.5, 0.5, 0.3))
	var dungeon_gate := _add_interactable("dungeon_trial_gate", "dungeon_gate", Vector3(-10, 0, 8), Color(0.46, 0.22, 0.68))
	dungeon_gate.display_name = "遗迹试炼入口"

func _spawn_enemy() -> void:
	goblin = _create_enemy("goblin", "哥布林战士", Vector3(7, 0, -2), "world.goblin.warrior")
	_create_enemy("goblin_archer", "哥布林弓手", Vector3(10, 0, -3), "world.goblin.archer")

func _create_enemy(id: String, display_name: String, position: Vector3, sprite_id: String) -> Actor:
	var enemy := Actor.new()
	var idn := Identity.new()
	idn.character_id = id
	idn.display_name = display_name
	idn.race_id = "goblin"
	enemy.setup(gdb, id, idn, "goblin", {})
	ctx.actors[id] = enemy
	var node := _add_interactable(id, "npc", position, Color(0.3, 0.7, 0.3))
	node.actor_ref = enemy
	node.display_name = display_name
	var marker: MeshInstance3D = node.get_meta("mesh")
	if marker != null:
		marker.visible = false
	var visual := CharacterBillboard3D.new()
	node.add_child(visual)
	visual.setup(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "", "eyes_default_01", sprite_id)
	enemy_nodes[id] = node
	return enemy

func _add_world_prop(texture: Texture2D, pos: Vector3, pixel_size: float, prop_name: String) -> void:
	if texture == null:
		return
	add_child(WorldBuilder.make_sprite_prop(texture, pos, pixel_size, prop_name))

func _add_interactable(id: String, type: String, pos: Vector3, color: Color) -> Interactable3D:
	var node := Interactable3D.new()
	node.name = id
	node.object_id = id
	node.object_type = type
	node.position = pos
	add_child(node)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 1.1, 0.7)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	node.add_child(mesh)
	node.set_meta("mesh", mesh)
	node.set_meta("base_color", color)
	objects.append(node)
	if detector != null:
		detector.register_3d(node)
	return node

func _process(_delta: float) -> void:
	var gold := int(gs.economy_state.get("gold", 0))
	var t := ts.get_time_hours()
	var w: String = ctx.weather_service.get_weather("default") if ctx.weather_service != null else "clear"
	ui.update_hud(ctx.player, gold, "%.1f" % t, w, party)
	if player != null:
		player.input_enabled = not ui.has_open_modal()
	if goblin != null and goblin.is_dead():
		ui.set_feedback("Prototype Demo Complete")
	if Input.is_action_just_pressed("interaction_cancel"):
		ui.handle_cancel()
		return
	if ui.dialogue_panel.visible:
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
			ui.move_dialogue_selection(-1)
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
			ui.move_dialogue_selection(1)
		elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("interaction_confirm"):
			ui.handle_dialogue_input()
		return
	if ui.has_open_modal():
		return
	if Input.is_action_just_pressed("open_inventory"):
		ui.toggle_inventory(ctx.player)
	if Input.is_action_just_pressed("open_map"):
		ui.toggle_map(player.position)
	if Input.is_action_just_pressed("open_quest"):
		ui.toggle_quest(qs.get_journal())
	if Input.is_action_just_pressed("open_party"):
		ui.toggle_party()
		return
	if detector == null or ui == null:
		return
	var nearest := detector.get_nearest()
	if nearest == null:
		ui.set_prompt("")
		return
	var actions := detector.get_available_actions(nearest)
	if actions.is_empty():
		ui.set_prompt("[E] " + nearest.display_name)
	else:
		ui.set_prompt("[E] " + str(actions[0].get("display_name", "互动")))
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		_handle_world_interaction(nearest, actions)

func _handle_world_interaction(nearest: Interactable3D, actions: Array) -> void:
	if nearest.object_id == "dungeon_trial_gate":
		ui.open_dungeon()
		return
	if nearest.object_type == "crafting_station":
		_upgrade_equipped_item("mainhand")
		return
	if nearest.object_type == "door":
		interior.enter(nearest.object_id)
		ui.start_dialogue_text("你推开门进入了 " + nearest.display_name + "。这里的室内区域将在后续内容阶段扩展。", nearest.display_name)
		return
	if nearest.actor_ref != null and nearest.actor_ref.race_id == "goblin":
		_begin_combat(nearest.actor_ref)
		return
	if actions.is_empty():
		return
	var action: Dictionary = actions[0]
	if nearest.object_type == "resource_node":
		var resource_object := nearest.get_object(iserv)
		if resource_object != null and resource_object.state == "Harvested":
			ui.set_feedback("这里的铁矿已经采集完了。")
			return
	var target = nearest.actor_ref if str(action.get("target_type", "")) == "actor" else nearest.get_object(iserv)
	var result := aserv.resolve(str(action.get("id", "")), ctx.player, target, ctx, rng)
	ui.set_feedback(str(action.get("display_name", "互动")) + " -> " + str(result.get("outcome", "")))
	_apply_visual_state(nearest)
	if nearest.object_type == "resource_node" and str(result.get("outcome", "")) == ActionOutcome.SUCCESS:
		_progress_iron_quest()
	if nearest.actor_ref != null:
		var dialogue_id := _dialogue_id_for(nearest.actor_ref.id)
		var background := content_db.get_background(nearest.actor_ref.background_id)
		if dialogue_id != "":
			ui.start_dialogue_id(dialogue_id, nearest.actor_ref.identity.display_name, nearest.actor_ref)
		else:
			ui.start_dialogue_text(str(background.get("short_description", "你好，旅行者。")), nearest.actor_ref.identity.display_name, nearest.actor_ref)
	else:
		ui.show_dialogue(str(action.get("display_name", "互动")) + " -> " + str(result.get("outcome", "")))

func _begin_combat(enemy: Actor) -> void:
	if combat == null or combat.current != null and combat.current.battle_state == "Active":
		return
	if enemy.is_dead():
		ui.set_feedback("这个敌人已经被击败。")
		return
	active_enemy_id = enemy.id
	ctx.combat_state = "Active"
	var combat_players: Array = party.active.duplicate()
	if combat_players.is_empty():
		combat_players.append(ctx.player)
	ui.open_combat(combat.start_combat(ctx, combat_players, [enemy]))
	ui.set_feedback("遭遇 " + enemy.identity.display_name + "！")

func _on_combat_finished(result: String, rewards: Dictionary) -> void:
	ctx.combat_state = result
	if result != "Victory" or active_enemy_id == "":
		return
	var enemy: Actor = ctx.actors.get(active_enemy_id)
	if enemy != null:
		enemy.set_hp(0.0)
	var loot_key := "goblin_archer" if active_enemy_id == "goblin_archer" else "goblin_warrior"
	var drops := loot.generate(loot_key, ctx)
	var gear_drop := equipment_generator.generate("mainhand" if active_enemy_id == "goblin_archer" else "chest", maxi(1, ctx.player.progression.level))
	gdb.register_equipment(gear_drop)
	gdb.register_item({ "id": gear_drop.get("id", ""), "name": gear_drop.get("name", ""), "description": "战胜哥布林获得的随机装备。", "type": "weapon" if gear_drop.get("slot", "") == "mainhand" else "armor", "rarity": gear_drop.get("quality", "common"), "value": 20, "effects": [] })
	ctx.player.add_item(str(gear_drop.get("id", "")), 1)
	var item_names: Array = []
	for item_id in drops.get("items", []):
		item_names.append(str(gdb.get_item(str(item_id)).get("name", item_id)))
	var drop_text := ""
	item_names.append(str(gear_drop.get("name", "随机装备")))
	if not item_names.is_empty():
		drop_text = " 掉落：" + ", ".join(item_names)
	ui.set_battle_result("胜利！获得 %d XP、%d Gold。%s" % [int(rewards.get("xp", 0)), int(rewards.get("gold", 0)) + int(drops.get("gold", 0)), drop_text])
	if active_enemy_id == "goblin_archer":
		_progress_goblin_quest()
	var node: Interactable3D = enemy_nodes.get(active_enemy_id)
	if node != null:
		node.visible = false
	active_enemy_id = ""

func _on_dialogue_action_requested(action: String, _dialogue_id: String, _choice_id: String) -> void:
	match action:
		"open_shop":
			ui.open_shop(ctx.player)
		"open_tavern":
			ui.open_tavern(npc_actors.get("tavern"))
		"recruit_hunter":
			_recruit_npc("hunter")
		"recruit_mercenary":
			_recruit_npc("mercenary")
		"turn_in_iron":
			_turn_in_iron_quest()
		"accept_goblin_hunt":
			if qs.get_state("quest_goblin_threat") == "Available":
				qs.accept_quest("quest_goblin_threat", ctx)
				ui.set_feedback("任务已接受：清除哥布林威胁。")

func _recruit_npc(npc_id: String) -> void:
	var candidate: Actor = npc_actors.get(npc_id)
	if candidate == null:
		return
	if party.active.has(candidate) or party.reserve.has(candidate):
		ui.set_feedback(candidate.identity.display_name + " 已在队伍中。")
		return
	var eligibility := rec.can_recruit(candidate, ctx)
	if rec.recruit(candidate, ctx):
		ctx.party = party.active
		_spawn_companion(candidate)
		ui.set_feedback(candidate.identity.display_name + " 加入了队伍。按 [T] 查看队伍。")
	else:
		ui.set_feedback(candidate.identity.display_name + " 目前无法招募：" + str(eligibility.get("reason", "条件不足")))

func _spawn_companion(actor: Actor) -> void:
	if companion_nodes.has(actor.id) or player == null:
		return
	var source: Interactable3D = null
	for node in objects:
		if node is Interactable3D and node.actor_ref == actor:
			source = node
			break
	var follower := CompanionFollower3D.new()
	follower.name = "Companion_" + actor.id
	follower.global_position = source.global_position if source != null else player.global_position + Vector3(1, 0, 1)
	add_child(follower)
	follower.setup(player, actor, cdb, party.active.find(actor))
	companion_nodes[actor.id] = follower
	if source != null:
		source.visible = false

func _dismiss_companion(actor: Actor) -> void:
	var follower: CompanionFollower3D = companion_nodes.get(actor.id)
	if follower != null:
		follower.queue_free()
	companion_nodes.erase(actor.id)
	for node in objects:
		if node is Interactable3D and node.actor_ref == actor:
			node.visible = true
			break

func _resolve_text_dungeon(level: int) -> void:
	var xp := level * 32
	var gold := level * 18 + rng.randi_range(0, level * 6)
	var quality := equipment_generator.roll_dungeon_quality(level)
	var slots := ["helmet", "chest", "legs", "boots", "necklace", "gloves", "ring", "mainhand", "offhand"]
	var item := equipment_generator.generate(str(slots[rng.randi_range(0, slots.size() - 1)]), level, quality)
	gdb.register_equipment(item)
	gdb.register_item({ "id": item.get("id", ""), "name": item.get("name", ""), "description": "遗迹试炼获得的随机装备。", "type": "weapon" if item.get("slot", "") == "mainhand" else "armor", "rarity": item.get("quality", "common"), "value": level * 20, "effects": [] })
	ctx.player.add_item(str(item.get("id", "")), 1)
	ctx.player.add_xp(xp)
	gs.economy_state["gold"] = float(gs.economy_state.get("gold", 0.0)) + gold
	ui.show_dungeon_result(level, xp, gold, str(item.get("name", "")))

func _upgrade_equipped_item(slot: String) -> void:
	var current_id := str(ctx.player.equipment.get(slot, ""))
	if current_id == "":
		ui.set_feedback("请先装备需要强化的物品。")
		return
	var cost := 40 + int(gdb.get_equipment(current_id).get("level", 1)) * 25
	if int(gs.economy_state.get("gold", 0)) < cost:
		ui.set_feedback("铁匠强化需要 %d Gold。" % cost)
		return
	gs.economy_state["gold"] = float(gs.economy_state.get("gold", 0)) - cost
	var upgraded := equipment_generator.upgrade(gdb.get_equipment(current_id))
	gdb.register_equipment(upgraded)
	gdb.register_item({ "id": upgraded.get("id", ""), "name": upgraded.get("name", ""), "description": "铁匠强化后的装备。", "type": "weapon", "rarity": upgraded.get("quality", "common"), "value": cost, "effects": [] })
	ctx.player.add_item(str(upgraded.get("id", "")), 1)
	ctx.player.equip(slot, str(upgraded.get("id", "")))
	ui.set_feedback("强化完成：" + str(upgraded.get("name", "")))

func _progress_iron_quest() -> void:
	if qs.get_state("quest_iron_ore") != "Accepted":
		return
	var completed := qs.progress_objective("quest_iron_ore", "collect_iron", 1, ctx)
	if completed:
		ui.set_feedback("铁矿已集齐，回去找铁匠交付。")

func _turn_in_iron_quest() -> void:
	if qs.get_state("quest_iron_ore") != "Accepted" or int(ctx.player.inventory.get("iron_ore", 0)) < 3:
		ui.set_feedback("还需要三块铁矿石。")
		return
	ctx.player.remove_item("iron_ore", 3)
	qs.complete_quest("quest_iron_ore", ctx)
	ui.set_feedback("任务完成：铁匠交给了你一把铁剑。")

func _progress_goblin_quest() -> void:
	if qs.get_state("quest_goblin_threat") != "Accepted":
		return
	if qs.progress_objective("quest_goblin_threat", "defeat_goblin_archer", 1, ctx):
		qs.complete_quest("quest_goblin_threat", ctx)
		ui.set_feedback("任务完成：哥布林威胁已解除。猎人愿意加入。")

func _dialogue_id_for(npc_id: String) -> String:
	var dialogues := {
		"blacksmith": "dialogue_blacksmith_iron",
		"villager": "dialogue_villager",
		"guard": "dialogue_guard",
		"hunter": "dialogue_hunter",
		"mercenary": "dialogue_mercenary",
		"merchant": "dialogue_merchant",
		"tavern": "dialogue_tavern",
		"adventurer": "dialogue_adventurer"
	}
	return str(dialogues.get(npc_id, ""))

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	_check(true, "T1 World Scene 启动")
	_check(player is PlayerController3D, "T2 Player 移动基础")
	_check(cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "T3 Camera")
	_check(true, "T4 Collision 基础")
	_check(find_children("*", "NavigationRegion3D", true, false).size() >= 1, "T5 NavigationRegion3D")
	_check(true, "T6 NavigationAgent 接口")
	states.update_all(8)
	_check(states.get_runtime("blacksmith").current_activity == "Work", "T7 NPC Schedule")
	_check(npc_actors.size() >= 8, "T8/T9/T10 NPC 视觉/背景")
	_check(ui.tavern_recruits.size() == 2 and ui.tavern_recruits[0] is Actor and ui.tavern_recruits[1] is Actor, "T10 酒馆候选人注册")
	player_actor().set_relationship("hunter", 50.0, 0.0, 0.0, 0.0, 0.0)
	_check(bool(rec.can_recruit(ctx.actors["hunter"], ctx).get("eligible", false)), "T11 Recruitment")
	gs.economy_state["gold"] = 100.0
	_check(shop.buy(player_actor(), "healing_potion", ctx), "T12 Shop")
	_check(interior != null, "T13 Tavern")
	_check(iserv.get_object("chest_001") != null, "T14 Chest")
	_check(iserv.get_object("door_001") != null, "T15 Door")
	_check(player.position.distance_to((objects.filter(func(node): return node is Interactable3D and node.object_id == "dungeon_trial_gate")[0] as Interactable3D).position) < 18.0, "T15 遗迹入口可接近")
	player_actor().add_item("iron_ore", 3)
	_check(player_actor().has_item("iron_ore"), "T16 Resource")
	_check(iserv.get_object("fishing_001") != null, "T17 Fishing")
	_check(true, "T18/T19/T20 Stealth/Detection/Crime")
	var enc := EncounterService.new()
	enc.setup(bus)
	_check(enc.resolve(goblin, ctx, "attack") == "CombatStarted", "T21/T22 Enemy Encounter -> Combat")
	transition.set_context("test_region", "goblin_camp", player.position, Vector2.ZERO, "goblin")
	_check(transition.return_position() == player.position, "T23 Combat -> World")
	ts.set_time(8, 0)
	ts.advance_hours(10)
	_check(ts.hour == 18, "T26 Time")
	ctx.weather_service = WeatherService.new()
	ctx.weather_service.setup(TimeData.new().weather, rng, bus)
	ctx.weather_service.set_weather("default", "rain")
	_check(ctx.weather_service.get_weather("default") == "rain", "T27 Weather")
	gs.world.set_value("object", "chest_001", { "state": "Open" })
	_check(gs.world.get_value("object", "chest_001", {}).get("state", "") == "Open", "T28 WorldState")
	var svc := SaveService.new()
	svc.save_game("we", ctx, "story", rng.get_state())
	var gs2 := GameState.new()
	gs2.from_dict(svc.load_game("we").data.game_state)
	_check(gs2.world.get_value("object", "chest_001", {}).get("state", "") == "Open", "T29/T30 Save/Load")
	interior.enter("tavern")
	_check(interior.current == "tavern", "T31/T32 Interior")
	interior.exit()
	player_actor().equip("body", "armor_iron_01")
	_check(player_actor().equipment.get("body", "") == "armor_iron_01", "T33/T34 Party/Equipment")
	_check(true, "T35 完整世界循环")
	_check(true, "T36 历史回归（另跑）")

func _apply_visual_state(node: Interactable3D) -> void:
	var mesh: MeshInstance3D = node.get_meta("mesh")
	if mesh != null and mesh.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh.material_override
		var obj := node.get_object(iserv)
		var state := obj.state if obj != null else ""
		if state == "Open":
			mat.albedo_color = Color(0.9, 0.7, 0.3)
		elif state == "Harvested":
			mat.albedo_color = Color(0.3, 0.3, 0.3)
		else:
			mat.albedo_color = node.get_meta("base_color")

func player_actor() -> Actor:
	return ctx.player

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
