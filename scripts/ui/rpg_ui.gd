class_name RPGUI
extends CanvasLayer

## 极简 RPG UI：只读服务结果，不直接改状态。
var hud_label: Label
var character_label: Label
var inventory_label: Label
var party_label: Label
var tooltip_label: Label
var feedback_label: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.position = Vector2(12, 12)
	add_child(root)
	hud_label = Label.new()
	root.add_child(hud_label)
	character_label = Label.new()
	root.add_child(character_label)
	inventory_label = Label.new()
	root.add_child(inventory_label)
	party_label = Label.new()
	root.add_child(party_label)
	tooltip_label = Label.new()
	root.add_child(tooltip_label)
	feedback_label = Label.new()
	root.add_child(feedback_label)

func refresh_character(a: Actor) -> void:
	character_label.text = "%s Lv%d XP%d AP%d STR%d" % [a.identity.display_name, a.progression.level, a.progression.xp, a.progression.attribute_points, int(a.get_base_stat("strength"))]

func refresh_inventory(a: Actor) -> void:
	var parts := []
	for id in a.inventory:
		parts.append(str(id) + "x" + str(a.inventory[id]))
	inventory_label.text = "Inv:" + " ".join(parts)

func refresh_party(ps: PartyService) -> void:
	var names := []
	for a in ps.active:
		names.append(a.identity.display_name)
	party_label.text = "Active:" + " ".join(names) + " Reserve:" + str(ps.reserve.size())

func set_tooltip(t: String) -> void:
	tooltip_label.text = t

func set_feedback(t: String) -> void:
	feedback_label.text = t

func set_hud(t: String) -> void:
	hud_label.text = t
