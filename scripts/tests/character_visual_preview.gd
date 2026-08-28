extends Node2D

## 角色视觉预览工具：开发用，非正式角色创建界面。
var db: CharacterVisualDB
var preview: CharacterVisual
var cam: Camera2D
var npcs: Array[CharacterVisual] = []
var validation_failures: int = 0
var _paused: bool = false

func _ready() -> void:
	db = CharacterVisualDB.new()
	_build_preview()
	_build_npcs()
	_build_ui()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_preview() -> void:
	preview = CharacterVisual.new()
	preview.name = "Preview"
	preview.position = Vector2(0, -16)
	add_child(preview)
	preview.setup(db, "human_male", "hair_short_01", "clothing_peasant_01", "human_male", "eyes_default_01")

	cam = Camera2D.new()
	cam.position = Vector2(0, 0)
	cam.zoom = Vector2(2, 2)
	add_child(cam)
	cam.make_current()

func _build_npcs() -> void:
	var defs := [
		["human_male_01", Vector2(-140, 130)],
		["human_female_01", Vector2(0, 130)],
		["human_male_armored_01", Vector2(140, 130)]
	]
	for d in defs:
		var tpl := db.get_npc_template(d[0])
		var npc := CharacterVisual.new()
		npc.name = "NPC_" + d[0]
		npc.position = d[1]
		add_child(npc)
		var equip: Dictionary = tpl.get("equipment", {}) as Dictionary
		npc.setup(db, str(tpl.get("body_id", "human_male")), str(tpl.get("hair_id", "hair_short_01")), str(tpl.get("clothing_id", "clothing_peasant_01")), str(tpl.get("face_id", "human_male")), "eyes_default_01")
		npc.equipment = equip.duplicate()
		npc.rebuild()
		npcs.append(npc)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := VBoxContainer.new()
	root.position = Vector2(8, 8)
	layer.add_child(root)

	_add_row(root, [["男", func(): preview.set_gender("male")], ["女", func(): preview.set_gender("female")]])
	_add_row(root, [["发型1", func(): preview.set_hair("hair_short_01")], ["发型2", func(): preview.set_hair("hair_long_01")], ["发型3", func(): preview.set_hair("hair_tied_01")]])
	_add_row(root, [["平民服", func(): preview.set_clothing("clothing_peasant_01")], ["冒险者服", func(): preview.set_clothing("clothing_adventurer_01")], ["轻甲服", func(): preview.set_clothing("clothing_light_armor_01")]])
	_add_row(root, [["皮甲", func(): preview.set_equipment("torso", "armor_leather_01")], ["铁甲", func(): preview.set_equipment("torso", "armor_iron_01")]])
	_add_row(root, [["无头盔", func(): preview.set_equipment("helmet", "")], ["铁头盔", func(): preview.set_equipment("helmet", "helmet_iron_01")]])
	_add_row(root, [["无主手", func(): preview.set_mainhand("")], ["木剑", func(): preview.set_mainhand("weapon_wood_sword_01")], ["铁剑", func(): preview.set_mainhand("weapon_iron_sword_01")]])
	_add_row(root, [["无副手", func(): preview.set_offhand("")], ["木盾", func(): preview.set_offhand("shield_wood_01")]])
	_add_row(root, [["Idle", func(): preview.animator.set_moving(false)], ["Walk", func(): preview.animator.set_moving(true)], ["Attack", func(): preview.animator.play_attack()]])
	_add_row(root, [["Zoom+", func(): cam.zoom *= 1.2], ["Zoom-", func(): cam.zoom /= 1.2], ["Rotate", func(): preview.rotation += 0.3], ["Play/Pause", func(): _toggle_pause()], ["Reset", func(): _reset()]])

func _toggle_pause() -> void:
	_paused = not _paused
	preview.animator.set_process(not _paused)

func _reset() -> void:
	preview.set_gender("male")
	preview.set_hair("hair_short_01")
	preview.set_clothing("clothing_peasant_01")
	preview.equipment.clear()
	preview.rebuild()
	preview.rotation = 0.0
	cam.zoom = Vector2(2, 2)

func _add_row(parent: VBoxContainer, defs: Array) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	for d in defs:
		var b := Button.new()
		b.text = d[0]
		b.pressed.connect(d[1])
		row.add_child(b)

