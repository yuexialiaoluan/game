class_name CharacterBillboard3D
extends Node3D

## 将现有 2D 分层角色渲染到 SubViewport，再以 Sprite3D billboard 放入 3D 世界。
const VIEWPORT_SIZE := Vector2i(80, 96)
const PIXEL_SIZE := 0.03125
const FOOT_PIVOT := Vector2(40, 80)

var visual: CharacterVisual
var sub_viewport: SubViewport
var sprite: Sprite3D

func setup(db: CharacterVisualDB, body_id: String, hair_id: String, clothing_id: String, face_id: String = "", eyes_id: String = "eyes_default_01") -> void:
	sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.size = VIEWPORT_SIZE
	add_child(sub_viewport)

	visual = CharacterVisual.new()
	visual.name = "Visual2D"
	visual.position = Vector2(FOOT_PIVOT.x, FOOT_PIVOT.y - CharacterSkeleton.FOOT_LOCAL_Y)
	sub_viewport.add_child(visual)
	visual.setup(db, body_id, hair_id, clothing_id, face_id, eyes_id)

	sprite = Sprite3D.new()
	sprite.name = "Billboard"
	sprite.texture = sub_viewport.get_texture()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.no_depth_test = false
	sprite.pixel_size = PIXEL_SIZE
	sprite.position.y = (VIEWPORT_SIZE.y * PIXEL_SIZE) / 2.0
	add_child(sprite)
