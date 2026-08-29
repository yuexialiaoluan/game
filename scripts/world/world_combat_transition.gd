class_name WorldCombatTransition
extends RefCounted

var world_scene: String = ""
var location: String = ""
var position: Vector3 = Vector3.ZERO
var facing: Vector2 = Vector2.ZERO
var encounter_id: String = ""

func set_context(p_scene: String, p_location: String, p_position: Vector3, p_facing: Vector2, p_encounter: String) -> void:
	world_scene = p_scene
	location = p_location
	position = p_position
	facing = p_facing
	encounter_id = p_encounter

func return_position() -> Vector3:
	return position
