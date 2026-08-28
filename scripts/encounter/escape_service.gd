class_name EscapeService
extends RefCounted

var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func attempt(actor: Actor, ctx: EvaluatorContext, rng: RNGService) -> String:
	var chance := 50.0
	if ctx.time_service != null and ctx.time_service.get_time_hours() >= 21.0:
		chance += 15.0
	if ctx.weather_service != null and ctx.weather_service.get_weather("default") == "rain":
		chance += 10.0
	var roll := rng.next_float() * 100.0
	var result := "Success" if roll < chance else "Failure"
	if bus != null:
		bus.emit("escape_resolved", { "actor": actor.id, "result": result })
	return result
