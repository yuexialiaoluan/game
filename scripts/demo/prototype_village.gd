class_name PrototypeVillage
extends "res://scripts/tests/world_exploration_test.gd"

## 正式可玩原型地图。复用既有世界、交互、NPC、任务与 UI 服务，替换测试场景的简陋布置。
const NPC_WANDER_SCRIPT := preload("res://scripts/npc/npc_wander_3d.gd")

var interior_exit: Interactable3D
var interior_spawn: Vector3 = Vector3(0, 0.3, -57)
var interior_return_positions: Dictionary = {}

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("6c9fbe")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b7d4c5")
	environment.ambient_light_energy = 0.72
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	add_child(WorldBuilder.make_plane(Vector2(96, 84), Vector3.ZERO, Color("5f8d4c"), "VillageGround"))
	_add_road(Vector3(0, 0.03, 3), Vector3(72, 0.06, 4))
	_add_road(Vector3(-7, 0.04, -3), Vector3(4, 0.06, 52))
	_add_road(Vector3(14, 0.04, -8), Vector3(34, 0.06, 3))
	_add_road(Vector3(-24, 0.04, 11), Vector3(3, 0.06, 24))
	_add_water(Vector3(34, 0.02, 0), Vector3(11, 0.04, 78))
	_add_road(Vector3(34, 0.08, 3), Vector3(13, 0.10, 3))
	_add_village_art()

	player = PlayerController3D.new()
	player.position = Vector3(-22, 0.3, 4)
	add_child(player)
	player.attach_visual(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "world.player.male")
	cam = OrthoFollowCamera.new()
	cam.target = player
	cam.offset = Vector3(0, 13, 14)
	cam.size = 14.0
	add_child(cam)
	player.camera = cam
	add_child(NavigationRegion3D.new())

func _add_road(position: Vector3, size: Vector3) -> void:
	add_child(WorldBuilder.make_box(size, position, Color("b89a6a"), "VillageRoad"))

func _add_water(position: Vector3, size: Vector3) -> void:
	add_child(WorldBuilder.make_box(size, position, Color("3c81a5"), "River"))

func _add_village_art() -> void:
	var art := AssetRegistry.new(cdb)
	var buildings := [
		["world.building.inn", Vector3(-8, 0, -10), 0.020, "Tavern"],
		["world.building.smith", Vector3(-15, 0, 6), 0.020, "Blacksmith"],
		["world.building.store", Vector3(6, 0, -9), 0.020, "Store"],
		["world.building.house_a", Vector3(9, 0, 8), 0.033, "HouseEast"],
		["world.building.house_b", Vector3(15, 0, 3), 0.030, "HouseSouthEast"],
		["world.building.house_a", Vector3(-2, 0, 12), 0.029, "HouseNorth"],
		["world.building.house_b", Vector3(-20, 0, -7), 0.029, "HouseWest"],
		["world.building.house_a", Vector3(-27, 0, 13), 0.029, "HouseMill"],
		["world.building.house_b", Vector3(-28, 0, -14), 0.029, "HouseFarm"],
		["world.building.house_a", Vector3(19, 0, -12), 0.029, "HouseRiver"],
		["world.building.house_b", Vector3(20, 0, 14), 0.029, "HouseOrchard"],
		["world.building.house_a", Vector3(5, 0, 20), 0.029, "HouseGarden"],
		["world.building.house_b", Vector3(-12, 0, 20), 0.029, "HouseNorthwest"]
	]
	for spec in buildings:
		_add_building(art.get_world_prop(str(spec[0])), spec[1], float(spec[2]), str(spec[3]))
	var tree_positions := [Vector3(-39, 0, -29), Vector3(-34, 0, -18), Vector3(-38, 0, 4), Vector3(-34, 0, 25), Vector3(-22, 0, 29), Vector3(-6, 0, 31), Vector3(9, 0, 29), Vector3(24, 0, 27), Vector3(42, 0, 20), Vector3(42, 0, -4), Vector3(40, 0, -25), Vector3(22, 0, -29), Vector3(12, 0, -23), Vector3(-13, 0, -25), Vector3(-29, 0, -25)]
	for tree_position in tree_positions:
		_add_world_prop(art.get_world_prop("world.prop.tree"), tree_position, 0.026, "VillageTree")
	_add_world_prop(art.get_world_prop("world.prop.well"), Vector3(-1, 0, 2), 0.028, "VillageWell")
	_add_world_prop(art.get_world_prop("world.prop.chest"), Vector3(11, 0, -1), 0.07, "VillageChest")

