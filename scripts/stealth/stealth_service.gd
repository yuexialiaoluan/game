class_name StealthService
extends RefCounted

var stealth: Dictionary = {}
var modifiers: Dictionary = {}
var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func enter(actor: Actor) -> void:
	stealth[actor.id] = true
	_emit("stealth_started", actor.id)

func exit(actor: Actor) -> void:
	stealth[actor.id] = false
	_emit("stealth_ended", actor.id)

func is_stealthed(actor: Actor) -> bool:
	return bool(stealth.get(actor.id, false))

func add_modifier(actor_id: String, value: float, condition: Dictionary = {}) -> void:
	if not modifiers.has(actor_id):
		modifiers[actor_id] = []
	modifiers[actor_id].append({ "value": value, "condition": condition })

func get_stealth_score(actor: Actor, ctx: EvaluatorContext) -> float:
	var score := 50.0
	if ctx.time_service != null and ctx.time_service.get_time_hours() >= 21.0:
		score += 20.0
	if ctx.weather_service != null and ctx.weather_service.get_weather("default") == "fog":
		score += 15.0
	for m in modifiers.get(actor.id, []):
		if ConditionEvaluator.evaluate(m.get("condition", {}), ctx):
			score += float(m.get("value", 0.0))
	return score

func _emit(ev: String, actor_id: String) -> void:
	if bus != null:
		bus.emit(ev, { "actor": actor_id })
