class_name Actor
extends RefCounted

## 统一 Actor/Character 基础：Player/NPC/Enemy/Creature/Companion 共用。
var db: GameplayDB
var id: String = ""
var identity: Identity
var attributes: Attributes
var modifiers: ModifierList
var progression: Progression

var race_id: String = ""
var classes: Dictionary = {}
var skills: Dictionary = {}
var feats: Array = []
var talents: Array = []
var equipment: Dictionary = {}
var inventory: Dictionary = {}
var status_effects: Array = []
var relationships: Dictionary = {}
var faction_id: String = ""
var reputation: Dictionary = {}
var state: String = "Alive"

var visual: CharacterVisual = null

func setup(p_db: GameplayDB, p_id: String, p_identity: Identity, p_race_id: String, p_classes: Dictionary) -> void:
	db = p_db
	id = p_id
	identity = p_identity
	race_id = p_race_id
	classes = p_classes.duplicate()
	attributes = Attributes.new()
	modifiers = ModifierList.new()
	progression = Progression.new()
	progression.setup(db.level_table.get("xp_to_next", []) as Array)
	recalculate()

func set_base(stat: String, value: float) -> void:
	attributes.set_base(stat, value)

func get_stat(stat: String) -> float:
	return attributes.get_final(stat)

func get_base_stat(stat: String) -> float:
	return attributes.get_base(stat)

func recalculate() -> void:
	modifiers.clear()
	var race := db.get_race(race_id)
	_add_mods(race.get("base_modifiers", []), "race:" + race_id)
	for cid in classes:
		var cdef := db.get_class_def(cid)
		_add_mods(cdef.get("base_modifiers", []), "class:" + cid)
	for fid in feats:
		_add_mods(db.get_feat(fid).get("modifiers", []), "feat:" + fid)
	for tid in talents:
		_add_mods(db.get_talent(tid).get("passive_modifiers", []), "talent:" + tid)
	for slot in equipment:
		var eq := db.get_equipment(str(equipment[slot]))
		var gp := eq.get("gameplay", {}) as Dictionary
		_add_gp(gp.get("attack", 0.0), "attack", str(slot))
		_add_gp(gp.get("defense", 0.0), "defense", str(slot))
		_add_gp(gp.get("magic", 0.0), "magic_attack", str(slot))
	for se in status_effects:
		var sdef := db.get_status(str(se.get("id", "")))
		_add_mods(sdef.get("modifiers", []), "status:" + str(se.get("id", "")))
	attributes.recalculate(modifiers)

func _add_mods(arr, source: String) -> void:
	if not arr is Array:
		return
	for item in arr:
		if item is Dictionary:
			var m := StatModifier.new()
			m.stat = str(item.get("stat", ""))
			m.value = float(item.get("value", 0.0))
			m.type = str(item.get("type", "add"))
			m.source = source
			modifiers.add(m)

func _add_gp(value, stat: String, source: String) -> void:
	if float(value) != 0.0:
		var m := StatModifier.new()
		m.stat = stat
		m.value = float(value)
		m.type = "add"
		m.source = "equip:" + source
		modifiers.add(m)

func equip(slot: String, item_id: String) -> void:
	if item_id == "":
		equipment.erase(slot)
	else:
		equipment[slot] = item_id
	recalculate()
	if visual != null:
		_sync_visual()

func _sync_visual() -> void:
	visual.set_mainhand(str(equipment.get("mainhand", "")))
	visual.set_offhand(str(equipment.get("offhand", "")))
	visual.set_equipment("helmet", str(equipment.get("head", "")))
	visual.set_equipment("torso", str(equipment.get("body", "")))

func add_item(item_id: String, qty: int) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + qty

func remove_item(item_id: String, qty: int) -> bool:
	var cur := int(inventory.get(item_id, 0))
	if cur < qty:
		return false
	if cur == qty:
		inventory.erase(item_id)
	else:
		inventory[item_id] = cur - qty
	return true

func has_item(item_id: String) -> bool:
	return int(inventory.get(item_id, 0)) > 0

func add_status(status_id: String) -> void:
	var dur := float(db.get_status(status_id).get("duration", 0.0))
	status_effects.append({ "id": status_id, "time_left": dur })
	recalculate()

func tick(delta: float) -> void:
	var changed := false
	var kept := []
	for se in status_effects:
		var left := float(se.get("time_left", 0.0)) - delta
		if left > 0.0:
			se["time_left"] = left
			kept.append(se)
		else:
			changed = true
	status_effects = kept
	if changed:
		recalculate()

func add_xp(amount: int) -> Array:
	var rewards := progression.add_xp(amount)
	_grant_level_rewards()
	return rewards

func _grant_level_rewards() -> void:
	for lvl in range(1, progression.level + 1):
		var key := str(lvl)
		for cid in classes:
			var cdef := db.get_class_def(cid)
			var lr := cdef.get("level_rewards", {}) as Dictionary
			if lr.has(key):
				var list = lr[key]
				for reward in list:
					var rid := str(reward)
					if rid.begins_with("skill_"):
						skills[rid] = true
					elif rid.begins_with("feat_") and not feats.has(rid):
						feats.append(rid)
	recalculate()

func set_relationship(target_id: String, affinity: float, trust: float, fear: float, respect: float, hostility: float) -> void:
	var r := RelationshipState.new()
	r.source = id
	r.target = target_id
	r.affinity = affinity
	r.trust = trust
	r.fear = fear
	r.respect = respect
	r.hostility = hostility
	relationships[target_id] = r

func set_faction(fid: String) -> void:
	faction_id = fid

func set_reputation(fid: String, value: float) -> void:
	reputation[fid] = value

func set_state(s: String) -> void:
	state = s