func _add_building(texture: Texture2D, pos: Vector3, pixel_size: float, building_name: String) -> void:
	var is_large := building_name == "Tavern" or building_name == "Blacksmith" or building_name == "Store"
	var size := Vector3(5.8, 2.4, 4.2) if is_large else Vector3(4.2, 2.0, 3.3)
	add_child(WorldBuilder.make_building_shell(size, pos, Color("b58b62"), Color("5f3a36"), building_name + "Shell"))
	if texture != null:
		var facade := WorldBuilder.make_sprite_prop(texture, Vector3(pos.x, -0.18, pos.z - size.z * 0.52 - 0.05), pixel_size, building_name + "Facade")
		facade.visible = false
		add_child(facade)
	var door := _add_interactable("door_" + building_name.to_lower(), "door", pos - Vector3(0, 0, size.z * 0.65), Color("8d633d"))
	door.display_name = building_name + " 入口"
	var mesh: MeshInstance3D = door.get_meta("mesh")
	if mesh != null:
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 1.7, 0.22)
		mesh.mesh = box

func _spawn_npcs() -> void:
	super._spawn_npcs()
	var placements := {
		"villager": Vector3(-5, 0, 1), "blacksmith": Vector3(-14, 0, 4), "merchant": Vector3(5, 0, -4),
		"tavern": Vector3(-8, 0, -6), "guard": Vector3(-20, 0, 4), "hunter": Vector3(-20, 0, 12),
		"mercenary": Vector3(-6, 0, -13), "adventurer": Vector3(3, 0, 10)
	}
	for node in objects:
		if node is Interactable3D and placements.has(node.object_id):
			node.position = placements[node.object_id]
	_add_wanderer("villager", [Vector3(-5, 0, 1), Vector3(-2, 0, 1), Vector3(-2, 0, 5), Vector3(-6, 0, 5)])
	_add_wanderer("guard", [Vector3(-20, 0, 4), Vector3(-22, 0, 8), Vector3(-18, 0, 11), Vector3(-16, 0, 7)])
	_add_wanderer("adventurer", [Vector3(3, 0, 10), Vector3(6, 0, 13), Vector3(3, 0, 16), Vector3(0, 0, 13)])
	ui.set_tavern_recruits([npc_actors.get("mercenary"), npc_actors.get("adventurer")])

func _spawn_objects() -> void:
	super._spawn_objects()
	for node in objects:
		if not (node is Interactable3D):
			continue
		match node.object_id:
			"door_001": node.visible = false
			"chest_001": node.position = Vector3(10, 0, -1)
			"resource_001": node.position = Vector3(20, 0, 11)
			"resource_002": node.position = Vector3(18, 0, 13)
			"resource_003": node.position = Vector3(22, 0, 14)
			"fishing_001": node.position = Vector3(21, 0, 4)
			"bed_001": node.position = Vector3(-8, 0, -9)
			"craft_001":
				node.position = Vector3(-14, 0, 2)
				node.display_name = "铁匠工作台（强化主手）"
			"dungeon_trial_gate":
				node.position = Vector3(-20, 0, 10)
				node.display_name = "遗迹试炼入口"
				var mesh: MeshInstance3D = node.get_meta("mesh")
				if mesh != null:
					var gate := BoxMesh.new()
					gate.size = Vector3(1.4, 2.8, 0.8)
					mesh.mesh = gate
					mesh.position.y = 1.4
	_build_interior()

func _spawn_enemy() -> void:
	super._spawn_enemy()
	for node in objects:
		if node is Interactable3D and node.object_id == "goblin":
			node.position = Vector3(21, 0, -14)
		elif node is Interactable3D and node.object_id == "goblin_archer":
			node.position = Vector3(24, 0, -11)

