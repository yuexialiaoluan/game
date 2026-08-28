class_name NPCRuntime
extends RefCounted

var actor_id: String = ""
var disposition: String = Disposition.NEUTRAL
var ai_state: String = "Idle"
var current_activity: String = ""
var current_location: String = ""
var schedule_id: String = ""
var recruitment_state: String = "Available"
var is_dead: bool = false

func to_dict() -> Dictionary:
	return {
		"actor_id": actor_id,
		"disposition": disposition,
		"ai_state": ai_state,
		"current_activity": current_activity,
		"current_location": current_location,
		"schedule_id": schedule_id,
		"recruitment_state": recruitment_state,
		"is_dead": is_dead
	}

func from_dict(d: Dictionary) -> void:
	actor_id = str(d.get("actor_id", ""))
	disposition = str(d.get("disposition", Disposition.NEUTRAL))
	ai_state = str(d.get("ai_state", "Idle"))
	current_activity = str(d.get("current_activity", ""))
	current_location = str(d.get("current_location", ""))
	schedule_id = str(d.get("schedule_id", ""))
	recruitment_state = str(d.get("recruitment_state", "Available"))
	is_dead = bool(d.get("is_dead", false))
