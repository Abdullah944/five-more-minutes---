extends CanvasLayer

## In-game HUD: Sleep Meter, XP bar, wave counter, timer, ability icons.

signal pause_requested

@onready var sleep_meter_bar: ProgressBar = $SafeArea/Layout/TopSection/TopRow/LeftHUD/SleepMeterBar
@onready var sleep_meter_fill: ColorRect = $SafeArea/Layout/TopSection/TopRow/LeftHUD/SleepMeterBar/Fill
@onready var moon_icon: TextureRect = $SafeArea/Layout/TopSection/TopRow/LeftHUD/SleepMeterBar/MoonIcon
@onready var wave_panel: PanelContainer = $SafeArea/Layout/TopSection/TopRow/LeftHUD/WavePanel
@onready var xp_bar: ProgressBar = $SafeArea/Layout/TopSection/TopRow/LeftHUD/XPStrip/XPBar
@onready var xp_label: Label = $SafeArea/Layout/TopSection/TopRow/LeftHUD/XPStrip/XPBar/LevelLabel
@onready var wave_badge: Label = $SafeArea/Layout/TopSection/TopRow/LeftHUD/WavePanel/WaveBadge
@onready var timer_label: Label = $SafeArea/Layout/TopSection/InfoRow/TimerLabel
@onready var ability_container: VBoxContainer = $SafeArea/Layout/MiddleSpacer/AbilityContainer
@onready var pause_button: Button = $SafeArea/Layout/TopSection/TopRow/PauseButton
@onready var snooze_button: Button = $SafeArea/Layout/MiddleSpacer/SnoozeButton
@onready var tester_row: HBoxContainer = $SafeArea/Layout/TesterRow
@onready var invulnerable_check: CheckBox = $SafeArea/Layout/TesterRow/InvulnerableCheck
@onready var mega_damage_check: CheckBox = $SafeArea/Layout/TesterRow/MegaDamageCheck
@onready var stats_corner: Label = $SafeArea/Layout/TopSection/TopRow/LeftHUD/XPStrip/StatsCorner
@onready var safe_area_root: MarginContainer = $SafeArea

var _base_margin_left: int = 0
var _base_margin_top: int = 0
var _base_margin_right: int = 0
var _base_margin_bottom: int = 0

var _pulse_tween: Tween
var _is_pulsing: bool = false
var _meter_fill_style: StyleBoxFlat
var _meter_bg_style: StyleBoxFlat
var _wave_panel_style: StyleBoxFlat
var _xp_bg_style: StyleBoxFlat
var _xp_fill_style: StyleBoxFlat

var current_xp: float = 0.0
var xp_to_next_level: float = 100.0
var current_level: int = 1


func _ready() -> void:
	SleepMeter.meter_changed.connect(_on_sleep_meter_changed)
	SleepMeter.zone_changed.connect(_on_zone_changed)
	GameManager.wave_spawned.connect(_on_wave_spawned)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	snooze_button.pressed.connect(_on_snooze_pressed)
	snooze_button.visible = false

	tester_row.visible = GameManager.is_tester_hud_enabled()
	if GameManager.is_tester_hud_enabled():
		invulnerable_check.button_pressed = GameManager.tester_invulnerable
		mega_damage_check.button_pressed = GameManager.tester_mega_damage
		invulnerable_check.toggled.connect(_on_tester_invulnerable_toggled)
		mega_damage_check.toggled.connect(_on_tester_mega_damage_toggled)

	_cache_base_safe_margins()
	get_viewport().size_changed.connect(_apply_safe_area_margins)
	_apply_safe_area_margins()

	_meter_fill_style = sleep_meter_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	sleep_meter_bar.add_theme_stylebox_override("fill", _meter_fill_style)

	_meter_bg_style = sleep_meter_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	_meter_bg_style.bg_color = UIPalette.TEXT_PRIMARY
	_meter_bg_style.border_color = Color.BLACK
	_meter_bg_style.border_width_left = 2
	_meter_bg_style.border_width_top = 2
	_meter_bg_style.border_width_right = 2
	_meter_bg_style.border_width_bottom = 2
	_meter_bg_style.corner_radius_top_left = 16
	_meter_bg_style.corner_radius_top_right = 16
	_meter_bg_style.corner_radius_bottom_right = 16
	_meter_bg_style.corner_radius_bottom_left = 16
	sleep_meter_bar.add_theme_stylebox_override("background", _meter_bg_style)

	_meter_fill_style.border_width_left = 0
	_meter_fill_style.border_width_top = 0
	_meter_fill_style.border_width_right = 0
	_meter_fill_style.border_width_bottom = 0
	_meter_fill_style.corner_radius_top_left = 14
	_meter_fill_style.corner_radius_top_right = 14
	_meter_fill_style.corner_radius_bottom_right = 14
	_meter_fill_style.corner_radius_bottom_left = 14

	_wave_panel_style = wave_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_wave_panel_style.bg_color = UIPalette.SURFACE
	_wave_panel_style.border_color = Color.BLACK
	_wave_panel_style.border_width_left = 2
	_wave_panel_style.border_width_top = 2
	_wave_panel_style.border_width_right = 2
	_wave_panel_style.border_width_bottom = 2
	_wave_panel_style.corner_radius_top_left = 6
	_wave_panel_style.corner_radius_top_right = 6
	_wave_panel_style.corner_radius_bottom_right = 6
	_wave_panel_style.corner_radius_bottom_left = 6
	_wave_panel_style.content_margin_left = 10.0
	_wave_panel_style.content_margin_top = 6.0
	_wave_panel_style.content_margin_right = 10.0
	_wave_panel_style.content_margin_bottom = 6.0
	wave_panel.add_theme_stylebox_override("panel", _wave_panel_style)

	wave_badge.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)

	_setup_xp_meter_styles()
	_setup_timer_label_style()
	_setup_kills_label_readability()

	_setup_pause_button()

	_update_sleep_meter_visual(0.0)
	_update_xp_display()


