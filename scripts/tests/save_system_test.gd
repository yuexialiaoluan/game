extends Node

## 正式 Save / Load 系统测试。
var db: GameplayDB
var cdb: CharacterVisualDB
var gs: GameState
var ctx: EvaluatorContext
var player: Actor
var npc: Actor
var reserve: Actor
var rng: RNGService
var service: SaveService
var validation_failures: int = 0

func _ready() -> void:
	db = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	_clean_saves()
	_build_runtime()
	service = SaveService.new()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_runtime() -> void:
	gs = GameState.new()
	ctx = EvaluatorContext.new()
	ctx.game_state = gs

	var idp := Identity.new()
	idp.character_id = "player"
	idp.display_name = "玩家"
	idp.gender = "male"
	idp.race_id = "human"
	player = Actor.new()
	player.setup(db, "player", idp, "human", { "warrior_test": 3 })
	player.set_base("strength", 12)
	player.progression.level = 3
	player.add_xp(0)
	player.appearance = { "body_id": "human_male", "face_id": "human_male", "hair_id": "hair_short_01", "clothing_id": "clothing_peasant_01", "eyes_id": "eyes_default_01" }

	var idn := Identity.new()
	idn.character_id = "npc_01"
	idn.display_name = "哥布林"
	idn.race_id = "goblin"
	npc = Actor.new()
	npc.setup(db, "npc_01", idn, "goblin", {})
	npc.set_state("Surrendered")

	var idr := Identity.new()
	idr.character_id = "reserve_01"
	idr.display_name = "备用队友"
	idr.race_id = "elf"
	reserve = Actor.new()
	reserve.setup(db, "reserve_01", idr, "elf", {})

	ctx.player = player
	ctx.actors["player"] = player
	ctx.actors["npc_01"] = npc
	ctx.actors["reserve_01"] = reserve
	ctx.party = [player, npc]
	ctx.reserve_party = [reserve]
	ctx.time = 19.5
	ctx.date = 12
	ctx.season = "autumn"
	ctx.weather = "rain"

	rng = RNGService.new()
	rng.set_seed(123)

func _clean_saves() -> void:
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		DirAccess.remove_absolute("user://saves".path_join(name))
		name = dir.get_next()
	dir.list_dir_end()

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _reconstruct(data: SaveGameData) -> Dictionary:
	var g2 := GameState.new()
	g2.from_dict(data.game_state)
	var actors := {}
	for aid in data.actors:
		var a := Actor.new()
		a.apply_save_data(data.actors[aid], db)
		actors[aid] = a
	return { "gs": g2, "actors": actors, "data": data }

