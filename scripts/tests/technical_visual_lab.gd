extends Node3D

## 2.5D 技术验证场景：3D 世界 + 2D 像素角色。
## 独立技术原型，不属于正式游戏内容。

var db: CharacterVisualDB
var player: PlayerController3D
var npc_a: CharacterBillboard3D
var npc_b: CharacterBillboard3D
var chest: TestChest3D
var camera: OrthoFollowCamera
var prompt_label: Label
var debug_label: Label
var portrait_rect: TextureRect

var wall: StaticBody3D
var tree: StaticBody3D
var stairs: StaticBody3D
var platform: StaticBody3D

var validation_failures: int = 0

func _ready() -> void:
	db = CharacterVisualDB.new()
	_build_environment()
	_build_player()
	_build_npcs()
	_build_chest()
	_build_camera()
	_build_ui()

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_environment() -> void:
	# 光照与环境
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.10, 0.14, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.40, 0.50, 1.0)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	add_child(env_node)

	# 地面
	_add_ground(Vector2(40, 40), Vector3.ZERO, Color(0.20, 0.26, 0.20, 1.0))

	# 台阶（3 级，向 +x 上升）
	_add_box(Vector3(2.0, 0.3, 2.0), Vector3(-7.0, 0.15, -2.0), Color(0.5, 0.5, 0.55, 1.0))
	_add_box(Vector3(2.0, 0.3, 2.0), Vector3(-5.0, 0.45, -2.0), Color(0.5, 0.5, 0.55, 1.0))
	stairs = _add_box(Vector3(2.0, 0.3, 2.0), Vector3(-3.0, 0.75, -2.0), Color(0.5, 0.5, 0.55, 1.0))

	# 高台（高低差）
	platform = _add_box(Vector3(4.0, 1.0, 4.0), Vector3(2.0, 0.5, -2.0), Color(0.45, 0.42, 0.5, 1.0))

	# 墙（用于遮挡验证）
	wall = _add_box(Vector3(10.0, 4.0, 0.4), Vector3(0.0, 2.0, -7.0), Color(0.55, 0.35, 0.30, 1.0))

	# 树/柱（用于遮挡验证）
	tree = _add_pillar(Vector3(4.0, 0.0, -4.0), 0.35, 4.0, Color(0.35, 0.3, 0.22, 1.0))

	# 箱子（环境物）
	_add_box(Vector3(1.0, 1.0, 1.0), Vector3(-3.0, 0.5, -4.0), Color(0.6, 0.5, 0.25, 1.0))

func _build_player() -> void:
	player = PlayerController3D.new()
	player.name = "Player"
	player.position = Vector3(-8, 0.1, -2)
	add_child(player)
	player.attach_visual(db, "human_male", "hair_short_01", "clothing_peasant_01")

func _build_npcs() -> void:
	npc_a = CharacterBillboard3D.new()
	npc_a.name = "NPCA"
	npc_a.position = Vector3(-1, 0, 1)
	add_child(npc_a)
	var ta := db.get_npc_template("human_male_01")
	npc_a.setup(db, str(ta.get("body_id", "human_male")), str(ta.get("hair_id", "hair_a")), str(ta.get("clothing_id", "cloth_a")))

	npc_b = CharacterBillboard3D.new()
	npc_b.name = "NPCB"
	npc_b.position = Vector3(1.5, 0, 1)
	add_child(npc_b)
	var tb := db.get_npc_template("human_female_01")
	npc_b.setup(db, str(tb.get("body_id", "human_female")), str(tb.get("hair_id", "hair_b")), str(tb.get("clothing_id", "cloth_b")))

func _build_chest() -> void:
	chest = TestChest3D.new()
	chest.name = "Chest"
	chest.position = Vector3(-1.5, 0, -1)
	add_child(chest)

