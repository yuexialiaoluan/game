class_name WorldState
extends RefCounted

## 世界状态：scope -> key -> value，可序列化。
var data: Dictionary = {}

func set_value(scope: String, key: String, value) -> void:
	if not data.has(scope):
		data[scope] = {}
	data[scope][key] = value

func get_value(scope: String, key: String, default = null):
	var sc = data.get(scope, {})
	if sc.has(key):
		return sc[key]
	return default

func has_value(scope: String, key: String) -> bool:
	return data.has(scope) and data[scope].has(key)

func to_dict() -> Dictionary:
	return data.duplicate(true)

func from_dict(d: Dictionary) -> void:
	data = d.duplicate(true)
