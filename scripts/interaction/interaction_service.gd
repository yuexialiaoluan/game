class_name InteractionService
extends RefCounted

var db: ContentDB
var objects: Dictionary = {}

func setup(p_db: ContentDB) -> void:
	db = p_db

func register(obj: InteractableObject) -> void:
	objects[obj.id] = obj

func get_object(id: String) -> InteractableObject:
	return objects.get(id)

func get_available_actions(obj: InteractableObject, ctx: EvaluatorContext) -> Array:
	var def := db.get_interaction(obj.object_type)
	var out := []
	for aid in def.get("actions", []):
		var a := db.get_action(str(aid))
		if not a.is_empty() and ConditionEvaluator.evaluate(a.get("conditions", {}), ctx):
			out.append(a)
	return out
