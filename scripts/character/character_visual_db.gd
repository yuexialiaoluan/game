class_name CharacterVisualDB
extends RefCounted

## 最小内容库：从 JSON 读取装备、外观、NPC 模板与立绘。
const EQUIPMENT_PATH := "res://data/equipment/equipment.json"
const APPEARANCE_PATH := "res://data/appearance/appearance_options.json"
const NPC_TEMPLATES_PATH := "res://data/characters/npc_templates.json"
const PORTRAITS_PATH := "res://data/appearance/portraits.json"

var equipment: Dictionary = {}
var appearance: Dictionary = {}
var npc_templates: Dictionary = {}
var portraits: Dictionary = {}

func _init() -> void:
	equipment = _load_json(EQUIPMENT_PATH)
	appearance = _load_json(APPEARANCE_PATH)
	npc_templates = _load_json(NPC_TEMPLATES_PATH)
	portraits = _load_json(PORTRAITS_PATH)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("CharacterVisualDB: missing " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	push_error("CharacterVisualDB: invalid JSON " + path)
	return {}

func get_equipment(id: String) -> Dictionary:
	return equipment.get(id, {}) as Dictionary

func get_hair(id: String) -> Dictionary:
	return (appearance.get("hair", {}) as Dictionary).get(id, {}) as Dictionary

func get_clothing(id: String) -> Dictionary:
	return (appearance.get("clothing", {}) as Dictionary).get(id, {}) as Dictionary

func get_body(id: String) -> Dictionary:
	return (appearance.get("body", {}) as Dictionary).get(id, {}) as Dictionary

func get_face(id: String) -> Dictionary:
	return (appearance.get("face", {}) as Dictionary).get(id, {}) as Dictionary

func get_eyes(id: String) -> Dictionary:
	return (appearance.get("eyes", {}) as Dictionary).get(id, {}) as Dictionary

func get_npc_template(id: String) -> Dictionary:
	return npc_templates.get(id, {}) as Dictionary

func get_portrait(id: String) -> Dictionary:
	return portraits.get(id, {}) as Dictionary

func find_asset(asset_id: String) -> Dictionary:
	for group in [appearance.get("body", {}), appearance.get("face", {}), appearance.get("eyes", {}), appearance.get("hair", {}), appearance.get("clothing", {})]:
		for key in group:
			var def = group[key]
			if def is Dictionary and str(def.get("asset_id", "")) == asset_id:
				return def
	for id in equipment:
		var eq = equipment[id]
		if eq is Dictionary:
			var visual = eq.get("visual", {})
			if visual is Dictionary and str(visual.get("asset_id", "")) == asset_id:
				return visual
	return {}
