extends RefCounted
class_name StoreUiKit

## Shared store row chrome: cards and primary action buttons.

## Width/height for buy / equip buttons — scales with phone screen width (Flip / portrait).
static func scaled_action_button_size(viewport_width: float) -> Vector2:
	var vw: float = maxf(viewport_width, 280.0)
	var w: float = clampf(vw * 0.26, 140.0, 228.0)
	var h: float = clampf(vw * 0.115, 66.0, 92.0)
	return Vector2(w, h)


func create_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 14.0
	style.content_margin_right = 12.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 14.0
	card.add_theme_stylebox_override("panel", style)
	return card


func make_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE_HOVER
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


## Set all text-color theme slots so price tint matches (theme hover/press colors won't override).
static func apply_button_label_tint(btn: Button, c: Color) -> void:
	btn.add_theme_color_override("font_color", c)
	btn.add_theme_color_override("font_hover_color", c)
	btn.add_theme_color_override("font_pressed_color", c)
	btn.add_theme_color_override("font_focus_color", c)
