class_name ContentDB
extends RefCounted

var quests: Dictionary = {}
var dialogues: Dictionary = {}
var npc_backgrounds: Dictionary = {}
var triggers: Array = []
var actions: Dictionary = {}
var interactions: Dictionary = {}
var resources: Dictionary = {}
var fishing: Dictionary = {}

func _init() -> void:
	quests = _load_dict("res://data/quests/quests.json")
	dialogues = _load_dict("res://data/dialogues/dialogues.json")
	npc_backgrounds = _load_dict("res://data/npc_backgrounds/npc_backgrounds.json")
	triggers = _load_array("res://data/triggers/triggers.json")
	actions = _load_dict("res://data/actions/actions.json")
	interactions = _load_dict("res://data/interactions/interactions.json")
	resources = _load_dict("res://data/resources/resources.json")
	fishing = _load_dict("res://data/fishing/fishing.json")

func get_quest(id: String) -> Dictionary:
	return quests.get(id, {}) as Dictionary

func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {}) as Dictionary

func get_background(id: String) -> Dictionary:
	var named := npc_backgrounds.get("named", {}) as Dictionary
	if named.has(id):
		return named.get(id, {}) as Dictionary
	var common := npc_backgrounds.get("common", {}) as Dictionary
	return common.get(id, {}) as Dictionary

func get_background_templates() -> Dictionary:
	return npc_backgrounds.get("templates", {}) as Dictionary

func get_action(id: String) -> Dictionary:
	return actions.get(id, {}) as Dictionary

func get_interaction(type_id: String) -> Dictionary:
	return interactions.get(type_id, {}) as Dictionary

func get_resource(id: String) -> Dictionary:
	return resources.get(id, {}) as Dictionary

func get_fishing_spot(id: String) -> Dictionary:
	return fishing.get(id, {}) as Dictionary

func _load_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func _load_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Array:
		return data
	return []
