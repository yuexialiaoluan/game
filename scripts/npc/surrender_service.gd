class_name SurrenderService
extends RefCounted

var data: NPCData
var states: NPCStateService
var bus: EventBus = null

func setup(p_data: NPCData, p_states: NPCStateService, p_bus: EventBus = null) -> void:
	data = p_data
	states = p_states
	bus = p_bus

func can_surrender(actor: Actor, ctx: EvaluatorContext) -> bool:
	var def := data.get_surrender(actor.id)
	if def.is_empty() or not bool(def.get("can_surrender", false)):
		return false
	return ConditionEvaluator.evaluate(def.get("conditions", {}), ctx)

func surrender(actor: Actor, ctx: EvaluatorContext) -> bool:
	if not can_surrender(actor, ctx):
		return false
	actor.set_state("Surrendered")
	states.set_disposition(actor.id, Disposition.SURRENDERED)
	if bus != null:
		bus.emit("actor_surrendered", { "actor": actor.id })
	return true
