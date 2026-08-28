class_name CombatWorldPicker
extends RefCounted

var camera: Camera3D
var grid3d: CombatGrid3D

func setup(p_camera: Camera3D, p_grid3d: CombatGrid3D) -> void:
	camera = p_camera
	grid3d = p_grid3d

func pick_tile_from_ray(origin: Vector3, dir: Vector3) -> Vector2i:
	if abs(dir.y) < 0.001:
		return Vector2i(-1, -1)
	var t := -origin.y / dir.y
	var point := origin + dir * t
	return grid3d.world_to_grid(point)

func pick_unit_from_ray(origin: Vector3, dir: Vector3, combatants: Array) -> Combatant:
	var tile := pick_tile_from_ray(origin, dir)
	for c in combatants:
		if c.alive and c.position == tile:
			return c
	return null

func pick_tile(screen_pos: Vector2) -> Vector2i:
	if camera == null:
		return Vector2i(-1, -1)
	return pick_tile_from_ray(camera.project_ray_origin(screen_pos), camera.project_ray_normal(screen_pos))
