class_name ModifierList
extends RefCounted

var _mods: Array[StatModifier] = []

func add(m: StatModifier) -> void:
	_mods.append(m)

func clear() -> void:
	_mods.clear()

func remove_by_source(source: String) -> void:
	var kept: Array[StatModifier] = []
	for m in _mods:
		if m.source != source:
			kept.append(m)
	_mods = kept

func apply(stat: String, base: float) -> float:
	var result := base
	var mult := 0.0
	for m in _mods:
		if m.stat == stat:
			if m.type == "percent":
				mult += m.value
			else:
				result += m.value
	result = result * (1.0 + mult / 100.0)
	return result
