class_name TestChest
extends Interactable

## 测试用箱子：开/关状态切换。
var is_open: bool = false
var _body: Sprite2D

func _ready() -> void:
	prompt_text = "打开箱子"
	_body = VisualFactory.make_pixel(Color(0.55, 0.35, 0.18, 1))
	_body.name = "ChestBody"
	_body.scale = Vector2(22, 14)
	add_child(_body)
	_update_visual()

func interact(_actor: Node) -> void:
	is_open = not is_open
	prompt_text = "关闭箱子" if is_open else "打开箱子"
	_update_visual()

func _update_visual() -> void:
	if _body:
		_body.modulate = Color(0.9, 0.7, 0.3, 1) if is_open else Color(0.55, 0.35, 0.18, 1)
