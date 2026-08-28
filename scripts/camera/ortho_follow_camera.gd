class_name OrthoFollowCamera
extends Camera3D

## 3D 正交跟随摄像机：平滑跟随、边界、LookAt、缩放，使用 Input Action。
@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 11, 11)
@export var follow_speed: float = 8.0
@export var min_zoom: float = 3.0
@export var max_zoom: float = 30.0
@export var limit_min: Vector3 = Vector3(-100, -10, -100)
@export var limit_max: Vector3 = Vector3(100, 100, 100)

var _size: float = 12.0

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = _size
	global_position = _desired_position()
	if target != null:
		look_at(target.global_position, Vector3.UP)

func _process(delta: float) -> void:
	if target == null:
		return
	var desired := _desired_position()
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	look_at(target.global_position, Vector3.UP)

func _desired_position() -> Vector3:
	var pos := offset
	if target != null:
		pos += target.global_position
	pos.x = clamp(pos.x, limit_min.x, limit_max.x)
	pos.y = clamp(pos.y, limit_min.y, limit_max.y)
	pos.z = clamp(pos.z, limit_min.z, limit_max.z)
	return pos

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		set_zoom(_size * 0.9)
	elif event.is_action_pressed("camera_zoom_out"):
		set_zoom(_size * 1.1)

func set_zoom(value: float) -> void:
	_size = clamp(value, min_zoom, max_zoom)
	size = _size

func get_zoom() -> float:
	return _size
