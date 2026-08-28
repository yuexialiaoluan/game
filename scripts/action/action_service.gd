class_name ActionService
extends RefCounted

## 统一 Action 解析：Request -> Conditions -> RNG -> Outcome -> Effects -> Time -> Event。
var db: ContentDB

func setup(p_db: ContentDB) -> void:
	db = p_db

func resolve(action_id: String, source: Actor, target, ctx: EvaluatorContext, rng: RNGService) -> Dictionary:
	var def := db.get_action(action_id)
	if def.is_empty():
		return { "outcome": ActionOutcome.BLOCKED, "reason": "unknown_action" }

	if not ConditionEvaluator.evaluate(def.get("conditions", {}), ctx):
		return { "outcome": ActionOutcome.BLOCKED, "reason": "condition" }

	if not _validate_target(def, target):
		return { "outcome": ActionOutcome.BLOCKED, "reason": "invalid_target" }

	var chance := float(def.get("success_chance", 100.0))
	for m in def.get("modifiers", []):
		if ConditionEvaluator.evaluate(m.get("condition", {}), ctx):
			chance += float(m.get("value", 0.0))

	var roll := rng.next_float() * 100.0
	var outcome: String = ActionOutcome.SUCCESS
	if chance <= 0.0:
		outcome = ActionOutcome.FAILURE
	elif roll >= chance:
		outcome = str(def.get("failure_outcome", ActionOutcome.FAILURE))
	else:
		outcome = ActionOutcome.SUCCESS
		if def.get("critical_on_rare", false) and target != null and target.data.has("rarity"):
			outcome = ActionOutcome.CRITICAL_SUCCESS

	var effects := []
	match outcome:
		ActionOutcome.SUCCESS:
			effects = def.get("effects_on_success", [])
		ActionOutcome.CRITICAL_SUCCESS:
			effects = def.get("effects_on_critical", def.get("effects_on_success", []))
		_:
			effects = def.get("effects_on_failure", [])

	for e in effects:
		EffectExecutor.execute(e, ctx)

	_apply_target_reward(def, target, source, ctx, rng)
	_apply_state_change(def, target, outcome, ctx)

	var minutes := int(def.get("time_cost_minutes", 0))
	if minutes > 0 and ctx.time_service != null:
		ctx.time_service.advance_minutes(minutes)

	if ctx.event_bus != null:
		ctx.event_bus.emit("action_completed", {
			"action_id": action_id,
			"outcome": outcome,
			"source_id": source.id if source != null else "",
			"target_id": target.id if target != null else ""
		})

	return { "outcome": outcome, "chance": chance, "roll": roll, "time_cost_minutes": minutes }

func _validate_target(def: Dictionary, target) -> bool:
	var tt := str(def.get("target_type", ""))
	if tt == "self":
		return true
	if tt == "actor":
		return target is Actor
	if tt == "object":
		return target is InteractableObject
	return true

func _apply_state_change(def: Dictionary, target, outcome: String, ctx: EvaluatorContext) -> void:
	if target is InteractableObject:
		var new_state := ""
		if outcome == ActionOutcome.SUCCESS or outcome == ActionOutcome.CRITICAL_SUCCESS:
			new_state = str(def.get("state_on_success", ""))
		else:
			new_state = str(def.get("state_on_failure", ""))
		if new_state != "":
			target.state = new_state
			if ctx.game_state != null:
				ctx.game_state.world.set_value("object", target.id, { "state": new_state })

func _apply_target_reward(def: Dictionary, target, source: Actor, ctx: EvaluatorContext, rng: RNGService) -> void:
	if target is InteractableObject:
		var field := str(def.get("target_reward", ""))
		if field != "":
			var item_id := str(target.data.get(field, ""))
			if item_id != "":
				EffectExecutor.execute({ "type": "add_item", "id": item_id, "qty": 1 }, ctx)
		var loot = def.get("loot_table", [])
		if loot is Array and loot.size() > 0:
			var total := 0
			for entry in loot:
				total += int(entry.get("weight", 1))
			var roll := rng.next_int(total)
			var acc := 0
			var chosen: Dictionary = {}
			for entry in loot:
				acc += int(entry.get("weight", 1))
				if roll < acc:
					chosen = entry
					break
			EffectExecutor.execute({ "type": "add_item", "id": str(chosen.get("id", "")), "qty": 1 }, ctx)
			if str(chosen.get("rarity", "")) == "rare" and ctx.event_bus != null:
				ctx.event_bus.emit("rare_loot", { "item_id": str(chosen.get("id", "")) })


