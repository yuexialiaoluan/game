class_name CombatInputController
extends Node

var inst: CombatInstance
var grid3d: CombatGrid3D
var camera: CombatCamera
var ui: CombatUI
var log: CombatLog
var views: Dictionary = {}

var state: String = CombatSelectionState.NONE
var selected: Combatant = null
var selected_skill: String = ""
var pending_action: String = ""
var blocked_reason: String = ""

func setup(p_inst: CombatInstance, p_grid3d: CombatGrid3D, p_camera: CombatCamera, p_ui: CombatUI, p_log: CombatLog) -> void:
	inst = p_inst
	grid3d = p_grid3d
	camera = p_camera
	ui = p_ui
	log = p_log

func bind_views(arr: Array) -> void:
	for v in arr:
		if v is CombatUnitView:
			views[v.combatant.actor.id] = v

func find_combatant(id: String) -> Combatant:
	for c in inst.all_combatants():
		if c.actor.id == id:
			return c
	return null

func select_unit(id: String) -> bool:
	var c := find_combatant(id)
	if c == null or c.team != "player" or not c.alive:
		return false
	selected = c
	state = CombatSelectionState.UNIT_SELECTED
	grid3d.clear_highlights()
	for p in CombatRangeQuery.movement_range(c, inst.grid):
		grid3d.set_tile_color(p, Color(0.2, 0.6, 1.0))
	camera.center_on(grid3d.grid_to_world(c.position))
	ui.set_selected(c)
	log.add(c.actor.identity.display_name + " 被选中")
	return true

func select_action(action: String) -> bool:
	if selected == null or state != CombatSelectionState.UNIT_SELECTED:
		return false
	pending_action = action
	if action == "wait":
		return wait()
	if action == "escape":
		return escape()
	if action == "attack":
		state = CombatSelectionState.SELECT_TARGET
		grid3d.clear_highlights()
		for p in CombatRangeQuery.attack_range(selected, inst.grid, 1, 1):
			grid3d.set_tile_color(p, Color(1.0, 0.4, 0.3))
		return true
	if action == "skill":
		state = CombatSelectionState.SELECT_SKILL
		return true
	return false

func select_skill(skill_id: String) -> bool:
	selected_skill = skill_id
	state = CombatSelectionState.SELECT_TARGET
	return true

func select_target(id: String) -> bool:
	if selected == null or state != CombatSelectionState.SELECT_TARGET:
		return false
	var c := find_combatant(id)
	var tt := "enemy"
	var max_range := 1
	if pending_action == "skill" and selected_skill == "skill_heal_test":
		tt = "ally"
	var res := CombatTargetSelector.validate(tt, selected, c, inst.grid, max_range)
	if not bool(res.get("allowed", false)):
		blocked_reason = str(res.get("reason", ""))
		ui.set_feedback(blocked_reason)
		return false
	return _execute(c)

func select_tile(pos: Vector2i) -> bool:
	if state != CombatSelectionState.SELECT_MOVE_TILE:
		return false
	if not inst.move(selected, pos):
		blocked_reason = "无法到达"
		ui.set_feedback(blocked_reason)
		return false
	if views.has(selected.actor.id):
		views[selected.actor.id].sync_position()
	log.add(selected.actor.identity.display_name + " 移动到 " + str(pos))
	state = CombatSelectionState.SELECT_ACTION
	ui.set_feedback("移动完成")
	return true

func begin_move() -> void:
	if selected == null:
		return
	state = CombatSelectionState.SELECT_MOVE_TILE
	grid3d.clear_highlights()
	for p in CombatRangeQuery.movement_range(selected, inst.grid):
		grid3d.set_tile_color(p, Color(0.2, 0.6, 1.0))

func wait() -> bool:
	if selected == null or selected.actions_remaining <= 0:
		return false
	selected.actions_remaining -= 1
	log.add(selected.actor.identity.display_name + " 等待")
	state = CombatSelectionState.UNIT_SELECTED
	return true

func escape() -> bool:
	inst.battle_state = "Escape"
	state = CombatSelectionState.BATTLE_END
	ui.set_result("Escape")
	return true

func end_turn() -> void:
	inst.end_turn()
	selected = null
	grid3d.clear_highlights()
	state = CombatSelectionState.SELECT_UNIT
	ui.refresh(inst)

func cancel() -> void:
	grid3d.clear_highlights()
	if state == CombatSelectionState.SELECT_TARGET:
		state = CombatSelectionState.SELECT_SKILL if pending_action == "skill" else CombatSelectionState.UNIT_SELECTED
	elif state == CombatSelectionState.SELECT_SKILL:
		state = CombatSelectionState.UNIT_SELECTED
	elif state == CombatSelectionState.SELECT_MOVE_TILE:
		state = CombatSelectionState.UNIT_SELECTED
	else:
		selected = null
		state = CombatSelectionState.SELECT_UNIT

func _execute(target: Combatant) -> bool:
	state = CombatSelectionState.EXECUTING
	if pending_action == "attack":
		var r := inst.attack(selected, target)
		log.add(selected.actor.identity.display_name + " 攻击 " + target.actor.identity.display_name + " 造成 " + str(r.get("damage", 0)) + " 伤害")
		if target.actor.is_dead():
			log.add(target.actor.identity.display_name + " 倒下")
	elif pending_action == "skill":
		if inst.use_skill(selected, selected_skill, target):
			log.add(selected.actor.identity.display_name + " 使用 " + selected_skill)
	if views.has(target.actor.id):
		views[target.actor.id].sync_position()
	ui.refresh(inst)
	grid3d.clear_highlights()
	state = CombatSelectionState.UNIT_SELECTED
	return true
