class_name TextureFactory

## 极简像素纹理工厂：按 shape + 尺寸 + 颜色生成可替换的占位像素素材。

static func make(shape: String, size: Vector2i, base: Color) -> Texture2D:
	var w := size.x
	var h := size.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := base.darkened(0.25)
	var light := base.lightened(0.2)
	match shape:
		"body":
			_rect(img, 0, 0, w, h, base)
			_rect(img, 0, h - 4, w, 4, dark)
		"face":
			_rect(img, 0, 0, w, h, base)
			_rect(img, 3, int(h * 0.4), 3, 2, dark)
			_rect(img, w - 6, int(h * 0.4), 3, 2, dark)
		"eyes":
			_rect(img, 1, 0, 3, h, dark)
			_rect(img, w - 4, 0, 3, h, dark)
		"hair":
			_rect(img, 0, 0, w, h, base)
			_rect(img, 0, h - 2, w, 2, dark)
		"clothing":
			_rect(img, 0, 0, w, h, base)
			_border(img, 0, 0, w, h, dark)
		"armor":
			_rect(img, 0, 0, w, h, base)
			_border(img, 0, 0, w, h, dark)
			_rect(img, 2, 2, w - 4, 2, light)
		"helmet":
			_rect(img, 0, 0, w, h, base)
			_border(img, 0, 0, w, h, dark)
			_rect(img, 2, 2, w - 4, 2, light)
		"weapon":
			_rect(img, int(w * 0.5) - 1, 0, 2, h, base)
			_rect(img, 0, h - 4, w, 4, dark)
		"shield":
			_rect(img, 0, 0, w, h, base)
			_border(img, 0, 0, w, h, dark)
			_rect(img, 1, 1, w - 2, 2, light)
		"cape":
			_rect(img, 0, 0, w, h, base)
		_:
			_rect(img, 0, 0, w, h, base)
	return ImageTexture.create_from_image(img)

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var x0 := maxi(0, x)
	var y0 := maxi(0, y)
	var x1 := mini(img.get_width(), x + w)
	var y1 := mini(img.get_height(), y + h)
	for iy in range(y0, y1):
		for ix in range(x0, x1):
			img.set_pixel(ix, iy, c)

static func _border(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_rect(img, x, y, w, 1, c)
	_rect(img, x, y + h - 1, w, 1, c)
	_rect(img, x, y, 1, h, c)
	_rect(img, x + w - 1, y, 1, h, c)
