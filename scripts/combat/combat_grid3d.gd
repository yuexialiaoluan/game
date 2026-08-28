class_name CombatGrid3D
extends Node3D

var grid: CombatGrid
var tile_size: float = 1.0
var tile_nodes: Dictionary = {}

func setup(p_grid: CombatGrid) -> void:
	grid = p_grid
	for x in range(grid.width):
		for y in range(grid.height):
			var pos := Vector2i(x, y)
			var mesh := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(tile_size * 0.9, 0.05, tile_size * 0.9)
			mesh.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.27, 0.3, 1.0)
			mesh.material_override = mat
			mesh.position = grid_to_world(pos)
			add_child(mesh)
			tile_nodes[pos] = mesh

func grid_to_world(pos: Vector2i) -> Vector3:
	return Vector3(float(pos.x) * tile_size, 0.0, float(pos.y) * tile_size)

func world_to_grid(p: Vector3) -> Vector2i:
	return Vector2i(int(round(p.x / tile_size)), int(round(p.z / tile_size)))

func set_tile_color(pos: Vector2i, color: Color) -> void:
	if tile_nodes.has(pos):
		var mat: StandardMaterial3D = tile_nodes[pos].material_override
		mat.albedo_color = color

func clear_highlights() -> void:
	for pos in tile_nodes:
		set_tile_color(pos, Color(0.25, 0.27, 0.3, 1.0))
