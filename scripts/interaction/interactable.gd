class_name Interactable
extends Node2D

## 最小交互接口：具体交互物覆写 interact()。
var prompt_text: String = "互动"

func interact(_actor: Node) -> void:
	push_warning("Interactable.interact() not overridden")
