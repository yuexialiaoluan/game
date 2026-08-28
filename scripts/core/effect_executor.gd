class_name EffectExecutor

## 数据驱动 Effect 执行器：可组合为 sequence。
static func execute(effect, ctx: EvaluatorContext) -> void:
	if effect == null:
		return
	if str(effect.get("type", "")) == "sequence":
		for e in effect.get("effects", []):
			execute(e, ctx)
		return

	var t := str(effect.get("type", ""))
	var subject := str(effect.get("subject", "player"))
	var actor := _get_actor(subject, ctx)
	var amount := float(effect.get("amount", 0.0))
	var value = effect.get("value", null)

	match t:
		"add_xp":
			if actor != null:
				actor.add_xp(int(amount))
		"add_level":
			if actor != null:
				actor.progression.level += int(amount)
				actor._grant_level_rewards()
		"add_skill":
			if actor != null:
				actor.skills[str(effect.get("id", ""))] = true
				actor.recalculate()
		"add_feat":
			if actor != null:
				var fid := str(effect.get("id", ""))
				if not actor.feats.has(fid):
					actor.feats.append(fid)
				actor.recalculate()
		"add_talent":
			if actor != null:
				var tid := str(effect.get("id", ""))
				if not actor.talents.has(tid):
					actor.talents.append(tid)
				actor.recalculate()
		"add_status":
			if actor != null:
				actor.add_status(str(effect.get("id", "")))
		"remove_status":
			if actor != null:
				_remove_status(actor, str(effect.get("id", "")))
		"modify_hp":
			if ctx.player != null:
				if amount >= 0.0:
					ctx.player.heal(amount)
				else:
					ctx.player.damage(-amount)
			else:
				ctx.game_state.player_state["hp"] = float(ctx.game_state.player_state.get("hp", 0.0)) + amount
		"modify_mp":
			ctx.game_state.player_state["mp"] = float(ctx.game_state.player_state.get("mp", 0.0)) + amount
		"modify_attribute":
			if actor != null:
				var key := str(effect.get("key", ""))
				actor.set_base(key, actor.get_base_stat(key) + amount)
				actor.recalculate()
		"add_item":
			if actor != null:
				actor.add_item(str(effect.get("id", "")), int(effect.get("qty", 1)))
		"remove_item":
			if actor != null:
				actor.remove_item(str(effect.get("id", "")), int(effect.get("qty", 1)))
		"equip":
			if actor != null:
				actor.equip(str(effect.get("slot", "")), str(effect.get("id", "")))
		"unequip":
			if actor != null:
				actor.equip(str(effect.get("slot", "")), "")
		"add_gold":
			ctx.game_state.economy_state["gold"] = float(ctx.game_state.economy_state.get("gold", 0.0)) + amount
		"remove_gold":
			ctx.game_state.economy_state["gold"] = float(ctx.game_state.economy_state.get("gold", 0.0)) - amount
		"add_currency":
			ctx.game_state.economy_state[str(effect.get("key", ""))] = float(ctx.game_state.economy_state.get(str(effect.get("key", "")), 0.0)) + amount
		"modify_relationship":
			if actor != null:
				_modify_relationship(actor, str(effect.get("target", "")), str(effect.get("key", "affinity")), amount)
		"modify_affinity":
			if actor != null:
				_modify_relationship(actor, str(effect.get("target", "")), "affinity", amount)
		"modify_trust":
			if actor != null:
				_modify_relationship(actor, str(effect.get("target", "")), "trust", amount)
		"modify_fear":
			if actor != null:
				_modify_relationship(actor, str(effect.get("target", "")), "fear", amount)
		"modify_reputation":
			if actor != null:
				var fid := str(effect.get("faction", ""))
				actor.set_reputation(fid, float(actor.reputation.get(fid, 0.0)) + amount)
		"set_story_flag":
			ctx.game_state.story_flags.set_flag(str(effect.get("flag", "")), effect.get("value", true))
		"remove_story_flag":
			ctx.game_state.story_flags.remove_flag(str(effect.get("flag", "")))
		"set_world_state":
			_set_world_state(ctx, effect)
		"unlock_location":
			ctx.game_state.world.set_value("location", str(effect.get("id", "")), { "locked": false })
		"lock_location":
			ctx.game_state.world.set_value("location", str(effect.get("id", "")), { "locked": true })
		"change_state":
			if actor != null:
				actor.set_state(str(value))
		"change_disposition":
			if actor != null:
				actor.set_state(str(value))
		"surrender":
			if actor != null:
				actor.set_state("Surrendered")
		"escape":
			if actor != null:
				actor.set_state("Alive")
		"capture":
			if actor != null:
				actor.set_state("Captured")
		"release":
			if actor != null:
				actor.set_state("Alive")
		"add_to_party":
			if actor != null and not ctx.party.has(actor):
				ctx.party.append(actor)
				actor.set_state("Companion")
		"remove_from_party":
			if actor != null:
				ctx.party.erase(actor)
				actor.set_state("Alive")
		"accept_quest":
			if ctx.quest_service != null:
				ctx.quest_service.accept_quest(str(effect.get("quest_id", "")), ctx)
		"progress_quest":
			if ctx.quest_service != null:
				ctx.quest_service.progress_objective(str(effect.get("quest_id", "")), str(effect.get("objective_id", "")), int(effect.get("amount", 1)), ctx)
		"complete_quest":
			if ctx.quest_service != null:
				ctx.quest_service.complete_quest(str(effect.get("quest_id", "")), ctx)
		"fail_quest":
			if ctx.quest_service != null:
				ctx.quest_service.fail_quest(str(effect.get("quest_id", "")))
		"teleport":
			ctx.location = str(value)
		"advance_time":
			if ctx.time_service != null:
				ctx.time_service.advance_minutes(int(effect.get("minutes", 0)))
			else:
				ctx.time += float(effect.get("minutes", 0)) / 60.0
		"advance_hours":
			if ctx.time_service != null:
				ctx.time_service.advance_hours(int(effect.get("hours", 0)))
			else:
				ctx.time += float(effect.get("hours", 0))
		"advance_days":
			if ctx.time_service != null:
				ctx.time_service.advance_days(int(effect.get("days", 0)))
			else:
				ctx.date += int(effect.get("days", 0))
		"set_time":
			if ctx.time_service != null:
				ctx.time_service.set_time(int(effect.get("hour", 0)), int(effect.get("minute", 0)))
			else:
				ctx.time = float(effect.get("hour", 0))
		"set_date":
			if ctx.time_service != null and ctx.time_service.calendar != null:
				ctx.time_service.calendar.set_date(int(effect.get("year", 1)), int(effect.get("month", 1)), int(effect.get("day", 1)))
			else:
				ctx.date = int(effect.get("day", 1))
		"set_weather":
			if ctx.weather_service != null:
				ctx.weather_service.set_weather(str(effect.get("region", "default")), str(value))
			else:
				ctx.weather = str(value)
		"change_time":
			if ctx.time_service != null:
				ctx.time_service.advance_hours(int(amount))
			else:
				ctx.time += amount
		"change_weather":
			if ctx.weather_service != null:
				ctx.weather_service.set_weather(str(effect.get("region", "default")), str(value))
			else:
				ctx.weather = str(value)
		"run_action":
			if ctx.action_service != null:
				var ttype := str(effect.get("target_type", "object"))
				var tgt = null
				if ttype == "actor":
					tgt = ctx.actors.get(str(effect.get("target_id", "")))
				else:
					tgt = ctx.action_service.get_object(str(effect.get("target_id", "")))
				ctx.action_service.resolve(str(effect.get("action_id", "")), ctx.player, tgt, ctx, ctx.rng)
		"trigger_event":
			if ctx.event_bus != null:
				ctx.event_bus.emit(str(effect.get("event", "")), ctx)
		_:
			push_warning("EffectExecutor: unhandled type " + t)

