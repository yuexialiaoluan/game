class_name UITheme
extends RefCounted

## 统一 UI 主题（现代半透明玻璃 + 蓝白细线，保留西幻/像素气质）。
var bg_color: Color = Color(0.05, 0.10, 0.20, 0.85)
var border_color: Color = Color(0.45, 0.75, 1.0, 0.9)
var text_color: Color = Color(0.85, 0.92, 1.0)
var accent_color: Color = Color(0.45, 0.75, 1.0)
var font_size: int = 16

static func panel() -> PanelContainer:
	var theme := UITheme.new()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", theme.make_style())
	return p

static func label(text: String, size: int = 16, color: Color = Color(0.85, 0.92, 1.0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String, min_size: Vector2 = Vector2(160, 36)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	return b

static func styled_button(text: String, min_size: Vector2 = Vector2(160, 36)) -> Button:
	var b := button(text, min_size)
	var theme := UITheme.new()
	var normal := theme.make_style()
	normal.bg_color = Color(0.08, 0.16, 0.28, 0.95)
	var hover := theme.make_style()
	hover.bg_color = Color(0.12, 0.26, 0.42, 0.95)
	hover.border_color = Color(0.75, 0.90, 1.0)
	var pressed := theme.make_style()
	pressed.bg_color = Color(0.05, 0.10, 0.18, 0.95)
	var disabled := theme.make_style()
	disabled.bg_color = Color(0.04, 0.06, 0.10, 0.85)
	disabled.border_color = Color(0.25, 0.30, 0.40, 0.8)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))
	return b

func make_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = border_color
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	return s
