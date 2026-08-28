extends Node3D

## World Interaction Bridge + Interaction UI 集成测试场景。
var content: ContentDB
var gdb: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var player: PlayerController3D
var npc: Actor
var rng: RNGService
var ts: TimeService
var ws: WeatherService
var bus: EventBus
var iserv: InteractionService
var aserv: ActionService
var dserv: DialogueService
var qs: QuestService
var detector: InteractionDetector
var ui: InteractionUI
var svc: SaveService
var validation_failures: int = 0

var chest: Interactable3D
var door: Interactable3D
var resource: Interactable3D
var fishing: Interactable3D
var npc_node: Interactable3D

func _ready() -> void:
	content = ContentDB.new()
	gdb = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	bus = EventBus.new()

	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus

	var idp := Identity.new()
	idp.character_id = "player"
	idp.race_id = "human"
	var pa := Actor.new()
	pa.setup(gdb, "player", idp, "human", {})
	ctx.player = pa
	ctx.actors["player"] = pa

	npc = Actor.new()
	var idn := Identity.new()
	idn.character_id = "npc_test"
	idn.race_id = "human"
	npc.setup(gdb, "npc_test", idn, "human", {})
	npc.background_id = "blacksmith_test"
	ctx.actors["npc_test"] = npc
	pa.set_relationship("npc_test", 5.0, 0.0, 0.0, 0.0, 0.0)

	var td := TimeData.new()
	var cal := CalendarService.new()
	cal.setup(td.calendar)
	ts = TimeService.new()
	ts.setup(cal, bus)
	ctx.time_service = ts
	rng = RNGService.new()
	rng.set_seed(42)
	ctx.rng = rng
	ws = WeatherService.new()
	ws.setup(td.weather, rng, bus)
	ctx.weather_service = ws

	iserv = InteractionService.new()
	iserv.setup(content)
	aserv = ActionService.new()
	aserv.setup(content)
	ctx.action_service = aserv
	dserv = DialogueService.new()
	dserv.setup(content)
	qs = QuestService.new()
	qs.setup(content, bus)
	ctx.quest_service = qs
	svc = SaveService.new()

	_build_world()
	_build_detector_ui()

	qs.set_available("quest_collect_iron")
	qs.accept_quest("quest_collect_iron", ctx)
	bus.subscribe("action_completed", func(p): _on_action_completed(p))

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
	env.ambient_light_color = Color(0.35, 0.4, 0.5, 1.0)
	env_node.environment = env
	add_child(env_node)

	var ground := StaticBody3D.new()
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(40, 0.2, 40)
	gshape.shape = gbox
	ground.add_child(gshape)
	var gmesh := MeshInstance3D.new()
	var gp := PlaneMesh.new()
	gp.size = Vector2(40, 40)
	gmesh.mesh = gp
	ground.add_child(gmesh)
	add_child(ground)

	player = PlayerController3D.new()
	player.position = Vector3(0, 0.2, 4)
	add_child(player)
	player.attach_visual(cdb, "human_male", "hair_short_01", "clothing_peasant_01")
	player.camera = null

	npc_node = _add_interactable("npc_001", "npc", Vector3(0, 0, 1), Color(0.4, 0.6, 0.9))
	npc_node.actor_ref = npc
	chest = _add_interactable("chest_001", "chest", Vector3(1.5, 0, 1), Color(0.6, 0.4, 0.2))
	door = _add_interactable("door_001", "door", Vector3(-1.5, 0, 1), Color(0.5, 0.35, 0.25))
	resource = _add_interactable("resource_001", "resource_node", Vector3(3, 0, 1), Color(0.5, 0.5, 0.5))
	fishing = _add_interactable("fishing_001", "fishing_spot", Vector3(4.5, 0, 1), Color(0.3, 0.5, 0.7))

func _add_interactable(id: String, type: String, pos: Vector3, color: Color) -> Interactable3D:
	var node := Interactable3D.new()
	node.name = id
	node.object_id = id
	node.object_type = type
	node.position = pos
	add_child(node)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 1.2, 0.8)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	node.add_child(mesh)
	return node

func _build_detector_ui() -> void:
	detector = InteractionDetector.new()
	add_child(detector)
	detector.setup(player, iserv, ctx)
	for n in [npc_node, chest, door, resource, fishing]:
		detector.register_3d(n)
	ui = InteractionUI.new()
	add_child(ui)
	ui.set_hud("Time:08:00 Weather:clear Gold:0")

func _on_action_completed(p) -> void:
	if str(p.get("action_id", "")) == "harvest" and qs.get_state("quest_collect_iron") == "Accepted":
		var done := qs.progress_objective("quest_collect_iron", "harvest_iron", 1, ctx)
		if done:
			qs.complete_quest("quest_collect_iron", ctx)

func _execute(node: Interactable3D, action_id: String) -> Dictionary:
	var def := content.get_action(action_id)
	var target = node.actor_ref if str(def.get("target_type", "")) == "actor" else node.get_object(iserv)
	var r := aserv.resolve(action_id, ctx.player, target, ctx, rng)
	ui.set_feedback(_outcome_text(str(r.get("outcome", ""))))
	if action_id == "talk":
		_talk_to_npc()
	elif action_id == "inspect" and node.actor_ref != null:
		_inspect_npc()
	return r

