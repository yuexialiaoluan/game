class_name CombatService
extends RefCounted

var bus: EventBus = null
var current: CombatInstance = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func start_combat(ctx: EvaluatorContext, player_actors: Array, enemy_actors: Array) -> CombatInstance:
	var inst := CombatInstance.new()
	inst.bus = bus
	inst.setup("combat_%d" % (Time.get_ticks_msec()), ctx, ctx.rng, player_actors, enemy_actors)
	current = inst
	return inst

func battle_result() -> String:
	if current == null:
		return "Active"
	return current.check_battle_end()
