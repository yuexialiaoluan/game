class_name CharacterAnimator
extends Node

enum State { IDLE, WALK, ATTACK }

var skeleton: CharacterSkeleton
var state: int = State.IDLE
var _t: float = 0.0
var _attack_t: float = 0.0
const ATTACK_DURATION := 0.5

func setup(sk: CharacterSkeleton) -> void:
	skeleton = sk

func set_moving(moving: bool) -> void:
	if state == State.ATTACK:
		return
	state = State.WALK if moving else State.IDLE

func play_attack() -> void:
	state = State.ATTACK
	_attack_t = 0.0

func _process(delta: float) -> void:
	_t += delta
	if state == State.ATTACK:
		_attack_t += delta
		if _attack_t >= ATTACK_DURATION:
			state = State.IDLE
			_attack_t = 0.0
	_apply_pose()

func _apply_pose() -> void:
	if skeleton == null:
		return
	for key in skeleton.bones:
		var bone: Node2D = skeleton.bones[key]
		bone.position = skeleton.base_positions[key]
		bone.rotation = 0.0
	match state:
		State.IDLE:
			_pose_idle()
		State.WALK:
			_pose_walk()
		State.ATTACK:
			_pose_attack()

func _pose_idle() -> void:
	var body: Node2D = skeleton.bones.get("Body")
	if body:
		body.position.y += sin(_t * 3.0) * 0.8

func _pose_walk() -> void:
	var body: Node2D = skeleton.bones.get("Body")
	if body:
		body.position.y += abs(sin(_t * 6.0)) * -1.0
	var leg_l: Node2D = skeleton.bones.get("Leg_L")
	var leg_r: Node2D = skeleton.bones.get("Leg_R")
	var arm_l: Node2D = skeleton.bones.get("Arm_L")
	var arm_r: Node2D = skeleton.bones.get("Arm_R")
	if leg_l:
		leg_l.rotation = sin(_t * 6.0) * 0.4
	if leg_r:
		leg_r.rotation = -sin(_t * 6.0) * 0.4
	if arm_l:
		arm_l.rotation = -sin(_t * 6.0) * 0.4
	if arm_r:
		arm_r.rotation = sin(_t * 6.0) * 0.4

func _pose_attack() -> void:
	var progress: float = clampf(_attack_t / ATTACK_DURATION, 0.0, 1.0)
	var arm_r: Node2D = skeleton.bones.get("Arm_R")
	var hand_r: Node2D = skeleton.bones.get("Hand_R")
	var body: Node2D = skeleton.bones.get("Body")
	if arm_r:
		arm_r.rotation = -0.7 * sin(progress * PI)
	if hand_r:
		hand_r.position += Vector2(8.0 + 8.0 * sin(progress * PI), -4.0 * sin(progress * PI))
	if body:
		body.position.x += 2.0 * sin(progress * PI)

