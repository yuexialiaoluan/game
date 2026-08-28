class_name Interactable3D
extends Node3D

## 3D 表现层交互载体：桥接到 Gameplay 层的 InteractableObject。
var prompt_text: String = "互动"
var object_id: String = ""
var object_type: String = ""
var display_name: String = ""
var actor_ref: Actor = null
var _gameplay_object: InteractableObject = null

func interact(_actor: Node) -> void:
	push_warning("Interactable3D.interact() not overridden")

func register_to(service: InteractionService, ctx: EvaluatorContext) -> InteractableObject:
	if _gameplay_object != null:
		return _gameplay_object
	var obj := InteractableObject.new()
	obj.id = object_id
	obj.object_type = object_type
	obj.state = "Closed"
	# 从 WorldState 恢复状态
	if ctx != null and ctx.game_state != null and object_id != "":
		var saved = ctx.game_state.world.get_value("object", object_id, null)
		if saved is Dictionary and saved.has("state"):
			obj.state = str(saved.get("state", "Closed"))
	service.register(obj)
	_gameplay_object = obj
	return obj

func get_object(service: InteractionService) -> InteractableObject:
	if _gameplay_object == null:
		return null
	return _gameplay_object
