class_name Interactable3D
extends Node3D

## 3D 交互载体：与 2D Interactable 使用同一 prompt/interact 协议。
var prompt_text: String = "互动"

func interact(_actor: Node) -> void:
	push_warning("Interactable3D.interact() not overridden")
