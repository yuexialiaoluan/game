class_name PlayerController3D
extends CharacterBody3D

## 正式玩家控制器：CharacterBody3D + 相机相对移动 + 逻辑朝向 + 加减速。
signal movement_changed(is_moving: bool)
signal facing_changed(facing: Vector2)

@export var move_speed: float = 4.0
@export var acceleration: float = 24.0
@export var deceleration: float = 30.0
@export var gravity: float = 20.0
@export var jump_velocity: float = 6.0
@export var floor_max_angle_deg: float = 45.0
@export var snap_length: float = 0.15
@export var step_up_max: float = 0.45

var billboard: CharacterBillboard3D
var camera: Camera3D
var facing: Vector2 = Vector2(0, -1)

var debug_enabled: bool = false
var debug_input: Vector2 = Vector2.ZERO
var input_enabled: bool = true
var _last_moving: bool = false

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.4
	shape.shape = capsule
	shape.position.y = 0.7
	add_child(shape)
	floor_max_angle = deg_to_rad(floor_max_angle_deg)
	floor_snap_length = snap_length

func attach_visual(db: CharacterVisualDB, body_id: String, hair_id: String, clothing_id: String, world_sprite_id: String = "") -> void:
	billboard = CharacterBillboard3D.new()
	billboard.name = "Billboard"
	add_child(billboard)
	billboard.setup(db, body_id, hair_id, clothing_id, "", "eyes_default_01", world_sprite_id)

func get_visual() -> CharacterVisual:
	if billboard == null:
		return null
	return billboard.visual

func get_facing() -> Vector2:
	return facing

func get_facing_name() -> String:
	var f := facing.normalized()
	if abs(f.x) >= abs(f.y):
		return "East" if f.x > 0.0 else "West"
	return "South" if f.y > 0.0 else "North"

func jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func _physics_process(delta: float) -> void:
	var input := _read_input()
	var world_dir := camera_relative_dir(input)

	var target_h := world_dir * move_speed
	var h := Vector3(velocity.x, 0.0, velocity.z)
	var rate := acceleration if world_dir.length() > 0.05 else deceleration
	h = h.move_toward(target_h, rate * delta)
	velocity.x = h.x
	velocity.z = h.z

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

	move_and_slide()
	_try_step_up(world_dir)

	var moving := world_dir.length() > 0.05
	if moving:
		var f2 := Vector2(world_dir.x, world_dir.z)
		if f2.length() > 0.01:
			facing = f2.normalized()

	if billboard != null and billboard.visual != null:
		billboard.visual.animator.set_moving(moving)

	if moving != _last_moving:
		_last_moving = moving
		movement_changed.emit(moving)
	if moving:
		facing_changed.emit(facing)

func _read_input() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	if debug_enabled:
		return debug_input
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func camera_relative_dir(input: Vector2) -> Vector3:
	if camera == null:
		return Vector3(input.x, 0.0, input.y)
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.001:
		fwd = Vector3(0, 0, -1)
	fwd = fwd.normalized()
	var right := camera.global_transform.basis.x
	right.y = 0.0
	if right.length() < 0.001:
		right = Vector3(1, 0, 0)
	right = right.normalized()
	return (right * input.x) + (fwd * -input.y)

func _try_step_up(dir: Vector3) -> void:
	if not is_on_floor() or not is_on_wall():
		return
	var fwd := Vector3(dir.x, 0.0, dir.z)
	if fwd.length() < 0.05:
		return
	fwd = fwd.normalized()
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * step_up_max + fwd * 0.5
	var to := from + Vector3.DOWN * (step_up_max + 0.2)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit:
		var step_top: float = hit.position.y
		if step_top - global_position.y <= step_up_max + 0.05:
			global_position.y = step_top + 0.02

