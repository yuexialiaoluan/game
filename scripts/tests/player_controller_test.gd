extends Node3D

## 正式玩家控制器测试场景：平地、斜坡、台阶、墙体、相机相对移动。

var db: CharacterVisualDB
var player: PlayerController3D
var camera: OrthoFollowCamera
var debug_label: Label
var validation_failures: int = 0

func _ready() -> void:
	db = CharacterVisualDB.new()
	_build_world()
	_build_player()
	_build_camera()
	_build_ui()

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_world() -> void:
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

	_add_ground(Vector2(40, 40), Vector3.ZERO)
	_add_box(Vector3(10, 4, 0.5), Vector3(0, 2, -6), Color(0.55, 0.35, 0.3, 1.0))
	_add_box(Vector3(2.0, 0.3, 2.0), Vector3(-7.0, 0.15, 2.0), Color(0.5, 0.5, 0.55, 1.0))
	_add_box(Vector3(2.0, 0.3, 2.0), Vector3(-5.0, 0.45, 2.0), Color(0.5, 0.5, 0.55, 1.0))
	_add_box(Vector3(2.0, 0.3, 2.0), Vector3(-3.0, 0.75, 2.0), Color(0.5, 0.5, 0.55, 1.0))
	_add_ramp(Vector3(2, 0, 2), 4.0, 1.2, 2.0, Color(0.45, 0.5, 0.45, 1.0))

func _build_player() -> void:
	player = PlayerController3D.new()
	player.name = "Player"
	player.position = Vector3(-8, 0.2, 2)
	add_child(player)
	player.attach_visual(db, "human_male", "hair_short_01", "clothing_peasant_01")

func _build_camera() -> void:
	camera = OrthoFollowCamera.new()
	camera.name = "Camera"
	camera.target = player
	camera.offset = Vector3(0, 11, 11)
	camera.set_zoom(12.0)
	add_child(camera)
	player.camera = camera

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	debug_label = Label.new()
	debug_label.position = Vector2(12, 12)
	layer.add_child(debug_label)

func _process(_delta: float) -> void:
	if debug_label != null and player != null:
		debug_label.text = "Player:%s\nCam:%s\nAnim:%s\nFacing:%s\nFloor:%s" % [
			player.global_position.round(),
			camera.global_position.round() if camera else Vector3.ZERO,
			player.get_visual().animator.state if player.get_visual() else -1,
			player.get_facing_name(),
			player.is_on_floor()
		]

func _start_validation() -> void:
	await get_tree().process_frame
	await _physics_frames(3)
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

func _run_validation() -> void:
	var fwd: Vector3 = player.camera_relative_dir(Vector2(0, -1))
	_check(fwd.z < -0.5 and abs(fwd.x) < 0.3, "相机相对：W 朝前")
	var right: Vector3 = player.camera_relative_dir(Vector2(1, 0))
	_check(abs(right.x) > 0.5, "相机相对：D 朝右")

	player.debug_enabled = true
	player.debug_input = Vector2(0, -1)
	await _physics_frames(20)
	_check(player.global_position.z < 1.5, "平地移动")
	player.debug_input = Vector2.ZERO
	await _physics_frames(12)
	_check(abs(player.velocity.x) < 0.1 and abs(player.velocity.z) < 0.1, "停止后速度归零")
	if player.get_visual() != null:
		_check(player.get_visual().animator.state == CharacterAnimator.State.IDLE, "停止后回到 Idle")

	_check(player.is_on_floor(), "不悬空（在地面）")
	_check(abs(player.global_position.y) < 0.15, "脚底位置稳定")

	player.debug_input = Vector2(0, -1)
	await _physics_frames(60)
	_check(player.global_position.z > -6.0, "不会穿墙")

	player.debug_input = Vector2.ZERO
	await _physics_frames(5)
	_check(camera.global_position.distance_to(player.global_position + camera.offset) < 3.0, "摄像机跟随")

	var z0: float = camera.get_zoom()
	camera.set_zoom(20.0)
	_check(camera.get_zoom() != z0, "镜头缩放")

	var toward_x := _input_toward_x()
	player.global_position = Vector3(-8, 0.2, 2)
	player.velocity = Vector3.ZERO
	await _physics_frames(3)
	player.debug_input = toward_x
	await _physics_frames(90)
	_check(player.global_position.y > 0.3, "上下台阶（高度变化）")

	player.global_position = Vector3(1.0, 0.2, 2)
	player.velocity = Vector3.ZERO
	await _physics_frames(3)
	player.debug_input = toward_x
	await _physics_frames(90)
	_check(player.global_position.y > 0.3 and player.global_position.x > 2.0, "斜坡移动")

	var f := player.get_facing()
	_check(f.length() > 0.99, "角色逻辑朝向有效")

	player.debug_enabled = false
	player.debug_input = Vector2.ZERO

func _input_toward_x() -> Vector2:
	var r: Vector3 = player.camera_relative_dir(Vector2(1, 0))
	return Vector2(1, 0) if r.x > 0.0 else Vector2(-1, 0)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1

func _add_ground(size: Vector2, pos: Vector3) -> void:
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
	mesh.material_override = _mat(Color(0.2, 0.26, 0.2, 1.0))
	body.add_child(mesh)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
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
	mesh.material_override = _mat(color)
	body.add_child(mesh)

func _add_ramp(start: Vector3, length: float, height: float, width: float, color: Color) -> void:
	var angle := atan2(height, length)
	var center := start + Vector3(length * 0.5, height * 0.5, 0.0)
	var body := StaticBody3D.new()
	body.position = center
	body.rotation.z = angle
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.2, width)
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(length, 0.2, width)
	mesh.mesh = bm
	mesh.material_override = _mat(color)
	body.add_child(mesh)

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

