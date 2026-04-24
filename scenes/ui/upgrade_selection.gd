extends Control

## 3–4 card upgrade selection screen shown on level-up (4th may be evolution).
## Time freezes while visible. Player picks 1 upgrade or rerolls.

signal upgrade_chosen(upgrade: Dictionary)
signal selection_closed

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var card_container: HBoxContainer = $Panel/VBox/CardContainer
@onready var reroll_btn: Button = $Panel/VBox/BottomBar/RerollButton
@onready var reroll_count: Label = $Panel/VBox/BottomBar/RerollCount
@onready var panel: PanelContainer = $Panel

var _current_choices: Array[Dictionary] = []

const CATEGORY_FRAME_PATHS: Dictionary = {
	UpgradeDefinitions.Category.SLEEP_STRENGTH: "res://art/ui/upgrade_card_frame_attack.png",
	UpgradeDefinitions.Category.CALMNESS: "res://art/ui/upgrade_card_frame_defense.png",
	UpgradeDefinitions.Category.COMFORT: "res://art/ui/upgrade_card_frame_comfort.png",
}

## Text on light inner area of SpriteCook frames (TEXT_PRIMARY is for dark panels).
const _INK_TITLE: Color = Color(0.1, 0.12, 0.2, 1.0)
const _INK_BODY: Color = Color(0.34, 0.37, 0.48, 1.0)
const _FRAME_FILL: Color = Color(0.93, 0.94, 0.99, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	reroll_btn.pressed.connect(_on_reroll)


func show_selection(choices: Array[Dictionary], rerolls: int) -> void:
	_current_choices = choices
	visible = true
	get_tree().paused = true

	_update_reroll_display(rerolls)
	_build_cards(choices)

	var sm := get_node_or_null("/root/SettingsManager") as Node
	var reduce_motion: bool = sm != null and bool(sm.get("reduced_motion"))
	if reduce_motion:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		return
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_cards(choices: Array[Dictionary]) -> void:
	for child in card_container.get_children():
		child.queue_free()

	var narrow: bool = choices.size() >= 4
	var sm := get_node_or_null("/root/SettingsManager") as Node
	var reduce_motion: bool = sm != null and bool(sm.get("reduced_motion"))

	for i in choices.size():
		var card := _create_card(choices[i], i, narrow)
		card_container.add_child(card)

		if reduce_motion:
			card.modulate.a = 1.0
			card.position.y = 0.0
			continue
		card.modulate.a = 0.0
		card.position.y = 40.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(card, "modulate:a", 1.0, 0.15).set_delay(i * 0.1)
		tween.parallel().tween_property(card, "position:y", 0.0, 0.2).set_delay(i * 0.1).set_ease(Tween.EASE_OUT)


func _create_card(upgrade: Dictionary, _idx: int, narrow: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.clip_contents = true
	card.custom_minimum_size = Vector2(158 if narrow else 196, 332 if narrow else 352)
	# Keep cards intrinsic width so HBoxContainer alignment = center actually groups them in the middle.
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var category: int = upgrade.get("category", 0)
	var rarity: int = upgrade.get("rarity", 0)
	var cat_color: Color = UpgradeDefinitions.CATEGORY_COLORS.get(category, UIPalette.TEXT_PRIMARY)
	var rarity_color: Color = UpgradeDefinitions.RARITY_COLORS.get(rarity, UIPalette.TEXT_PRIMARY)

	var frame_path: String = CATEGORY_FRAME_PATHS.get(category, "")
	var used_texture_frame := false
	if frame_path != "" and ResourceLoader.exists(frame_path):
		var ftex: Texture2D = load(frame_path) as Texture2D
		# Tiny outputs (e.g. bad smart-crop) break nine-slice and look like horizontal bands.
		const MIN_FRAME_PX := 96
		if ftex and ftex.get_width() >= MIN_FRAME_PX and ftex.get_height() >= MIN_FRAME_PX:
			var sb_tex := StyleBoxTexture.new()
			sb_tex.texture = ftex
			var m := 44.0
			sb_tex.texture_margin_left = m
			sb_tex.texture_margin_top = m
			sb_tex.texture_margin_right = m
			sb_tex.texture_margin_bottom = m
			# Extra top inset so rarity line clears decorative frame art.
			sb_tex.content_margin_left = 14.0
			sb_tex.content_margin_top = 26.0
			sb_tex.content_margin_right = 14.0
			sb_tex.content_margin_bottom = 26.0
			# COMFORT frame art is tighter on the bottom — pull content up so the fill stays inside.
			if category == UpgradeDefinitions.Category.COMFORT:
				sb_tex.content_margin_bottom = 30.0
				sb_tex.content_margin_top = 28.0
			card.add_theme_stylebox_override("panel", sb_tex)
			used_texture_frame = true

	if not used_texture_frame:
		var style := StyleBoxFlat.new()
		style.bg_color = UIPalette.SURFACE
		style.border_color = rarity_color
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		style.content_margin_left = 18.0
		style.content_margin_right = 18.0
		style.content_margin_top = 20.0
		style.content_margin_bottom = 18.0
		card.add_theme_stylebox_override("panel", style)

	var title_col: Color = _INK_TITLE if used_texture_frame else UIPalette.TEXT_PRIMARY
	var desc_col: Color = _INK_BODY if used_texture_frame else UIPalette.TEXT_MUTED
	var cat_txt_col: Color = cat_color.darkened(0.5) if used_texture_frame else cat_color.lightened(0.2)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var rarity_label := Label.new()
	rarity_label.text = UpgradeDefinitions.RARITY_NAMES.get(rarity, "Common")
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.custom_minimum_size = Vector2(0, 18)
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(rarity_label)

	var cat_bar := ColorRect.new()
	cat_bar.custom_minimum_size = Vector2(0, 3)
	cat_bar.color = cat_color
	vbox.add_child(cat_bar)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer1)

	var name_label := Label.new()
	name_label.text = upgrade.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", title_col)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	vbox.add_child(name_label)

	var cat_label := Label.new()
	cat_label.text = UpgradeDefinitions.CATEGORY_NAMES.get(category, "")
	cat_label.add_theme_font_size_override("font_size", 12)
	cat_label.add_theme_color_override("font_color", cat_txt_col)
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(cat_label)

	var icon_holder := CenterContainer.new()
	icon_holder.custom_minimum_size = Vector2(0, 82)
	icon_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon_holder)

	var icon_tex := TextureRect.new()
	icon_tex.custom_minimum_size = Vector2(76, 76)
	icon_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path: String = UpgradeDefinitions.resolve_icon_path(upgrade)
	var loaded: Texture2D = load(icon_path) as Texture2D
	if loaded:
		icon_tex.texture = loaded
	icon_tex.modulate = Color(1.0, 1.0, 1.0, 1.0)
	icon_holder.add_child(icon_tex)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer2)

	## Label has no max_lines in this API; clip inside a short row so long perks do not spill the card.
	var desc_clip := Control.new()
	desc_clip.clip_contents = true
	desc_clip.custom_minimum_size = Vector2(0, 52)
	desc_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var desc_label := Label.new()
	desc_label.text = upgrade.get("desc", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", desc_col)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	desc_clip.add_child(desc_label)
	vbox.add_child(desc_clip)

	var current_stack: int = UpgradeManager.get_upgrade_stack(upgrade.get("id", ""))
	var max_stack: int = upgrade.get("max_stack", 99)
	if current_stack > 0:
		var stack_label := Label.new()
		stack_label.text = "Stack: %d/%d" % [current_stack, max_stack]
		stack_label.add_theme_font_size_override("font_size", 12)
		stack_label.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
		stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(stack_label)

	var spacer3 := Control.new()
	spacer3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer3)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if used_texture_frame:
		var bg_fill := ColorRect.new()
		bg_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Inset so cream panel stays inside ornate pixels (esp. COMFORT bottom flourish).
		var inset_l := 5.0
		var inset_t := 6.0
		var inset_r := 5.0
		var inset_b := 10.0
		if category == UpgradeDefinitions.Category.COMFORT:
			inset_t = 7.0
			inset_b = 12.0
		bg_fill.offset_left = inset_l
		bg_fill.offset_top = inset_t
		bg_fill.offset_right = -inset_r
		bg_fill.offset_bottom = -inset_b
		bg_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_fill.color = _FRAME_FILL
		root.add_child(bg_fill)

	var content_wrap := MarginContainer.new()
	content_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_wrap.add_child(vbox)
	root.add_child(content_wrap)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(_on_card_pressed.bind(upgrade))
	root.add_child(btn)

	## Long-press: tooltip with name + full description
	var tip_t := Timer.new()
	tip_t.one_shot = true
	tip_t.wait_time = 0.55
	tip_t.process_mode = Node.PROCESS_MODE_ALWAYS
	card.add_child(tip_t)
	var finger_down: bool = false
	btn.button_down.connect(func() -> void:
		finger_down = true
		tip_t.start()
	)
	btn.button_up.connect(func() -> void:
		finger_down = false
		tip_t.stop()
	)
	tip_t.timeout.connect(func() -> void:
		if not finger_down:
			return
		var d: AcceptDialog = AcceptDialog.new()
		d.process_mode = Node.PROCESS_MODE_ALWAYS
		d.title = str(upgrade.get("name", "Upgrade"))
		d.dialog_text = str(upgrade.get("desc", ""))
		d.ok_button_text = "OK"
		add_child(d)
		d.confirmed.connect(d.queue_free)
		d.popup_centered()
	)

	card.add_child(root)

	return card


func _on_card_pressed(upgrade: Dictionary) -> void:
	visible = false
	get_tree().paused = false
	upgrade_chosen.emit(upgrade)
	selection_closed.emit()


func _on_reroll() -> void:
	if UpgradeManager.use_reroll():
		var new_choices := UpgradeManager.roll_level_up_choices()
		_current_choices = new_choices
		_update_reroll_display(UpgradeManager.rerolls_remaining)
		_build_cards(new_choices)


func _update_reroll_display(rerolls: int) -> void:
	reroll_btn.visible = rerolls > 0
	reroll_count.text = "x%d" % rerolls
	reroll_count.visible = rerolls > 0
