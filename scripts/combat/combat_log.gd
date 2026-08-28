class_name CombatLog
extends RefCounted

var entries: Array = []

func add(text: String) -> void:
	entries.append(text)

func get_text() -> String:
	return " / ".join(entries)

func clear() -> void:
	entries.clear()
