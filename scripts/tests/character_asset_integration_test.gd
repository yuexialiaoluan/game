extends Node3D

var failures := 0
var db: CharacterVisualDB
var npc_motion_test: CharacterBillboard3D
var player_motion_test: CharacterBillboard3D

func _ready() -> void:
	db = CharacterVisualDB.new()
	var ids := [
		"world.player.male", "world.player.female", "world.npc.01", "world.npc.03",
		"world.npc.05", "world.goblin.warrior", "world.goblin.archer"
	]
	for i in range(ids.size()):
		var character := CharacterBillboard3D.new()
		character.position = Vector3(float(i) * 2.0, 0.0, 0.0)
		add_child(character)
		character.setup(db, "human_male", "hair_short_01", "clothing_peasant_01", "", "eyes_default_01", str(ids[i]))
		if str(ids[i]) == "world.player.male":
			player_motion_test = character
		if str(ids[i]) == "world.npc.01":
			npc_motion_test = character
		_check(character.sprite != null and character.sprite.texture != null, "T%d Full Sprite %s" % [i + 1, ids[i]])
		_check(character.sub_viewport.size == Vector2i(96, 96), "T%d Viewport Size" % [i + 8])
		_check(character.visual.world_sprite.sprite.position.x == 0.0, "T%d Foot Pivot X" % [i + 15])
	var equipment := CharacterBillboard3D.new()
	add_child(equipment)
	equipment.setup(db, "human_male", "hair_short_01", "clothing_peasant_01", "", "eyes_default_01", "world.player.male")
	equipment.visual.set_mainhand("weapon_wood_sword_01")
	equipment.visual.set_offhand("shield_wood_01")
	equipment.visual.set_equipment("helmet", "helmet_iron_01")
	_check(equipment.visual.world_sprite.equipment_nodes.size() == 3, "T22 Equipment Overlay")
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_finish")

func _finish() -> void:
	await get_tree().process_frame
	_check(player_motion_test.visual.world_sprite.sprite.hframes == 8, "T23 Player Sheet Uses 8 Frames")
	_check(player_motion_test.visual.world_sprite.frame_width == 48, "T24 Player Frame Width")
	npc_motion_test.visual.animator.set_moving(true)
	await get_tree().process_frame
	_check(npc_motion_test.visual.world_sprite.sprite.frame_coords.y == 1, "T25 NPC Walk Uses Motion Row")
	print("VALIDATION_DONE failures=", failures)
	get_tree().quit()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		print("FAIL ", label)
		failures += 1
