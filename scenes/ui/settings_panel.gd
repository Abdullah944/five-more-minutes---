extends Control

## Settings panel — battery saver, haptics, accessibility options.

signal closed

@onready var back_btn: Button = $Panel/Layout/TopBar/BackButton
@onready var item_list: VBoxContainer = $Panel/Layout/Scroll/ItemList
@onready var panel: PanelContainer = $Panel
@onready var _settings: Node = get_node_or_null("/root/SettingsManager")


func _ready() -> void:
	visible = false
	back_btn.pressed.connect(func() -> void: visible = false; closed.emit())


func show_panel() -> void:
	visible = true
	_build_settings()
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _build_settings() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if not _settings:
		return

	_add_toggle(
		"Battery Saver",
		"Limits to 30 FPS to save battery",
		_settings.battery_saver,
		func(v: bool) -> void: _settings.set_battery_saver(v)
	)

	_add_toggle(
		"Music",
		"Background music",
		_settings.music_enabled,
		func(v: bool) -> void: _settings.set_music_enabled(v)
	)

	_add_toggle(
		"Sound effects",
		"Gameplay and UI sounds",
		_settings.sfx_enabled,
		func(v: bool) -> void: _settings.set_sfx_enabled(v)
	)

	_add_toggle(
		"Haptics",
		"Vibration feedback on events",
		_settings.haptics_enabled,
		func(v: bool) -> void: _settings.set_haptics(v)
	)

	_add_toggle(
		"Reduced Motion",
		"Minimize animations and screen shake",
		_settings.reduced_motion,
		func(v: bool) -> void: _settings.set_reduced_motion(v)
	)

	_add_toggle(
		"Colorblind Mode",
		"Add shapes to color-coded elements",
		_settings.colorblind_mode,
		func(v: bool) -> void: _settings.set_colorblind_mode(v)
	)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	item_list.add_child(spacer)

	var danger_card := _create_card()
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = "Delete Save Data"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", UIPalette.DANGER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var del_btn := Button.new()
	del_btn.text = "Delete"
	del_btn.add_theme_font_size_override("font_size", 20)
	del_btn.add_theme_color_override("font_color", UIPalette.DANGER)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = UIPalette.SURFACE_HOVER
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.content_margin_left = 20.0
	btn_style.content_margin_right = 20.0
	btn_style.content_margin_top = 10.0
	btn_style.content_margin_bottom = 10.0
	del_btn.add_theme_stylebox_override("normal", btn_style)
	del_btn.add_theme_stylebox_override("hover", btn_style)
	del_btn.add_theme_stylebox_override("pressed", btn_style)
	del_btn.pressed.connect(func() -> void:
		SaveManager.delete_save()
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
	)
	hbox.add_child(del_btn)

	danger_card.add_child(hbox)
	item_list.add_child(danger_card)


func _add_toggle(title: String, desc: String, current: bool, callback: Callable) -> void:
	var card := _create_card()
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	left.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	left.add_child(desc_label)

	hbox.add_child(left)

	# CheckButton draws a tiny theme “switch” inside a large min-size box — looks like a huge card and a speck.
	# Toggle-mode Button: the whole pill is the control, with large ON/OFF text.
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.button_pressed = current
	toggle.custom_minimum_size = Vector2(188, 84)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.focus_mode = Control.FOCUS_NONE
	_apply_toggle_button_look(toggle, current)
	toggle.toggled.connect(func(pressed: bool) -> void:
		_apply_toggle_button_look(toggle, pressed)
		callback.call(pressed)
	)
	hbox.add_child(toggle)

	card.add_child(hbox)
	item_list.add_child(card)


func _create_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 26.0
	style.content_margin_right = 22.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	card.add_theme_stylebox_override("panel", style)

	return card


func _apply_toggle_button_look(btn: Button, on: bool) -> void:
	btn.text = "ON" if on else "OFF"
	btn.add_theme_font_size_override("font_size", 30)
	btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD if on else UIPalette.TEXT_MUTED)
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_right = 16
	normal.corner_radius_bottom_left = 16
	normal.content_margin_left = 32.0
	normal.content_margin_right = 32.0
	normal.content_margin_top = 22.0
	normal.content_margin_bottom = 22.0
	normal.bg_color = UIPalette.DREAM_VIOLET.lightened(0.06) if on else UIPalette.SURFACE
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.07)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.04)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
