class_name InteriorArea
extends RefCounted

var current: String = "exterior"

func enter(area: String) -> void:
	current = area

func exit() -> void:
	current = "exterior"
