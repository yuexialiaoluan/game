class_name TestChest3D
extends Interactable3D

## 3D 测试箱子：开/关状态切换，不实现 Loot。
var is_open: bool = false
var _mesh: MeshInstance3D
var _closed_mat: StandardMaterial3D
var _open_mat: StandardMaterial3D

func _ready() -> void:
	prompt_text = "打开箱子"
	var body := StaticBody3D.new()
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.6, 0.6)
	shape.shape = box
	body.add_child(shape)

	_mesh = MeshInstance3D.new()
	_mesh.mesh = BoxMesh.new()
	_mesh.mesh.size = Vector3(0.8, 0.6, 0.6)
	_mesh.position.y = 0.3
	add_child(_mesh)

	_closed_mat = _make_mat(Color(0.55, 0.35, 0.18, 1.0))
	_open_mat = _make_mat(Color(0.9, 0.7, 0.3, 1.0))
	_update_visual()

func interact(_actor: Node) -> void:
	is_open = not is_open
	prompt_text = "关闭箱子" if is_open else "打开箱子"
	_update_visual()

func _update_visual() -> void:
	if _mesh:
		_mesh.material_override = _open_mat if is_open else _closed_mat

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
