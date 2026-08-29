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
var current_hp: float = 0.0
var current_mp: float = 0.0

var visual: CharacterVisual = null
var appearance: Dictionary = {}
var background_id: String = ""

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
	current_hp = get_stat("max_hp")
	current_mp = get_stat("max_mp")

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
		for affix in eq.get("affixes", []) as Array:
			if affix is Dictionary:
				_add_gp(affix.get("value", 0.0), str(affix.get("stat", "")), str(slot) + ":affix")
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
	visual.set_equipment("helmet", str(equipment.get("helmet", equipment.get("head", ""))))
	visual.set_equipment("torso", str(equipment.get("chest", equipment.get("body", ""))))

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



func capture_appearance() -> void:
	if visual != null:
		appearance = {
			"body_id": visual.body_id,
			"face_id": visual.face_id,
			"hair_id": visual.hair_id,
			"clothing_id": visual.clothing_id,
			"eyes_id": visual.eyes_id
		}

func apply_appearance() -> void:
	if visual != null:
		visual.set_body(str(appearance.get("body_id", "human_male")))
		visual.set_face(str(appearance.get("face_id", "human_male")))
		visual.set_hair(str(appearance.get("hair_id", "hair_short_01")))
		visual.set_clothing(str(appearance.get("clothing_id", "clothing_peasant_01")))
		visual.set_eyes(str(appearance.get("eyes_id", "eyes_default_01")))

func to_save_data() -> Dictionary:
	capture_appearance()
	return {
		"id": id,
		"identity": {
			"character_id": identity.character_id,
			"display_name": identity.display_name,
			"gender": identity.gender,
			"age": identity.age,
			"race_id": identity.race_id,
			"background": identity.background
		},
		"race_id": race_id,
		"classes": classes.duplicate(),
		"skills": skills.duplicate(),
		"feats": feats.duplicate(),
		"talents": talents.duplicate(),
		"base_attributes": attributes.base.duplicate(),
		"progression": { "level": progression.level, "xp": progression.xp, "attribute_points": progression.attribute_points },
		"equipment": equipment.duplicate(),
		"inventory": inventory.duplicate(),
		"relationships": _relationships_to_dict(),
		"faction_id": faction_id,
		"reputation": reputation.duplicate(),
		"state": state,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"background_id": background_id,
		"appearance": appearance.duplicate()
	}

func apply_save_data(d: Dictionary, p_db: GameplayDB) -> void:
	db = p_db
	id = str(d.get("id", ""))
	var idict: Dictionary = d.get("identity", {}) as Dictionary
	identity = Identity.new()
	identity.character_id = str(idict.get("character_id", ""))
	identity.display_name = str(idict.get("display_name", ""))
	identity.gender = str(idict.get("gender", ""))
	identity.age = int(idict.get("age", 0))
	identity.race_id = str(idict.get("race_id", ""))
	identity.background = str(idict.get("background", ""))

	race_id = str(d.get("race_id", ""))
	classes = (d.get("classes", {}) as Dictionary).duplicate()
	skills = (d.get("skills", {}) as Dictionary).duplicate()
	feats = (d.get("feats", []) as Array).duplicate()
	talents = (d.get("talents", []) as Array).duplicate()

	attributes = Attributes.new()
	attributes.base = (d.get("base_attributes", {}) as Dictionary).duplicate()
	modifiers = ModifierList.new()
	progression = Progression.new()
	progression.setup(db.level_table.get("xp_to_next", []) as Array)
	var prog: Dictionary = d.get("progression", {}) as Dictionary
	progression.level = int(prog.get("level", 1))
	progression.xp = int(prog.get("xp", 0))
	progression.attribute_points = int(prog.get("attribute_points", 0))

	equipment = (d.get("equipment", {}) as Dictionary).duplicate()
	inventory = (d.get("inventory", {}) as Dictionary).duplicate()
	relationships = _relationships_from_dict(d.get("relationships", {}) as Dictionary)
	faction_id = str(d.get("faction_id", ""))
	reputation = (d.get("reputation", {}) as Dictionary).duplicate()
	state = str(d.get("state", "Alive"))
	background_id = str(d.get("background_id", ""))
	appearance = (d.get("appearance", {}) as Dictionary).duplicate()
	recalculate()
	current_hp = float(d.get("current_hp", get_stat("max_hp")))
	current_mp = float(d.get("current_mp", get_stat("max_mp")))

func _relationships_to_dict() -> Dictionary:
	var out := {}
	for target in relationships:
		var rs = relationships[target]
		out[target] = {
			"affinity": float(rs.get("affinity")),
			"trust": float(rs.get("trust")),
			"fear": float(rs.get("fear")),
			"respect": float(rs.get("respect")),
			"hostility": float(rs.get("hostility"))
		}
	return out

func _relationships_from_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for target in d:
		var rd: Dictionary = d[target]
		var rs := RelationshipState.new()
		rs.source = id
		rs.target = str(target)
		rs.affinity = float(rd.get("affinity", 0.0))
		rs.trust = float(rd.get("trust", 0.0))
		rs.fear = float(rd.get("fear", 0.0))
		rs.respect = float(rd.get("respect", 0.0))
		rs.hostility = float(rd.get("hostility", 0.0))
		out[str(target)] = rs
	return out




func get_hp() -> float:
	return current_hp

func max_hp() -> float:
	return get_stat("max_hp")

func set_hp(value: float) -> void:
	current_hp = clampf(value, 0.0, max_hp())

func damage(amount: float) -> void:
	set_hp(current_hp - amount)

func heal(amount: float) -> void:
	set_hp(current_hp + amount)

func is_dead() -> bool:
	return current_hp <= 0.0

func get_equipment_combat_effects() -> Array:
	var effects: Array = []
	for slot in equipment:
		var definition := db.get_equipment(str(equipment[slot]))
		for affix in definition.get("affixes", []) as Array:
			if affix is Dictionary and affix.get("combat_effect", {}) is Dictionary and not (affix.get("combat_effect", {}) as Dictionary).is_empty():
				effects.append({ "source": str(affix.get("name", "词条")), "effect": (affix.get("combat_effect", {}) as Dictionary).duplicate(true) })
	return effects
