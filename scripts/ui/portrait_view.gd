class_name PortraitView
extends TextureRect

## 独立于 World Sprite 的立绘/头像视图。
## 优先读取 UIAssetRegistry 中的稳定 Asset ID；资源缺失时回退到程序占位 Portrait。

var asset_id: String = "portrait.default"

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func set_portrait(p_id: String) -> void:
	if asset_id == p_id and texture != null:
		return
	asset_id = p_id
	var path := UIAssetRegistry.new().get_path(p_id)
	if path != "" and ResourceLoader.exists(path):
		texture = load(path)
	else:
		texture = _fallback_texture()

func set_actor_portrait(actor: Actor) -> void:
	if actor == null:
		set_portrait("portrait.default")
		return
	if actor.identity != null and actor.identity.gender == "female":
		set_portrait("portrait.eleonore")
	else:
		set_portrait("portrait.default")

func _fallback_texture() -> Texture2D:
	return PortraitFactory.make_portrait(96, 96, Color(0.80, 0.62, 0.46), Color(0.25, 0.18, 0.12), Color(0.28, 0.40, 0.62))
