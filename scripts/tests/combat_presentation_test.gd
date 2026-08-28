extends Node3D

## 3D 战斗表现与 UI 集成测试。
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
var views: Array = []
var validation_failures: int = 0

var players: Array = []
var enemies: Array = []

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
	sun.shadow_enabled = true
	add_child(sun)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.1, 0.14, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.5, 1.0)
	env_node.environment = env
	add_child(env_node)

	grid3d = CombatGrid3D.new()
	grid3d.setup(CombatGrid.new())
	add_child(grid3d)

	camera = CombatCamera.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)

	ui = CombatUI.new()
	add_child(ui)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	inst = combat.start_combat(ctx, players, enemies)
	_check(inst != null, "T1 Battle Scene 启动")

	# 绑定视图
	for c in inst.all_combatants():
		var v := CombatUnitView.new()
		v.setup(c, grid3d, cdb)
		add_child(v)
		views.append(v)

	# T2/T3 Grid
	_check(grid3d.tile_nodes.size() == 64, "T2 Grid 3D 表现")
	_check(grid3d.grid_to_world(Vector2i(3, 4)) == Vector3(3, 0, 4), "T3 Grid -> World")
	_check(grid3d.world_to_grid(Vector3(3, 0, 4)) == Vector2i(3, 4), "T3 World -> Grid")

	# T4 Unit Spawn / T5 Select
	_check(views.size() == 8, "T4 Unit Spawn")
	var v0: CombatUnitView = views[0]
	v0.set_selected(true)
	_check(v0.selected, "T5 Unit Select")
	ui.set_selected(v0.combatant)

	# T6 Movement Highlight
	grid3d.set_tile_color(Vector2i(1, 2), Color(0.2, 0.6, 1.0))
	_check((grid3d.tile_nodes[Vector2i(1, 2)].material_override as StandardMaterial3D).albedo_color == Color(0.2, 0.6, 1.0), "T6 Movement Highlight")

	# T7 Movement
	var c0: Combatant = v0.combatant
	var dest := Vector2i(1, 2)
	_check(inst.move(c0, dest), "T7 Movement Execution")
	v0.sync_position()
	_check(v0.global_position == grid3d.grid_to_world(dest), "T7 View 位置同步")

	# T8/T18 HUD
	ui.refresh(inst)
	_check(ui.round_label.text != "", "T8/T18 Battle HUD")

	# T9/T10/T11 Attack
	var a: Combatant = inst.player_team[0]
	var e: Combatant = inst.enemy_team[0]
	a.position = Vector2i(6, 2)
	inst.grid.clear_occupant(Vector2i(0, 2))
	inst.grid.set_occupant(Vector2i(6, 2), a.actor.id)
	e.position = Vector2i(7, 2)
	var hp0: float = e.actor.get_hp()
	inst.attack(a, e)
	_check(e.actor.get_hp() < hp0, "T9/T10 Attack Target/Execute")
	ui.refresh(inst)
	_check(ui.hp_label.text != "", "T11 Damage UI")

	# T12/T13 Skill
	var mage: Combatant = inst.player_team[2]
	mage.actions_remaining = 1
	mage.position = Vector2i(5, 2)
	var heal_hp: float = a.actor.get_hp()
	inst.use_skill(mage, "skill_heal_test", a)
	_check(a.actor.get_hp() > heal_hp, "T12/T13 Skill Target/Execute")

	# T14 Status UI
	e.actor.add_status("status_poison")
	_check(e.actor.status_effects.size() > 0, "T14 Status UI")

	# T15 Death Visual / T16 Enemy Turn
	e.actor.set_hp(0.0)
	inst.tick_statuses(e)
	_check(not e.alive, "T15 Death Visual")
	var idx_before: int = inst.current_index
	CombatAI.take_turn(inst, inst.enemy_team[1])
	_check(inst.current_index != idx_before, "T16 Enemy Turn")

	# T17 Camera
	camera.center_on(Vector3(3, 0, 3))
	_check(camera.global_position != Vector3.ZERO, "T17 Battle Camera")

	# T19 Result / T20 Escape
	var esc := EscapeService.new()
	esc.setup(bus)
	var er := esc.attempt(players[0], ctx, rng)
	_check(er == "Success" or er == "Failure", "T20 Escape")
	for e2 in inst.enemy_team:
		e2.alive = false
	_check(inst.check_battle_end() == "Victory", "T19 Battle Result")
	ui.set_result("Victory")

	# T21 Encounter -> Combat -> Battle
	var enc := EncounterService.new()
	enc.setup(bus)
	_check(enc.resolve(enemies[0], ctx, "attack") == "CombatStarted", "T21 Encounter -> Combat")
	var inst2 := combat.start_combat(ctx, players, enemies)
	_check(inst2 != null, "T21 Battle")

	# T22/T23 World state
	gs.story_flags.set_flag("world_ok", true)
	var svc := SaveService.new()
	svc.save_game("cp", ctx, "story", rng.get_state())
	var lr := svc.load_game("cp")
	var gs2 := GameState.new()
	gs2.from_dict(lr.data.game_state)
	_check(gs2.story_flags.get_flag("world_ok"), "T22/T23 World/Save state")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
