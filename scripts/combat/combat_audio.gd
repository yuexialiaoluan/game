class_name CombatAudio
extends RefCounted

var requests: Array = []

func play(sfx_id: String) -> void:
	requests.append(sfx_id)
