class_name DetectionService
extends RefCounted

var rng: RNGService
var bus: EventBus = null
var stealth: StealthService

func setup(p_rng: RNGService, p_stealth: StealthService, p_bus: EventBus = null) -> void:
	rng = p_rng
	stealth = p_stealth
	bus = p_bus

func evaluate(detector: Actor, target: Actor, ctx: EvaluatorContext, distance: float, noise: float = 0.0, light: float = 1.0) -> String:
	var score := 50.0 - distance * 5.0 + noise * 10.0 + light * 20.0
	if stealth.is_stealthed(target):
		score -= stealth.get_stealth_score(target, ctx)
	if ctx.time_service != null and ctx.time_service.get_time_hours() >= 21.0:
		score -= 15.0
	if ctx.weather_service != null and ctx.weather_service.get_weather("default") == "rain":
		score += 10.0
	var roll := rng.next_float() * 100.0
	var state := "Unaware"
	if roll < score:
		state = "Hostile" if score >= 70.0 else "Alerted"
	else:
		state = "Suspicious" if score >= 40.0 else "Unaware"
	_emit(state, detector.id, target.id)
	if ctx.game_state != null:
		ctx.game_state.suspicion_state[detector.id] = state
	return state

func _emit(state: String, detector_id: String, target_id: String) -> void:
	if bus != null:
		bus.emit("detection_changed", { "state": state, "detector": detector_id, "target": target_id })

