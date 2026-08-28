class_name Progression
extends RefCounted

var level: int = 1
var xp: int = 0
var attribute_points: int = 0
var xp_to_next: Array = []

func setup(table: Array) -> void:
	xp_to_next = table

func get_xp_to_next() -> int:
	if level - 1 < xp_to_next.size():
		return int(xp_to_next[level - 1])
	return 100000

func add_xp(amount: int) -> Array:
	xp += amount
	var rewards := []
	while level - 1 < xp_to_next.size() and xp >= get_xp_to_next():
		xp -= get_xp_to_next()
		level += 1
		attribute_points += 3
		rewards.append("level_up")
	return rewards
