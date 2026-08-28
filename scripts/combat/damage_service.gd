class_name DamageService

static func resolve(attacker: Actor, target: Actor, base: float, rng: RNGService) -> Dictionary:
	var atk := attacker.get_stat("attack")
	var defense := target.get_stat("defense")
	var critical := rng.next_float() < 0.1
	var raw := maxf(1.0, base + atk - defense)
	if critical:
		raw *= 1.5
	var final := int(raw)
	target.damage(final)
	return { "damage": final, "critical": critical }
