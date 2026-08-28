class_name ConditionEvaluator

## 数据驱动 Condition 评估器：支持 all/any/not、比较、范围、集合。
static func evaluate(cond, ctx: EvaluatorContext) -> bool:
	if cond == null:
		return true
	var type := str(cond.get("type", ""))
	match type:
		"all":
			for c in cond.get("conditions", []):
				if not evaluate(c, ctx):
					return false
			return true
		"any":
			for c in cond.get("conditions", []):
				if evaluate(c, ctx):
					return true
			return false
		"not":
			return not evaluate(cond.get("condition", {}), ctx)
		_:
			var actual = _resolve(cond, ctx)
			return _compare(actual, str(cond.get("operator", "==")), cond.get("value", true))

static func _resolve(cond, ctx: EvaluatorContext):
	var t := str(cond.get("type", ""))
	var key := str(cond.get("key", ""))
	var actor := _get_actor(cond.get("subject", "player"), ctx)
	match t:
		"level":
			return actor.progression.level if actor != null else 0
		"xp":
			return actor.progression.xp if actor != null else 0
		"attribute":
			return actor.get_stat(key) if actor != null else 0.0
		"base_attribute":
			return actor.get_base_stat(key) if actor != null else 0.0
		"race":
			return actor.race_id if actor != null else ""
		"class":
			return actor.classes.has(key) if actor != null else false
		"skill":
			return actor.skills.has(key) if actor != null else false
		"feat":
			return actor.feats.has(key) if actor != null else false
		"talent":
			return actor.talents.has(key) if actor != null else false
		"status":
			return _actor_has_status(actor, key)
		"equipment":
			return actor.equipment.get(key, "") if actor != null else ""
		"inventory":
			return int(actor.inventory.get(key, 0)) if actor != null else 0
		"currency":
			return _currency(ctx, key)
		"hp":
			return float(ctx.game_state.player_state.get("hp", 0.0))
		"mp":
			return float(ctx.game_state.player_state.get("mp", 0.0))
		"relationship":
			return _relationship(ctx, cond, actor)
		"faction":
			return actor.faction_id if actor != null else ""
		"reputation":
			return float(actor.reputation.get(key, 0.0)) if actor != null else 0.0
		"quest":
			return ctx.game_state.quest_state.get(key, "")
		"story_flag":
			return ctx.game_state.story_flags.get_flag(key)
		"event_state":
			return ctx.game_state.event_state.get(key, "")
		"world":
			return _world_value(ctx, cond)
		"location":
			return ctx.location
		"time":
			return ctx.time
		"date":
			return ctx.date
		"season":
			return ctx.season
		"weather":
			return ctx.weather
		"distance":
			return ctx.distance
		"combat_state":
			return ctx.combat_state
		"stealth_state":
			return ctx.stealth_state
		"crime_state":
			return ctx.crime_state
		"surrender_state":
			return ctx.surrender_state
		"captured_state":
			return ctx.captured_state
		"actor_state":
			return actor.state if actor != null else ""
		_:
			return null

static func _get_actor(subject, ctx: EvaluatorContext) -> Actor:
	var s := str(subject)
	if s == "" or s == "player":
		return ctx.player
	if s.begins_with("actor:"):
		return ctx.actors.get(s.trim_prefix("actor:"))
	return ctx.actors.get(s)

static func _actor_has_status(actor: Actor, id: String) -> bool:
	if actor == null:
		return false
	for se in actor.status_effects:
		if str(se.get("id", "")) == id:
			return true
	return false

static func _currency(ctx: EvaluatorContext, key: String) -> float:
	return float(ctx.game_state.economy_state.get(key, 0.0))

static func _relationship(ctx: EvaluatorContext, cond, actor: Actor) -> float:
	var target := str(cond.get("target", ""))
	var field := str(cond.get("key", "affinity"))
	if actor == null or not actor.relationships.has(target):
		return 0.0
	var rs = actor.relationships[target]
	return float(rs.get(field))

static func _world_value(ctx: EvaluatorContext, cond):
	var scope := str(cond.get("scope", "location"))
	var key := str(cond.get("key", ""))
	var field := str(cond.get("field", ""))
	var v = ctx.game_state.world.get_value(scope, key, null)
	if field != "" and v is Dictionary:
		return v.get(field)
	return v

static func _compare(actual, op: String, expected) -> bool:
	match op:
		">=":
			return _num(actual) >= _num(expected)
		"<=":
			return _num(actual) <= _num(expected)
		">":
			return _num(actual) > _num(expected)
		"<":
			return _num(actual) < _num(expected)
		"==":
			return actual == expected
		"!=":
			return actual != expected
		"between":
			if expected is Array and expected.size() >= 2:
				return _num(actual) >= _num(expected[0]) and _num(actual) <= _num(expected[1])
			return false
		"in":
			return expected is Array and expected.has(actual)
		_:
			return false

static func _num(x) -> float:
	if x is bool:
		return 1.0 if x else 0.0
	return float(x)
