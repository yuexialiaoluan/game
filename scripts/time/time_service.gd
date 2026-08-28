class_name TimeService
extends RefCounted

## 以“行动推进时间”为核心的 TimeService。
var calendar: CalendarService
var bus: EventBus = null
var hour: int = 8
var minute: int = 0
var paused: bool = false

func setup(cal: CalendarService, p_bus: EventBus = null) -> void:
	calendar = cal
	bus = p_bus

func get_current_time() -> Dictionary:
	return { "hour": hour, "minute": minute }

func get_time_hours() -> float:
	return float(hour) + float(minute) / 60.0

func get_current_date() -> Dictionary:
	return calendar.get_date()

func get_current_day() -> int:
	return calendar.get_current_day()

func get_current_weekday() -> String:
	return calendar.get_current_weekday()

func get_current_season() -> String:
	return calendar.get_current_season()

func get_day_phase() -> String:
	return calendar.get_day_phase(get_time_hours())

func set_time(h: int, m: int) -> void:
	hour = h
	minute = m
	_emit("time_changed", get_current_time())

func set_paused(p: bool) -> void:
	paused = p

func is_paused() -> bool:
	return paused

func advance_minutes(minutes: int) -> void:
	if paused:
		return
	var phase_before := get_day_phase()
	var total := hour * 60 + minute + minutes
	var day_shift := int(total / 1440.0)
	hour = int((total % 1440) / 60)
	minute = total % 60

	var cal_events := {}
	if day_shift > 0:
		cal_events = calendar.advance_days(day_shift)

	_emit("time_changed", get_current_time())
	if cal_events.has("day_changed"):
		_emit("day_changed", calendar.get_date())
	if cal_events.has("month_changed"):
		_emit("month_changed", calendar.get_date())
	if cal_events.has("season_changed"):
		_emit("season_changed", get_current_season())
	if phase_before != get_day_phase():
		_emit("day_phase_changed", get_day_phase())
	_emit("time_advance_completed", minutes)

func advance_hours(hours: int) -> void:
	advance_minutes(hours * 60)

func advance_days(days: int) -> void:
	var events := calendar.advance_days(days)
	if events.has("day_changed"):
		_emit("day_changed", calendar.get_date())
	if events.has("month_changed"):
		_emit("month_changed", calendar.get_date())
	if events.has("season_changed"):
		_emit("season_changed", get_current_season())
	_emit("time_changed", get_current_time())
	_emit("time_advance_completed", days * 1440)

func to_dict() -> Dictionary:
	return {
		"year": calendar.year,
		"month": calendar.month,
		"day": calendar.day,
		"hour": hour,
		"minute": minute,
		"season": get_current_season(),
		"day_phase": get_day_phase()
	}

func from_dict(d: Dictionary) -> void:
	calendar.set_date(int(d.get("year", 1)), int(d.get("month", 1)), int(d.get("day", 1)))
	hour = int(d.get("hour", 8))
	minute = int(d.get("minute", 0))

func _emit(event_name: String, payload = null) -> void:
	if bus != null:
		bus.emit(event_name, payload)

func advance_action(action_id: String, td: TimeData, ctx: EvaluatorContext, rng: RNGService) -> int:
	var def := td.get_action(action_id)
	if def.is_empty():
		return 0
	var minutes := ActionTimeCost.compute(def, ctx, rng)
	advance_minutes(minutes)
	return minutes
