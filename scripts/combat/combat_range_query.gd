class_name CombatRangeQuery

static func movement_range(c: Combatant, grid: CombatGrid) -> Array:
	var out := []
	for x in range(grid.width):
		for y in range(grid.height):
			var p := Vector2i(x, y)
			var d: int = abs(p.x - c.position.x) + abs(p.y - c.position.y)
			if d > 0 and d <= c.movement_remaining and grid.is_walkable(p):
				out.append(p)
	return out

static func attack_range(c: Combatant, grid: CombatGrid, min_r: int, max_r: int) -> Array:
	var out := []
	for x in range(grid.width):
		for y in range(grid.height):
			var p := Vector2i(x, y)
			var d: int = abs(p.x - c.position.x) + abs(p.y - c.position.y)
			if d >= min_r and d <= max_r and grid.is_walkable(p):
				out.append(p)
	return out
