class_name NPCStateService
extends RefCounted

var data: NPCData
var runtimes: Dictionary = {}

func setup(p_data: NPCData) -> void:
	data = p_data

func register(actor: Actor, schedule_id: String, disposition: String = Disposition.NEUTRAL) -> NPCRuntime:
	var rt := NPCRuntime.new()
	rt.actor_id = actor.id
	rt.schedule_id = schedule_id
	rt.disposition = disposition
	runtimes[actor.id] = rt
	return rt

func get_runtime(actor_id: String) -> NPCRuntime:
	return runtimes.get(actor_id)

func update_all(hour: int) -> void:
	for id in runtimes:
		var rt: NPCRuntime = runtimes[id]
		var a := get_activity(rt.schedule_id, hour)
		rt.current_activity = str(a.get("activity", ""))
		rt.current_location = str(a.get("location", ""))

func get_activity(schedule_id: String, hour: int) -> Dictionary:
	var svc := ScheduleService.new()
	svc.setup(data)
	return svc.get_activity(schedule_id, hour)

func set_disposition(actor_id: String, disposition: String) -> void:
	if runtimes.has(actor_id):
		runtimes[actor_id].disposition = disposition

func to_dict() -> Dictionary:
	var out := {}
	for id in runtimes:
		out[id] = runtimes[id].to_dict()
	return out

func from_dict(d: Dictionary) -> void:
	runtimes.clear()
	for id in d:
		var rt := NPCRuntime.new()
		rt.from_dict(d[id])
		runtimes[id] = rt
