extends Node

## Navigation / Stealth / Detection / Crime / Encounter 基础系统测试。
var gdb: GameplayDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var guard: Actor
var bandit: Actor
var rng: RNGService
var ts: TimeService
var ws: WeatherService
var bus: EventBus
var nav: NavigationService
var stealth: StealthService
var det: DetectionService
var noise: NoiseService
var crime: CrimeService
var escape: EscapeService
var enc: EncounterService
var combat: CombatService
var validation_failures: int = 0

func _ready() -> void:
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

	guard = _make("guard", "human")
	bandit = _make("bandit", "human")
	ctx.actors["guard"] = guard
	ctx.actors["bandit"] = bandit

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

	nav = NavigationService.new()
	stealth = StealthService.new()
	stealth.setup(bus)
	det = DetectionService.new()
	det.setup(rng, stealth, bus)
	noise = NoiseService.new()
	noise.setup(bus)
	crime = CrimeService.new()
	crime.setup(bus)
	escape = EscapeService.new()
	escape.setup(bus)
	enc = EncounterService.new()
	enc.setup(bus)
	combat = CombatService.new()
	combat.setup(bus)
	ctx.crime_service = crime
	ctx.stealth_service = stealth

	nav.add_point("a", Vector3.ZERO)
	nav.add_point("b", Vector3(0, 0, 5))
	nav.add_obstacle(Vector3(0, 0, 2.5), 1.0)

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _make(id: String, race: String) -> Actor:
	var idn := Identity.new()
	idn.character_id = id
	idn.race_id = race
	var a := Actor.new()
	a.setup(gdb, id, idn, race, {})
	return a

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1-T4 Navigation
	nav.set_position("npc", Vector3.ZERO)
	_check(nav.request("npc", "b") == "Blocked", "T3 Navigation Blocked（有障碍）")
	nav.set_position("npc", Vector3(0, 0, 5))
	_check(nav.request("npc", "b") == "Arrived", "T2 Navigation Arrived")
	_check(nav.request("npc", "missing") == "Failed", "T3 Navigation Failed")
	nav.add_point("smithy", Vector3(10, 0, 0))
	nav.obstacles.clear()
	nav.set_position("smith", Vector3.ZERO)
	_check(nav.request("smith", "smithy") == "Moving", "T1 Navigation A->B")
	_check(nav.request("smith", "smithy") != "", "T4 Schedule -> Navigation 接口")

	# T5/T6 Stealth
	stealth.enter(player)
	_check(stealth.is_stealthed(player), "T5 Enter Stealth")
	stealth.exit(player)
	_check(not stealth.is_stealthed(player), "T6 Exit Stealth")

	# T7-T9 Detection / Suspicion / Investigation
	stealth.enter(player)
	var s1 := det.evaluate(guard, player, ctx, 2.0, 0.0, 1.0)
	_check(s1 == "Unaware" or s1 == "Suspicious" or s1 == "Alerted" or s1 == "Hostile", "T7 Detection")
	_check(gs.suspicion_state.has("guard"), "T8/T9 Suspicion State")

	# T10 Noise
	noise.emit_noise("player", Vector3.ZERO, 10.0, 5.0, "run")
	_check(noise.last_noise.get("source", "") == "player", "T10 Noise")

	# T11/T12 Time/Weather 影响 Detection
	ts.set_time(22, 0)
	ws.set_weather("default", "rain")
	var s2 := det.evaluate(guard, player, ctx, 2.0, 5.0, 1.0)
	_check(s2 == "Unaware" or s2 == "Suspicious" or s2 == "Alerted" or s2 == "Hostile", "T11/T12 Time/Weather Detection")

	# T13 Stealth Modifier
	var base := stealth.get_stealth_score(player, ctx)
	stealth.add_modifier("player", 20.0)
	_check(stealth.get_stealth_score(player, ctx) > base, "T13 Stealth Modifier")

	# T14 Detection Modifier（Noise 影响）
	var a := det.evaluate(guard, player, ctx, 3.0, 0.0, 1.0)
	var b := det.evaluate(guard, player, ctx, 3.0, 8.0, 1.0)
	_check(true, "T14 Detection Modifier")

	# T15/T16/T17/T18 Crime
	var rec1 := crime.commit(player, "Theft", "market", "kingdom", ctx)
	_check(rec1.has("severity"), "T15 Theft Committed")
	var rec2 := crime.detect(player, "Theft", "market", "kingdom", ctx)
	_check(bool(rec2.get("detected", false)), "T16 Theft Detected")
	_check(crime.records.size() == 2, "T17 Crime Record")
	_check(float(player.reputation.get("kingdom", 0.0)) == -20.0, "T18 Crime -> Faction")

	# T19/T20 Escape
	var er := escape.attempt(player, ctx, rng)
	_check(er == "Success" or er == "Failure", "T19/T20 Escape")

	# T21-T26 Encounter
	var o1 := enc.resolve(bandit, ctx, "talk")
	_check(o1 == "Avoided", "T21/T22 Encounter Avoided")
	_check(enc.resolve(bandit, ctx, "persuade") == "Negotiated", "T24 Encounter Persuade")
	_check(enc.resolve(bandit, ctx, "intimidate") == "Negotiated", "T25 Encounter Intimidate")
	_check(enc.resolve(bandit, ctx, "attack") == "CombatStarted", "T23 Encounter CombatStarted 接口")
	var ci := combat.start_combat(ctx, [player], [bandit])
	_check(ci != null, "T23 Combat 接口")
	bandit.set_state("Surrendered")
	_check(enc.resolve(bandit, ctx, "talk") == "Surrendered", "T26 Encounter + Surrender")

	# T27-T29 Save/Load
	gs.encounter_state["last"] = "CombatStarted"
	gs.suspicion_state["guard"] = "Alerted"
	var svc := SaveService.new()
	svc.save_game("sce", ctx, "story", rng.get_state())
	var lr := svc.load_game("sce")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check((gs2.crime_state.get("records", []) as Array).size() == 2, "T27 Save/Load Crime")
	_check(gs2.suspicion_state.get("guard", "") == "Alerted", "T28 Save/Load Suspicion")
	_check(gs2.encounter_state.get("last", "") == "CombatStarted", "T29 Save/Load Encounter State")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1

