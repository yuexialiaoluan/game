class_name NPCData
extends RefCounted

var schedules: Dictionary = {}
var recruitment: Dictionary = {}
var surrender: Dictionary = {}

func _init() -> void:
	schedules = _load("res://data/npcs/schedules.json")
	recruitment = _load("res://data/npcs/recruitment.json")
	surrender = _load("res://data/npcs/surrender.json")

func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func get_schedule(id: String) -> Dictionary:
	return schedules.get(id, {}) as Dictionary

func get_recruitment(id: String) -> Dictionary:
	return recruitment.get(id, {}) as Dictionary

func get_surrender(id: String) -> Dictionary:
	return surrender.get(id, {}) as Dictionary
