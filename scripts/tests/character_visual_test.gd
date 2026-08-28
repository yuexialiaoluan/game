extends Node2D

## 《灰烬之上的勇者》角色表现技术验证场景。
## 仅验证表现层，不属于正式游戏内容。

var db: CharacterVisualDB
var player: CharacterVisual
var npc_a: CharacterVisual
var npc_b: CharacterVisual
var chest: TestChest
var prompt_label: Label
var validation_failures: int = 0

func _ready() -> void:
	db = CharacterVisualDB.new()
	_build_scene()
	_build_ui()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _build_scene() -> void:
	var ground := VisualFactory.make_pixel(Color(0.16, 0.22, 0.16, 1))
	ground.name = "Ground"
	ground.scale = Vector2(1000, 40)
	ground.position = Vector2(0, 90)
	add_child(ground)

	player = CharacterVisual.new()
	player.name = "Player"
	player.position = Vector2(0, 60)
	add_child(player)
	player.setup(db, "human_male", "hair_short_01", "clothing_peasant_01")

	npc_a = CharacterVisual.new()
	npc_a.name = "NPCA"
	npc_a.position = Vector2(-140, 60)
	add_child(npc_a)
	var ta := db.get_npc_template("human_male_01")
	npc_a.setup(db, str(ta.get("body_id", "human_male")), str(ta.get("hair_id", "hair_short_01")), str(ta.get("clothing_id", "clothing_peasant_01")))

	npc_b = CharacterVisual.new()
	npc_b.name = "NPCB"
	npc_b.position = Vector2(140, 60)
	add_child(npc_b)
	var tb := db.get_npc_template("human_female_01")
	npc_b.setup(db, str(tb.get("body_id", "human_female")), str(tb.get("hair_id", "hair_long_01")), str(tb.get("clothing_id", "clothing_adventurer_01")))

	chest = TestChest.new()
	chest.name = "Chest"
	chest.position = Vector2(60, 72)
	add_child(chest)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TestUI"
	add_child(layer)

	var root := VBoxContainer.new()
	root.position = Vector2(8, 8)
	layer.add_child(root)

	var title := Label.new()
	title.text = "Character Visual Test"
	root.add_child(title)

	var eq_row := HBoxContainer.new()
	root.add_child(eq_row)
	_add_button(eq_row, "普通衣服", func(): player.set_equipment("torso", "cloth"))
	_add_button(eq_row, "铁甲", func(): player.set_equipment("torso", "iron_armor"))
	_add_button(eq_row, "无头盔", func(): player.set_equipment("helmet", ""))
	_add_button(eq_row, "铁头盔", func(): player.set_equipment("helmet", "iron_helmet"))
	_add_button(eq_row, "无武器", func(): player.set_equipment("weapon", ""))
	_add_button(eq_row, "长剑", func(): player.set_equipment("weapon", "longsword"))
	_add_button(eq_row, "无盾牌", func(): player.set_equipment("shield", ""))
	_add_button(eq_row, "木盾", func(): player.set_equipment("shield", "wood_shield"))

	var cust_row := HBoxContainer.new()
	root.add_child(cust_row)
	_add_button(cust_row, "发型A", func(): player.set_hair("hair_short_01"))
	_add_button(cust_row, "发型B", func(): player.set_hair("hair_long_01"))
	_add_button(cust_row, "衣服A", func(): player.set_clothing("clothing_peasant_01"))
	_add_button(cust_row, "衣服B", func(): player.set_clothing("clothing_adventurer_01"))

	prompt_label = Label.new()
	prompt_label.text = "[E] 互动"
	prompt_label.visible = false
	root.add_child(prompt_label)

	var help := Label.new()
	help.text = "A/D 移动，Space 攻击，E 互动"
	root.add_child(help)

func _add_button(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)

