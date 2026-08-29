class_name CombatInstance
extends RefCounted

var combat_id: String = ""
var grid: CombatGrid
var player_team: Array = []
var enemy_team: Array = []
var turn_order: Array = []
var current_index: int = 0
var round: int = 1
var battle_state: String = "Active"
var bus: EventBus = null
var rng: RNGService
var ctx: EvaluatorContext
var db: GameplayDB

func setup(p_combat_id: String, p_ctx: EvaluatorContext, p_rng: RNGService, player_actors: Array, enemy_actors: Array) -> void:
	combat_id = p_combat_id
	ctx = p_ctx
	rng = p_rng
	db = GameplayDB.new()
	grid = CombatGrid.new()

	for i in range(player_actors.size()):
		var c := Combatant.new()
		c.actor = player_actors[i]
		c.team = "player"
		c.position = Vector2i(0, 2 + i)
		c.initiative = 100 + i
		c.movement_remaining = 3
		grid.set_occupant(c.position, c.actor.id)
		player_team.append(c)
	for i in range(enemy_actors.size()):
		var c := Combatant.new()
		c.actor = enemy_actors[i]
		c.team = "enemy"
		c.position = Vector2i(7, 2 + i)
		c.initiative = 90 + i
		grid.set_occupant(c.position, c.actor.id)
		enemy_team.append(c)

	_build_turn_order()
	current_index = 0
	_apply_turn_start_effects(current_combatant())
	_emit("combat_started", { "combat_id": combat_id })

func _build_turn_order() -> void:
	turn_order.clear()
	for c in player_team + enemy_team:
		turn_order.append(c)
	turn_order.sort_custom(func(a, b): return a.initiative > b.initiative)

func all_combatants() -> Array:
	return player_team + enemy_team

func current_combatant() -> Combatant:
	if current_index >= 0 and current_index < turn_order.size():
		return turn_order[current_index]
	return null

func end_turn() -> void:
	current_index += 1
	if current_index >= turn_order.size():
		current_index = 0
		round += 1
		for c in all_combatants():
			c.movement_remaining = 3
			c.actions_remaining = 1
	_apply_turn_start_effects(current_combatant())
	_emit("turn_changed", { "round": round, "combatant": current_combatant().actor.id if current_combatant() != null else "" })

func _apply_turn_start_effects(combatant: Combatant) -> void:
	if combatant == null or combatant.actor == null or not combatant.alive:
		return
	tick_statuses(combatant)
	for entry in combatant.actor.get_equipment_combat_effects():
		var effect: Dictionary = entry.get("effect", {}) as Dictionary
		if str(effect.get("type", "")) == "max_hp_percent_damage":
			var damage := combatant.actor.max_hp() * float(effect.get("percent", 0.0)) / 100.0
			combatant.actor.damage(damage)
			_emit("affix_triggered", { "actor": combatant.actor.id, "affix": str(entry.get("source", "词条")), "damage": damage })
	if combatant.actor.is_dead():
		combatant.alive = false
		grid.clear_occupant(combatant.position)
		_emit("actor_defeated", { "actor": combatant.actor.id })

func move(combatant: Combatant, dest: Vector2i) -> bool:
	var dist: int = abs(dest.x - combatant.position.x) + abs(dest.y - combatant.position.y)
	if dist <= 0 or dist > combatant.movement_remaining:
		return false
	if not grid.is_walkable(dest):
		return false
	grid.clear_occupant(combatant.position)
	combatant.position = dest
	grid.set_occupant(dest, combatant.actor.id)
	combatant.movement_remaining -= dist
	return true

func attack(attacker: Combatant, target: Combatant) -> Dictionary:
	if attacker.actions_remaining <= 0 or not attacker.alive or not target.alive:
		return { "blocked": true }
	var dist: int = abs(attacker.position.x - target.position.x) + abs(attacker.position.y - target.position.y)
	if dist > 1:
		return { "blocked": true, "reason": "range" }
	attacker.actions_remaining -= 1
	var res := DamageService.resolve(attacker.actor, target.actor, 5.0, rng)
	_emit("attack_resolved", { "attacker": attacker.actor.id, "target": target.actor.id, "damage": res["damage"], "critical": res["critical"] })
	if target.actor.is_dead():
		target.alive = false
		grid.clear_occupant(target.position)
		_emit("enemy_defeated" if target.team == "enemy" else "actor_defeated", { "actor": target.actor.id })
	return res

func use_skill(user: Combatant, skill_id: String, target: Combatant) -> bool:
	var def := db.get_skill(skill_id)
	if def.is_empty():
		return false
	if user.actions_remaining <= 0:
		return false
	user.actions_remaining -= 1
	for eff in def.get("effects", []):
		var t := str(eff.get("type", ""))
		if t == "damage":
			DamageService.resolve(user.actor, target.actor, float(eff.get("value", 0.0)), rng)
		elif t == "heal":
			target.actor.heal(float(eff.get("value", 0.0)))
		elif t == "status":
			target.actor.add_status(str(eff.get("value", "")))
	_emit("skill_used", { "skill": skill_id, "user": user.actor.id })
	return true

func tick_statuses(combatant: Combatant) -> void:
	for se in combatant.actor.status_effects:
		var def := db.get_status(str(se.get("id", "")))
		var tick := int(def.get("tick_damage", 0))
		if tick > 0:
			combatant.actor.damage(tick)
	if combatant.actor.is_dead() and combatant.alive:
		combatant.alive = false
		grid.clear_occupant(combatant.position)
		_emit("actor_defeated", { "actor": combatant.actor.id })

func check_battle_end() -> String:
	var enemies_alive := 0
	var players_alive := 0
	for c in enemy_team:
		if c.alive:
			enemies_alive += 1
	for c in player_team:
		if c.alive:
			players_alive += 1
	if enemies_alive == 0:
		battle_state = "Victory"
	elif players_alive == 0:
		battle_state = "Defeat"
	_emit("battle_result", { "result": battle_state })
	return battle_state

func resolve_rewards() -> Dictionary:
	var gold := 0
	var xp := 0
	for c in enemy_team:
		xp += 30
	gold = 50
	for c in player_team:
		if c.alive and c.actor != null:
			c.actor.add_xp(xp)
	ctx.game_state.economy_state["gold"] = float(ctx.game_state.economy_state.get("gold", 0.0)) + gold
	return { "gold": gold, "xp": xp }

func _emit(ev: String, payload) -> void:
	if bus != null:
		bus.emit(ev, payload)


