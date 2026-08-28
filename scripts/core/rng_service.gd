class_name RNGService
extends RefCounted

## 统一随机接口（种子化），供 NPC/Loot/Fishing/Event/Dungeon 使用。
var seed: int = 0
var _rng := RandomNumberGenerator.new()

func set_seed(s: int) -> void:
	seed = s
	_rng.seed = s

func next_int(max_value: int) -> int:
	if max_value <= 0:
		return 0
	return _rng.randi_range(0, max_value - 1)

func next_float() -> float:
	return _rng.randf()

func pick(items: Array):
	if items.is_empty():
		return null
	return items[_rng.randi_range(0, items.size() - 1)]
