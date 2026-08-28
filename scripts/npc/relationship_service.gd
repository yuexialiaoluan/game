class_name RelationshipService
extends RefCounted

func get_value(actor: Actor, target: String, field: String) -> float:
	var rs = actor.relationships.get(target)
	if rs == null:
		return 0.0
	return float(rs.get(field))

func modify(actor: Actor, target: String, field: String, amount: float) -> void:
	var rs = actor.relationships.get(target)
	if rs == null:
		actor.set_relationship(target, 0.0, 0.0, 0.0, 0.0, 0.0)
		rs = actor.relationships.get(target)
	rs.set(field, float(rs.get(field)) + amount)
