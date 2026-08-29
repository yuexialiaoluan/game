class_name InteractionDetector
extends Node

## 独立检测器：注册表 + 距离过滤，不每帧遍历整个场景树。
var player: Node3D
var service: InteractionService
var ctx: EvaluatorContext
var nodes: Array = []
var radius: float = 3.0
var _timer: float = 0.0

func setup(p_player: Node3D, p_service: InteractionService, p_ctx: EvaluatorContext) -> void:
	player = p_player
	service = p_service
	ctx = p_ctx

func register_3d(node: Interactable3D) -> void:
	nodes.append(node)
	node.register_to(service, ctx)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.1

func get_nearest() -> Interactable3D:
	if player == null:
		return null
	var best = null
	var best_d: float = radius
	for node in nodes:
		if not is_instance_valid(node) or not node.visible:
			continue
		var d: float = player.global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best

func get_available_actions(node: Interactable3D) -> Array:
	if node == null:
		return []
	var obj := node.get_object(service)
	if obj == null:
		return []
	return service.get_available_actions(obj, ctx)
