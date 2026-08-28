class_name CombatUnitView
extends Node3D

var combatant: Combatant
var grid3d: CombatGrid3D
var visual: CharacterBillboard3D
var selected: bool = false

func setup(p_combatant: Combatant, p_grid3d: CombatGrid3D, db: CharacterVisualDB) -> void:
	combatant = p_combatant
	grid3d = p_grid3d
	visual = CharacterBillboard3D.new()
	add_child(visual)
	visual.setup(db, "human_male", "hair_short_01", "clothing_peasant_01")
	sync_position()

func sync_position() -> void:
	position = grid3d.grid_to_world(combatant.position)

func set_selected(s: bool) -> void:
	selected = s
	if visual != null and visual.sprite != null:
		visual.sprite.modulate = Color(1.2, 1.2, 1.2) if s else Color(1, 1, 1)

