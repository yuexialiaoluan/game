class_name ScheduleService
extends RefCounted

var data: NPCData

func setup(p_data: NPCData) -> void:
	data = p_data

func get_activity(schedule_id: String, hour: int) -> Dictionary:
	var def := data.get_schedule(schedule_id)
	var entries = def.get("entries", [])
	if entries.is_empty():
		return {}
	var best = entries[0]
	for e in entries:
		if int(e.get("hour", 0)) <= hour:
			best = e
	return best

func get_location(schedule_id: String, hour: int) -> String:
	var a := get_activity(schedule_id, hour)
	return str(a.get("location", ""))
