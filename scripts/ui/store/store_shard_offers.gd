extends Object
class_name StoreShardOffers

## "Not enough shards" overlay with grant packs (debug/meta progression grants).

const SHARD_PACK_OFFERS: Array[Dictionary] = [
	{"grant": 60, "title": "Pouch of Shards"},
	{"grant": 100, "title": "Bag of Shards"},
	{"grant": 1000, "title": "Vault of Shards"},
]


static func may_grant_free_shard_packs() -> bool:
	if OS.is_debug_build():
		return true
	return bool(ProjectSettings.get_setting("fmm/allow_dev_shard_grants", false))


## If [param browse] is true, show a friendly "get shards" blurb (e.g. header tap); [param cost] is ignored.
static func show_overlay(host: Control, cost: int, browse: bool = false) -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_c := UIPalette.NIGHT_NAVY
	dim_c.a = 0.78
	dim.color = dim_c
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			overlay.queue_free()
	)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var vw: float = host.get_viewport().get_visible_rect().size.x
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(maxf(120.0, vw - 16.0), 0.0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = UIPalette.TEXT_PRIMARY.lerp(UIPalette.SURFACE, 0.42)
	card_style.border_color = Color.BLACK
	card_style.border_width_left = 4
	card_style.border_width_top = 4
	card_style.border_width_right = 4
	card_style.border_width_bottom = 4
	card_style.corner_radius_top_left = 18
	card_style.corner_radius_top_right = 18
	card_style.corner_radius_bottom_right = 18
	card_style.corner_radius_bottom_left = 18
	card_style.content_margin_left = 18.0
	card_style.content_margin_right = 18.0
	card_style.content_margin_top = 14.0
	card_style.content_margin_bottom = 18.0
	card.add_theme_stylebox_override("panel", card_style)

	var press_font := load("res://art/fonts/PressStart2P-Regular.ttf") as Font

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var left_pad := Control.new()
	left_pad.custom_minimum_size = Vector2(44, 44)
	top_row.add_child(left_pad)

	var rib_spacer := Control.new()
	rib_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(rib_spacer)

	var close_x := Button.new()
	close_x.text = "✕"
	close_x.flat = true
	close_x.focus_mode = Control.FOCUS_NONE
	close_x.custom_minimum_size = Vector2(44, 44)
	close_x.add_theme_font_size_override("font_size", 20)
	close_x.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	var cx := StyleBoxFlat.new()
	cx.bg_color = UIPalette.DANGER
	cx.corner_radius_top_left = 22
	cx.corner_radius_top_right = 22
	cx.corner_radius_bottom_right = 22
	cx.corner_radius_bottom_left = 22
	close_x.add_theme_stylebox_override("normal", cx)
	var cx_h := cx.duplicate() as StyleBoxFlat
	cx_h.bg_color = cx.bg_color.lightened(0.12)
	close_x.add_theme_stylebox_override("hover", cx_h)
	close_x.add_theme_stylebox_override("pressed", cx_h)
	close_x.pressed.connect(func() -> void:
		AudioManager.play_ui_by_name("button_tap")
		overlay.queue_free()
	)
	top_row.add_child(close_x)
	root.add_child(top_row)

	var ribbon := PanelContainer.new()
	ribbon.custom_minimum_size = Vector2(0, 50)
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rib_st := StyleBoxFlat.new()
	rib_st.bg_color = UIPalette.DREAM_VIOLET.darkened(0.08)
	rib_st.border_width_bottom = 4
	rib_st.border_color = UIPalette.MOON_GOLD
	rib_st.corner_radius_top_left = 10
	rib_st.corner_radius_top_right = 10
	rib_st.corner_radius_bottom_right = 6
	rib_st.corner_radius_bottom_left = 6
	rib_st.content_margin_left = 10.0
	rib_st.content_margin_right = 10.0
	rib_st.content_margin_top = 10.0
	rib_st.content_margin_bottom = 8.0
	ribbon.add_theme_stylebox_override("panel", rib_st)
	var rib_center := CenterContainer.new()
	var rib_title := Label.new()
	rib_title.text = "Dream Shards"
	rib_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rib_ls := LabelSettings.new()
	rib_ls.font = press_font
	rib_ls.font_size = 20
	rib_ls.font_color = UIPalette.TEXT_PRIMARY
	rib_ls.outline_size = 5
	rib_ls.outline_color = Color.BLACK
	rib_title.label_settings = rib_ls
	rib_center.add_child(rib_title)
	ribbon.add_child(rib_center)
	root.add_child(ribbon)

	var sub := Label.new()
	if browse:
		sub.text = "Get more Dream Shards.\nPick a pack:"
	else:
		var need := maxi(int(cost) - int(MetaProgression.dream_shards), 0)
		sub.text = "Need %d more shards for this purchase.\nPick a pack:" % need
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	var sub_ls := LabelSettings.new()
	sub_ls.font = press_font
	sub_ls.font_size = 14
	sub_ls.font_color = UIPalette.NIGHT_NAVY
	sub_ls.outline_size = 4
	sub_ls.outline_color = UIPalette.TEXT_PRIMARY
	sub.label_settings = sub_ls
	root.add_child(sub)

	var have_lbl := Label.new()
	have_lbl.text = "You have: %d" % int(MetaProgression.dream_shards)
	have_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	have_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var have_ls := LabelSettings.new()
	have_ls.font = press_font
	have_ls.font_size = 16
	have_ls.font_color = UIPalette.TEXT_PRIMARY
	have_ls.outline_size = 5
	have_ls.outline_color = Color.BLACK
	have_lbl.label_settings = have_ls
	root.add_child(have_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 340)
	for offer: Dictionary in SHARD_PACK_OFFERS:
		row.add_child(_create_shard_pack_shop_unit(host, offer, overlay))
	root.add_child(row)

	card.add_child(root)
	center.add_child(card)
	host.add_child(overlay)


static func _create_shard_pack_shop_unit(host: Control, offer: Dictionary, overlay: Control) -> PanelContainer:
	var grant: int = int(offer.get("grant", 0))
	var pack_title: String = str(offer.get("title", "Shards"))

	var unit := PanelContainer.new()
	unit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	unit.custom_minimum_size = Vector2(96, 0)

	var shell := StyleBoxFlat.new()
	shell.bg_color = UIPalette.TEXT_PRIMARY.lerp(UIPalette.SURFACE, 0.35)
	shell.border_color = Color.BLACK
	shell.border_width_left = 3
	shell.border_width_top = 3
	shell.border_width_right = 3
	shell.border_width_bottom = 3
	shell.corner_radius_top_left = 14
	shell.corner_radius_top_right = 14
	shell.corner_radius_bottom_right = 14
	shell.corner_radius_bottom_left = 14
	shell.content_margin_left = 10.0
	shell.content_margin_right = 10.0
	shell.content_margin_top = 10.0
	shell.content_margin_bottom = 12.0
	unit.add_theme_stylebox_override("panel", shell)

	var press_font := load("res://art/fonts/PressStart2P-Regular.ttf") as Font
	var shard_tex := load("res://art/ui/icon_shard.png") as Texture2D

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = pack_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	var t_ls := LabelSettings.new()
	t_ls.font = press_font
	t_ls.font_size = 13
	t_ls.font_color = UIPalette.TEXT_PRIMARY
	t_ls.outline_size = 4
	t_ls.outline_color = Color.BLACK
	title.label_settings = t_ls
	col.add_child(title)

	var inner := PanelContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner_st := StyleBoxFlat.new()
	inner_st.bg_color = UIPalette.NIGHT_NAVY.darkened(0.04)
	inner_st.border_color = Color.BLACK
	inner_st.border_width_left = 4
	inner_st.border_width_top = 4
	inner_st.border_width_right = 4
	inner_st.border_width_bottom = 4
	inner_st.corner_radius_top_left = 8
	inner_st.corner_radius_top_right = 8
	inner_st.corner_radius_bottom_right = 8
	inner_st.corner_radius_bottom_left = 8
	inner_st.content_margin_left = 8.0
	inner_st.content_margin_right = 8.0
	inner_st.content_margin_top = 10.0
	inner_st.content_margin_bottom = 10.0
	inner.add_theme_stylebox_override("panel", inner_st)

	var inner_v := VBoxContainer.new()
	inner_v.add_theme_constant_override("separation", 8)
	inner_v.alignment = BoxContainer.ALIGNMENT_CENTER

	var qty := Label.new()
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.text = "%d" % grant
	var qty_ls := LabelSettings.new()
	qty_ls.font = press_font
	qty_ls.font_size = 24
	qty_ls.font_color = UIPalette.MOON_GOLD
	qty_ls.outline_size = 5
	qty_ls.outline_color = Color.BLACK
	qty.label_settings = qty_ls
	inner_v.add_child(qty)

	var art := CenterContainer.new()
	art.custom_minimum_size = Vector2(0, 84)
	var shard_img := TextureRect.new()
	shard_img.texture = shard_tex
	shard_img.custom_minimum_size = Vector2(72, 72)
	shard_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.add_child(shard_img)
	inner_v.add_child(art)

	inner.add_child(inner_v)
	col.add_child(inner)

	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 8)
	var pr := Label.new()
	pr.text = "%d" % grant
	pr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pr_ls := LabelSettings.new()
	pr_ls.font = press_font
	pr_ls.font_size = 18
	pr_ls.font_color = UIPalette.TEXT_PRIMARY
	pr_ls.outline_size = 4
	pr_ls.outline_color = Color.BLACK
	pr.label_settings = pr_ls
	price_row.add_child(pr)
	var sm := TextureRect.new()
	sm.texture = shard_tex
	sm.custom_minimum_size = Vector2(32, 32)
	sm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	price_row.add_child(sm)
	col.add_child(price_row)

	var claim := Button.new()
	claim.text = "+%d" % grant
	claim.custom_minimum_size = Vector2(0, 48)
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.add_theme_font_size_override("font_size", 16)
	claim.add_theme_color_override("font_color", UIPalette.NIGHT_NAVY)
	var cn := StyleBoxFlat.new()
	cn.bg_color = UIPalette.SUCCESS
	cn.border_color = UIPalette.MOON_GOLD
	cn.border_width_left = 2
	cn.border_width_top = 2
	cn.border_width_right = 2
	cn.border_width_bottom = 2
	cn.corner_radius_top_left = 10
	cn.corner_radius_top_right = 10
	cn.corner_radius_bottom_right = 10
	cn.corner_radius_bottom_left = 10
	cn.content_margin_top = 12.0
	cn.content_margin_bottom = 12.0
	claim.add_theme_stylebox_override("normal", cn)
	var cn_h := cn.duplicate() as StyleBoxFlat
	cn_h.bg_color = cn.bg_color.lightened(0.08)
	claim.add_theme_stylebox_override("hover", cn_h)
	claim.add_theme_stylebox_override("pressed", cn_h)
	var g := grant
	var can_gr: bool = may_grant_free_shard_packs()
	if not can_gr:
		claim.disabled = true
		claim.text = "IAP"
		claim.tooltip_text = "Wire AdMob / IAP; enable fmm/allow_dev_shard_grants in project settings for non-debug."
	claim.pressed.connect(func() -> void:
		if not may_grant_free_shard_packs():
			return
		MetaProgression.add_shards(g)
		SaveManager.save_game()
		host.refresh_shards_display()
		host.play_purchase_feedback()
		overlay.queue_free()
	)
	col.add_child(claim)

	unit.add_child(col)
	return unit
