class_name GameplayDB
extends RefCounted

## Gameplay 内容库：加载种族/职业/技能/专长/天赋/状态/物品/装备/等级表。
var races: Dictionary = {}
var classes: Dictionary = {}
var skills: Dictionary = {}
var feats: Dictionary = {}
var talents: Dictionary = {}
var status_effects: Dictionary = {}
var items: Dictionary = {}
var equipment: Dictionary = {}
var level_table: Dictionary = {}

func _init() -> void:
	races = _load("res://data/races/races.json")
	classes = _load("res://data/classes/classes.json")
	skills = _load("res://data/skills/skills.json")
	feats = _load("res://data/feats/feats.json")
	talents = _load("res://data/talents/talents.json")
	status_effects = _load("res://data/status_effects/status_effects.json")
	items = _load("res://data/items/items.json")
	equipment = _load("res://data/equipment/equipment.json")
	level_table = _load("res://data/progression/level_table.json")

func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameplayDB: missing " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func get_race(id: String) -> Dictionary:
	return races.get(id, {}) as Dictionary

func get_class_def(id: String) -> Dictionary:
	return classes.get(id, {}) as Dictionary

func get_skill(id: String) -> Dictionary:
	return skills.get(id, {}) as Dictionary

func get_feat(id: String) -> Dictionary:
	return feats.get(id, {}) as Dictionary

func get_talent(id: String) -> Dictionary:
	return talents.get(id, {}) as Dictionary

func get_status(id: String) -> Dictionary:
	return status_effects.get(id, {}) as Dictionary

func get_item(id: String) -> Dictionary:
	return items.get(id, {}) as Dictionary

func get_equipment(id: String) -> Dictionary:
	return equipment.get(id, {}) as Dictionary

