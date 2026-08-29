class_name WorldSpriteAdapter
extends Node2D

## 将已有完整角色帧适配到既有分层角色视图。
## 分层 Skeleton 仍保留给换装和动画接口；此节点只提供 Prototype 的真实像素外观。
var registry: AssetRegistry
var visual: CharacterVisual
var sprite: Sprite2D
var equipment_nodes: Dictionary = {}
var idle_texture: Texture2D
var walk_texture: Texture2D
var frame_count: int = 1
var frame_width: int = 64
var frame_height: int = 64
var frame_rows: int = 1
var idle_frame_count: int = 1
var idle_frame_step: int = 1
var idle_row: int = 0
var walk_row: int = 0
var initial_frame: int = 0
var animate_idle: bool = true
var animation_time: float = 0.0

func setup(p_registry: AssetRegistry, p_visual: CharacterVisual, sprite_id: String) -> void:
	registry = p_registry
	visual = p_visual
	var spec := registry.get_world_sprite(sprite_id)
	if spec.is_empty():
		return
	var texture := registry.get_external_texture(str(spec.get("path", "")))
	if texture == null:
		return
	idle_texture = texture
	var walk_path := str(spec.get("walk_path", ""))
	walk_texture = registry.get_external_texture(walk_path) if walk_path != "" else idle_texture
	if walk_texture == null:
		walk_texture = idle_texture
	frame_count = int(spec.get("frames", 1))
	frame_width = int(spec.get("frame_width", texture.get_width()))
	frame_rows = int(spec.get("rows", 1))
	frame_height = int(spec.get("frame_height", texture.get_height() / max(frame_rows, 1)))
	idle_frame_count = int(spec.get("idle_frames", frame_count))
	idle_frame_step = int(spec.get("idle_frame_step", 1))
	idle_row = int(spec.get("idle_row", 0))
	walk_row = int(spec.get("walk_row", 0))
	initial_frame = int(spec.get("initial_frame", 0))
	animate_idle = bool(spec.get("animate_idle", true))
	sprite = Sprite2D.new()
	sprite.name = "SourceSprite"
	sprite.texture = idle_texture
	sprite.hframes = frame_count
	sprite.vframes = frame_rows
	sprite.centered = true
	# CharacterVisual already sits at the viewport foot pivot. Keep the source
	# frame centered on X and align its lower edge exactly to that same foot.
	sprite.position = Vector2(0, CharacterSkeleton.FOOT_LOCAL_Y - frame_height * 0.5)
	sprite.z_index = 100
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func set_equipment(equipment: Dictionary) -> void:
	for node in equipment_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	equipment_nodes.clear()
	for slot in equipment:
		var icon := registry.get_equipment_icon(str(equipment[slot]))
		if icon == null:
			continue
		var overlay := Sprite2D.new()
		overlay.name = "Equipment_" + str(slot)
		overlay.texture = icon
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		overlay.z_index = 110
		overlay.scale = Vector2(1.4, 1.4)
		match str(slot):
			"weapon", "mainhand":
				overlay.position = Vector2(65, 53)
			"shield", "offhand":
				overlay.position = Vector2(15, 54)
			"helmet", "head":
				overlay.position = Vector2(40, 24)
			_:
				overlay.position = Vector2(40, 48)
		add_child(overlay)
		equipment_nodes[slot] = overlay

func uses_source_sprite() -> bool:
	return sprite != null

func _process(delta: float) -> void:
	if sprite == null or visual == null or visual.animator == null:
		return
	animation_time += delta
	var is_walking := visual.animator.state == CharacterAnimator.State.WALK
	var target_texture := walk_texture if is_walking else idle_texture
	if sprite.texture != target_texture:
		sprite.texture = target_texture
	var frame_x := initial_frame
	var frame_y := idle_row
	if is_walking and frame_count > 1:
		frame_x = int(animation_time * 8.0) % frame_count
		frame_y = walk_row
	elif animate_idle and idle_frame_count > 1:
		frame_x = (int(animation_time * 3.0) % idle_frame_count) * idle_frame_step
	sprite.frame_coords = Vector2i(frame_x, frame_y)
	var weapon: Sprite2D = equipment_nodes.get("weapon") as Sprite2D
	if weapon != null and visual.animator.state == CharacterAnimator.State.ATTACK:
		weapon.rotation = -0.55 * sin(animation_time * 12.0)
	else:
		if weapon != null:
			weapon.rotation = 0.0
