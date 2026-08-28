class_name QuestService
extends RefCounted

var db: ContentDB
var bus: EventBus = null
var quests: Dictionary = {}

func setup(p_db: ContentDB, p_bus: EventBus = null) -> void:
	db = p_db
	bus = p_bus

func get_state(quest_id: String) -> String:
	return str(quests.get(quest_id, {}).get("state", "Inactive"))

func set_available(quest_id: String) -> void:
	quests[quest_id] = { "state": "Available", "objectives": {} }

func accept_quest(quest_id: String, ctx: EvaluatorContext) -> bool:
	var def := db.get_quest(quest_id)
	if def.is_empty():
		return false
	if not ConditionEvaluator.evaluate(def.get("accept_conditions", {}), ctx):
		return false
	var st = quests.get(quest_id, null)
	if st == null:
		st = { "state": "Available", "objectives": {} }
	st["state"] = "Accepted"
	var objectives := {}
	for obj in def.get("objectives", []):
		objectives[str(obj.get("id", ""))] = int(obj.get("progress", 0))
	st["objectives"] = objectives
	quests[quest_id] = st
	_emit("quest_started", quest_id)
	return true

func progress_objective(quest_id: String, objective_id: String, amount: int, ctx: EvaluatorContext) -> bool:
	var st = quests.get(quest_id)
	if st == null:
		return false
	var objectives: Dictionary = st.get("objectives", {}) as Dictionary
	var def := db.get_quest(quest_id)
	var target := 0
	for obj in def.get("objectives", []):
		if str(obj.get("id", "")) == objective_id:
			target = int(obj.get("target", 0))
	var cur := int(objectives.get(objective_id, 0)) + int(amount)
	objectives[objective_id] = cur
	st["objectives"] = objectives
	_emit("quest_progress", quest_id)
	return cur >= target

func complete_quest(quest_id: String, ctx: EvaluatorContext) -> void:
	var st = quests.get(quest_id)
	if st == null:
		return
	st["state"] = "Completed"
	var def := db.get_quest(quest_id)
	for eff in def.get("rewards", []):
		EffectExecutor.execute(eff, ctx)
	_emit("quest_completed", quest_id)

func fail_quest(quest_id: String) -> void:
	if quests.has(quest_id):
		quests[quest_id]["state"] = "Failed"

func abandon_quest(quest_id: String) -> void:
	if quests.has(quest_id):
		quests[quest_id]["state"] = "Abandoned"

func get_journal() -> Array:
	var out := []
	for qid in quests:
		var def := db.get_quest(qid)
		var st: Dictionary = quests[qid] as Dictionary
		var objectives := st.get("objectives", {}) as Dictionary
		var cur_obj := ""
		var prog := 0
		if not objectives.is_empty():
			cur_obj = str(objectives.keys()[0])
			prog = int(objectives.get(cur_obj, 0))
		out.append({
			"quest_id": qid,
			"title": str(def.get("title", "")),
			"description": str(def.get("description", "")),
			"state": str(st.get("state", "")),
			"current_objective": cur_obj,
			"progress": prog,
			"objectives": objectives
		})
	return out

func to_dict() -> Dictionary:
	return quests.duplicate(true)

func from_dict(d: Dictionary) -> void:
	quests = d.duplicate(true)

func _emit(event_name: String, payload = null) -> void:
	if bus != null:
		bus.emit(event_name, payload)

