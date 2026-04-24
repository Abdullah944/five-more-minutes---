extends Node

## Manages game settings: battery saver, haptics, accessibility.
## Autoload singleton — access via SettingsManager anywhere.

signal settings_changed

# --- Display ---
var battery_saver: bool = false
var reduced_motion: bool = false
var text_scale: float = 1.0

# --- Controls ---
var haptics_enabled: bool = true

# --- Accessibility ---
var colorblind_mode: bool = false

# --- Audio (bus mutes via AudioManager) ---
var music_enabled: bool = true
var sfx_enabled: bool = true

const SETTINGS_PATH := "user://settings.cfg"


func _ready() -> void:
	_load_settings()
	_apply_fps()


func set_battery_saver(enabled: bool) -> void:
	battery_saver = enabled
	_apply_fps()
	_save_settings()
	settings_changed.emit()


func set_haptics(enabled: bool) -> void:
	haptics_enabled = enabled
	_save_settings()
	settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_save_settings()
	settings_changed.emit()


func set_text_scale(scale: float) -> void:
	text_scale = clampf(scale, 0.8, 1.5)
	_save_settings()
	settings_changed.emit()


func set_colorblind_mode(enabled: bool) -> void:
	colorblind_mode = enabled
	_save_settings()
	settings_changed.emit()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_save_settings()
	settings_changed.emit()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	_save_settings()
	settings_changed.emit()


func _apply_fps() -> void:
	Engine.max_fps = 30 if battery_saver else 60


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "battery_saver", battery_saver)
	config.set_value("display", "reduced_motion", reduced_motion)
	config.set_value("display", "text_scale", text_scale)
	config.set_value("controls", "haptics", haptics_enabled)
	config.set_value("accessibility", "colorblind", colorblind_mode)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.save(SETTINGS_PATH)


## Short vibrate (mobile) when haptics are enabled. No-op on desktop.
func play_haptic_ms(duration_ms: int = 45) -> void:
	if not haptics_enabled:
		return
	Input.vibrate_handheld(duration_ms)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	battery_saver = config.get_value("display", "battery_saver", false)
	reduced_motion = config.get_value("display", "reduced_motion", false)
	text_scale = config.get_value("display", "text_scale", 1.0)
	haptics_enabled = config.get_value("controls", "haptics", true)
	colorblind_mode = config.get_value("accessibility", "colorblind", false)
	music_enabled = config.get_value("audio", "music_enabled", true)
	sfx_enabled = config.get_value("audio", "sfx_enabled", true)
