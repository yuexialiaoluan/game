class_name PortraitFactory

## 生成独立于 World Sprite 的极简占位 Portrait 纹理。
static func make_portrait(width: int, height: int, skin: Color, hair: Color, cloth: Color) -> Texture2D:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.12, 0.18, 1.0))
	for y in range(int(height * 0.25), int(height * 0.75)):
		for x in range(int(width * 0.25), int(width * 0.75)):
			img.set_pixel(x, y, skin)
	for y in range(int(height * 0.16), int(height * 0.32)):
		for x in range(int(width * 0.22), int(width * 0.78)):
			img.set_pixel(x, y, hair)
	for y in range(int(height * 0.75), height):
		for x in range(int(width * 0.22), int(width * 0.78)):
			img.set_pixel(x, y, cloth)
	return ImageTexture.create_from_image(img)
