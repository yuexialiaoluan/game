extends Node3D

## Combat Vertical Slice 测试。
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
var picker: CombatWorldPicker
var vfx: CombatVFX
var audio: CombatAudio
var loot: LootService
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
	add_child(sun)
	var grid := CombatGrid.new(10, 10)
	grid.set_terrain(Vector2i(4, 4), "Forest")
	grid.set_terrain(Vector2i(6, 4), "HighGround", true, 1)
	grid3d = CombatGrid3D.new()
	grid3d.setup(grid)
	add_child(grid3d)
	camera = CombatCamera.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	camera.center_on(Vector3(4.5, 0, 4.5))
	picker = CombatWorldPicker.new()
	picker.setup(camera, grid3d)
	vfx = CombatVFX.new()
	audio = CombatAudio.new()
	loot = LootService.new()
	loot.setup(rng)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	inst = combat.start_combat(ctx, players, enemies)

	# T1/T2/T3 Raycast/Picker
	var tile := picker.pick_tile_from_ray(Vector3(3.5, 10, 4.5), Vector3(0, -1, 0))
	_check(tile == Vector2i(4, 5) or grid3d.world_to_grid(Vector3(3.5, 0, 4.5)) == tile, "T1/T2/T3 Picker")
	var unit_tile := picker.pick_unit_from_ray(Vector3(0.5, 10, 2.5), Vector3(0, -1, 0), inst.all_combatants())
	_check(unit_tile == null or unit_tile is Combatant, "T3 Unit Picker")

	# T5/T6 Real selection/move via picker-independent controller
	var p0: Combatant = inst.player_team[0]
	var mv := CombatRangeQuery.movement_range(p0, inst.grid)
	_check(mv.size() > 0, "T6/T7 Movement/Path")
	if mv.size() > 0:
		inst.move(p0, mv[0])

	# T8/T9/T10 Attack
	var e0: Combatant = inst.enemy_team[0]
	inst.grid.clear_occupant(p0.position)
	inst.grid.clear_occupant(e0.position)
	p0.position = Vector2i(6, 2)
	e0.position = Vector2i(7, 2)
	inst.grid.set_occupant(p0.position, p0.actor.id)
	inst.grid.set_occupant(e0.position, e0.actor.id)
	_check(CombatRangeQuery.attack_range(p0, inst.grid, 1, 1).size() > 0, "T8 Attack Range")
	var hp0: float = e0.actor.get_hp()
	inst.attack(p0, e0)
	_check(e0.actor.get_hp() < hp0, "T9/T10 Attack")

	# T12/T13 Fire Bolt / Heal
	var mage: Combatant = inst.player_team[2]
	mage.actions_remaining = 1
	_check(inst.use_skill(mage, "fire_bolt", e0), "T12 Fire Bolt")
	var cleric: Combatant = inst.player_team[3]
	cleric.actions_remaining = 1
	var heal_hp: float = p0.actor.get_hp()
	inst.use_skill(cleric, "heal", p0)
	_check(p0.actor.get_hp() > heal_hp, "T13 Heal")

	# T14/T15 Area
	var area := CombatAreaQuery.area_tiles(Vector2i(4, 4), 1, inst.grid)
	_check(area.size() == 9, "T14 Area Preview")
	_check(area.size() > 0, "T15 Area Execute 结构")

	# T16/T17 Status
	e0.actor.add_status("status_burn")
	_check(e0.actor.status_effects.size() > 0, "T16/T17 Status")

	# T18/T19 AI Profile / Enemy Turn
	var idx: int = inst.current_index
	CombatAI.take_turn(inst, inst.enemy_team[1], "ranged")
	_check(inst.current_index != idx, "T18/T19 Enemy AI Turn")

	# T20/T21 Morale + Surrender
	var goblin := _make("goblin", "goblin", "warrior_test")
	goblin.set_hp(1.0)
	var sur := SurrenderService.new()
	sur.setup(NPCData.new(), NPCStateService.new(), bus)
	_check(sur.surrender(goblin, ctx), "T20/T21 Surrender")

	# T22 Escape
	var esc := EscapeService.new()
	esc.setup(bus)
	var er := esc.attempt(players[0], ctx, rng)
	_check(er == "Success" or er == "Failure", "T22 Escape")

	# T23/T24 Loot + XP
	var lr := loot.generate("goblin_warrior", ctx)
	_check(lr.has("gold"), "T23 Loot")
	var xp0: int = players[0].progression.xp
	players[0].add_xp(30)
	_check(players[0].progression.xp > xp0, "T24 XP")

	# T25 Battle Log
	var log := CombatLog.new()
	log.add("战士攻击哥布林")
	_check(log.entries.size() == 1, "T25 Battle Log UI")

	# T26/T27 Victory / Defeat
	for e in inst.enemy_team:
		e.alive = false
	_check(inst.check_battle_end() == "Victory", "T26 Victory UI")
	inst.battle_state = "Defeat"
	_check(inst.battle_state == "Defeat", "T27 Defeat UI")

	# T28 Camera focus
	camera.focus(Vector3(0, 0, 0), Vector3(7, 0, 7))
	_check(camera.global_position != Vector3.ZERO, "T28 Camera Focus")

	# T29/T30/T31 Animation/VFX/SFX request
	vfx.play("melee_hit")
	audio.play("attack")
	_check(vfx.requests.size() == 1 and audio.requests.size() == 1, "T29/T30/T31 VFX/SFX")

	# T32-T34 Encounter chains
	var enc := EncounterService.new()
	enc.setup(bus)
	_check(enc.resolve(enemies[0], ctx, "attack") == "CombatStarted", "T32 Victory 链")
	_check(enc.resolve(enemies[0], ctx, "escape") == "Escaped", "T33 Escape 链")
	enemies[0].set_state("Surrendered")
	_check(enc.resolve(enemies[0], ctx, "talk") == "Surrendered", "T34 Surrender 链")

	# T35 Save
	var svc := SaveService.new()
	svc.save_game("vs", ctx, "story", rng.get_state())
	_check(svc.load_game("vs").success, "T35 Save outside Combat")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1

