class_name CompanionFollower3D
extends CharacterBody3D

@export var follow_distance: float = 2.2
@export var move_speed: float = 3.4
@export var acceleration: float = 14.0
@export var gravity: float = 20.0

var target: Node3D
var actor: Actor
var visual: CharacterBillboard3D
var slot_index: int = 0

func setup(p_target: Node3D, p_actor: Actor, p_cdb: CharacterVisualDB, p_slot_index: int) -> void:
	target = p_target
	actor = p_actor
	slot_index = p_slot_index
	visual = CharacterBillboard3D.new()
	add_child(visual)
	var body := "human_female" if actor.identity.gender == "female" else "human_male"
	visual.setup(p_cdb, body, "hair_short_01", "clothing_adventurer_01", "", "eyes_default_01", "world.npc.0%d" % (slot_index % 6 + 1))

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.15
	shape.shape = capsule
	shape.position.y = 0.58
	add_child(shape)
	floor_snap_length = 0.2

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var behind := target.global_transform.basis.z.normalized() * (follow_distance + slot_index * 0.48)
	var side := target.global_transform.basis.x.normalized() * (0.7 if slot_index % 2 == 0 else -0.7)
	var desired := target.global_position + behind + side
	var flat := desired - global_position
	flat.y = 0.0
	var motion := Vector3.ZERO
	if flat.length() > 0.35:
		motion = flat.normalized() * move_speed
	velocity.x = move_toward(velocity.x, motion.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, motion.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	if visual != null and visual.visual != null:
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		visual.visual.animator.set_moving(horizontal_speed > 0.08)