# ---------------- 自动验证 ----------------

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	# 1/2 男女
	var body0 = _part_asset(preview, "body")
	preview.set_gender("female")
	_check(_part_asset(preview, "body") != body0, "男/女身体切换")
	preview.set_gender("male")

	# 3 发型
	var h0 = _part_asset(preview, "hair")
	preview.set_hair("hair_long_01")
	_check(_part_asset(preview, "hair") != h0, "发型切换")

	# 4 服装
	var c0 = _part_asset(preview, "clothing")
	preview.set_clothing("clothing_adventurer_01")
	_check(_part_asset(preview, "clothing") != c0, "服装切换")

	# 5/6 轻甲/铁甲隐藏衣服
	preview.set_equipment("torso", "armor_leather_01")
	_check(not preview.resolver.parts.has("clothing") and preview.resolver.parts.has("torso"), "轻甲隐藏衣服")
	preview.set_equipment("torso", "armor_iron_01")
	_check(preview.resolver.parts.has("torso"), "铁甲显示")
	preview.set_equipment("torso", "")

	# 7 头盔隐藏头发
	preview.set_equipment("helmet", "helmet_iron_01")
	_check(not preview.resolver.parts.has("hair") and preview.resolver.parts.has("helmet"), "头盔隐藏头发")
	preview.set_equipment("helmet", "")

	# 8/9 木剑/铁剑
	preview.set_mainhand("weapon_wood_sword_01")
	var sword = preview.resolver.parts.get("weapon")
	_check(sword != null and sword.get_parent() == preview.get_bone("Hand_R"), "木剑绑定 Hand_R")
	preview.set_mainhand("weapon_iron_sword_01")
	_check(preview.resolver.parts.has("weapon"), "铁剑切换")

	# 10 木盾
	preview.set_offhand("shield_wood_01")
	var shield = preview.resolver.parts.get("shield")
	_check(shield != null and shield.get_parent() == preview.get_bone("Hand_L"), "木盾绑定 Hand_L")

	# 11/12/13 动画
	preview.animator.set_moving(true)
	_check(preview.animator.state == CharacterAnimator.State.WALK, "Walk")
	preview.animator.set_moving(false)
	_check(preview.animator.state == CharacterAnimator.State.IDLE, "Idle")
	var hand_r: Node2D = preview.get_bone("Hand_R")
	var base_pos = preview.skeleton.base_positions["Hand_R"]
	preview.animator.play_attack()
	await get_tree().create_timer(0.15).timeout
	_check(hand_r.position != base_pos, "Attack 手部移动")

	# 16 脚底 Pivot 稳定
	var foot0 = _foot_y(preview)
	preview.set_gender("female")
	preview.set_hair("hair_tied_01")
	preview.set_equipment("torso", "armor_iron_01")
	var foot1 = _foot_y(preview)
	_check(abs(foot0 - foot1) < 1.0, "脚底 Pivot 稳定")
	preview.set_gender("male")
	preview.set_equipment("torso", "")

	# 18 NPC 模板
	_check(npcs.size() == 3, "3 个 NPC")
	_check(_part_asset(npcs[0], "hair") != _part_asset(npcs[1], "hair"), "NPC 模板外观不同")
	_check(npcs[2].equipment.has("torso"), "NPC3 装备数据")

	# 19 Portrait 分离
	var pm := db.get_portrait("portrait_male_01")
	var pf := db.get_portrait("portrait_female_01")
	_check(not pm.is_empty() and not pf.is_empty(), "Portrait 数据存在")
	if preview.assets != null:
		var tpm := preview.assets.get_portrait("portrait_male_01")
		var tpf := preview.assets.get_portrait("portrait_female_01")
		_check(tpm != null and tpf != null and tpm != tpf, "男/女 Portrait 不同")

	# 20 反复换装无残留
	for i in range(25):
		preview.set_equipment("torso", "armor_iron_01" if i % 2 == 0 else "")
		preview.set_equipment("helmet", "helmet_iron_01" if i % 3 == 0 else "")
		preview.set_mainhand("weapon_iron_sword_01" if i % 2 == 0 else "weapon_wood_sword_01")
		preview.set_offhand("shield_wood_01" if i % 2 == 0 else "")
		preview.set_hair("hair_long_01" if i % 2 == 0 else "hair_short_01")
	_check(preview.resolver._created.size() == preview.resolver.parts.size(), "反复换装无残留")

	# 21 资源替换不修改 Gameplay
	var old_tex = preview.assets.get_texture("weapon_wood_sword_01")
	var replacement := TextureFactory.make("weapon", Vector2i(10, 40), Color(1, 0, 1, 1))
	preview.assets.set_override("weapon_wood_sword_01", replacement)
	preview.set_mainhand("weapon_wood_sword_01")
	preview.rebuild()
	var sword2 = preview.resolver.parts.get("weapon")
	_check(sword2 != null and sword2.texture == replacement, "资源替换无需改 Gameplay")
	preview.assets.set_override("weapon_wood_sword_01", old_tex)
	preview.rebuild()

func _part_asset(c: CharacterVisual, key: String):
	var node = c.resolver.parts.get(key)
	if node == null:
		return null
	return node.get_meta("asset_id")

func _foot_y(c: CharacterVisual) -> float:
	var node: Node2D = c.resolver.parts.get("body")
	if node == null:
		return 0.0
	var tex: Texture2D = node.texture
	return node.global_position.y + tex.get_height() / 2.0

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
