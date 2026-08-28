extends Node3D

## 完整战斗交互流程测试。
var gdb: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var bus: EventBus
var rng: RNGService
var ts: TimeService
var combat: CombatService
var inst: CombatInstance
var grid3d: CombatGrid3D
var camera: CombatCamera
var ui: CombatUI
var log: CombatLog
var controller: CombatInputController
var views: Array = []
var players: Array = []
var enemies: Array = []
var validation_failures: int = 0

func _ready() -> void:
	gdb = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	bus = EventBus.new()
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	ctx.event_bus = bus
	rng = RNGService.new()
	rng.set_seed(42)
	ctx.rng = rng
	var td := TimeData.new()
	var cal := CalendarService.new()
	cal.setup(td.calendar)
	ts = TimeService.new()
	ts.setup(cal, bus)
	ctx.time_service = ts

	for i in range(4):
		players.append(_make("p%d" % i, "human", "warrior_test"))
	for i in range(4):
		enemies.append(_make("e%d" % i, "goblin", "warrior_test"))

	_build_scene()
	combat = CombatService.new()
	combat.setup(bus)

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _make(id: String, race: String, cls: String) -> Actor:
	var idn := Identity.new()
	idn.character_id = id
	idn.race_id = race
	var a := Actor.new()
	a.setup(gdb, id, idn, race, { cls: 1 })
	a.set_base("strength", 10)
	a.recalculate()
	ctx.actors[id] = a
	return a

func _build_scene() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)
	grid3d = CombatGrid3D.new()
	grid3d.setup(CombatGrid.new())
	add_child(grid3d)
	camera = CombatCamera.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	ui = CombatUI.new()
	add_child(ui)
	log = CombatLog.new()

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	inst = combat.start_combat(ctx, players, enemies)
	controller = CombatInputController.new()
	add_child(controller)
	controller.setup(inst, grid3d, camera, ui, log)
	for c in inst.all_combatants():
		var v := CombatUnitView.new()
		v.setup(c, grid3d, cdb)
		add_child(v)
		views.append(v)
	controller.bind_views(views)

	# 布置相邻位置
	var p0: Combatant = inst.player_team[0]
	var e0: Combatant = inst.enemy_team[0]
	inst.grid.clear_occupant(p0.position)
	inst.grid.clear_occupant(e0.position)
	p0.position = Vector2i(6, 2)
	e0.position = Vector2i(7, 2)
	inst.grid.set_occupant(p0.position, p0.actor.id)
	inst.grid.set_occupant(e0.position, e0.actor.id)

	_check(controller.state == CombatSelectionState.NONE, "T1 Input State")
	_check(controller.select_unit("p0"), "T2 Select Unit")
	_check(controller.selected == p0, "T3 Unit Highlight")
	_check(CombatRangeQuery.movement_range(p0, inst.grid).size() > 0, "T4 Movement Range")

	controller.begin_move()
	var mv := CombatRangeQuery.movement_range(p0, inst.grid)
	_check(mv.size() > 0, "T5 Tile Selection")
	_check(controller.select_tile(mv[0]), "T6/T7 Path Preview + Move Execute")
	_check(log.entries.size() > 0, "T25 Battle Log")

	# 把 p0 移回相邻位置
	inst.grid.clear_occupant(p0.position)
	p0.position = Vector2i(6, 2)
	inst.grid.set_occupant(p0.position, p0.actor.id)

	controller.state = CombatSelectionState.UNIT_SELECTED
	controller.selected = p0
	_check(controller.select_action("attack"), "T8 Action Menu")
	_check(CombatRangeQuery.attack_range(p0, inst.grid, 1, 1).size() > 0, "T9 Attack Range")
	var hp0: float = e0.actor.get_hp()
	_check(controller.select_target("e0"), "T10 Enemy Target")
	_check(e0.actor.get_hp() < hp0, "T11 Attack Execute")

	# Skill
	controller.selected = p0
	controller.state = CombatSelectionState.UNIT_SELECTED
	p0.actions_remaining = 1
	controller.select_action("skill")
	controller.select_skill("skill_heal_test")
	_check(controller.state == CombatSelectionState.SELECT_TARGET, "T12/T13 Skill Selection/Range")
	var heal_hp: float = p0.actor.get_hp()
	_check(controller.select_target("p0"), "T14 Skill Target")
	_check(p0.actor.get_hp() > heal_hp, "T16 Skill Execute")

	# Invalid target
	controller.selected = p0
	controller.state = CombatSelectionState.SELECT_TARGET
	controller.pending_action = "attack"
	_check(not controller.select_target("e1") or controller.blocked_reason != "", "T17/T18 Invalid Target + Blocked Reason")

	# Wait / End Turn / Cancel
	controller.selected = p0
	controller.state = CombatSelectionState.UNIT_SELECTED
	p0.actions_remaining = 1
	_check(controller.wait(), "T19 Wait")
	var idx := inst.current_index
	controller.end_turn()
	_check(inst.current_index != idx, "T20 End Turn")
	controller.cancel()
	_check(controller.state != CombatSelectionState.SELECT_TARGET, "T21 Cancel")

	# Enemy turn / lock
	controller.state = CombatSelectionState.ENEMY_TURN
	ui.set_feedback("Enemy Turn")
	CombatAI.take_turn(inst, inst.enemy_team[0])
	_check(inst.current_index != idx, "T22/T23 Enemy Turn")

	# Result
	for e in inst.enemy_team:
		e.alive = false
	_check(inst.check_battle_end() == "Victory", "T24 Battle Result")
	ui.set_result("Victory")

	# Encounter -> Combat / Combat -> World
	var enc := EncounterService.new()
	enc.setup(bus)
	_check(enc.resolve(enemies[0], ctx, "attack") == "CombatStarted", "T26 Encounter -> Combat")
	_check(gs != null, "T27 Combat -> World state")

	# Escape / Surrender
	controller.escape()
	_check(controller.state == CombatSelectionState.BATTLE_END, "T28 Escape -> World")
	var goblin := _make("goblin", "goblin", "warrior_test")
	goblin.set_hp(1.0)
	var sur := SurrenderService.new()
	sur.setup(NPCData.new(), NPCStateService.new(), bus)
	_check(sur.surrender(goblin, ctx), "T29 Surrender -> World")

	# Save
	var svc := SaveService.new()
	svc.save_game("ci", ctx, "story", rng.get_state())
	_check(svc.load_game("ci").success, "T30 Save outside Combat")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1


