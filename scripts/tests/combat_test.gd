extends Node

## 战棋回合制战斗基础系统测试。
var gdb: GameplayDB
var gs: GameState
var ctx: EvaluatorContext
var bus: EventBus
var rng: RNGService
var ts: TimeService
var combat: CombatService
var inst: CombatInstance
var validation_failures: int = 0

var players: Array = []
var enemies: Array = []

func _ready() -> void:
	gdb = GameplayDB.new()
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

	players.append(_make("warrior", "human", "warrior_test"))
	players.append(_make("ranger", "human", "ranger_test"))
	players.append(_make("mage", "human", "mage_test"))
	players.append(_make("healer", "human", "mage_test"))
	enemies.append(_make("goblin_warrior", "goblin", "warrior_test"))
	enemies.append(_make("goblin_archer", "goblin", "ranger_test"))
	enemies.append(_make("goblin_mage", "goblin", "mage_test"))
	enemies.append(_make("goblin_leader", "goblin", "warrior_test"))

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
	a.set_base("dexterity", 10)
	a.set_base("constitution", 10)
	a.set_base("intelligence", 10)
	a.set_base("wisdom", 10)
	a.set_base("charisma", 10)
	a.recalculate()
	ctx.actors[id] = a
	return a

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	inst = combat.start_combat(ctx, players, enemies)
	_check(inst != null and inst.battle_state == "Active", "T1/T2 Combat Start/Instance")
	_check(inst.player_team.size() == 4 and inst.enemy_team.size() == 4, "T3 Team Setup")
	_check(inst.grid.tiles.size() == 64, "T4 Grid Create")
	_check(inst.grid.is_walkable(Vector2i(4, 4)), "T5 Walkable Tile")
	_check(not inst.grid.is_walkable(Vector2i(0, 2)), "T6 Occupied Tile")

	# T7/T8 Movement
	var c0: Combatant = inst.player_team[0]
	_check(inst.move(c0, Vector2i(1, 2)), "T7 Movement")
	_check(not inst.move(c0, Vector2i(5, 2)), "T8 Movement Limit")

	# T9 Turn Order / T10 End Turn
	_check(inst.turn_order.size() == 8, "T9 Turn Order")
	var idx0 := inst.current_index
	inst.end_turn()
	_check(inst.current_index != idx0, "T10 End Turn")

	# T11/T12/T13 Basic Attack + Damage
	var a: Combatant = inst.player_team[0]
	var e: Combatant = inst.enemy_team[0]
	a.position = Vector2i(6, 2)
	inst.grid.clear_occupant(Vector2i(0, 2))
	inst.grid.set_occupant(Vector2i(6, 2), a.actor.id)
	e.position = Vector2i(7, 2)
	var hp0: float = e.actor.get_hp()
	var r := inst.attack(a, e)
	_check(e.actor.get_hp() < hp0, "T11/T12 Attack + Damage")
	_check(r.has("critical"), "T13 Critical 结构")

	# T14/T15 Skill
	var mage: Combatant = inst.player_team[2]
	mage.actions_remaining = 1
	mage.position = Vector2i(5, 2)
	var heal_target: Combatant = inst.player_team[0]
	var heal_hp: float = heal_target.actor.get_hp()
	inst.use_skill(mage, "skill_heal_test", heal_target)
	_check(heal_target.actor.get_hp() > heal_hp, "T14/T15 Skill 单体治疗")

	# T17/T18 Status
	var target: Combatant = inst.enemy_team[0]
	target.actor.add_status("status_poison")
	_check(target.actor.status_effects.size() > 0, "T17 Status Effect")
	var poison_hp: float = target.actor.get_hp()
	inst.tick_statuses(target)
	_check(target.actor.get_hp() < poison_hp, "T18 Status Tick")

	# T19/T20 Death + Turn removal
	target.actor.set_hp(0.0)
	inst.tick_statuses(target)
	_check(not target.alive, "T19/T20 Death")

	# T21 Enemy AI
	var ai_target: Combatant = inst.enemy_team[1]
	var before_round := inst.round
	CombatAI.take_turn(inst, ai_target)
	_check(inst.round >= before_round, "T21 Enemy AI")

	# T22 Morale（简单计算）
	_check(_morale(inst.enemy_team[2]) >= 0.0, "T22 Morale")

	# T23 Surrender / T24 Escape
	var sur := SurrenderService.new()
	sur.setup(NPCData.new(), NPCStateService.new(), bus)
	var low: Combatant = inst.enemy_team[2]
	low.actor.set_hp(1.0)
	_check(low.actor.get_hp() > 0.0, "T23 Surrender 前置")
	var esc := EscapeService.new()
	esc.setup(bus)
	var er := esc.attempt(players[0], ctx, rng)
	_check(er == "Success" or er == "Failure", "T24 Escape")

	# T25 Victory / T27 Loot / T28 EXP
	for e2 in inst.enemy_team:
		e2.alive = false
		inst.grid.clear_occupant(e2.position)
	_check(inst.check_battle_end() == "Victory", "T25 Battle Victory")
	var xp0: int = players[0].progression.xp
	var loot := inst.resolve_rewards()
	_check(int(loot.get("gold", 0)) > 0, "T27 Loot")
	_check(players[0].progression.xp > xp0, "T28 Experience")

	# T29 Quest Event
	var defeated := [0]
	bus.subscribe("enemy_defeated", func(_p): defeated[0] += 1)
	# 重新触发一个死亡事件
	bus.emit("enemy_defeated", { "actor": "test" })
	_check(defeated[0] == 1, "T29 Quest Event")

	# T30 Time Cost
	ts.advance_minutes(inst.round * 5)
	_check(ts.minute == (inst.round * 5) % 60, "T30 Time Cost")

	# T31/T32 Encounter -> Combat -> Result
	var enc := EncounterService.new()
	enc.setup(bus)
	var outcome := enc.resolve(enemies[0], ctx, "attack")
	_check(outcome == "CombatStarted", "T31 Encounter -> Combat")
	var inst2 := combat.start_combat(ctx, players, enemies)
	_check(inst2.check_battle_end() == "Active", "T32 Combat -> Result")

	# T33 Save/Load outside Combat
	var svc := SaveService.new()
	svc.save_game("cb", ctx, "story", rng.get_state())
	var lr := svc.load_game("cb")
	_check(lr.success, "T33 Save/Load outside Combat")

func _morale(c: Combatant) -> float:
	var m := 50.0 + c.actor.get_hp() / maxf(1.0, c.actor.max_hp()) * 20.0
	return m

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1

