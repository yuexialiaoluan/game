class_name WorldBuilder

static func make_box(size: Vector3, pos: Vector3, color: Color, name: String = "Prop") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	return body

static func make_plane(size: Vector2, pos: Vector3, color: Color, name: String = "Ground") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mesh.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	return body

static func make_sprite_prop(texture: Texture2D, pos: Vector3, pixel_size: float, name: String = "SpriteProp") -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = name
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.no_depth_test = false
	sprite.pixel_size = pixel_size
	if texture != null:
		sprite.position = pos + Vector3.UP * (texture.get_height() * pixel_size * 0.5)
	return sprite

static func make_building_shell(size: Vector3, pos: Vector3, wall_color: Color, roof_color: Color, name: String = "Building") -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.position = pos
	root.add_child(make_box(Vector3(size.x, 0.25, size.z), Vector3(0, 0.125, 0), wall_color.darkened(0.22), "Foundation"))
	root.add_child(make_box(Vector3(size.x, size.y, size.z), Vector3(0, size.y * 0.5, 0), wall_color, "SolidWalls"))
	var roof_mesh := MeshInstance3D.new()
	roof_mesh.name = "Roof"
	var roof := PrismMesh.new()
	roof.size = Vector3(size.x + 0.45, 0.9, size.z + 0.45)
	roof.left_to_right = 0.5
	roof_mesh.mesh = roof
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = roof_color
	roof_mat.roughness = 0.95
	roof_mesh.material_override = roof_mat
	roof_mesh.position.y = size.y + 0.45
	root.add_child(roof_mesh)
	return root
