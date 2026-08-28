extends Node

## Quest / Dialogue / NPC Background 基础系统测试。
var content: ContentDB
var gdb: GameplayDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var qs: QuestService
var ds: DialogueService
var trig: TriggerService
var bus: EventBus
var ts: TimeService
var ws: WeatherService
var rng: RNGService
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
	player.background_id = "blacksmith_test"
	ctx.player = player

	var td := TimeData.new()
	var cal := CalendarService.new()
	cal.setup(td.calendar)
	ts = TimeService.new()
	ts.setup(cal, bus)
	ctx.time_service = ts
	rng = RNGService.new()
	rng.set_seed(42)
	ws = WeatherService.new()
	ws.setup(td.weather, rng, bus)
	ctx.weather_service = ws

	qs = QuestService.new()
	qs.setup(content, bus)
	ctx.quest_service = qs
	ds = DialogueService.new()
	ds.setup(content)
	trig = TriggerService.new()
	trig.setup(content.triggers)

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1 普通背景
	var common := NPCBackgroundFactory.from_def(content.get_background("common_blacksmith"))
	_check(common.occupation == "铁匠", "T1 普通 NPC 背景")

	# T2 命名背景
	var named := NPCBackgroundFactory.from_def(content.get_background("blacksmith_test"))
	_check(named.is_named and named.personal_goal != "", "T2 命名 NPC 背景")

	# T3 随机背景 / T4 seed
	var r1 := RNGService.new()
	var r2 := RNGService.new()
	var bg1 := NPCBackgroundFactory.generate(content.get_background_templates(), r1, 123)
	var bg2 := NPCBackgroundFactory.generate(content.get_background_templates(), r2, 123)
	_check(bg1.occupation != "" and bg1.personality != "", "T3 随机 NPC 背景")
	_check(bg1.summary() == bg2.summary(), "T4 Seed 可重现")

	# T5 Quest 创建
	qs.set_available("quest_iron_ore")
	_check(qs.get_state("quest_iron_ore") == "Available", "T5 Quest 创建")

	# T11/T12 Dialogue
	var dia := ds.get_dialogue("dialogue_blacksmith_iron")
	_check(not dia.is_empty(), "T11 Dialogue 创建")
	var choices := ds.get_available_choices("dialogue_blacksmith_iron", ctx)
	_check(choices.size() == 2, "T12 Dialogue Choice")

	# T14 Dialogue Effect -> 接受 Quest
	player.set_relationship("blacksmith_test", 15.0, 0.0, 0.0, 0.0, 0.0)
	var accepted := ds.execute_choice("dialogue_blacksmith_iron", "help", ctx)
	_check(accepted and qs.get_state("quest_iron_ore") == "Accepted", "T14 Dialogue Effect 接受 Quest")
	_check(qs.get_state("quest_iron_ore") == "Accepted", "T6 Quest 状态变化")

	# T13/T15 分支
	var after_choices := ds.get_available_choices("dialogue_blacksmith_iron", ctx)
	_check(after_choices.size() == 1 and str(after_choices[0].get("id", "")) == "decline", "T13/T15 Dialogue 条件分支")

	# T8 Quest 接受条件
	qs.set_available("quest_iron_ore")
	player.set_relationship("blacksmith_test", 5.0, 0.0, 0.0, 0.0, 0.0)
	_check(not qs.accept_quest("quest_iron_ore", ctx), "T8 Quest 条件拒绝")
	player.set_relationship("blacksmith_test", 15.0, 0.0, 0.0, 0.0, 0.0)
	_check(qs.accept_quest("quest_iron_ore", ctx), "T8 Quest 条件接受")

	# T7 Objective 进度
	_check(not qs.progress_objective("quest_iron_ore", "collect_iron", 2, ctx), "T7 进度 2/3")
	_check(qs.progress_objective("quest_iron_ore", "collect_iron", 1, ctx), "T7 目标完成")

	# T9/T10 Quest 完成与奖励
	gs.economy_state["gold"] = 0.0
	var affinity_before := float(player.relationships["blacksmith_test"].get("affinity"))
	qs.complete_quest("quest_iron_ore", ctx)
	_check(qs.get_state("quest_iron_ore") == "Completed", "T6 Quest Completed")
	_check(float(gs.economy_state.get("gold", 0.0)) == 100.0, "T10 Quest 奖励 Gold")
	_check(float(player.relationships["blacksmith_test"].get("affinity")) > affinity_before, "T9 Quest Effect Relationship")

	# T16-T18 Trigger
	qs.set_available("quest_iron_ore")
	trig.dispatch("on_quest_available", ctx)
	_check(gs.story_flags.get_flag("trig_quest_available"), "T16/T17/T18 Trigger + Condition + Effect")
	gs.story_flags.remove_flag("trig_quest_available")
	qs.accept_quest("quest_iron_ore", ctx)
	trig.dispatch("on_quest_available", ctx)
	_check(not gs.story_flags.get_flag("trig_quest_available"), "T17 Trigger 条件不满足不触发")

	# T19 Time Trigger / T20 Weather Trigger
	ts.set_time(22, 0)
	trig.dispatch("on_time_night", ctx)
	_check(gs.story_flags.get_flag("trig_time_night"), "T19 Time Trigger")
	ws.set_weather("default", "rain")
	trig.dispatch("on_weather_rain", ctx)
	_check(gs.story_flags.get_flag("trig_weather_rain"), "T20 Weather Trigger")

	# T21/T22 背景加载与关联
	_check(not content.get_background("blacksmith_test").is_empty(), "T21 NPC Background 加载")
	_check(player.background_id == "blacksmith_test", "T22 背景与 Character 关联")

	# T23 Quest Journal
	var journal := qs.get_journal()
	_check(journal.size() > 0 and str(journal[0].get("title", "")) != "", "T23 Quest Journal")

	# T24 Story Flag / T25 WorldState 与 Quest
	_check(gs.story_flags.get_flag("quest_iron_ore_done"), "T24 Story Flag 与 Quest")
	_check(gs.world.get_value("location", "village", {}).get("iron_delivered", false) == true, "T25 WorldState 与 Quest")

	# T26 Save/Load
	var svc := SaveService.new()
	svc.save_game("qd", ctx, "story", rng.get_state())
	var lr := svc.load_game("qd")
	_check(lr.success, "T26 Save")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(gs2.quest_state.has("quest_iron_ore"), "T26 Load Quest 状态")
	_check(gs2.story_flags.get_flag("quest_iron_ore_done"), "T26 Load StoryFlag")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
