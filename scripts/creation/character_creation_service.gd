class_name CharacterCreationService
extends RefCounted

var game_mode: String = "story"
var data: Dictionary = {}

const RULES := { "story": { "race_locked": "human" }, "free": {} }

func setup(mode: String) -> void:
	game_mode = mode
	data = {
		"name": "",
		"gender": "male",
		"race": "human",
		"hair_id": "hair_short_01",
		"clothing_id": "clothing_peasant_01",
		"face_id": "human_male",
		"initial_class": "warrior_test",
		"background": "common_blacksmith",
		"game_mode": mode
	}
	if mode == "story":
		data["race"] = "human"

func is_race_locked() -> bool:
	var rules = RULES.get(game_mode, {})
	return rules.has("race_locked")

func get_allowed_race() -> String:
	var rules = RULES.get(game_mode, {})
	return str(rules.get("race_locked", ""))

func set_value(key: String, value) -> void:
	if key == "race" and is_race_locked():
		data["race"] = get_allowed_race()
		return
	data[key] = value

func validate_name(name: String) -> String:
	if name.strip_edges().is_empty():
		return "名称不能为空"
	if name.length() > 16:
		return "名称过长"
	for ch in name:
		if ch in ["<", ">", "\"", "\\", "/"]:
			return "名称含非法字符"
	return ""

func get_data() -> Dictionary:
	return data.duplicate(true)
