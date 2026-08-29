class_name InventoryDragItem
extends PanelContainer

var item_id: String = ""

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == "":
		return null
	var preview := Label.new()
	preview.text = get_meta("display_name", item_id)
	preview.modulate = Color(0.75, 0.9, 1.0)
	set_drag_preview(preview)
	return { "item_id": item_id }
