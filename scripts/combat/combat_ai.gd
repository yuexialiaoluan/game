class_name CombatAI

static func take_turn(inst: CombatInstance, c: Combatant, profile: String = "aggressive") -> void:
	var enemies: Array = inst.player_team if c.team == "enemy" else inst.enemy_team
	var target: Combatant = null
	var best := 9999
	for e in enemies:
		if e.alive:
			var d: int = abs(e.position.x - c.position.x) + abs(e.position.y - c.position.y)
			if d < best:
				best = d
				target = e
	if target == null:
		inst.end_turn()
		return
	match profile:
		"defensive":
			inst.end_turn()
			return
		"ranged", "caster":
			if best <= 3:
				if inst.use_skill(c, "fire_bolt", target):
					inst.end_turn()
					return
			_move_toward(inst, c, target)
		_:
			if best <= 1:
				inst.attack(c, target)
				inst.end_turn()
				return
			_move_toward(inst, c, target)
	inst.end_turn()

static func _move_toward(inst: CombatInstance, c: Combatant, target: Combatant) -> void:
	var dx: int = sign(target.position.x - c.position.x)
	var dy: int = sign(target.position.y - c.position.y)
	var dest := Vector2i(c.position.x + dx, c.position.y + dy)
	if not inst.move(c, dest):
		if dy != 0:
			dest = Vector2i(c.position.x, c.position.y + dy)
			if not inst.move(c, dest):
				return
