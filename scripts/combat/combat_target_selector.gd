class_name CombatTargetSelector

static func validate(target_type: String, attacker: Combatant, target: Combatant, grid: CombatGrid, max_range: int) -> Dictionary:
	if target == null or not target.alive:
		return { "allowed": false, "reason": "无有效目标" }
	if target_type == "self":
		if target == attacker:
			return { "allowed": true, "reason": "" }
		return { "allowed": false, "reason": "只能选择自己" }
	var d: int = abs(attacker.position.x - target.position.x) + abs(attacker.position.y - target.position.y)
	if d > max_range:
		return { "allowed": false, "reason": "超出范围" }
	return { "allowed": true, "reason": "" }
