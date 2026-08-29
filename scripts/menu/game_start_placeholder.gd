extends Node

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "角色创建完成。"
	label.position = Vector2(40, 40)
	label.add_theme_font_size_override("font_size", 24)
	layer.add_child(label)
	var back := Button.new()
	back.text = "返回标题"
	back.position = Vector2(40, 90)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn"))
	layer.add_child(back)
