extends Control

## Pause menu overlay — Resume, Restart, Quit buttons.
## process_mode = ALWAYS so it works while tree is paused.

signal resume_pressed
signal restart_pressed
signal quit_pressed

@onready var panel: PanelContainer = $Overlay/Panel
@onready var music_toggle: CheckButton = $Overlay/Panel/VBox/AudioRow/MusicToggle
@onready var sfx_toggle: CheckButton = $Overlay/Panel/VBox/AudioRow/SFXToggle
@onready var resume_btn: Button = $Overlay/Panel/VBox/ResumeButton
@onready var restart_btn: Button = $Overlay/Panel/VBox/RestartButton
@onready var quit_btn: Button = $Overlay/Panel/VBox/QuitButton
@onready var _settings: Node = get_node_or_null("/root/SettingsManager")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	quit_btn.pressed.connect(_on_quit)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	if _settings and not _settings.settings_changed.is_connected(_refresh_audio_toggles):
		_settings.settings_changed.connect(_refresh_audio_toggles)


func show_pause() -> void:
	visible = true
	get_tree().paused = true
	_refresh_audio_toggles()
	# Slide in animation
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)


func hide_pause() -> void:
	get_tree().paused = false
	visible = false


func _on_resume() -> void:
	hide_pause()
	resume_pressed.emit()


func _on_restart() -> void:
	hide_pause()
	restart_pressed.emit()


func _on_quit() -> void:
	hide_pause()
	quit_pressed.emit()


func _refresh_audio_toggles() -> void:
	if _settings == null:
		return
	music_toggle.set_block_signals(true)
	sfx_toggle.set_block_signals(true)
	music_toggle.button_pressed = bool(_settings.music_enabled)
	sfx_toggle.button_pressed = bool(_settings.sfx_enabled)
	music_toggle.set_block_signals(false)
	sfx_toggle.set_block_signals(false)


func _on_music_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_music_enabled(pressed)


func _on_sfx_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_sfx_enabled(pressed)
