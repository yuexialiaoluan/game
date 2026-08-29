class_name NPCWander3D
extends Node

@export var move_speed: float = 1.15
@export var pause_duration: float = 1.5

var host: Node3D
var visual: CharacterBillboard3D
var waypoints: Array[Vector3] = []
var waypoint_index: int = 0
var pause_left: float = 0.0

func setup(p_host: Node3D, p_visual: CharacterBillboard3D, p_waypoints: Array[Vector3], p_speed: float = 1.15) -> void:
	host = p_host
	visual = p_visual
	waypoints = p_waypoints
	move_speed = p_speed

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(host) or waypoints.is_empty():
		return
	if pause_left > 0.0:
		pause_left -= delta
		_set_moving(false)
		return
	var target := waypoints[waypoint_index]
	var flat := target - host.global_position
	flat.y = 0.0
	if flat.length() <= 0.06:
		waypoint_index = (waypoint_index + 1) % waypoints.size()
		pause_left = pause_duration
		_set_moving(false)
		return
	host.global_position = host.global_position.move_toward(target, move_speed * delta)
	_set_moving(true)

func _set_moving(is_moving: bool) -> void:
	if visual != null and visual.visual != null and visual.visual.animator != null:
		visual.visual.animator.set_moving(is_moving)
