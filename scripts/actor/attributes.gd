class_name Attributes
extends RefCounted

const BASE_STATS := ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]
const DERIVED_STATS := ["max_hp", "max_mp", "attack", "defense", "magic_attack", "magic_defense", "accuracy", "evasion", "critical", "movement", "initiative"]

var base: Dictionary = {}
var final_stats: Dictionary = {}

func set_base(stat: String, value: float) -> void:
	base[stat] = value

func get_base(stat: String) -> float:
	return float(base.get(stat, 0.0))

func get_final(stat: String) -> float:
	return float(final_stats.get(stat, 0.0))

func recalculate(mods: ModifierList) -> void:
	final_stats.clear()
	for s in BASE_STATS:
		final_stats[s] = mods.apply(s, get_base(s))

	var str_: float = get_final("strength")
	var dex: float = get_final("dexterity")
	var con: float = get_final("constitution")
	var int_: float = get_final("intelligence")
	var wis: float = get_final("wisdom")

	var derived := {}
	derived["max_hp"] = 30.0 + con * 5.0 + str_ * 2.0
	derived["max_mp"] = 20.0 + int_ * 4.0 + wis * 2.0
	derived["attack"] = str_ * 2.0 + dex * 0.5
	derived["defense"] = con * 1.5 + str_ * 0.5
	derived["magic_attack"] = int_ * 2.0 + wis * 0.5
	derived["magic_defense"] = wis * 1.5 + int_ * 0.5
	derived["accuracy"] = dex * 1.5 + int_ * 0.3
	derived["evasion"] = dex * 1.2
	derived["critical"] = dex * 0.3
	derived["movement"] = 3.0 + dex * 0.1
	derived["initiative"] = dex * 0.5 + wis * 0.3

	for s in DERIVED_STATS:
		final_stats[s] = mods.apply(s, float(derived.get(s, 0.0)))
