class_name DialogueService
extends RefCounted

var db: ContentDB

func setup(p_db: ContentDB) -> void:
	db = p_db

func get_dialogue(id: String) -> Dictionary:
	return db.get_dialogue(id)

func get_available_choices(dialogue_id: String, ctx: EvaluatorContext) -> Array:
	var def := db.get_dialogue(dialogue_id)
	var out := []
	for ch in def.get("choices", []):
		if ConditionEvaluator.evaluate(ch.get("conditions", {}), ctx):
			out.append(ch)
	return out

func execute_choice(dialogue_id: String, choice_id: String, ctx: EvaluatorContext) -> bool:
	var def := db.get_dialogue(dialogue_id)
	for ch in def.get("choices", []):
		if str(ch.get("id", "")) == choice_id:
			if ConditionEvaluator.evaluate(ch.get("conditions", {}), ctx):
				for eff in ch.get("effects", []):
					EffectExecutor.execute(eff, ctx)
				return true
	return false
