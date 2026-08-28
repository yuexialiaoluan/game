class_name CharacterSkeleton
extends Node2D

## 最小 2D 骨骼结构：骨骼为可挂载视觉部件的 Node2D。
const FOOT_LOCAL_Y := 16.0

var bones: Dictionary = {}
var base_positions: Dictionary = {}

func build() -> void:
	for child in get_children():
		child.queue_free()
	bones.clear()
	base_positions.clear()

	var body := _add_bone("Body", self, Vector2.ZERO)
	_add_bone("Head", body, Vector2(0, -16))
	var arm_l := _add_bone("Arm_L", body, Vector2(-9, -4))
	var arm_r := _add_bone("Arm_R", body, Vector2(9, -4))
	_add_bone("Hand_L", arm_l, Vector2(0, 10))
	_add_bone("Hand_R", arm_r, Vector2(0, 10))
	_add_bone("Leg_L", body, Vector2(-4, 14))
	_add_bone("Leg_R", body, Vector2(4, 14))

func _add_bone(bone_name: String, parent: Node2D, pos: Vector2) -> Node2D:
	var bone := Node2D.new()
	bone.name = bone_name
	parent.add_child(bone)
	bone.position = pos
	bones[bone_name] = bone
	base_positions[bone_name] = pos
	return bone

func get_bone(bone_name: String) -> Node2D:
	return bones.get(bone_name)

func get_foot_local_y() -> float:
	return FOOT_LOCAL_Y