func _build_camera() -> void:
	camera = OrthoFollowCamera.new()
	camera.name = "Camera"
	camera.target = player
	camera.offset = Vector3(0, 11, 11)
	camera.set_zoom(12.0)
	player.camera = camera
	add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LabUI"
	add_child(layer)

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.20, 0.55)
	style.border_color = Color(0.45, 0.75, 1.0, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(360, 340)
	panel.size = panel.custom_minimum_size
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Technical Visual Lab"
	vbox.add_child(title)

	# 角色信息 + Portrait
	var info := HBoxContainer.new()
	vbox.add_child(info)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(96, 128)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.texture = _make_portrait()
	info.add_child(portrait_rect)

	var info_v := VBoxContainer.new()
	info.add_child(info_v)
	info_v.add_child(_label("Ashes of the Brave"))
	info_v.add_child(_label("HP: 100/100"))
	info_v.add_child(_label("装备: 无"))

	# 装备按钮
	var eq_row := HBoxContainer.new()
	vbox.add_child(eq_row)
	_add_button(eq_row, "普通衣服", func(): player.get_visual().set_equipment("torso", "cloth"))
	_add_button(eq_row, "铁甲", func(): player.get_visual().set_equipment("torso", "iron_armor"))
	_add_button(eq_row, "无头盔", func(): player.get_visual().set_equipment("helmet", ""))
	_add_button(eq_row, "头盔", func(): player.get_visual().set_equipment("helmet", "iron_helmet"))
	_add_button(eq_row, "无武器", func(): player.get_visual().set_equipment("weapon", ""))
	_add_button(eq_row, "长剑", func(): player.get_visual().set_equipment("weapon", "longsword"))
	_add_button(eq_row, "无盾", func(): player.get_visual().set_equipment("shield", ""))
	_add_button(eq_row, "盾牌", func(): player.get_visual().set_equipment("shield", "wood_shield"))

	# 自定义按钮
	var cust_row := HBoxContainer.new()
	vbox.add_child(cust_row)
	_add_button(cust_row, "发型A", func(): player.get_visual().set_hair("hair_short_01"))
	_add_button(cust_row, "发型B", func(): player.get_visual().set_hair("hair_long_01"))
	_add_button(cust_row, "衣服A", func(): player.get_visual().set_clothing("clothing_peasant_01"))
	_add_button(cust_row, "衣服B", func(): player.get_visual().set_clothing("clothing_adventurer_01"))

	prompt_label = _label("[E] 互动")
	prompt_label.visible = false
	vbox.add_child(prompt_label)

	var help := _label("WASD 移动，Space 攻击，E 互动，滚轮缩放")
	vbox.add_child(help)

	debug_label = _label("debug")
	vbox.add_child(debug_label)

func _process(delta: float) -> void:
	if player != null and player.get_visual() != null:
		if Input.is_key_pressed(KEY_SPACE):
			player.get_visual().animator.play_attack()

	if chest != null and prompt_label != null and player != null:
		var near: bool = player.global_position.distance_to(chest.global_position) < 2.0
		prompt_label.visible = near
		if near:
			prompt_label.text = "[E] " + chest.prompt_text
			if Input.is_key_pressed(KEY_E):
				chest.interact(player)

	if debug_label != null:
		debug_label.text = _debug_text()

func _debug_text() -> String:
	var lines: Array[String] = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	if camera != null:
		lines.append("Cam: " + str(camera.global_position.round()))
	if player != null:
		lines.append("Player: " + str(player.global_position.round()))
		var vis := player.get_visual()
		if vis != null:
			lines.append("Anim: " + str(vis.animator.state))
			lines.append("Equip: " + str(vis.equipment))
			lines.append("Layers: " + str(vis.resolver.parts.keys()))
	return "\n".join(lines)

func _make_portrait() -> Texture2D:
	return PortraitFactory.make_portrait(48, 64, Color(0.9, 0.75, 0.6, 1.0), Color(0.85, 0.65, 0.3, 1.0), Color(0.25, 0.45, 0.9, 1.0))

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l

func _add_button(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _make_mat(color)
	body.add_child(mesh)
	return body

func _add_ground(size: Vector2, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mesh.mesh = pm
	mesh.material_override = _make_mat(color)
	body.add_child(mesh)
	return body

func _add_pillar(pos: Vector3, radius: float, height: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mesh.mesh = cm
	mesh.material_override = _make_mat(color)
	body.add_child(mesh)
	return body

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

# ---------------- 自动验证 ----------------

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	var vis := player.get_visual() if player != null else null

	_check(player != null and vis != null, "T1 项目启动（玩家与角色存在）")
	_check(player is CharacterBody3D, "T2 玩家为 3D 移动体")

	# 移动
	var before: Vector3 = player.global_position
	player.move_and_collide(Vector3(1.0, 0.0, 0.0))
	_check(player.global_position.x > before.x, "T2 角色在 3D 中移动")

	# 摄像机跟随
	_check(camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "T3 正交摄像机")
	_check(camera.target == player, "T3 摄像机跟随目标")
	var cam_before: Vector3 = camera.global_position
	await get_tree().create_timer(0.2).timeout
	_check(camera.global_position.distance_to(cam_before) > 0.01, "T3 摄像机实际跟随")

	# 遮挡结构
	_check(wall != null and tree != null, "T4/T5 墙与树存在")
	if player.billboard != null and player.billboard.sprite != null:
		_check(player.billboard.sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "T4/T5 角色可被深度遮挡")
	_check(stairs != null and platform != null, "T6 台阶与高台存在")

	# 动画状态与攻击
	if vis != null:
		var hand_r: Node2D = vis.get_bone("Hand_R")
		var base_pos = vis.skeleton.base_positions["Hand_R"]
		vis.animator.play_attack()
		await get_tree().create_timer(0.15).timeout
		_check(hand_r.position != base_pos, "T9 Attack 移动 Hand_R")

	# 装备挂点
	vis.set_equipment("weapon", "longsword")
	var sword: Node = vis.resolver.parts.get("weapon")
	_check(sword != null and sword.get_parent() == vis.get_bone("Hand_R"), "T10 长剑跟随 Hand_R")
	vis.set_equipment("shield", "wood_shield")
	var shield: Node = vis.resolver.parts.get("shield")
	_check(shield != null and shield.get_parent() == vis.get_bone("Hand_L"), "T11 盾牌跟随 Hand_L")

	# 衣服/铁甲/头盔/发型
	var cloth0 = _part_color(vis, "clothing")
	vis.set_clothing("clothing_adventurer_01")
	_check(_part_color(vis, "clothing") != cloth0, "T12 衣服切换")
	vis.set_equipment("torso", "iron_armor")
	_check(not vis.resolver.parts.has("clothing") and vis.resolver.parts.has("torso"), "T13 铁甲隐藏衣服")
	vis.set_equipment("helmet", "iron_helmet")
	_check(not vis.resolver.parts.has("hair") and vis.resolver.parts.has("helmet"), "T14 头盔隐藏头发")
	vis.set_equipment("helmet", "")
	var hair0 = _part_color(vis, "hair")
	vis.set_hair("hair_long_01")
	_check(_part_color(vis, "hair") != hair0, "T15 发型切换")

	# 反复切换
	for i in range(20):
		vis.set_equipment("torso", "iron_armor" if i % 2 == 0 else "")
		vis.set_equipment("helmet", "iron_helmet" if i % 3 == 0 else "")
		vis.set_equipment("weapon", "longsword" if i % 2 == 0 else "")
		vis.set_equipment("shield", "wood_shield" if i % 2 == 0 else "")
		vis.set_hair("hair_long_01" if i % 2 == 0 else "hair_short_01")
	_check(vis.resolver._created.size() == vis.resolver.parts.size(), "T16 反复切换无重复节点")

	# NPC 模板
	_check(npc_a != null and npc_b != null, "T17 NPC 存在")
	var na_hair = _part_color(npc_a.visual, "hair")
	var nb_hair = _part_color(npc_b.visual, "hair")
	_check(na_hair != nb_hair, "T17 NPC 外观不同")

	# 宝箱交互
	var open0: bool = chest.is_open
	chest.interact(player)
	_check(chest.is_open != open0, "T18 宝箱打开")
	chest.interact(player)
	_check(chest.is_open == open0, "T18 宝箱关闭")

	# Portrait
	_check(portrait_rect != null and portrait_rect.texture != null, "T19 Portrait 显示")

func _part_color(c: CharacterVisual, key: String):
	var node = c.resolver.parts.get(key)
	if node == null:
		return null
	return node.get_meta("asset_id")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
