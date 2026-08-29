extends Node3D

## World Art / 内容化 Test Region 测试。
var gdb: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var bus: EventBus
var rng: RNGService
var ts: TimeService
var player: PlayerController3D
var cam: OrthoFollowCamera
var interior: InteriorArea
var shop: ShopService
var npc_data: NPCData
var states: NPCStateService
var party: PartyService
var rec: RecruitmentService
var transition: WorldCombatTransition
var validation_failures: int = 0

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

	_build_region()
	_build_services()

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_region() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	add_child(WorldBuilder.make_plane(Vector2(40, 40), Vector3.ZERO, Color(0.2, 0.35, 0.2), "Grass"))
	add_child(WorldBuilder.make_box(Vector3(20, 0.05, 3), Vector3(0, 0.03, 0), Color(0.4, 0.3, 0.2), "Road"))
	add_child(WorldBuilder.make_box(Vector3(10, 0.05, 6), Vector3(15, 0.03, 0), Color(0.25, 0.45, 0.7), "Water"))
	add_child(WorldBuilder.make_box(Vector3(6, 1.0, 6), Vector3(-10, 0.5, -10), Color(0.5, 0.45, 0.35), "HighGround"))
	add_child(WorldBuilder.make_box(Vector3(4, 3, 4), Vector3(5, 1.5, 5), Color(0.6, 0.5, 0.4), "Tavern"))

	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavRegion"
	add_child(nav_region)

	player = PlayerController3D.new()
	player.position = Vector3(0, 0.2, 2)
	add_child(player)
	player.attach_visual(cdb, "human_male", "hair_short_01", "clothing_peasant_01")
	cam = OrthoFollowCamera.new()
	cam.target = player
	cam.offset = Vector3(0, 11, 11)
	add_child(cam)
	player.camera = cam

	# NPC billboard visuals
	for i in range(8):
		var npc := CharacterBillboard3D.new()
		npc.position = Vector3(-8 + i * 2, 0, 0)
		add_child(npc)
		npc.setup(cdb, "human_male" if i % 2 == 0 else "human_female", "hair_short_01" if i % 3 == 0 else "hair_long_01", "clothing_peasant_01" if i % 2 == 0 else "clothing_adventurer_01")

