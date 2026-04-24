extends Control

## Title screen with Play and Store buttons, plus Dream Shards display.

@onready var play_btn: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var store_btn: Button = $CenterContainer/VBoxContainer/StoreButton
@onready var music_label: Label = $AudioToggles/MusicLabel
@onready var music_toggle: Button = $AudioToggles/MusicToggle
@onready var sfx_label: Label = $AudioToggles/SfxLabel
@onready var sfx_toggle: Button = $AudioToggles/SfxToggle
@onready var shards_display: Label = $ShardsDisplay
@onready var store_screen: Control = $StoreScreen
@onready var credit_label: Label = $CreditLabel
@onready var cloud_tex: TextureRect = get_node_or_null("CloudsBG/CloudTex") as TextureRect

var _pulse_tween: Tween
const CLOUD_SCROLL_SPEED: float = 18.0


func _ready() -> void:
	play_btn.pressed.connect(_go_to_game)
	store_btn.pressed.connect(_open_store)
	store_screen.closed.connect(_close_store)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm and not sm.settings_changed.is_connected(_sync_audio_toggles):
		sm.settings_changed.connect(_sync_audio_toggles)

	MetaProgression.shards_changed.connect(func(_t: int) -> void: _update_shards())
	_update_shards()
	AudioManager.play_bgm("menu", -8.0)

	get_viewport().size_changed.connect(_apply_root_safe_area)
	_apply_root_safe_area()

	# Optional palette-applied colors at runtime
	shards_display.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	credit_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	music_label.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	sfx_label.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	_sync_audio_toggles()

	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.8)
	await fade_in.finished
	_start_play_pulse()


func _apply_root_safe_area() -> void:
	var e: Vector4i = SafeAreaUtil.compute_extra_margins_for_node(self)
	offset_left = e.x
	offset_top = e.y
	offset_right = -e.z
	offset_bottom = -e.w


func _process(delta: float) -> void:
	if cloud_tex:
		cloud_tex.position.x -= CLOUD_SCROLL_SPEED * delta
		if cloud_tex.position.x < -cloud_tex.size.x * 0.35:
			cloud_tex.position.x = 0.0


func _update_shards() -> void:
	shards_display.text = "%d Shards" % MetaProgression.dream_shards


func _sync_audio_toggles() -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var music_on: bool = bool(sm.get("music_enabled"))
	var sfx_on: bool = bool(sm.get("sfx_enabled"))
	music_toggle.set_pressed_no_signal(music_on)
	sfx_toggle.set_pressed_no_signal(sfx_on)
	_apply_audio_toggle_look(music_toggle, music_on)
	_apply_audio_toggle_look(sfx_toggle, sfx_on)


func _apply_audio_toggle_look(btn: Button, on: bool) -> void:
	btn.text = "ON" if on else "OFF"
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD if on else UIPalette.TEXT_MUTED)
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.content_margin_left = 20.0
	normal.content_margin_right = 20.0
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
	normal.bg_color = UIPalette.DREAM_VIOLET.lightened(0.06) if on else UIPalette.SURFACE
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.07)
	var pressed_s := hover.duplicate() as StyleBoxFlat
	pressed_s.bg_color = normal.bg_color.darkened(0.04)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed_s)


func _on_music_toggled(pressed: bool) -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_music_enabled(pressed)
	_apply_audio_toggle_look(music_toggle, pressed)
	AudioManager.play_ui_by_name("button_tap", -4.0)


func _on_sfx_toggled(pressed: bool) -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set_sfx_enabled(pressed)
	_apply_audio_toggle_look(sfx_toggle, pressed)
	if pressed:
		AudioManager.play_ui_by_name("button_tap", -4.0)


func _go_to_game() -> void:
	AudioManager.play_ui_by_name("button_tap")
	play_btn.disabled = true
	store_btn.disabled = true
	music_toggle.disabled = true
	sfx_toggle.disabled = true
	if _pulse_tween:
		_pulse_tween.kill()

	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.4)
	await fade_out.finished
	get_tree().change_scene_to_file("res://scenes/main/bedroom_hub.tscn")


func _open_store() -> void:
	AudioManager.play_ui_by_name("menu_open")
	if _pulse_tween:
		_pulse_tween.kill()
	store_screen.show_store()


func _close_store() -> void:
	_update_shards()
	_start_play_pulse()


func _start_play_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(play_btn, "modulate:a", 0.6, 1.0)
	_pulse_tween.tween_property(play_btn, "modulate:a", 1.0, 1.0)
