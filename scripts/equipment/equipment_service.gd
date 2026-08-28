class_name EquipmentService
extends RefCounted

var db: GameplayDB
var bus: EventBus = null

func setup(p_db: GameplayDB, p_bus: EventBus = null) -> void:
	db = p_db
	bus = p_bus

func can_equip(actor: Actor, item_id: String, ctx: EvaluatorContext) -> Dictionary:
	var eq := db.get_equipment(item_id)
	if eq.is_empty():
		return { "allowed": false, "reason": "装备不存在" }
	var req = eq.get("requirements", {})
	if not ConditionEvaluator.evaluate(req, ctx):
		return { "allowed": false, "reason": _reason(eq, ctx) }
	return { "allowed": true, "reason": "" }

func equip(actor: Actor, slot: String, item_id: String, ctx: EvaluatorContext) -> bool:
	if item_id == "":
		actor.equip(slot, "")
		_emit(actor, slot, "")
		return true
	var res := can_equip(actor, item_id, ctx)
	if not bool(res.get("allowed", false)):
		return false
	actor.equip(slot, item_id)
	_emit(actor, slot, item_id)
	return true

func _reason(eq: Dictionary, ctx: EvaluatorContext) -> String:
	var req = eq.get("requirements", {})
	if req is Dictionary:
		var cs = req.get("conditions", [])
		for c in cs:
			if c is Dictionary and str(c.get("type", "")) == "level":
				return "需要等级" + str(c.get("value", 0))
			if c is Dictionary and str(c.get("type", "")) == "base_attribute":
				return "需要" + str(c.get("key", "")) + " " + str(c.get("value", 0))
	return "无法装备"

func _emit(actor: Actor, slot: String, item_id: String) -> void:
	if bus != null:
		bus.emit("equipment_changed", { "actor": actor.id, "slot": slot, "item_id": item_id })
