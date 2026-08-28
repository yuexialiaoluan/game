class_name CombatGrid
extends RefCounted

var width: int = 8
var height: int = 8
var tiles: Dictionary = {}
var occupied: Dictionary = {}

func _init(p_width: int = 8, p_height: int = 8) -> void:
	width = p_width
	height = p_height
	for x in range(width):
		for y in range(height):
			tiles[Vector2i(x, y)] = { "terrain": "Normal", "height": 0, "walkable": true }

func is_walkable(pos: Vector2i) -> bool:
	var t = tiles.get(pos)
	if t == null:
		return false
	return bool(t.get("walkable", true)) and not occupied.has(pos)

func set_terrain(pos: Vector2i, terrain: String, walkable: bool = true, height: int = 0) -> void:
	if tiles.has(pos):
		tiles[pos] = { "terrain": terrain, "height": height, "walkable": walkable }

func set_occupant(pos: Vector2i, combatant_id: String) -> void:
	occupied[pos] = combatant_id

func clear_occupant(pos: Vector2i) -> void:
	occupied.erase(pos)

func height_at(pos: Vector2i) -> int:
	var t = tiles.get(pos)
	return int(t.get("height", 0)) if t != null else 0
