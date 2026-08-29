class_name MenuNavigator
extends RefCounted

var state: String = "Title"
var stack: Array = []

func goto(s: String) -> void:
	stack.append(state)
	state = s

func back() -> void:
	if not stack.is_empty():
		state = str(stack.pop_back())