func _talk_to_npc() -> void:
	var dia := dserv.get_dialogue("dialogue_persuade")
	ui.set_feedback("Talk: " + str(dia.get("text", "")))

func _inspect_npc() -> void:
	var bg := content.get_background(npc.background_id)
	ui.set_feedback(str(bg.get("short_description", "")))

func _outcome_text(outcome: String) -> String:
	match outcome:
		ActionOutcome.SUCCESS:
			return "成功"
		ActionOutcome.FAILURE:
			return "失败"
		ActionOutcome.DETECTED:
			return "被发现了"
		ActionOutcome.BLOCKED:
			return "无法执行"
		ActionOutcome.CRITICAL_SUCCESS:
			return "完美成功"
		ActionOutcome.CRITICAL_FAILURE:
			return "严重失败"
		_:
			return "行动被打断"

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1/T2 注册与桥接
	_check(detector.nodes.size() >= 5, "T1 注册 Interactable3D")
	_check(chest.get_object(iserv) != null, "T2 Gameplay/Visual Bridge")

	# T3 附近检测
	player.position = Vector3(1.5, 0.2, 1)
	await get_tree().process_frame
	_check(detector.get_nearest() == chest, "T3 获取附近 Interactable")

	# T4/T5 Action 列表与条件过滤
	var actions := detector.get_available_actions(chest)
	_check(actions.size() >= 3, "T4 Action 列表")
	ctx.player.progression.level = 1
	var door_actions := detector.get_available_actions(door)
	_check(not _has(door_actions, "break"), "T5 Condition 过滤")

	# T6/T7 Prompt 与 Menu
	ui.set_prompt("[E] 打开")
	_check(ui.prompt.visible, "T6 Interaction Prompt")
	ui.show_menu(actions, func(_a): pass)
	_check(ui.menu_buttons.size() == actions.size(), "T7 Action Menu")
	ui.hide_menu()

	# T8 NPC Talk / T9 NPC Inspect
	_execute(npc_node, "talk")
	_check(ui.feedback.text.begins_with("Talk:"), "T8 NPC Talk")
	_execute(npc_node, "inspect")
	_check(ui.feedback.text != "", "T9 NPC Inspect")

	# T10 Chest Open / T22 Object State
	_execute(chest, "open")
	_check(chest.get_object(iserv).state == "Open", "T10 Chest Open")
	_check(gs.world.get_value("object", "chest_001", {}).get("state", "") == "Open", "T22 Object State 保存")

	# T11 Chest Steal（需要时间>=18）
	ts.set_time(20, 0)
	var sr := _execute(chest, "steal")
	_check(sr.get("outcome", "") == ActionOutcome.SUCCESS or sr.get("outcome", "") == ActionOutcome.DETECTED, "T11 Chest Steal")

	# T12 Door Open / T13 Door Lockpick
	_execute(door, "open")
	_check(door.get_object(iserv).state == "Open", "T12 Door Open")
	ts.set_time(8, 0)
	var lock_r := _execute(door, "lockpick")
	_check(lock_r.has("outcome"), "T13 Door Lockpick")

	# T14 Resource Harvest
	var q0 := int(qs.quests["quest_collect_iron"]["objectives"]["harvest_iron"])
	_execute(resource, "harvest")
	_check(resource.get_object(iserv).state == "Harvested", "T14 Resource Harvest")
	_check(int(qs.quests["quest_collect_iron"]["objectives"]["harvest_iron"]) > q0, "T20 Quest 监听 Action")

	# T15 Fishing
	ts.set_time(8, 0)
	var fish_before := _fish_count()
	_execute(fishing, "fish")
	_check(_fish_count() > fish_before, "T15 Fishing")

	# T16 Animation 接口
	_check(str(content.get_action("talk").get("animation", "")) != "", "T16 Action Animation 接口")

	# T17 Time Cost
	ts.set_time(8, 0)
	_execute(door, "lockpick")
	_check(ts.minute == 5, "T17 Time Cost")

	# T18/T19 Outcome 反馈与 Event
	var count := [0]
	bus.subscribe("action_completed", func(_p): count[0] += 1)
	_execute(chest, "inspect")
	_check(ui.feedback.text != "", "T18 Outcome 反馈")
	_check(count[0] >= 1, "T19 Action Event")

	# T21 Dialogue 触发 Action
	ts.set_time(8, 0)
	dserv.execute_choice("dialogue_persuade", "persuade", ctx)
	_check(ts.minute == 5, "T21 Dialogue 触发 Action")

	# T23 Save/Load Object State
	svc.save_game("wi", ctx, "story", rng.get_state())
	var lr := svc.load_game("wi")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(gs2.world.get_value("object", "chest_001", {}).get("state", "") == "Open", "T23 Object State Load")

func _has(arr: Array, aid: String) -> bool:
	for a in arr:
		if str(a.get("id", "")) == aid:
			return true
	return false

func _fish_count() -> int:
	var t := 0
	for k in ctx.player.inventory:
		if str(k).begins_with("fish_"):
			t += int(ctx.player.inventory[k])
	return t

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1





