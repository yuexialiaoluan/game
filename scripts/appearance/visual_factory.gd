class_name VisualFactory

## 生成 Sprite2D：真实纹理或 1x1 色块占位。
static func make_sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	return sprite

static func make_pixel(color: Color) -> Sprite2D:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return make_sprite(ImageTexture.create_from_image(img))
