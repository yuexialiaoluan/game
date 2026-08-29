class_name CharacterVisual
extends Node2D

## 可复用的角色表现节点：Skeleton + Resolver + Animator + AssetRegistry。
var db: CharacterVisualDB
var assets: AssetRegistry
var skeleton: CharacterSkeleton
var resolver: AppearanceResolver
var animator: CharacterAnimator

var body_id: String = "human_male"
var face_id: String = "human_male"
var eyes_id: String = "eyes_default_01"
var hair_id: String = "hair_short_01"
var clothing_id: String = "clothing_peasant_01"
var equipment: Dictionary = {}
var world_sprite: WorldSpriteAdapter

func setup(database: CharacterVisualDB, p_body_id: String, p_hair_id: String, p_clothing_id: String, p_face_id: String = "", p_eyes_id: String = "eyes_default_01", p_world_sprite_id: String = "") -> void:
	db = database
	body_id = p_body_id
	hair_id = p_hair_id
	clothing_id = p_clothing_id
	face_id = p_face_id if p_face_id != "" else p_body_id
	eyes_id = p_eyes_id

	assets = AssetRegistry.new(db)

	skeleton = CharacterSkeleton.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	skeleton.build()

	resolver = AppearanceResolver.new()
	resolver.setup(skeleton, db, assets)

	animator = CharacterAnimator.new()
	animator.name = "Animator"
	add_child(animator)
	animator.setup(skeleton)

	# Complete source sprites are only an explicit world-presentation choice.
	# The default remains the modular resolver path used by battle, previews,
	# and future replaceable character-part assets.
	if p_world_sprite_id != "":
		world_sprite = WorldSpriteAdapter.new()
		world_sprite.name = "WorldSpriteAdapter"
		add_child(world_sprite)
		world_sprite.setup(assets, self, p_world_sprite_id)

	rebuild()

func rebuild() -> void:
	if resolver != null:
		if world_sprite != null and world_sprite.uses_source_sprite():
			resolver.clear()
		else:
			resolver.rebuild(body_id, face_id, eyes_id, hair_id, clothing_id, equipment)
	if world_sprite != null:
		world_sprite.set_equipment(equipment)

func set_equipment(slot: String, id: String) -> void:
	if id == "":
		equipment.erase(slot)
	else:
		equipment[slot] = id
	rebuild()

func set_mainhand(id: String) -> void:
	set_equipment("weapon", id)

func set_offhand(id: String) -> void:
	set_equipment("shield", id)

func set_hair(id: String) -> void:
	hair_id = id
	rebuild()

func set_clothing(id: String) -> void:
	clothing_id = id
	rebuild()

func set_body(id: String) -> void:
	body_id = id
	rebuild()

func set_eyes(id: String) -> void:
	eyes_id = id
	rebuild()

func set_face(id: String) -> void:
	face_id = id
	rebuild()

func set_gender(gender: String) -> void:
	if gender == "female":
		set_body("human_female")
		set_face("human_female")
	else:
		set_body("human_male")
		set_face("human_male")

func get_bone(bone_name: String) -> Node2D:
	if skeleton == null:
		return null
	return skeleton.get_bone(bone_name)

func get_foot_local_y() -> float:
	return skeleton.get_foot_local_y() if skeleton else 16.0