func _process(delta: float) -> void:
	if player == null:
		return
	var dir := 0.0
	if Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir += 1.0
	player.position.x += dir * 120.0 * delta
	player.animator.set_moving(abs(dir) > 0.01)

	if Input.is_key_pressed(KEY_SPACE):
		player.animator.play_attack()

	if chest != null and prompt_label != null:
		var near: bool = player.position.distance_to(chest.position) < 40.0
		prompt_label.visible = near
		if near:
			prompt_label.text = "[E] " + chest.prompt_text
			if Input.is_key_pressed(KEY_E):
				chest.interact(player)

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	_check(player != null and player.skeleton.bones.size() >= 8, "T1 角色正常显示（骨骼存在）")
	_check(player.resolver.parts.has("body") and player.resolver.parts.has("face"), "T1 分层视觉部件存在")

	# T2 衣服切换
	var cloth_color0 = _part_color(player, "clothing")
	player.set_clothing("clothing_adventurer_01")
	var cloth_color1 = _part_color(player, "clothing")
	_check(cloth_color0 != cloth_color1, "T2 切换衣服外观变化")
	player.set_clothing("clothing_peasant_01")

	# T2b 装备普通衣服会覆盖基础衣服
	player.set_equipment("torso", "cloth")
	_check(not player.resolver.parts.has("clothing") and player.resolver.parts.has("torso"), "T2 装备普通衣服覆盖基础衣服")

	# T3 头盔隐藏头发
	player.set_equipment("helmet", "iron_helmet")
	_check(not player.resolver.parts.has("hair") and player.resolver.parts.has("helmet"), "T3 头盔隐藏头发")
	player.set_equipment("helmet", "")

	# T4 长剑绑到 Hand_R
	player.set_equipment("weapon", "longsword")
	var sword: Node = player.resolver.parts.get("weapon")
	var hand_r: Node2D = player.get_bone("Hand_R")
	_check(sword != null and hand_r != null and sword.get_parent() == hand_r, "T4 长剑绑定 Hand_R")

	# T5 盾牌绑到 Hand_L
	player.set_equipment("shield", "wood_shield")
	var shield: Node = player.resolver.parts.get("shield")
	var hand_l: Node2D = player.get_bone("Hand_L")
	_check(shield != null and hand_l != null and shield.get_parent() == hand_l, "T5 盾牌绑定 Hand_L")

	# T6 攻击动画：Hand_R 移动，剑跟随
	var sword2 = player.resolver.parts.get("weapon")
	var hand_r2 = player.get_bone("Hand_R")
	if sword2 != null and hand_r2 != null:
		var base_pos = player.skeleton.base_positions["Hand_R"]
		player.animator.play_attack()
		await get_tree().create_timer(0.15).timeout
		var moved = hand_r2.position
		_check(moved != base_pos, "T6 攻击动画 Hand_R 移动")
		_check(sword2.get_parent() == hand_r2, "T6 剑跟随 Hand_R")

	# T7 发型切换
	var hair0 = _part_color(player, "hair")
	player.set_hair("hair_long_01")
	var hair1 = _part_color(player, "hair")
	_check(hair0 != hair1, "T7 切换发型外观变化")
	player.set_hair("hair_short_01")

	# T8 NPC 模板不同
	var na_hair = _part_color(npc_a, "hair")
	var nb_hair = _part_color(npc_b, "hair")
	_check(na_hair != nb_hair, "T8 NPC 发型颜色不同")
	_check(npc_a.body_id != npc_b.body_id or npc_a.hair_id != npc_b.hair_id, "T8 NPC 模板不同")

	# T9 箱子互动
	var open0: bool = chest.is_open
	chest.interact(player)
	_check(chest.is_open != open0, "T9 箱子打开")
	chest.interact(player)
	_check(chest.is_open == open0, "T9 箱子关闭")

	# T10 反复切换无重复/残留
	for i in range(15):
		player.set_equipment("torso", "iron_armor" if i % 2 == 0 else "")
		player.set_equipment("helmet", "iron_helmet" if i % 3 == 0 else "")
		player.set_hair("hair_long_01" if i % 2 == 0 else "hair_short_01")
		player.set_clothing("clothing_adventurer_01" if i % 2 == 0 else "clothing_peasant_01")
	_check(player.resolver.parts.size() >= 4, "T10 反复切换后部件有效")
	_check(player.resolver._created.size() == player.resolver.parts.size(), "T10 无重复/孤儿节点")

func _part_color(c: CharacterVisual, key: String):
	var node = c.resolver.parts.get(key)
	if node == null:
		return null
	return node.get_meta("asset_id")

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1


