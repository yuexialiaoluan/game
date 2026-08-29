class_name EquipmentGenerator
extends RefCounted

const QUALITY_ORDER := ["poor", "common", "uncommon", "rare", "epic", "legendary", "artifact"]
const QUALITY_NAMES := {
	"poor": "劣质", "common": "普通", "uncommon": "优秀", "rare": "精良",
	"epic": "大师之作", "legendary": "传说中的", "artifact": "神器"
}
const QUALITY_COLORS := {
	"poor": "#8e8e8e", "common": "#eeeeee", "uncommon": "#5bcf67", "rare": "#579cff",
	"epic": "#b36cff", "legendary": "#ff9b37", "artifact": "#ef4a4a"
}
const QUALITY_AFFIX_COUNTS := { "poor": 0, "common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4, "artifact": 5 }

var rng: RNGService
var affix_data: Dictionary = {}
var sequence: int = 0

func setup(p_rng: RNGService) -> void:
	rng = p_rng
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/loot/affix_definitions.json"))
	if parsed is Dictionary:
		affix_data = parsed
	_expand_affix_catalog()

func register_prototype_catalog(db: GameplayDB) -> void:
	var targets := { "artifact": 12, "legendary": 24, "epic": 36, "rare": 36, "uncommon": 36, "common": 36 }
	var slot_cycle := ["helmet", "chest", "legs", "boots", "necklace", "gloves", "ring", "mainhand", "offhand"]
	for quality in targets:
		for index in range(int(targets[quality])):
			var definition := generate(str(slot_cycle[index % slot_cycle.size()]), 1 + index % 12, str(quality))
			definition["id"] = "catalog_%s_equipment_%02d" % [quality, index + 1]
			db.register_equipment(definition)
			db.register_item({ "id": definition.get("id", ""), "name": definition.get("name", ""), "type": "weapon" if definition.get("slot", "") == "mainhand" else "armor", "rarity": quality, "value": 10 + index * 3, "effects": [] })
			db.register_talent({
				"id": "catalog_%s_talent_%02d" % [quality, index + 1],
				"name": "%s天赋 %02d" % [QUALITY_NAMES.get(quality, quality), index + 1],
				"passive_modifiers": [ { "stat": "attack" if index % 2 == 0 else "defense", "value": 1 + index % 4, "type": "add" } ]
			})

func _expand_affix_catalog() -> void:
	var targets := { "artifact": 12, "legendary": 24, "epic": 36, "rare": 36, "uncommon": 36, "common": 36 }
	for quality in targets:
		var pool: Array = affix_data.get(quality, []) as Array
		if pool.is_empty():
			pool.append({ "id": quality + "_plain", "name": "朴素的", "stat": "defense", "min": 1, "max": 1 })
		while pool.size() < int(targets[quality]):
			var source: Dictionary = pool[pool.size() % mini(3, pool.size())] as Dictionary
			var entry := source.duplicate()
			entry["id"] = quality + "_affix_%02d" % (pool.size() + 1)
			entry["name"] = str(source.get("name", "精制"))
			pool.append(entry)
		affix_data[quality] = pool

func generate(slot: String, level: int, quality: String = "") -> Dictionary:
	sequence += 1
	if quality == "":
		quality = _roll_quality()
	var safe_level := maxi(1, level)
	var base := _base_for(slot, safe_level)
	var affixes: Array = []
	var pool: Array = affix_data.get(quality, []) as Array
	var count := int(QUALITY_AFFIX_COUNTS.get(quality, 0))
	for index in range(count):
		if pool.is_empty():
			break
		var template: Dictionary = pool[(sequence + index) % pool.size()] as Dictionary
		var low := float(template.get("min", 1))
		var high := float(template.get("max", low))
		var value := low + (high - low) * minf(1.0, safe_level / 20.0)
		var affix := { "id": str(template.get("id", "")), "name": str(template.get("name", "")), "stat": str(template.get("stat", "attack")), "value": snappedf(value, 1.0) }
		if template.has("description"):
			affix["description"] = str(template.get("description", ""))
		if template.has("combat_effect"):
			affix["combat_effect"] = (template.get("combat_effect", {}) as Dictionary).duplicate(true)
		affixes.append(affix)
	var name := str(base.get("name", "训练装备"))
	if not affixes.is_empty():
		name = str(affixes[0].get("name", "精制")) + name
	return {
		"id": "generated_%s_%s_%03d" % [quality, slot, sequence],
		"name": "[%s] %s" % [QUALITY_NAMES.get(quality, quality), name],
		"slot": slot,
		"quality": quality,
		"quality_color": QUALITY_COLORS.get(quality, "#ffffff"),
		"level": safe_level,
		"gameplay": base.get("gameplay", {}).duplicate(),
		"affixes": affixes,
		"visual": {},
		"requirements": {}
	}

func upgrade(definition: Dictionary) -> Dictionary:
	sequence += 1
	var upgraded := definition.duplicate(true)
	upgraded["id"] = str(definition.get("id", "equipment")) + "_forge_%03d" % sequence
	upgraded["level"] = int(definition.get("level", 1)) + 1
	upgraded["name"] = str(definition.get("name", "装备")) + " +1"
	var gameplay: Dictionary = upgraded.get("gameplay", {}) as Dictionary
	for key in ["attack", "defense", "magic"]:
		if gameplay.has(key):
			gameplay[key] = maxi(1, int(ceil(float(gameplay[key]) * 1.15)))
	upgraded["gameplay"] = gameplay
	return upgraded

func _roll_quality() -> String:
	var roll := rng.next_int(100) if rng != null else sequence % 100
	if roll < 1: return "artifact"
	if roll < 5: return "legendary"
	if roll < 14: return "epic"
	if roll < 30: return "rare"
	if roll < 55: return "uncommon"
	if roll < 85: return "common"
	return "poor"

func roll_dungeon_quality(level: int) -> String:
	var roll := rng.next_int(100) if rng != null else sequence % 100
	if level >= 12:
		if roll < 12: return "artifact"
		if roll < 38: return "legendary"
		if roll < 72: return "epic"
		return "rare"
	if level >= 10:
		if roll < 4: return "artifact"
		if roll < 18: return "legendary"
		if roll < 52: return "epic"
		return "rare"
	if level >= 8:
		if roll < 4: return "legendary"
		if roll < 30: return "epic"
		return "rare"
	if level >= 5:
		if roll < 15: return "epic"
		if roll < 60: return "rare"
		return "uncommon"
	if level >= 3:
		return "rare" if roll < 20 else "uncommon"
	return "uncommon" if roll < 45 else "common"

func _base_for(slot: String, level: int) -> Dictionary:
	var defense := level + 1
	match slot:
		"helmet": return { "name": "铁盔", "gameplay": { "defense": defense } }
		"chest": return { "name": "胸甲", "gameplay": { "defense": defense * 2 } }
		"legs": return { "name": "护腿", "gameplay": { "defense": defense } }
		"boots": return { "name": "战靴", "gameplay": { "defense": defense } }
		"mainhand": return { "name": "冒险者之剑", "gameplay": { "attack": level + 2 } }
		"offhand": return { "name": "圆盾", "gameplay": { "defense": defense } }
		"necklace": return { "name": "护符", "gameplay": {} }
		"gloves": return { "name": "护手", "gameplay": {} }
		"ring", "ring_1", "ring_2", "ring_3", "ring_4": return { "name": "戒指", "gameplay": {} }
		_: return { "name": "饰品", "gameplay": {} }