func _run_validation() -> void:
	# T1 新游戏
	_check(gs != null, "T1 新游戏创建")

	# T2 保存 GameState
	var sr := service.save_game("t_main", ctx, "story", rng.get_state())
	_check(sr.success, "T2 保存 GameState")
	_check(service.has_save("t_main"), "T2 存档存在")

	# T3 读取 GameState
	var lr := service.load_game("t_main")
	_check(lr.success, "T3 读取 GameState")
	_check(lr.data != null, "T3 数据非空")

	# T4 Player 状态保存/恢复
	var rec := _reconstruct(lr.data)
	var p2: Actor = rec["actors"]["player"]
	_check(p2.get_base_stat("strength") == 12.0, "T4 Player 属性恢复")
	_check(p2.progression.level == 3, "T4 Player 等级恢复")

	# T5 Party / T6 Reserve
	_check(lr.data.party.has("player") and lr.data.party.has("npc_01"), "T5 Party 恢复")
	_check(lr.data.reserve_party.has("reserve_01"), "T6 Reserve Party 恢复")

	# T7 Inventory / T8 Equipment
	player.add_item("iron_ore", 5)
	player.equip("mainhand", "weapon_iron_sword_01")
	service.save_game("t_equip", ctx, "story", rng.get_state())
	var rec2 := _reconstruct(service.load_game("t_equip").data)
	var p3: Actor = rec2["actors"]["player"]
	_check(int(p3.inventory.get("iron_ore", 0)) == 5, "T7 Inventory 恢复")
	_check(p3.equipment.get("mainhand", "") == "weapon_iron_sword_01", "T8 Equipment 恢复")

	# T9 Appearance
	player.appearance["hair_id"] = "hair_long_01"
	player.appearance["clothing_id"] = "clothing_adventurer_01"
	service.save_game("t_appear", ctx, "story", rng.get_state())
	var p4: Actor = _reconstruct(service.load_game("t_appear").data)["actors"]["player"]
	_check(p4.appearance.get("hair_id", "") == "hair_long_01", "T9 Appearance 恢复")

	# T10 NPC 状态
	_check(rec["actors"]["npc_01"].state == "Surrendered", "T10 NPC 状态恢复")

	# T11 Relationship
	player.set_relationship("iva", 50.0, 30.0, 5.0, 20.0, 0.0)
	service.save_game("t_rel", ctx, "story", rng.get_state())
	var p5: Actor = _reconstruct(service.load_game("t_rel").data)["actors"]["player"]
	_check(float(p5.relationships["iva"].get("affinity")) == 50.0, "T11 Relationship 恢复")

	# T12 Faction/Reputation
	player.set_faction("kingdom")
	player.set_reputation("kingdom", 80.0)
	service.save_game("t_fac", ctx, "story", rng.get_state())
	var p6: Actor = _reconstruct(service.load_game("t_fac").data)["actors"]["player"]
	_check(p6.faction_id == "kingdom" and float(p6.reputation.get("kingdom", 0.0)) == 80.0, "T12 Faction/Reputation 恢复")

	# T13 WorldState / T14 StoryFlag
	gs.world.set_value("location", "village", { "destroyed": true })
	gs.story_flags.set_flag("iva_test", true)
	service.save_game("t_world", ctx, "story", rng.get_state())
	var rec3 := _reconstruct(service.load_game("t_world").data)
	_check(rec3["gs"].world.get_value("location", "village", {}).get("destroyed", false) == true, "T13 WorldState 恢复")
	_check(rec3["gs"].story_flags.get_flag("iva_test"), "T14 StoryFlag 恢复")

	# T15 Time/Weather
	var lr_t := service.load_game("t_world")
	_check(float(lr_t.data.time_state.get("hour", 0.0)) == 19.5, "T15 Time 恢复")
	_check(lr_t.data.weather == "rain", "T15 Weather 恢复")

	# T16 RNG 状态恢复
	rng.set_seed(123)
	var state0: int = rng.get_state()
	var expected: int = rng.next_int(1000)
	service.save_game("t_rng", ctx, "story", state0)
	var lr_r := service.load_game("t_rng")
	var r2 := RNGService.new()
	r2.set_state(lr_r.data.rng_state)
	_check(r2.next_int(1000) == expected, "T16 RNG 状态恢复")

	# T17 不存在的引用不崩溃
	var bad := player.to_save_data()
	bad["equipment"] = { "mainhand": "weapon_missing_xyz" }
	var ba := Actor.new()
	ba.apply_save_data(bad, db)
	_check(ba != null, "T17 不存在引用不崩溃")

	# T18 损坏存档不破坏其他
	service.save_game("t_good", ctx, "story", rng.get_state())
	var f := FileAccess.open("user://saves/slot_t_bad.json", FileAccess.WRITE)
	f.store_string("{not valid json")
	f.close()
	_check(service.load_game("t_good").success, "T18 正常存档仍可读")
	_check(service.load_game("t_bad").error_code == "corrupted", "T18 损坏存档返回错误")

	# T19 Migration v0 -> v1
	var v0 := { "save_version": 0, "game_state": gs.to_dict(), "actors": {}, "party": [], "reserve_party": [] }
	var fm := FileAccess.open("user://saves/slot_t_mig.json", FileAccess.WRITE)
	fm.store_string(JSON.stringify(v0))
	fm.close()
	var lrm := service.load_game("t_mig")
	_check(lrm.success and lrm.data.save_version == 1 and lrm.data.weather == "clear", "T19 Migration v0->v1")

	# T20 重复 Save/Load
	var stable := true
	for i in range(5):
		service.save_game("t_loop", ctx, "story", rng.get_state())
		if not service.load_game("t_loop").success:
			stable = false
	_check(stable, "T20 重复 Save/Load")

	# T21 重新实例化服务后读取（模拟重启）
	var service2 := SaveService.new()
	_check(service2.load_game("t_loop").success, "T21 重启后读取")

	# T22 多槽位互不影响
	gs.economy_state["gold"] = 100.0
	service.save_game("s1", ctx, "story", rng.get_state())
	gs.economy_state["gold"] = 200.0
	service.save_game("s2", ctx, "story", rng.get_state())
	gs.economy_state["gold"] = 999.0
	_check(float(_reconstruct(service.load_game("s1").data)["gs"].economy_state.get("gold", 0.0)) == 100.0, "T22 槽位1独立")
	_check(float(_reconstruct(service.load_game("s2").data)["gs"].economy_state.get("gold", 0.0)) == 200.0, "T22 槽位2独立")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