func _setup_xp_meter_styles() -> void:
	if not xp_bar:
		return
	_xp_bg_style = xp_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	_xp_bg_style.bg_color = UIPalette.TEXT_PRIMARY
	_xp_bg_style.border_color = Color.BLACK
	_xp_bg_style.border_width_left = 2
	_xp_bg_style.border_width_top = 2
	_xp_bg_style.border_width_right = 2
	_xp_bg_style.border_width_bottom = 2
	_xp_bg_style.corner_radius_top_left = 8
	_xp_bg_style.corner_radius_top_right = 8
	_xp_bg_style.corner_radius_bottom_right = 8
	_xp_bg_style.corner_radius_bottom_left = 8
	xp_bar.add_theme_stylebox_override("background", _xp_bg_style)

	_xp_fill_style = xp_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	_xp_fill_style.bg_color = UIPalette.MOON_GOLD
	_xp_fill_style.border_width_left = 0
	_xp_fill_style.border_width_top = 0
	_xp_fill_style.border_width_right = 0
	_xp_fill_style.border_width_bottom = 0
	_xp_fill_style.corner_radius_top_left = 6
	_xp_fill_style.corner_radius_top_right = 6
	_xp_fill_style.corner_radius_bottom_right = 6
	_xp_fill_style.corner_radius_bottom_left = 6
	xp_bar.add_theme_stylebox_override("fill", _xp_fill_style)

	if xp_label:
		xp_label.add_theme_color_override("font_color", UIPalette.NIGHT_NAVY)


func _setup_timer_label_style() -> void:
	if not timer_label:
		return
	var pf := load("res://art/fonts/PressStart2P-Regular.ttf") as Font
	var ls := LabelSettings.new()
	ls.font = pf
	ls.font_size = 22
	ls.font_color = UIPalette.TEXT_PRIMARY
	ls.outline_size = 4
	ls.outline_color = UIPalette.NIGHT_NAVY
	timer_label.label_settings = ls


func _setup_kills_label_readability() -> void:
	if not stats_corner:
		return
	var font_f := load("res://art/fonts/PressStart2P-Regular.ttf") as Font
	var ls := LabelSettings.new()
	ls.font = font_f
	ls.font_size = 15
	ls.font_color = UIPalette.TEXT_PRIMARY
	ls.outline_size = 4
	ls.outline_color = UIPalette.NIGHT_NAVY
	stats_corner.label_settings = ls


func _setup_pause_button() -> void:
	pause_button.text = ""
	pause_button.flat = true
	pause_button.expand_icon = true
	pause_button.custom_minimum_size = Vector2(96, 96)
	pause_button.add_theme_constant_override("icon_max_width", 84)
	var pause_tex := load("res://art/ui/icon_hud_pause.png") as Texture2D
	if pause_tex:
		pause_button.icon = pause_tex
	var empty := StyleBoxEmpty.new()
	pause_button.add_theme_stylebox_override("normal", empty)
	pause_button.add_theme_stylebox_override("hover", empty)
	pause_button.add_theme_stylebox_override("pressed", empty)
	pause_button.add_theme_stylebox_override("focus", empty)


func _process(_delta: float) -> void:
	if GameManager.run_state == GameManager.RunState.PLAYING:
		_update_timer()
		_update_stats_corner()


# --- Public API ---

func add_xp(amount: float) -> void:
	var multiplier: float = GameManager.player_stats.get("xp_multiplier", 1.0)
	current_xp += amount * multiplier
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level = _calculate_xp_requirement(current_level)
		GameManager.level_up_triggered.emit(current_level)
		_play_level_up_effect()
	_update_xp_display()


func reset_xp() -> void:
	current_xp = 0.0
	current_level = 1
	xp_to_next_level = _calculate_xp_requirement(1)
	_update_xp_display()


