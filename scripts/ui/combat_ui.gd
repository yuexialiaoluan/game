class_name CombatUI
extends CanvasLayer

var round_label: Label
var unit_label: Label
var hp_label: Label
var skill_label: Label
var feedback_label: Label
var result_label: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.position = Vector2(12, 12)
	add_child(root)
	round_label = Label.new()
	root.add_child(round_label)
	unit_label = Label.new()
	root.add_child(unit_label)
	hp_label = Label.new()
	root.add_child(hp_label)
	skill_label = Label.new()
	root.add_child(skill_label)
	feedback_label = Label.new()
	root.add_child(feedback_label)
	result_label = Label.new()
	root.add_child(result_label)

func refresh(inst: CombatInstance) -> void:
	if inst == null:
		return
	round_label.text = "Round %d" % inst.round
	var c: Combatant = inst.current_combatant()
	if c != null:
		unit_label.text = "Turn: " + c.actor.identity.display_name
		hp_label.text = "HP %d/%d" % [int(c.actor.get_hp()), int(c.actor.max_hp())]
	else:
		unit_label.text = "Turn: -"
		hp_label.text = "HP -"

func set_selected(c: Combatant) -> void:
	if c == null:
		skill_label.text = ""
		return
	skill_label.text = "Skills: Attack Wait"
	feedback_label.text = "选中 " + c.actor.identity.display_name

func set_feedback(t: String) -> void:
	feedback_label.text = t

func set_result(t: String) -> void:
	result_label.text = t
