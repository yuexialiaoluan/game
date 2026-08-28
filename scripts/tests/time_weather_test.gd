extends Node

## Time / Calendar / Weather 服务测试。
var td: TimeData
var cal: CalendarService
var ts: TimeService
var ws: WeatherService
var rng: RNGService
var bus: EventBus
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var db: GameplayDB
var validation_failures: int = 0

var counters: Dictionary = {}

func _ready() -> void:
	db = GameplayDB.new()
	td = TimeData.new()
	cal = CalendarService.new()
	cal.setup(td.calendar)
	bus = EventBus.new()
	ts = TimeService.new()
	ts.setup(cal, bus)
	rng = RNGService.new()
	rng.set_seed(42)
	ws = WeatherService.new()
	ws.setup(td.weather, rng, bus)

	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.time_service = ts
	ctx.weather_service = ws
	ctx.event_bus = bus

	var idp := Identity.new()
	idp.character_id = "player"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(db, "player", idp, "human", {})
	ctx.player = player

	_register_counters()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _register_counters() -> void:
	for ev in ["time_changed", "day_changed", "month_changed", "season_changed", "day_phase_changed", "time_advance_completed", "weather_changed"]:
		counters[ev] = [0]
		bus.subscribe(ev, _on_event.bind(ev))

func _on_event(_payload, ev: String) -> void:
	counters[ev][0] += 1

