class_name EquipmentDropSlot
extends Button

signal equipment_dropped(item_id: String, slot: String)

var slot: String = ""
var db: GameplayDB

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or not data.has("item_id") or db == null:
		return false
	var definition := db.get_equipment(str(data.item_id))
	return not definition.is_empty() and _slot_matches(str(definition.get("slot", "")))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	equipment_dropped.emit(str(data.item_id), slot)

func _slot_matches(source_slot: String) -> bool:
	source_slot = _canonical_slot(source_slot)
	if slot.begins_with("ring_"):
		return source_slot == "ring"
	return source_slot == slot

func _canonical_slot(source_slot: String) -> String:
	match source_slot:
		"head": return "helmet"
		"torso": return "chest"
		"weapon": return "mainhand"
		"shield": return "offhand"
	return source_slot
