class_name UIAssetRegistry
extends RefCounted

## Prototype UI 资源稳定 Asset ID -> 原始路径。现有素材可直接用于开发与 Demo。
const ASSETS := {
	"portrait.default": "res://assets/123/Portraits_v1/Portraits/Joanna/JoannaPortrait1.png",
	"portrait.eleonore": "res://assets/123/Portraits_v1/Portraits/Eleonore/Eleonore1.png",
	"title.village": "res://assets/123/Rasaks_Fantasy_Tileset/Fantasy/Tileset/Special_Buildings/Common_Inn_Small.png",
	"title.hero": "res://assets/123/The Male adventurer - Free/The Male adventurer - Free/Idle/idle_down.png",
	"font.ui.bold_pixels": "res://assets/123/webfontkit-BoldPixels/boldpixels.ttf",
	"icon.gold": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/consumables.png",
	"icon.quest": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/books.png",
	"icon.inventory": "res://assets/123/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/16x16 Assorted RPG Icons/armours.png",
	"ui.panel": "",
	"ui.button": ""
}

func get_path(id: String) -> String:
	return str(ASSETS.get(id, ""))

func get_texture(id: String, region: Rect2 = Rect2()) -> Texture2D:
	var path := get_path(id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var source := load(path) as Texture2D
	if source == null or region.size == Vector2.ZERO:
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	return atlas
