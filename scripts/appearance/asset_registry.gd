class_name AssetRegistry
extends RefCounted

## 稳定 Asset ID -> 纹理 的注册表；当前用程序化占位纹理，未来可替换为文件加载。
var db: CharacterVisualDB
var _cache: Dictionary = {}

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
