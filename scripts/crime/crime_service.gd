class_name CrimeService
extends RefCounted

var bus: EventBus = null
var records: Array = []
var severity: Dictionary = { "Theft": 10, "Trespass": 5, "Assault": 30, "Murder": 100 }
var faction_delta: Dictionary = { "Theft": -10 }

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func commit(actor: Actor, crime_type: String, location: String, faction: String, ctx: EvaluatorContext) -> Dictionary:
	var rec := {
		"actor_id": actor.id,
		"crime_type": crime_type,
		"location": location,
		"faction": faction,
		"severity": int(severity.get(crime_type, 1)),
		"time": ctx.time_service.get_time_hours() if ctx.time_service != null else 0.0
	}
	records.append(rec)
	if bus != null:
		bus.emit("crime_committed", rec)
	_apply_faction(actor, crime_type, faction)
	return rec

func detect(actor: Actor, crime_type: String, location: String, faction: String, ctx: EvaluatorContext) -> Dictionary:
	var rec := commit(actor, crime_type, location, faction, ctx)
	rec["detected"] = true
	if bus != null:
		bus.emit("crime_detected", rec)
	return rec

func _apply_faction(actor: Actor, crime_type: String, faction: String) -> void:
	if faction == "":
		return
	var delta := int(faction_delta.get(crime_type, 0))
	if delta != 0:
		actor.set_reputation(faction, float(actor.reputation.get(faction, 0.0)) + delta)

func to_dict() -> Dictionary:
	return { "records": records.duplicate(true) }

func from_dict(d: Dictionary) -> void:
	records = (d.get("records", []) as Array).duplicate(true)
