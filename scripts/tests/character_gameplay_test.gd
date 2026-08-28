extends Node2D

## Character / Actor 基础系统测试：三个角色共用同一套 Actor/Character 基础。
var db: GameplayDB
var cdb: CharacterVisualDB
var a: Actor
var b: Actor
var c: Actor
var a_visual: CharacterVisual
var validation_failures: int = 0

func _ready() -> void:
	db = GameplayDB.new()
	cdb = CharacterVisualDB.new()
	_build_actors()
	_build_visual()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_actors() -> void:
	# A: Human Warrior Lv3
	var ida := Identity.new()
	ida.character_id = "actor_a"
	ida.display_name = "战士A"
	ida.gender = "male"
	ida.age = 20
	ida.race_id = "human"
	ida.background = "test"
	a = Actor.new()
	a.setup(db, "actor_a", ida, "human", { "warrior_test": 3 })
	a.set_base("strength", 10)
	a.set_base("dexterity", 8)
	a.set_base("constitution", 12)
	a.set_base("intelligence", 6)
	a.set_base("wisdom", 7)
	a.set_base("charisma", 8)
	a.progression.level = 3
	a.add_xp(0)

	# B: Elf Ranger Lv2
	var idb := Identity.new()
	idb.character_id = "actor_b"
	idb.display_name = "游侠B"
	idb.gender = "female"
	idb.age = 120
	idb.race_id = "elf"
	idb.background = "test"
	b = Actor.new()
	b.setup(db, "actor_b", idb, "elf", { "ranger_test": 2 })
	b.set_base("strength", 7)
	b.set_base("dexterity", 14)
	b.set_base("constitution", 8)
	b.set_base("intelligence", 9)
	b.set_base("wisdom", 10)
	b.set_base("charisma", 9)
	b.progression.level = 2
	b.add_xp(0)

	# C: Goblin creature Lv1
	var idc := Identity.new()
	idc.character_id = "actor_c"
	idc.display_name = "哥布林C"
	idc.gender = "male"
	idc.age = 4
	idc.race_id = "goblin"
	idc.background = "creature"
	c = Actor.new()
	c.setup(db, "actor_c", idc, "goblin", {})

func _build_visual() -> void:
	a_visual = CharacterVisual.new()
	a_visual.name = "ActorAVisual"
	a_visual.position = Vector2(0, -16)
	add_child(a_visual)
	a_visual.setup(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "human_male", "eyes_default_01")
	a.visual = a_visual

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# 1 创建角色
	_check(a != null and b != null and c != null, "创建三个角色")

	# 2 读取基础属性
	_check(a.get_base_stat("strength") == 10.0, "读取基础属性")

	# 3 派生属性
	_check(a.get_stat("max_hp") > 0.0, "计算派生属性 MaxHP")

	# 4 添加 Modifier
	var atk0: float = a.get_stat("attack")
	var m := StatModifier.new()
	m.stat = "attack"
	m.value = 5.0
	m.type = "add"
	m.source = "test"
	a.modifiers.add(m)
	a.attributes.recalculate(a.modifiers)
	_check(a.get_stat("attack") > atk0, "添加 Modifier 生效")
	a.modifiers.remove_by_source("test")
	a.recalculate()

	# 5 装备武器
	var atk1: float = a.get_stat("attack")
	a.equip("mainhand", "weapon_iron_sword_01")
	_check(a.get_stat("attack") > atk1, "装备武器提升攻击")
	_check(a_visual.resolver.parts.has("weapon"), "装备后外观出现武器")

	# 6 装备防具
	var def1: float = a.get_stat("defense")
	a.equip("body", "armor_iron_01")
	_check(a.get_stat("defense") > def1, "装备防具提升防御")
	_check(a_visual.resolver.parts.has("torso"), "装备后外观出现防具")
	_check(not a_visual.resolver.parts.has("clothing"), "防具隐藏衣服")

	# 8/9/10 经验与升级、属性点
	var lvl0: int = a.progression.level
	var pts0: int = a.progression.attribute_points
	a.add_xp(300)
	_check(a.progression.level > lvl0, "升级")
	_check(a.progression.attribute_points > pts0, "获得属性点")

	# 11 获得技能（Lv3 战士）
	_check(a.skills.has("skill_attack_test"), "获得技能")

	# 12 获得 Feat（Lv2 战士）
	_check(a.feats.has("feat_armor_master_test"), "获得 Feat")

	# 13 Talent
	var dex0: float = a.get_stat("dexterity")
	a.talents.append("talent_forest_hunter")
	a.recalculate()
	_check(a.get_stat("dexterity") > dex0, "Talent 修改属性")

	# 14/15 Status Effect 与结束
	var atk2: float = a.get_stat("attack")
	a.add_status("status_attack_up")
	_check(a.get_stat("attack") > atk2, "Status Buff 提升攻击")
	a.tick(5.0)
	_check(abs(a.get_stat("attack") - atk2) < 0.001, "Status 结束后恢复")

	# 16 Inventory
	a.add_item("iron_ore", 5)
	_check(a.has_item("iron_ore"), "Inventory 添加")
	a.remove_item("iron_ore", 2)
	_check(int(a.inventory.get("iron_ore", 0)) == 3, "Inventory 移除")

	# 17 Relationship
	a.set_relationship("npc_x", 10.0, 5.0, 2.0, 4.0, 0.0)
	_check(a.relationships.has("npc_x"), "设置 Relationship")

	# 18 Faction / Reputation
	a.set_faction("kingdom")
	a.set_reputation("kingdom", 50.0)
	_check(a.faction_id == "kingdom" and float(a.reputation.get("kingdom", 0.0)) == 50.0, "设置 Faction/Reputation")

	# 19 Character State
	a.set_state("Combat")
	_check(a.state == "Combat", "改变 Character State")

	# 共享基础：B/C 使用同一 Actor
	_check(b.race_id == "elf" and b.skills.has("skill_attack_test"), "Elf Ranger 共享系统")
	_check(c.race_id == "goblin" and c.get_stat("max_hp") > 0.0, "Goblin Creature 共享系统")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
