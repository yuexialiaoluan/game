class_name CombatAreaQuery

static func area_tiles(center: Vector2i, radius: int, grid: CombatGrid) -> Array:
	var out := []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var p := Vector2i(x, y)
			if grid.tiles.has(p):
				out.append(p)
	return out