static func _get_actor(subject: String, ctx: EvaluatorContext) -> Actor:
	if subject == "" or subject == "player":
		return ctx.player
	if subject.begins_with("actor:"):
		return ctx.actors.get(subject.trim_prefix("actor:"))
	return ctx.actors.get(subject)

static func _remove_status(actor: Actor, id: String) -> void:
	var kept := []
	for se in actor.status_effects:
		if str(se.get("id", "")) != id:
			kept.append(se)
	actor.status_effects = kept
	actor.recalculate()

static func _modify_relationship(actor: Actor, target: String, field: String, amount: float) -> void:
	var rs = actor.relationships.get(target)
	if rs == null:
		actor.set_relationship(target, 0.0, 0.0, 0.0, 0.0, 0.0)
		rs = actor.relationships.get(target)
	rs.set(field, float(rs.get(field)) + amount)

static func _set_world_state(ctx: EvaluatorContext, effect) -> void:
	var scope := str(effect.get("scope", "location"))
	var key := str(effect.get("key", ""))
	var field := str(effect.get("field", ""))
	var value = effect.get("value", true)
	if field == "":
		ctx.game_state.world.set_value(scope, key, value)
	else:
		var cur = ctx.game_state.world.get_value(scope, key, {})
		if cur is Dictionary:
			cur[field] = value
			ctx.game_state.world.set_value(scope, key, cur)
		else:
			ctx.game_state.world.set_value(scope, key, { field: value })




