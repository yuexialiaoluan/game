class_name StoryFlagStore
extends RefCounted

## 稳定字符串 ID 的剧情 Flag，可查询/设置/删除/序列化。
var flags: Dictionary = {}

func set_flag(id: String, value = true) -> void:
	flags[id] = value

func get_flag(id: String) -> bool:
	return bool(flags.get(id, false))

func has_flag(id: String) -> bool:
	return flags.has(id)

func remove_flag(id: String) -> void:
	flags.erase(id)

func to_dict() -> Dictionary:
	return flags.duplicate()

func from_dict(d: Dictionary) -> void:
	flags = d.duplicate()