func _count(ev: String) -> int:
	return int(counters.get(ev, [0])[0])

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# T1 初始化
	_check(ts.get_current_day() == 1 and ts.hour == 8 and ts.minute == 0, "T1 Time 初始化")

	# T2 推进分钟
	ts.advance_minutes(30)
	_check(ts.hour == 8 and ts.minute == 30, "T2 推进分钟")

	# T3 推进小时
	ts.advance_hours(1)
	_check(ts.hour == 9 and ts.minute == 30, "T3 推进小时")

	# T4 跨天
	ts.advance_hours(24)
	_check(ts.get_current_day() == 2 and ts.hour == 9, "T4 跨天")

	# T5 跨月
	cal.set_date(1, 1, 30)
	ts.hour = 8
	ts.minute = 0
	ts.advance_days(1)
	_check(cal.month == 2 and cal.day == 1, "T5 跨月")

	# T6 跨年
	cal.set_date(1, 12, 30)
	ts.advance_days(1)
	_check(cal.year == 2 and cal.month == 1 and cal.day == 1, "T6 跨年")

	# T7 星期
	cal.set_date(1, 1, 1)
	var w0 := ts.get_current_weekday()
	ts.advance_days(7)
	_check(ts.get_current_weekday() == w0, "T7 星期计算")

	# T8 季节
	cal.set_date(1, 1, 1)
	_check(ts.get_current_season() == "spring", "T8 季节 spring")
	cal.set_date(1, 4, 1)
	_check(ts.get_current_season() == "summer", "T8 季节 summer")

	# T9 Day Phase
	ts.set_time(0, 0)
	_check(ts.get_day_phase() == "midnight", "T9 DayPhase midnight")
	ts.set_time(9, 0)
	_check(ts.get_day_phase() == "morning", "T9 DayPhase morning")

	# T10 固定 Action Time Cost
	ts.set_time(8, 0)
	var m1 := ts.advance_action("rest_short", td, ctx, rng)
	_check(m1 == 60 and ts.hour == 9, "T10 固定 Action Cost")

	# T11 随机 Action Time Cost
	var m2 := ts.advance_action("explore_area", td, ctx, rng)
	_check(m2 >= 20 and m2 <= 40, "T11 随机 Action Cost")

	# T12 Modifier 影响
	var base_minutes := ActionTimeCost.compute(td.get_action("travel_small"), ctx, rng)
	player.talents.append("talent_master_traveler")
	var mod_minutes := ActionTimeCost.compute(td.get_action("travel_small"), ctx, rng)
	_check(mod_minutes < base_minutes, "T12 Time Cost 受 Modifier 影响")

	# T13-T16 事件
	ts.set_time(7, 0)
	cal.set_date(1, 1, 1)
	var c0 := _count("time_changed")
	ts.advance_hours(1)
	_check(_count("time_changed") > c0, "T13 TimeChanged")
	_check(_count("day_phase_changed") > 0, "T16 DayPhaseChanged")
	var day_before := _count("day_changed")
	ts.advance_hours(24)
	_check(_count("day_changed") > day_before, "T14 DayChanged")
	var season_before := _count("season_changed")
	cal.set_date(1, 3, 30)
	ts.advance_days(1)
	_check(_count("season_changed") > season_before, "T15 SeasonChanged")

	# T17 Weather 初始化
	_check(ws.get_weather("default") == "clear", "T17 Weather 初始化")

	# T18 Weather 切换
	ws.set_weather("default", "rain")
	_check(ws.get_weather("default") == "rain", "T18 Weather 切换")

	# T19 Weather 持续时间
	ws.force_weather("default", "rain", 60)
	var w_old := ws.get_weather("default")
	ws.advance_minutes(70)
	_check(ws.get_weather("default") != w_old, "T19 Weather 持续时间结束切换")

	# T20 Region Weather
	ws.set_weather("north", "snow")
	_check(ws.get_weather("north") == "snow", "T20 Region Weather")

	# T21 WeatherChanged
	var wc0 := _count("weather_changed")
	ws.set_weather("default", "fog")
	_check(_count("weather_changed") > wc0, "T21 WeatherChanged 事件")

	# T22 Condition 读取时间
	ts.set_time(19, 0)
	_check(ConditionEvaluator.evaluate({ "type": "time", "operator": ">=", "value": 18 }, ctx), "T22 Condition 时间")

	# T23 Condition 读取天气
	ws.set_weather("default", "rain")
	_check(ConditionEvaluator.evaluate({ "type": "weather", "operator": "==", "value": "rain" }, ctx), "T23 Condition 天气")

	# T24 Effect 推进时间
	ts.set_time(8, 0)
	EffectExecutor.execute({ "type": "advance_time", "minutes": 60 }, ctx)
	_check(ts.hour == 9, "T24 Effect 推进时间")

	# T25 Effect 修改天气
	EffectExecutor.execute({ "type": "set_weather", "region": "default", "value": "storm" }, ctx)
	_check(ws.get_weather("default") == "storm", "T25 Effect 修改天气")

	# T26-T29 Save/Load Time & Weather
	ts.set_time(11, 30)
	cal.set_date(1, 1, 1)
	ws.set_weather("default", "rain")
	var svc := SaveService.new()
	svc.save_game("tw", ctx, "story", rng.get_state())
	var lr := svc.load_game("tw")
	_check(lr.success, "T26 Save Time")
	var ts2 := TimeService.new()
	ts2.setup(CalendarService.new(), null)
	ts2.calendar.setup(td.calendar)
	ts2.from_dict(lr.data.time_state)
	_check(ts2.get_current_day() == 1 and ts2.hour == 11 and ts2.minute == 30, "T27 Load Time")
	var ws2 := WeatherService.new()
	ws2.setup(td.weather, RNGService.new(), null)
	ws2.from_dict(lr.data.weather_state)
	_check(ws2.get_weather("default") == "rain", "T29 Load Weather")
	_check(lr.data.time_state.has("year"), "T28 Save 结构")

	# T30 RNG 天气可重现
	var rng_a := RNGService.new()
	rng_a.set_seed(7)
	var rng_b := RNGService.new()
	rng_b.set_seed(7)
	var wa := WeatherService.new()
	wa.setup(td.weather, rng_a, null)
	var wb := WeatherService.new()
	wb.setup(td.weather, rng_b, null)
	wa.force_weather("default", "clear", 60)
	wb.force_weather("default", "clear", 60)
	wa.advance_minutes(70)
	wb.advance_minutes(70)
	_check(wa.get_weather("default") == wb.get_weather("default"), "T30 RNG 天气可重现")

	# T31 Load 不重复推进时间
	var before := ts.get_time_hours()
	svc.load_game("tw")
	_check(ts.get_time_hours() == before, "T31 Load 不推进时间")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1



