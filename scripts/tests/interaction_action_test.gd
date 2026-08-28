extends Node

## Interaction / Action / Outcome 基础系统测试。
var content: ContentDB
var gdb: GameplayDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var npc: Actor
var rng: RNGService
var ts: TimeService
var ws: WeatherService
var bus: EventBus
var iserv: InteractionService
var aserv: ActionService
var dserv: DialogueService
var validation_failures: int = 0

func _ready() -> void:
	content = ContentDB.new()
	gdb = GameplayDB.new()
	bus = EventBus.new()

	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus

	var idp := Identity.new()
	idp.character_id = "player"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(gdb, "player", idp, "human", {})
	ctx.player = player
	ctx.actors["player"] = player

	var idn := Identity.new()
	idn.character_id = "npc_test"
	idn.race_id = "human"
	npc = Actor.new()
	npc.setup(gdb, "npc_test", idn, "human", {})
	ctx.actors["npc_test"] = npc
	player.set_relationship("npc_test", 5.0, 0.0, 0.0, 0.0, 0.0)

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

	_register_objects()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _register_objects() -> void:
	var chest := InteractableObject.new()
	chest.id = "chest"
	chest.object_type = "chest"
	chest.state = "Closed"
	iserv.register(chest)

	var door := InteractableObject.new()
	door.id = "door"
	door.object_type = "door"
	door.state = "Closed"
	iserv.register(door)

	var node := InteractableObject.new()
	node.id = "iron_node"
	node.object_type = "resource_node"
	node.state = "Available"
	node.data = { "resource_id": "iron_ore" }
	iserv.register(node)

	var spot := InteractableObject.new()
	spot.id = "lake_spot"
	spot.object_type = "fishing_spot"
	spot.state = "Idle"
	spot.data = content.get_fishing_spot("lake_spot")
	iserv.register(spot)

	var bed := InteractableObject.new()
	bed.id = "bed"
	bed.object_type = "bed"
	bed.state = "Idle"
	iserv.register(bed)

	var station := InteractableObject.new()
	station.id = "crafting_station"
	station.object_type = "crafting_station"
	station.state = "Idle"
	iserv.register(station)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1 发现目标 / T2 Actions 生成
	var chest := iserv.get_object("chest")
	_check(chest != null, "T1 Interaction 发现目标")
	ts.set_time(20, 0)
	var chest_actions := iserv.get_available_actions(chest, ctx)
	_check(chest_actions.size() == 4, "T2 Interaction Actions 生成")

	# T3 Condition 过滤（break 需要 level>=5）
	var door := iserv.get_object("door")
	var door_actions := iserv.get_available_actions(door, ctx)
	_check(not _has_action(door_actions, "break"), "T3 Condition 过滤 Action")
	player.progression.level = 5
	door_actions = iserv.get_available_actions(door, ctx)
	_check(_has_action(door_actions, "break"), "T3 Condition 放行 Action")

	# T4 Action 执行 / T8 Outcome / T10 Event
	var action_completed := [0]
	bus.subscribe("action_completed", func(_p): action_completed[0] += 1)
	var r := aserv.resolve("inspect", player, chest, ctx, rng)
	_check(r.get("outcome", "") == ActionOutcome.SUCCESS, "T4/T8 Action 执行与 Outcome")
	_check(action_completed[0] == 1, "T10 Action Event")

	# T5 Effect / T12 Chest Open / T19 Object State
	aserv.resolve("open", player, chest, ctx, rng)
	_check(chest.state == "Open", "T5/T12 Chest Open")
	_check(gs.story_flags.get_flag("opened_target"), "T5 Effect 执行")
	_check(gs.world.get_value("object", "chest", {}).get("state", "") == "Open", "T19 Object State 保存")

	# T6 Time Cost / T13 Door Lockpick
	ts.set_time(8, 0)
	aserv.resolve("lockpick", player, door, ctx, rng)
	_check(ts.minute == 5, "T6/T13 Lockpick Time Cost")

	# T9 Animation 接口
	var talk_def := content.get_action("talk")
	_check(str(talk_def.get("animation", "")) != "", "T9 Animation 接口")

	# T11 NPC Talk
	aserv.resolve("talk", player, npc, ctx, rng)
	_check(gs.story_flags.get_flag("talked_to_target"), "T11 NPC Talk")

	# T14 Resource Harvest
	var node := iserv.get_object("iron_node")
	aserv.resolve("harvest", player, node, ctx, rng)
	_check(node.state == "Harvested" and player.has_item("iron_ore"), "T14 Resource Harvest")

	# T15 Fishing
	var spot := iserv.get_object("lake_spot")
	var fish_before := _inventory_fish(player)
	ts.set_time(8, 0)
	aserv.resolve("fish", player, spot, ctx, rng)
	_check(_inventory_fish(player) > fish_before, "T15 Fishing")
	_check(ts.minute == 30, "T15 Fishing Time")

	# T16 Steal（时间条件 >=18）
	ts.set_time(12, 0)
	var blocked := aserv.resolve("steal", player, chest, ctx, rng)
	_check(blocked.get("outcome", "") == ActionOutcome.BLOCKED, "T23 Time 条件阻止")
	ts.set_time(20, 0)
	var steal_r := aserv.resolve("steal", player, chest, ctx, rng)
	_check(steal_r.get("outcome", "") == ActionOutcome.SUCCESS or steal_r.get("outcome", "") == ActionOutcome.DETECTED, "T16 Steal")

	# T17 Persuade
	player.set_relationship("npc_test", 5.0, 0.0, 0.0, 0.0, 0.0)
	var aff0 := float(player.relationships["npc_test"].get("affinity"))
	var per := aserv.resolve("persuade", player, npc, ctx, rng)
	if per.get("outcome", "") == ActionOutcome.SUCCESS:
		_check(float(player.relationships["npc_test"].get("affinity")) > aff0, "T17 Persuade 成功")

	# T18 Sleep
	var bed := iserv.get_object("bed")
	ts.set_time(8, 0)
	aserv.resolve("sleep", player, bed, ctx, rng)
	_check(bed.state == "Active" and gs.story_flags.get_flag("slept"), "T18 Sleep")

	# T20 Quest 监听 Action
	var quest_heard := [false]
	bus.subscribe("action_completed", func(p): if str(p.get("action_id", "")) == "close": quest_heard[0] = true)
	aserv.resolve("close", player, chest, ctx, rng)
	_check(quest_heard[0], "T20 Quest 监听 Action")

	# T21 Dialogue 触发 Action
	ts.set_time(8, 0)
	var ok := dserv.execute_choice("dialogue_persuade", "persuade", ctx)
	_check(ok and ts.minute == 5, "T21 Dialogue 触发 Action")

	# T22 Save/Load Interaction State
	var svc := SaveService.new()
	svc.save_game("ia", ctx, "story", rng.get_state())
	var lr := svc.load_game("ia")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(gs2.world.get_value("object", "chest", {}).get("state", "") == "Closed", "T22 Save/Load Interaction State")

func _has_action(arr: Array, aid: String) -> bool:
	for a in arr:
		if str(a.get("id", "")) == aid:
			return true
	return false

func _inventory_fish(a: Actor) -> int:
	var total := 0
	for key in a.inventory:
		if str(key).begins_with("fish_"):
			total += int(a.inventory[key])
	return total

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1

