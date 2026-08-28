class_name SaveService
extends RefCounted

const SAVE_DIR := "user://saves"
const CURRENT_VERSION := SaveGameData.CURRENT_SAVE_VERSION

var migrations: Array = [
	{ "from": 0, "to": 1, "func": "_migrate_0_to_1" }
]

func save_game(slot_id: String, ctx: EvaluatorContext, game_mode: String, rng_state: int) -> SaveResult:
	var data := SaveGameData.new()
	data.game_mode = game_mode
	data.timestamp = int(Time.get_unix_time_from_system())
	data.player_id = ctx.player.id if ctx.player != null else ""
	data.game_state = ctx.game_state.to_dict()
	if ctx.crime_service != null:
		data.game_state["crime_state"] = ctx.crime_service.to_dict()
	if ctx.stealth_service != null:
		data.game_state["stealth_state"] = ctx.stealth_service.stealth.duplicate()
	if ctx.npc_state_service != null:
		data.game_state["npc_state"] = ctx.npc_state_service.to_dict()
	if ctx.quest_service != null:
		data.game_state["quest_state"] = ctx.quest_service.to_dict()

	for aid in ctx.actors:
		var actor = ctx.actors[aid]
		if actor is Actor:
			data.actors[str(aid)] = actor.to_save_data()
	if ctx.player != null:
		data.actors[ctx.player.id] = ctx.player.to_save_data()

	for a in ctx.party:
		if a is Actor:
			data.party.append(a.id)
	for a in ctx.reserve_party:
		if a is Actor:
			data.reserve_party.append(a.id)

	if ctx.time_service != null:
		data.time_state = ctx.time_service.to_dict()
	else:
		data.time_state = { "hour": ctx.time, "date": ctx.date, "season": ctx.season }
	if ctx.weather_service != null:
		data.weather_state = ctx.weather_service.to_dict()
		data.weather = ctx.weather_service.get_weather("default")
	else:
		data.weather = ctx.weather
	data.rng_state = rng_state

	return _write_slot(slot_id, data.to_dict())

func load_game(slot_id: String) -> SaveResult:
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return SaveResult.fail("file_not_found", "存档不存在")
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		return SaveResult.fail("corrupted", "存档数据损坏")
	var parsed = json.data
	if not parsed is Dictionary:
		return SaveResult.fail("corrupted", "存档数据损坏")
	var d: Dictionary = parsed
	var vr := SaveValidator.validate(d)
	if not vr.success:
		return vr
	var migrated = _migrate(d)
	if migrated is SaveResult:
		return migrated
	return SaveResult.ok(SaveGameData.from_dict(d))

func delete_save(slot_id: String) -> SaveResult:
	var path := _slot_path(slot_id)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			return SaveResult.fail("write_failed", "删除存档失败")
	return SaveResult.ok()

func list_saves() -> Array:
	var out := []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".json") and not name.ends_with(".tmp"):
			out.append(name.trim_suffix(".json"))
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

func has_save(slot_id: String) -> bool:
	return FileAccess.file_exists(_slot_path(slot_id))

func validate_save(d: Dictionary) -> SaveResult:
	return SaveValidator.validate(d)

func _write_slot(slot_id: String, d: Dictionary) -> SaveResult:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := _slot_path(slot_id)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return SaveResult.fail("write_failed", "无法创建临时存档")
	f.store_string(JSON.stringify(d, "\t"))
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		return SaveResult.fail("write_failed", "临时文件替换失败")
	return SaveResult.ok()

func _slot_path(slot_id: String) -> String:
	return SAVE_DIR.path_join("slot_" + slot_id + ".json")

func _migrate(d: Dictionary):
	var version := int(d.get("save_version", 0))
	while version < CURRENT_VERSION:
		var step = _find_migration(version)
		if step.is_empty():
			return SaveResult.fail("unsupported_version", "缺少版本迁移路径")
		var f = step.get("func", "")
		call(f, d)
		version = int(step.get("to", version))
		d["save_version"] = version
	return null

func _find_migration(from: int) -> Dictionary:
	for m in migrations:
		if int(m.get("from", -1)) == from:
			return m
	return {}

func _migrate_0_to_1(d: Dictionary) -> void:
	if not d.has("game_mode"):
		d["game_mode"] = "story"
	if not d.has("weather"):
		d["weather"] = "clear"
	if not d.has("rng_state"):
		d["rng_state"] = 0






