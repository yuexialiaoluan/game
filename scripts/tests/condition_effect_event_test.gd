extends Node

## Condition / Effect / Event / GameState 基础设施测试与完整链路验证。
var db: GameplayDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var enemy: Actor
var bus: EventBus
var registry: EventRegistry
var rng: RNGService
var validation_failures: int = 0

func _ready() -> void:
	db = GameplayDB.new()
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs
	_build_player()
	_build_enemy()
	ctx.player = player
	ctx.actors["enemy_01"] = enemy

	bus = EventBus.new()
	registry = EventRegistry.new()
	registry.load("res://data/events/events.json")
	ctx.event_bus = bus
	bus.subscribe("on_test_reward", func(_p): registry.dispatch("on_test_reward", ctx))
	bus.subscribe("on_actor_surrendered", func(_p): registry.dispatch("on_actor_surrendered", ctx))
	bus.subscribe("on_enter_location", func(_p): registry.dispatch("on_enter_location", ctx))
	rng = RNGService.new()

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_player() -> void:
	var idp := Identity.new()
	idp.character_id = "player"
	idp.display_name = "玩家"
	idp.gender = "male"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(db, "player", idp, "human", { "warrior_test": 5 })
	player.set_base("strength", 10)
	player.set_base("dexterity", 8)
	player.set_base("constitution", 12)
	player.set_base("intelligence", 6)
	player.set_base("wisdom", 7)
	player.set_base("charisma", 8)
	player.progression.level = 5
	player.add_xp(0)
	player.set_relationship("iva", 50.0, 30.0, 5.0, 20.0, 0.0)
	gs.economy_state["gold"] = 100.0

func _build_enemy() -> void:
	var ide := Identity.new()
	ide.character_id = "enemy_01"
	ide.display_name = "哥布林"
	ide.race_id = "goblin"
	enemy = Actor.new()
	enemy.setup(db, "enemy_01", ide, "goblin", {})
	enemy.set_state("Enemy")

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# 简单 Condition
	_check(ConditionEvaluator.evaluate({ "type": "level", "subject": "player", "operator": ">=", "value": 5 }, ctx), "简单 Condition level>=5")

	# AND / OR / NOT
	var and_cond := { "type": "all", "conditions": [
		{ "type": "level", "subject": "player", "operator": ">=", "value": 5 },
		{ "type": "currency", "key": "gold", "operator": ">=", "value": 100 }
	] }
	_check(ConditionEvaluator.evaluate(and_cond, ctx), "AND 组合")
	var or_cond := { "type": "any", "conditions": [
		{ "type": "level", "subject": "player", "operator": "<", "value": 3 },
		{ "type": "currency", "key": "gold", "operator": ">=", "value": 50 }
	] }
	_check(ConditionEvaluator.evaluate(or_cond, ctx), "OR 组合")
	_check(ConditionEvaluator.evaluate({ "type": "not", "condition": { "type": "level", "subject": "player", "operator": "<", "value": 5 } }, ctx), "NOT 组合")

	# 比较运算
	_check(ConditionEvaluator.evaluate({ "type": "base_attribute", "subject": "player", "key": "strength", "operator": "==", "value": 10 }, ctx), "比较 ==")
	_check(ConditionEvaluator.evaluate({ "type": "base_attribute", "subject": "player", "key": "strength", "operator": ">", "value": 9 }, ctx), "比较 >")
	_check(ConditionEvaluator.evaluate({ "type": "level", "subject": "player", "operator": "between", "value": [3, 7] }, ctx), "范围 BETWEEN")
	_check(ConditionEvaluator.evaluate({ "type": "race", "subject": "player", "operator": "in", "value": ["human", "elf"] }, ctx), "集合 IN")

	# Effect
	EffectExecutor.execute({ "type": "remove_gold", "amount": 30 }, ctx)
	_check(float(gs.economy_state.get("gold", 0.0)) == 70.0, "Effect 扣除金币")
	EffectExecutor.execute({ "type": "set_story_flag", "flag": "effect_flag", "value": true }, ctx)
	_check(gs.story_flags.get_flag("effect_flag"), "Effect 设置 Flag")
	var xp0: int = player.progression.xp
	EffectExecutor.execute({ "type": "add_xp", "amount": 500 }, ctx)
	_check(player.progression.xp > xp0, "Effect 增加 XP")
	EffectExecutor.execute({ "type": "add_item", "id": "iron_ore", "qty": 3 }, ctx)
	_check(player.has_item("iron_ore"), "Effect 添加物品")
	EffectExecutor.execute({ "type": "add_status", "id": "status_attack_up" }, ctx)
	_check(player.status_effects.size() > 0, "Effect 添加状态")
	EffectExecutor.execute({ "type": "modify_hp", "amount": -10 }, ctx)
	_check(float(gs.player_state.get("hp", 0.0)) == -10.0, "Effect 修改 HP")
	EffectExecutor.execute({ "type": "sequence", "effects": [
		{ "type": "add_gold", "amount": 20 },
		{ "type": "set_story_flag", "flag": "seq_flag", "value": true }
	] }, ctx)
	_check(float(gs.economy_state.get("gold", 0.0)) == 90.0 and gs.story_flags.get_flag("seq_flag"), "Effect Sequence")

	# 完整链路 1：奖励链
	gs.economy_state["gold"] = 100.0
	player.progression.xp = 0
	gs.story_flags.remove_flag("iva_test")
	bus.emit("on_test_reward")
	_check(float(gs.economy_state.get("gold", 0.0)) == 0.0, "链路1 金币清零")
	_check(gs.story_flags.get_flag("iva_test"), "链路1 Flag 设置")
	_check(player.progression.xp == 500, "链路1 XP +500")
	_check(registry.get_event_state("event_iva_reward") == "done", "链路1 Event 完成")

	# 完整链路 2：NPC 投降招募
	enemy.set_state("Surrendered")
	bus.emit("on_actor_surrendered")
	_check(ctx.party.has(enemy), "链路2 加入队伍")
	_check(enemy.state == "Companion", "链路2 状态为 Companion")

	# 完整链路 3：世界互动（时间/天气）
	ctx.time = 19.0
	ctx.weather = "rain"
	bus.emit("on_enter_location")
	var wv = gs.world.get_value("location", "test_area", {})
	_check(wv.get("night_rain", false) == true, "链路3 世界状态")
	_check(gs.story_flags.get_flag("world_interaction_done"), "链路3 Flag")

	# EventBus 通信
	var calls := [0]
	bus.subscribe("ping", func(_p): calls[0] += 1)
	bus.emit("ping")
	_check(calls[0] == 1, "EventBus 派发")

	# RNG 可复现
	rng.set_seed(42)
	var r1: int = rng.next_int(1000)
	rng.set_seed(42)
	var r2: int = rng.next_int(1000)
	_check(r1 == r2, "RNG 同种子可复现")

	# 序列化
	gs.world.set_value("location", "village", { "destroyed": true })
	gs.story_flags.set_flag("serial_test", true)
	var data: Dictionary = gs.to_dict()
	var gs2 := GameState.new()
	gs2.from_dict(data)
	_check(gs2.story_flags.get_flag("serial_test"), "序列化 StoryFlag")
	_check(gs2.world.get_value("location", "village", {}).get("destroyed", false) == true, "序列化 WorldState")
	_check(float(gs2.economy_state.get("gold", 0.0)) == float(gs.economy_state.get("gold", 0.0)), "序列化 EconomyState")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
