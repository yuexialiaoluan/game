class_name ActionTimeCost

## 行动时间消耗计算：base + modifiers -> final minutes。
static func compute(def: Dictionary, ctx: EvaluatorContext, rng: RNGService) -> int:
	var cost_type := str(def.get("cost_type", "fixed"))
	var base := int(def.get("base_minutes", 0))
	if cost_type == "random":
		base = rng.randi_range(int(def.get("random_min", 1)), int(def.get("random_max", 1)))
	var final_value := float(base)
	var mult := 0.0
	var add := 0.0
	for m in def.get("modifiers", []):
		var cond = m.get("condition", {})
		if cond != null and not ConditionEvaluator.evaluate(cond, ctx):
			continue
		if str(m.get("type", "add")) == "percent":
			mult += float(m.get("value", 0.0))
		else:
			add += float(m.get("value", 0.0))
	final_value = final_value * (1.0 + mult / 100.0) + add
	return int(final_value)
