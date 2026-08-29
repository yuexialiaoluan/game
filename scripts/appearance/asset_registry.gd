class_name AssetRegistry
extends RefCounted

## 稳定 Asset ID -> 纹理 的注册表；当前用程序化占位纹理，未来可替换为文件加载。
var db: CharacterVisualDB
var _cache: Dictionary = {}

const WORLD_SPRITES := {
	"world.player.male": { "path": "res://assets/123/The Male adventurer - Free/The Male adventurer - Free/Idle/idle_down.png", "walk_path": "res://assets/123/The Male adventurer - Free/The Male adventurer - Free/Walk/walk_down.png", "frames": 8, "idle_frames": 8, "frame_width": 48, "frame_height": 64 },
	"world.player.female": { "path": "res://assets/123/EleonoreAndJoanna/Sprites/Eleonore/Idle/Idle1.png", "frames": 1, "frame_width": 64, "frame_height": 64 },
	"world.npc.01": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_01/npc_01__down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.npc.02": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_02/npc_02_down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.npc.03": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_03/npc_03__down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.npc.04": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_04/npc_04__down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.npc.05": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_05/npc_05__down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.npc.06": { "path": "res://assets/123/Village_NPC_Vol1/Village_NPC_Vol1/NPC_06/npc_06__down.png", "frames": 8, "rows": 2, "idle_frames": 4, "idle_frame_step": 2, "animate_idle": false, "walk_row": 1, "frame_width": 96, "frame_height": 96 },
	"world.goblin.warrior": { "path": "res://assets/123/Orcs/Orcs/orcs.png", "frames": 12, "rows": 8, "frame_width": 48, "frame_height": 48, "initial_frame": 0 },
	"world.goblin.archer": { "path": "res://assets/123/Orcs/Orcs/orcs.png", "frames": 12, "rows": 8, "frame_width": 48, "frame_height": 48, "initial_frame": 12 }
}

const WORLD_PROPS := {
	"world.building.small": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/premade_buildings_demo.png", "region": [45, 35, 105, 140] },
	"world.building.large": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/premade_buildings_demo.png", "region": [155, 30, 185, 150] },
	"world.prop.tree": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/objects_demo.png", "region": [230, 0, 125, 110] },
	"world.prop.chest": { "path": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/chests.png", "region": [0, 0, 16, 16] },
	"world.building.inn": { "path": "res://assets/123/Rasaks_Fantasy_Tileset/Fantasy/Tileset/Special_Buildings/Common_Inn_Small.png" },
	"world.building.smith": { "path": "res://assets/123/Rasaks_Fantasy_Tileset/Fantasy/Tileset/Special_Buildings/Common_Smith_Small.png" },
	"world.building.store": { "path": "res://assets/123/Rasaks_Fantasy_Tileset/Fantasy/Tileset/Special_Buildings/Common_Store_small.png" },
	"world.building.house_a": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/premade_buildings_demo.png", "region": [45, 35, 105, 140] },
	"world.building.house_b": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/premade_buildings_demo.png", "region": [155, 30, 185, 150] },
	"world.prop.well": { "path": "res://assets/123/Pixel Lands Village Demo/Pixel Lands Village Demo/objects_demo.png", "region": [0, 310, 80, 80] }
}

const EQUIPMENT_ICONS := {
	"weapon_wood_sword_01": { "path": "res://assets/123/weapons.png", "region": [0, 0, 16, 16] },
	"weapon_iron_sword_01": { "path": "res://assets/123/iron-weapons.png", "region": [0, 0, 16, 16] },
	"shield_wood_01": { "path": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/armours.png", "region": [0, 0, 16, 16] },
	"helmet_iron_01": { "path": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/armours.png", "region": [16, 0, 16, 16] },
	"armor_leather_01": { "path": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/armours.png", "region": [32, 0, 16, 16] },
	"armor_iron_01": { "path": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/armours.png", "region": [48, 0, 16, 16] }
}

func _init(database: CharacterVisualDB) -> void:
	db = database

func get_texture(asset_id: String) -> Texture2D:
	if asset_id == "":
		return null
	if _cache.has(asset_id):
		return _cache[asset_id]
	var def := db.find_asset(asset_id)
	if def.is_empty():
		return null
	var size := _vec2i(def.get("size", [8, 8]))
	var shape := str(def.get("shape", "rect"))
	var color := _color(def, "color")
	var tex := TextureFactory.make(shape, size, color)
	_cache[asset_id] = tex
	return tex

func get_portrait(asset_id: String) -> Texture2D:
	var p := db.get_portrait(asset_id)
	if p.is_empty():
		return null
	var size := _vec2i(p.get("size", [48, 64]))
	var skin := _color(p, "skin")
	var hair := _color(p, "hair")
	var cloth := _color(p, "cloth")
	return PortraitFactory.make_portrait(size.x, size.y, skin, hair, cloth)

func get_world_sprite(id: String) -> Dictionary:
	return WORLD_SPRITES.get(id, {}) as Dictionary

func get_external_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func get_equipment_icon(item_id: String) -> Texture2D:
	var spec := EQUIPMENT_ICONS.get(item_id, {}) as Dictionary
	if spec.is_empty():
		return null
	var source := get_external_texture(str(spec.get("path", "")))
	if source == null:
		return null
	var region_data: Array = spec.get("region", []) as Array
	if region_data.size() != 4:
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(float(region_data[0]), float(region_data[1]), float(region_data[2]), float(region_data[3]))
	return atlas

func get_world_prop(id: String) -> Texture2D:
	var spec := WORLD_PROPS.get(id, {}) as Dictionary
	if spec.is_empty():
		return null
	var source := get_external_texture(str(spec.get("path", "")))
	if source == null:
		return null
	var region_data: Array = spec.get("region", []) as Array
	if region_data.size() != 4:
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(float(region_data[0]), float(region_data[1]), float(region_data[2]), float(region_data[3]))
	return atlas

func set_override(asset_id: String, tex: Texture2D) -> void:
	_cache[asset_id] = tex

func _vec2i(arr) -> Vector2i:
	if arr is Array and arr.size() >= 2:
		return Vector2i(int(arr[0]), int(arr[1]))
	return Vector2i(8, 8)

func _color(def: Dictionary, key: String) -> Color:
	var arr = def.get(key, null)
	if arr == null and def.has("skin"):
		arr = def.get("skin")
	if arr is Array and arr.size() >= 4:
		return Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))
	return Color.WHITE
