class_name RecruitmentService
extends RefCounted

var data: NPCData
var party: PartyService
var bus: EventBus = null

func setup(p_data: NPCData, p_party: PartyService, p_bus: EventBus = null) -> void:
	data = p_data
	party = p_party
	bus = p_bus

func can_recruit(actor: Actor, ctx: EvaluatorContext) -> Dictionary:
	var def := data.get_recruitment(actor.id)
	if def.is_empty() or not bool(def.get("can_recruit", false)):
		return { "eligible": false, "reason": "不可招募" }
	if not ConditionEvaluator.evaluate(def.get("conditions", {}), ctx):
		return { "eligible": false, "reason": "条件不足" }
	return { "eligible": true, "reason": "" }

func recruit(actor: Actor, ctx: EvaluatorContext) -> bool:
	var res := can_recruit(actor, ctx)
	if not bool(res.get("eligible", false)):
		return false
	var def := data.get_recruitment(actor.id)
	var cost = def.get("cost", {})
	if cost is Dictionary and cost.size() > 0:
		EffectExecutor.execute(cost, ctx)
	for eff in def.get("effects", []):
		EffectExecutor.execute(eff, ctx)
	actor.set_state("Companion")
	party.add(actor)
	if bus != null:
		bus.emit("recruited", { "actor": actor.id })
	return true