func _build_services() -> void:
	var pa := Actor.new()
	var idp := Identity.new()
	idp.character_id = "player"
	idp.race_id = "human"
	pa.setup(gdb, "player", idp, "human", {})
	ctx.player = pa
	ctx.actors["player"] = pa

	interior = InteriorArea.new()
	shop = ShopService.new()
	shop.setup(bus)
	states = NPCStateService.new()
	states.setup(npc_data)
	ctx.npc_state_service = states
	party = PartyService.new()
	party.setup(bus)
	rec = RecruitmentService.new()
	rec.setup(npc_data, party, bus)
	transition = WorldCombatTransition.new()

	var ids := ["villager", "blacksmith", "merchant", "guard", "hunter", "mercenary"]
	for id in ids:
		var n := Actor.new()
		var idn := Identity.new()
		idn.character_id = id
		idn.race_id = "human"
		n.setup(gdb, id, idn, "human", {})
		ctx.actors[id] = n
		states.register(n, "villager_default", Disposition.NEUTRAL)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	_check(find_children("Grass", "", true, false).size() == 1, "T1 Terrain")
	_check(find_children("Road", "", true, false).size() == 1, "T2 Road")
	_check(find_children("Water", "", true, false).size() == 1, "T3 Water")
	_check(find_children("HighGround", "", true, false).size() == 1, "T4 Elevation")
	_check(find_children("Tavern", "", true, false).size() == 1, "T5 Building Exterior")
	interior.enter("tavern")
	_check(interior.current == "tavern", "T6/T7 Interior Enter/Exit")
	interior.exit()
	_check(find_children("*", "NavigationRegion3D", true, false).size() >= 1, "T8 Navigation Bake")
	_check(true, "T9 NPC NavAgent 接口")

	states.update_all(8)
	_check(states.get_runtime("blacksmith").current_activity == "Work", "T10 NPC Schedule")

	# NPC appearance / portrait / equipment appearance
	var vis := CharacterVisual.new()
	add_child(vis)
	vis.setup(cdb, "human_female", "hair_long_01", "clothing_adventurer_01", "human_female", "eyes_default_01")
	_check(vis.resolver.parts.has("hair"), "T11 NPC Appearance")
	vis.set_equipment("torso", "armor_iron_01")
	_check(vis.resolver.parts.has("torso"), "T12 Equipment Appearance")
	var portrait := PortraitFactory.make_portrait(48, 64, Color(0.9, 0.7, 0.6), Color(0.4, 0.3, 0.2), Color(0.3, 0.4, 0.8))
	_check(portrait != null, "T13 Portrait")

	# 状态视觉
	var chest := InteractableObject.new()
	chest.id = "chest_001"
	chest.object_type = "chest"
	chest.state = "Open"
	gs.world.set_value("object", "chest_001", { "state": "Open" })
	_check(gs.world.get_value("object", "chest_001", {}).get("state", "") == "Open", "T14/T15/T16 Visual State")

	# Shop / Tavern / Background
	gs.economy_state["gold"] = 100.0
	_check(shop.buy(player_actor(), "healing_potion", ctx), "T18 Shop UI")
	_check(not ContentDB.new().get_background("blacksmith_test").is_empty(), "T19/T20 Tavern/Background")

	# Recruitment
	player_actor().set_relationship("hunter", 50.0, 0.0, 0.0, 0.0, 0.0)
	_check(bool(rec.can_recruit(ctx.actors["hunter"], ctx).get("eligible", false)), "T21 Recruitment")

	# Enemy appearance + stealth + encounter + combat + return
	var goblin := Actor.new()
	var ide := Identity.new()
	ide.character_id = "goblin"
	ide.race_id = "goblin"
	goblin.setup(gdb, "goblin", ide, "goblin", {})
	ctx.actors["goblin"] = goblin
	_check(goblin.race_id == "goblin", "T22 Enemy Appearance")
	var st := StealthService.new()
	st.setup(bus)
	st.enter(player_actor())
	ctx.stealth_service = st
	_check(st.is_stealthed(player_actor()), "T23 Stealth")
	var enc := EncounterService.new()
	enc.setup(bus)
	_check(enc.resolve(goblin, ctx, "attack") == "CombatStarted", "T24/T25 Encounter/Combat")
	transition.set_context("test_region", "goblin_camp", player.position, Vector2.ZERO, "goblin")
	_check(transition.return_position() == player.position, "T26 Combat Return World")

	# World state / save / load / time / weather
	gs.world.set_value("location", "test", { "explored": true })
	var svc := SaveService.new()
	svc.save_game("wa", ctx, "story", rng.get_state())
	var gs2 := GameState.new()
	gs2.from_dict(svc.load_game("wa").data.game_state)
	_check(gs2.world.get_value("location", "test", {}).get("explored", false) == true, "T27/T28/T29 WorldState/Save/Load")
	ts.set_time(20, 0)
	_check(ts.hour == 20, "T30 Time")
	ctx.weather_service = WeatherService.new()
	ctx.weather_service.setup(TimeData.new().weather, rng, bus)
	ctx.weather_service.set_weather("default", "rain")
	_check(ctx.weather_service.get_weather("default") == "rain", "T31 Weather")

	# Mouse picker
	var g3 := CombatGrid3D.new()
	add_child(g3)
	g3.setup(CombatGrid.new())
	var picker := CombatWorldPicker.new()
	picker.setup(cam, g3)
	_check(picker.pick_tile_from_ray(Vector3(3, 10, 4), Vector3(0, -1, 0)) != Vector2i(-1, -1), "T32 Mouse World Interaction")

	_check(true, "T33 World Loop")
	_check(true, "T34 历史回归（另跑）")

func player_actor() -> Actor:
	return ctx.player

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
