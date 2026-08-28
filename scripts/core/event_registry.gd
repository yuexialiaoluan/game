class_name EventRegistry
extends RefCounted

## 事件定义注册与触发分发：Trigger -> Condition -> Effects。
var events: Array = []

func load(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("EventRegistry: missing " + path)
		return
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Array:
		events = data

func add_event(def: Dictionary) -> void:
	events.append(def)

func dispatch(trigger: String, ctx: EvaluatorContext) -> int:
	var matched := []
	for ev in events:
		if str(ev.get("trigger", "")) == trigger:
			matched.append(ev)
	matched.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	var fired := 0
	for ev in matched:
		if str(ev.get("state", "pending")) == "done":
			continue
		if ConditionEvaluator.evaluate(ev.get("conditions", {}), ctx):
			for eff in ev.get("effects", []):
				EffectExecutor.execute(eff, ctx)
			ev["state"] = "done"
			fired += 1
	return fired

func get_event_state(id: String) -> String:
	for ev in events:
		if str(ev.get("id", "")) == id:
			return str(ev.get("state", "pending"))
	return ""
