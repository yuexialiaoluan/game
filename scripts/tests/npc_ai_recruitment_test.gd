extends Node

## NPC AI / Schedule / Relationship / Recruitment / Surrender 测试。
var gdb: GameplayDB
var npc_data: NPCData
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var villager: Actor
var smith: Actor
var guard: Actor
var bandit: Actor
var goblin: Actor
var mercenary: Actor
var quest_npc: Actor
var rng: RNGService
var ts: TimeService
var bus: EventBus
var sched: ScheduleService
var states: NPCStateService
var rel: RelationshipService
var party: PartyService
var rec: RecruitmentService
var sur: SurrenderService
var qs: QuestService
var validation_failures: int = 0

func _ready() -> void:
	gdb = GameplayDB.new()
	npc_data = NPCData.new()
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
	gs.economy_state["gold"] = 0.0

	var td := TimeData.new()
	var cal := CalendarService.new()
	cal.setup(td.calendar)
	ts = TimeService.new()
	ts.setup(cal, bus)
	ctx.time_service = ts

	rng = RNGService.new()
	rng.set_seed(42)
	ctx.rng = rng

	villager = _make("villager", "human")
	smith = _make("smith", "human")
	guard = _make("guard", "human")
	bandit = _make("bandit", "human")
	goblin = _make("goblin", "goblin")
	mercenary = _make("mercenary", "human")
	quest_npc = _make("quest_npc", "human")

	sched = ScheduleService.new()
	sched.setup(npc_data)
	states = NPCStateService.new()
	states.setup(npc_data)
	states.register(villager, "villager_default", Disposition.NEUTRAL)
	states.register(smith, "smith_default", Disposition.NEUTRAL)
	states.register(guard, "guard_patrol", Disposition.NEUTRAL)
	states.register(bandit, "", Disposition.HOSTILE)
	states.register(goblin, "", Disposition.HOSTILE)
	states.register(mercenary, "", Disposition.NEUTRAL)
	states.register(quest_npc, "", Disposition.NEUTRAL)
	ctx.npc_state_service = states

	rel = RelationshipService.new()
	party = PartyService.new()
	party.setup(bus)
	rec = RecruitmentService.new()
	rec.setup(npc_data, party, bus)
	sur = SurrenderService.new()
	sur.setup(npc_data, states, bus)

	qs = QuestService.new()
	qs.setup(ContentDB.new(), bus)
	ctx.quest_service = qs

	player.set_relationship("villager", 40.0, 0.0, 0.0, 0.0, 0.0)
	player.set_relationship("bandit", 35.0, 0.0, 0.0, 0.0, 0.0)

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _make(id: String, race: String) -> Actor:
	var idn := Identity.new()
	idn.character_id = id
	idn.race_id = race
	var a := Actor.new()
	a.setup(gdb, id, idn, race, {})
	ctx.actors[id] = a
	return a

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1/T2 Schedule
	_check(states.get_runtime("villager") != null, "T1 NPC Runtime")
	var act := sched.get_activity("villager_default", 8)
	_check(str(act.get("activity", "")) == "Work", "T2 NPC Schedule")

	# T3/T4/T5 Schedule + Time + Location
	states.update_all(18)
	var rt: NPCRuntime = states.get_runtime("villager")
	_check(rt.current_activity == "Tavern" and rt.current_location == "tavern", "T3/T4/T5 Schedule + Time + Location")

	# T6 AI State
	rt.ai_state = "Working"
	_check(rt.ai_state == "Working", "T6 AI State")

	# T7/T8 Relationship
	_check(rel.get_value(player, "villager", "affinity") == 40.0, "T7 Relationship 读取")
	rel.modify(player, "villager", "affinity", 20.0)
	_check(rel.get_value(player, "villager", "affinity") == 60.0, "T8 Relationship 修改")

	# T9/T10/T12 Relationship Recruitment
	var r1 := rec.can_recruit(villager, ctx)
	_check(bool(r1.get("eligible", false)), "T9/T10 Recruitment 条件满足")
	_check(rec.recruit(villager, ctx), "T12 Relationship Recruitment")

	# T11 Gold Recruitment
	gs.economy_state["gold"] = 300.0
	var r2 := rec.can_recruit(mercenary, ctx)
	_check(bool(r2.get("eligible", false)), "T11 Gold Recruitment 条件")
	_check(rec.recruit(mercenary, ctx) and float(gs.economy_state.get("gold", 0.0)) == 0.0, "T11 Gold Recruitment")

	# T13 Quest Recruitment
	qs.set_available("quest_collect_iron")
	qs.accept_quest("quest_collect_iron", ctx)
	qs.complete_quest("quest_collect_iron", ctx)
	_check(bool(rec.can_recruit(quest_npc, ctx).get("eligible", false)), "T13 Quest Recruitment")

	# T15/T16/T17 Surrender
	var bmax := bandit.max_hp()
	bandit.set_hp(bmax * 0.9)
	_check(not sur.can_surrender(bandit, ctx), "T16 Surrender Condition 高HP")
	bandit.set_hp(bmax * 0.2)
	_check(sur.can_surrender(bandit, ctx), "T16 Surrender Condition 低HP")
	_check(sur.surrender(bandit, ctx), "T15 Surrender")
	_check(bandit.state == "Surrendered" and states.get_runtime("bandit").disposition == Disposition.SURRENDERED, "T17 Surrender State")

	# T18 Surrender -> Recruit
	_check(bool(rec.can_recruit(bandit, ctx).get("eligible", false)), "T18 Surrender -> Recruit 条件")
	_check(rec.recruit(bandit, ctx), "T18 Surrender -> Recruit")

	# T19 Escape / T20 Captured
	states.set_disposition("guard", Disposition.FLEEING)
	_check(states.get_runtime("guard").disposition == Disposition.FLEEING, "T19 Escape State")
	states.set_disposition("guard", Disposition.CAPTURED)
	_check(states.get_runtime("guard").disposition == Disposition.CAPTURED, "T20 Captured State")

	# T21/T22 Creature Recruitment
	player.add_item("goblin_trinket", 1)
	var gmax := goblin.max_hp()
	goblin.set_hp(gmax * 0.3)
	sur.surrender(goblin, ctx)
	_check(bool(rec.can_recruit(goblin, ctx).get("eligible", false)), "T21 Creature Recruitment 条件")
	_check(rec.recruit(goblin, ctx), "T22 Creature -> Party")
	_check(goblin.race_id == "goblin" and party.active.has(goblin), "T22 Goblin 保留 Race 并入队")

	# T23 Companion / T24 Dismiss
	states.set_disposition("goblin", Disposition.COMPANION)
	_check(states.get_runtime("goblin").disposition == Disposition.COMPANION, "T23 Companion State")
	party.remove(goblin)
	goblin.set_state("Wanderer")
	states.set_disposition("goblin", Disposition.WANDERER)
	_check(states.get_runtime("goblin").disposition == Disposition.WANDERER, "T24 Companion -> Dismiss")

	# T25 Background / T26 Occupation -> Schedule
	_check(not ContentDB.new().get_background("blacksmith_test").is_empty(), "T25 Background 加载")
	var smith_act := sched.get_activity("smith_default", 8)
	_check(str(smith_act.get("location", "")) == "smithy", "T26 Occupation -> Schedule")

	# T27 Faction -> Disposition
	bandit.set_faction("bandit_faction")
	states.set_disposition("bandit", Disposition.HOSTILE)
	_check(bandit.faction_id == "bandit_faction" and states.get_runtime("bandit").disposition == Disposition.HOSTILE, "T27 Faction -> Disposition")

	# T28-T32 Save / Load NPC State
	ctx.party = party.active.duplicate()
	ctx.reserve_party = party.reserve.duplicate()
	var svc := SaveService.new()
	svc.save_game("npc", ctx, "story", rng.get_state())
	var lr := svc.load_game("npc")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(gs2.npc_state.has("villager"), "T28 Save NPC State")
	var states2 := NPCStateService.new()
	states2.setup(npc_data)
	states2.from_dict(gs2.npc_state)
	_check(states2.get_runtime("bandit").disposition == Disposition.HOSTILE, "T32 Load Surrender/Disposition")
	var p2 := Actor.new()
	p2.apply_save_data(lr.data.actors["player"], gdb)
	_check(p2.relationships.has("villager"), "T30 Load Relationship")
	_check(lr.data.actors.has("goblin"), "T29 Load Recruitment/Actor")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
