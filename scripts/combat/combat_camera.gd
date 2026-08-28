class_name CombatCamera
extends Camera3D

func center_on(pos: Vector3) -> void:
	global_position = pos + Vector3(0, 9, 9)
	look_at(pos, Vector3.UP)

func focus(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	center_on(mid)
