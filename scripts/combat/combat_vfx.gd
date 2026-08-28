class_name CombatVFX
extends RefCounted

var requests: Array = []

func play(vfx_id: String) -> void:
	requests.append(vfx_id)