func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("quick_save"):
		SaveService.new().save_game("prototype", ctx, "story", rng.get_state())
		ui.set_feedback("已保存到 Prototype 存档")

func _add_wanderer(npc_id: String, waypoints: Array[Vector3]) -> void:
	for node in objects:
		if not (node is Interactable3D) or node.object_id != npc_id:
			continue
		var visual: CharacterBillboard3D
		for child in node.get_children():
			if child is CharacterBillboard3D:
				visual = child
				break
		if visual == null:
			return
		var wanderer: Node = NPC_WANDER_SCRIPT.new()
		node.add_child(wanderer)
		wanderer.call("setup", node, visual, waypoints)
		return

func _build_interior() -> void:
	var center := Vector3(0, 0, -58)
	add_child(WorldBuilder.make_plane(Vector2(16, 12), center - Vector3(0, 0.1, 0), Color("9a7758"), "PrototypeInteriorFloor"))
	add_child(WorldBuilder.make_box(Vector3(16, 3, 0.4), center + Vector3(0, 1.5, -6), Color("705044"), "InteriorBackWall"))
	add_child(WorldBuilder.make_box(Vector3(0.4, 3, 12), center + Vector3(-8, 1.5, 0), Color("705044"), "InteriorLeftWall"))
	add_child(WorldBuilder.make_box(Vector3(0.4, 3, 12), center + Vector3(8, 1.5, 0), Color("705044"), "InteriorRightWall"))
	add_child(WorldBuilder.make_box(Vector3(5.5, 3, 0.4), center + Vector3(-5.25, 1.5, 6), Color("705044"), "InteriorFrontWallLeft"))
	add_child(WorldBuilder.make_box(Vector3(5.5, 3, 0.4), center + Vector3(5.25, 1.5, 6), Color("705044"), "InteriorFrontWallRight"))
	add_child(WorldBuilder.make_box(Vector3(2.8, 0.9, 1.2), center + Vector3(-3.5, 0.45, -1), Color("6e4e34"), "InteriorTable"))
	add_child(WorldBuilder.make_box(Vector3(1.2, 1.4, 0.8), center + Vector3(3.6, 0.7, -2.5), Color("553e2d"), "InteriorCabinet"))
	interior_exit = _add_interactable("interior_exit", "interior_exit", center + Vector3(0, 0, 5.2), Color("c9a06b"))
	interior_exit.display_name = "返回村庄"
	var mesh: MeshInstance3D = interior_exit.get_meta("mesh")
	if mesh != null:
		mesh.position.y = 0.85
		var exit_box := BoxMesh.new()
		exit_box.size = Vector3(1.4, 1.7, 0.25)
		mesh.mesh = exit_box

func _handle_world_interaction(nearest: Interactable3D, actions: Array) -> void:
	if nearest == interior_exit:
		var return_position: Vector3 = interior_return_positions.get("active", Vector3(-22, 0.3, 4))
		interior.exit()
		_teleport_player(return_position)
		ui.set_feedback("已返回村庄。")
		return
	if nearest.object_type == "door" and nearest.object_id.begins_with("door_"):
		interior_return_positions["active"] = nearest.global_position - Vector3(0, 0, 1.4)
		interior.enter(nearest.object_id)
		_teleport_player(interior_spawn)
		ui.set_feedback("已进入室内。按 [E] 返回村庄。")
		return
	super._handle_world_interaction(nearest, actions)

func _teleport_player(destination: Vector3) -> void:
	if player == null:
		return
	player.global_position = destination
	player.velocity = Vector3.ZERO

func _run_validation() -> void:
	super._run_validation()
	_check(interior_exit != null and iserv.get_object("interior_exit") != null, "T37 实体室内与出口")
	_check(party.get_shared_inventory_owner(ctx.player) == ctx.player, "T38 队伍共享背包")
	var red_item := equipment_generator.generate("helmet", 12, "artifact")
	_check(not str(red_item.get("name", "")).contains("06"), "T39 装备名称无内部编号")
	_check(equipment_generator.roll_dungeon_quality(12) in ["rare", "epic", "legendary", "artifact"], "T40 副本最高支持红色掉落")
