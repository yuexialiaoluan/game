class_name SaveValidator

static func validate(d: Dictionary) -> SaveResult:
	if not d.has("save_version"):
		return SaveResult.fail("missing_fields", "缺少 save_version")
	var version = int(d.get("save_version", 0))
	if version > SaveGameData.CURRENT_SAVE_VERSION:
		return SaveResult.fail("unsupported_version", "存档版本高于当前支持")
	if not d.has("game_state") or not d.has("actors") or not d.has("party"):
		return SaveResult.fail("missing_fields", "缺少 game_state/actors/party")
	var actors = d.get("actors", {})
	if not actors is Dictionary:
		return SaveResult.fail("type_error", "actors 必须是对象")
	for aid in actors:
		var ad = actors[aid]
		if not ad is Dictionary:
			return SaveResult.fail("type_error", "actor 数据必须是对象")
		if not ad.has("id"):
			return SaveResult.fail("missing_fields", "actor 缺少 id")
	var party = d.get("party", [])
	if not party is Array:
		return SaveResult.fail("type_error", "party 必须是数组")
	return SaveResult.ok()

