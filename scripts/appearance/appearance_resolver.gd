class_name AppearanceResolver
extends RefCounted

## 根据身体/脸/眼/头发/服装/装备计算最终视觉层，挂到骨骼。
var skeleton: CharacterSkeleton
var db: CharacterVisualDB
var assets: AssetRegistry
var parts: Dictionary = {}
var _created: Array[Node] = []

func setup(sk: CharacterSkeleton, database: CharacterVisualDB, registry: AssetRegistry) -> void:
	skeleton = sk
	db = database
	assets = registry

func rebuild(body_id: String, face_id: String, eyes_id: String, hair_id: String, clothing_id: String, equipment: Dictionary) -> void:
	_clear()
	var body_spec := db.get_body(body_id)
	var face_spec := db.get_face(face_id)
	if face_spec.is_empty():
		face_spec = body_spec
	var eyes_spec := db.get_eyes(eyes_id)
	var hair_spec := db.get_hair(hair_id)
	var clothing_spec := db.get_clothing(clothing_id)

	var hidden := {}
	for slot in equipment:
		var eq := db.get_equipment(str(equipment[slot]))
		var visual: Dictionary = eq.get("visual", {}) as Dictionary
		for key in visual.get("hide_rules", {}):
			hidden[key] = true
		for key in visual.get("override_rules", {}):
			hidden[key] = true

	# 基础层（body 底部对齐脚底）
	var body_tex := _tex(body_spec)
	if body_tex != null:
		var body_pos := Vector2(0, CharacterSkeleton.FOOT_LOCAL_Y - body_tex.get_height() / 2.0)
		_add_texture("Body", "body", 0, body_pos, body_tex, 0.0, Vector2.ONE, str(body_spec.get("asset_id", "body")))

	_add_texture("Head", "face", 1, Vector2(0, 0), _tex(face_spec), 0.0, Vector2.ONE, str(face_spec.get("asset_id", "face")))
	_add_texture("Head", "eyes", 2, Vector2(0, 1), _tex(eyes_spec), 0.0, Vector2.ONE, str(eyes_spec.get("asset_id", "eyes")))

	if not hidden.has("hair"):
		_add_texture("Head", "hair", 20, Vector2(0, -10), _tex(hair_spec), 0.0, Vector2.ONE, str(hair_spec.get("asset_id", "hair")))

	if not hidden.has("clothing"):
		_add_texture("Body", "clothing", 5, Vector2(0, 2), _tex(clothing_spec), 0.0, Vector2.ONE, str(clothing_spec.get("asset_id", "clothing")))

	for slot in ["torso", "helmet", "weapon", "shield"]:
		if equipment.has(slot) and str(equipment[slot]) != "":
			var eq := db.get_equipment(str(equipment[slot]))
			var visual: Dictionary = eq.get("visual", {}) as Dictionary
			var bone_name := str(visual.get("bone", "Body"))
			var layer := int(visual.get("layer", 10))
			var offset := _vec2(visual.get("offset", [0, 0]))
			var rot := float(visual.get("rotation", 0.0))
			var scale := _vec2(visual.get("scale", [1, 1]))
			var tex := assets.get_texture(str(visual.get("asset_id", "")))
			if tex == null:
				tex = TextureFactory.make(str(visual.get("shape", "rect")), _vec2i(visual.get("size", [8, 8])), _color_of(visual, "color"))
			_add_texture(bone_name, slot, layer, offset, tex, rot, scale, str(visual.get("asset_id", slot)))

func _tex(spec: Dictionary) -> Texture2D:
	var aid := str(spec.get("asset_id", ""))
	if aid == "":
		return null
	return assets.get_texture(aid)

func _add_texture(bone_name: String, key: String, layer: int, pos: Vector2, tex: Texture2D, rot: float, extra_scale: Vector2, asset_id: String) -> void:
	if tex == null:
		return
	var bone := skeleton.get_bone(bone_name)
	if bone == null:
		return
	var node := VisualFactory.make_sprite(tex)
	node.name = key
	node.z_index = layer
	node.position = pos
	node.rotation = rot
	node.scale = extra_scale
	node.set_meta("layer", layer)
	node.set_meta("asset_id", asset_id)
	bone.add_child(node)
	parts[key] = node
	_created.append(node)

func _clear() -> void:
	for n in _created:
		if is_instance_valid(n):
			n.queue_free()
	_created.clear()
	parts.clear()

func _color_of(spec: Dictionary, key: String) -> Color:
	var arr = spec.get(key, [1, 1, 1, 1])
	if arr is Array and arr.size() >= 4:
		return Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))
	return Color.WHITE

func _vec2(value) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _vec2i(value) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(8, 8)