func show_snooze_button(charges: int) -> void:
	snooze_button.visible = charges > 0


func add_ability_icon(icon_texture: Texture2D) -> void:
	var tex_rect := TextureRect.new()
	tex_rect.texture = icon_texture
	tex_rect.custom_minimum_size = Vector2(32, 32)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ability_container.add_child(tex_rect)


# --- Internal ---

func _cache_base_safe_margins() -> void:
	_base_margin_left = safe_area_root.get_theme_constant("margin_left", "MarginContainer")
	_base_margin_top = safe_area_root.get_theme_constant("margin_top", "MarginContainer")
	_base_margin_right = safe_area_root.get_theme_constant("margin_right", "MarginContainer")
	_base_margin_bottom = safe_area_root.get_theme_constant("margin_bottom", "MarginContainer")


func _apply_safe_area_margins() -> void:
	var extra := _compute_safe_area_extra_margins()
	safe_area_root.add_theme_constant_override("margin_left", _base_margin_left + extra.x)
	safe_area_root.add_theme_constant_override("margin_top", _base_margin_top + extra.y)
	safe_area_root.add_theme_constant_override("margin_right", _base_margin_right + extra.z)
	safe_area_root.add_theme_constant_override("margin_bottom", _base_margin_bottom + extra.w)


## Extra insets (left, top, right, bottom) in **viewport pixels** from OS safe area vs game window.
func _compute_safe_area_extra_margins() -> Vector4i:
	return SafeAreaUtil.compute_extra_margins_for_node(self)


func _on_sleep_meter_changed(value: float) -> void:
	_update_sleep_meter_visual(value)


func _on_zone_changed(zone: SleepMeter.DepthZone) -> void:
	if zone == SleepMeter.DepthZone.CRITICAL and not _is_pulsing:
		AudioManager.play_sfx_by_name("meter_critical", -4.0)
		_start_pulse()
	elif zone != SleepMeter.DepthZone.CRITICAL and _is_pulsing:
		_stop_pulse()


func _on_wave_spawned(wave: int) -> void:
	wave_badge.text = "Wave %d" % wave
	AudioManager.play_sfx_by_name("wave_start", -6.0)
	var tween := create_tween()
	tween.tween_property(wave_badge, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(wave_badge, "scale", Vector2.ONE, 0.15)


func _on_snooze_pressed() -> void:
	SleepMeter.activate_snooze()


func _update_sleep_meter_visual(value: float) -> void:
	if sleep_meter_bar:
		sleep_meter_bar.value = value * 100.0

	if _meter_fill_style:
		var full := UIPalette.DREAM_VIOLET.lerp(UIPalette.MOON_GOLD, 0.55)
		var low := UIPalette.SURFACE.lerp(UIPalette.DANGER, 0.35)
		_meter_fill_style.bg_color = full.lerp(low, 1.0 - value)

	if moon_icon:
		# Stay readable on dark gameplay: soft moonlit white at empty, warm gold when full.
		var dim_moon: Color = UIPalette.TEXT_PRIMARY.lerp(UIPalette.MOON_GOLD, 0.22)
		moon_icon.modulate = dim_moon.lerp(UIPalette.MOON_GOLD, value)

	if sleep_meter_fill:
		sleep_meter_fill.color = Color(0, 0, 0, 0)


func _update_xp_display() -> void:
	if xp_bar:
		xp_bar.max_value = xp_to_next_level
		xp_bar.value = current_xp
	if xp_label:
		xp_label.text = "Lv %d" % current_level


func _update_timer() -> void:
	@warning_ignore("integer_division")
	var total_seconds := int(GameManager.elapsed_time)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	@warning_ignore("integer_division")
	var seconds := total_seconds % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_stats_corner() -> void:
	if stats_corner:
		stats_corner.text = "Kills: %d" % GameManager.enemies_defeated


func _calculate_xp_requirement(level: int) -> float:
	return 100.0 * pow(1.15, level - 1)


func _play_level_up_effect() -> void:
	if xp_bar:
		var tween := create_tween()
		tween.tween_property(xp_bar, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.1)
		tween.tween_property(xp_bar, "modulate", Color.WHITE, 0.3)


func _start_pulse() -> void:
	_is_pulsing = true
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(sleep_meter_bar, "modulate", Color(1.15, 0.92, 0.92, 1.0), 0.5)
	_pulse_tween.tween_property(sleep_meter_bar, "modulate", Color.WHITE, 0.5)


func _stop_pulse() -> void:
	_is_pulsing = false
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if sleep_meter_bar:
		sleep_meter_bar.modulate = Color.WHITE


func _on_tester_invulnerable_toggled(pressed: bool) -> void:
	GameManager.tester_invulnerable = pressed


func _on_tester_mega_damage_toggled(pressed: bool) -> void:
	GameManager.tester_mega_damage = pressed
