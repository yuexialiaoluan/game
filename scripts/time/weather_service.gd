class_name WeatherService
extends RefCounted

var defs: Dictionary = {}
var region_defs: Dictionary = {}
var rng: RNGService
var bus: EventBus = null
var states: Dictionary = {}

func setup(data: Dictionary, p_rng: RNGService, p_bus: EventBus = null) -> void:
	defs = data.get("weather", {}) as Dictionary
	region_defs = data.get("regions", {}) as Dictionary
	rng = p_rng
	bus = p_bus
	if region_defs.is_empty():
		region_defs = { "default": { "transition_weights": { "clear": 100 } } }
	for region in region_defs:
		states[region] = { "weather_id": "clear", "remaining_minutes": _random_duration("clear") }

func get_weather(region: String = "default") -> String:
	return str(states.get(region, {}).get("weather_id", "clear"))

func get_remaining_minutes(region: String = "default") -> int:
	return int(states.get(region, {}).get("remaining_minutes", 0))

func set_weather(region: String, weather_id: String) -> void:
	states[region] = { "weather_id": weather_id, "remaining_minutes": _random_duration(weather_id) }
	_emit_weather(region, weather_id)

func force_weather(region: String, weather_id: String, duration: int) -> void:
	states[region] = { "weather_id": weather_id, "remaining_minutes": duration }
	_emit_weather(region, weather_id)

func advance_minutes(minutes: int) -> void:
	for region in states:
		var st: Dictionary = states[region]
		var remaining := int(st.get("remaining_minutes", 0)) - minutes
		if remaining <= 0:
			var next := _pick_next(region)
			st["weather_id"] = next
			st["remaining_minutes"] = _random_duration(next)
			_emit_weather(region, next)
		else:
			st["remaining_minutes"] = remaining

func _random_duration(weather_id: String) -> int:
	var wd := defs.get(weather_id, {}) as Dictionary
	return rng.randi_range(int(wd.get("min_duration", 120)), int(wd.get("max_duration", 240)))

func _pick_next(region: String) -> String:
	var rd := region_defs.get(region, {}) as Dictionary
	var weights := rd.get("transition_weights", { "clear": 100 }) as Dictionary
	var total := 0
	for k in weights:
		total += int(weights[k])
	if total <= 0:
		return "clear"
	var roll := rng.next_int(total)
	var acc := 0
	for k in weights:
		acc += int(weights[k])
		if roll < acc:
			return str(k)
	return "clear"

func _emit_weather(region: String, weather_id: String) -> void:
	if bus != null:
		bus.emit("weather_changed", { "region": region, "weather_id": weather_id })

func to_dict() -> Dictionary:
	return states.duplicate(true)

func from_dict(d: Dictionary) -> void:
	states = d.duplicate(true)
