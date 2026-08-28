class_name LootService
extends RefCounted

var data: Dictionary = {}
var rng: RNGService

func setup(p_rng: RNGService) -> void:
	rng = p_rng
	if FileAccess.file_exists("res://data/loot/loot.json"):
		var text := FileAccess.get_file_as_string("res://data/loot/loot.json")
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			data = parsed

func generate(enemy_id: String, ctx: EvaluatorContext) -> Dictionary:
	var table = data.get(enemy_id, {}) as Dictionary
	var gold_range = table.get("gold", [0, 0])
	var gold := rng.randi_range(int(gold_range[0]), int(gold_range[1])) if gold_range is Array and gold_range.size() == 2 else 0
	if ctx.game_state != null:
		ctx.game_state.economy_state["gold"] = float(ctx.game_state.economy_state.get("gold", 0.0)) + gold
	var items := []
	for entry in table.get("items", []):
		if rng.next_int(100) < int(entry.get("weight", 0)):
			if ctx.player != null:
				ctx.player.add_item(str(entry.get("id", "")), 1)
			items.append(str(entry.get("id", "")))
	return { "gold": gold, "items": items }
