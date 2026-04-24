extends Node

## Manages dynamic music layering, SFX pooling, and audio bus control.
## Autoload singleton — access via AudioManager anywhere.
##
## Music layers by Sleep Meter depth zone:
##   DEEP    -> minimal piano
##   LIGHT   -> + soft drums
##   RESTLESS -> + faster tempo, bass
##   CRITICAL -> + heartbeat, clock tick overlay

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"

const SFX_POOL_SIZE := 16

# --- Audio layers ---

enum MusicLayer { BASE, DRUMS, BASS, TENSION }

var music_players: Dictionary = {}  # MusicLayer -> AudioStreamPlayer
var target_volumes: Dictionary = {} # MusicLayer -> float (linear)
var current_volumes: Dictionary = {} # MusicLayer -> float (linear)

const VOLUME_FADE_SPEED := 2.0  # Linear units per second

# --- SFX pool ---

var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_index: int = 0

# --- UI sound player ---

var ui_player: AudioStreamPlayer

# --- BGM player ---

var bgm_player: AudioStreamPlayer
var _current_bgm_key: String = ""

# --- Preloaded SFX ---

var sfx_cache: Dictionary = {}

const SFX_PATHS: Dictionary = {
	"button_tap":      "res://audio/sfx/ui_button_tap.mp3",
	"purchase":        "res://audio/sfx/ui_purchase.mp3",
	"level_up":        "res://audio/sfx/ui_level_up.mp3",
	"menu_open":       "res://audio/sfx/ui_menu_open.mp3",
	"menu_close":      "res://audio/sfx/ui_menu_close.mp3",
	"pillow_toss":     "res://audio/sfx/combat_pillow_toss.mp3",
	"snore_wave":      "res://audio/sfx/combat_snore_wave.mp3",
	"dream_beam":      "res://audio/sfx/combat_dream_beam.mp3",
	"enemy_hit":       "res://audio/sfx/combat_enemy_hit.mp3",
	"enemy_death":     "res://audio/sfx/combat_enemy_death.mp3",
	"pickup_xp":       "res://audio/sfx/pickup_xp_gem.mp3",
	"pickup_milk":     "res://audio/sfx/pickup_warm_milk.mp3",
	"meter_critical":  "res://audio/sfx/meter_critical.mp3",
	"game_over":       "res://audio/sfx/game_over_sting.mp3",
	"wave_start":      "res://audio/sfx/wave_start.mp3",
}

const BGM_PATHS: Dictionary = {
	"menu":     "res://audio/music/menu_theme.mp3",
	"gameplay": "res://audio/music/gameplay_theme.mp3",
	"boss":     "res://audio/music/boss_theme.mp3",
}

## Pillow / beam / hits / enemy defeat — skip when run is not PLAYING (intro idle, pause, after death).
const COMBAT_ATTACK_SFX_NAMES: Array[String] = [
	"pillow_toss",
	"snore_wave",
	"dream_beam",
	"enemy_hit",
	"enemy_death",
]


func _ready() -> void:
	_setup_buses()
	_create_sfx_pool()
	_create_ui_player()
	_create_music_players()
	_create_bgm_player()
	_preload_sfx()
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm and not sm.settings_changed.is_connected(_sync_audio_buses):
		sm.settings_changed.connect(_sync_audio_buses)
	call_deferred("_sync_audio_buses")


func _process(delta: float) -> void:
	_fade_music_layers(delta)


# --- Public API ---

func _sync_audio_buses() -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var music_on: bool = bool(sm.get("music_enabled"))
	var sfx_on: bool = bool(sm.get("sfx_enabled"))
	set_bus_mute(MUSIC_BUS, not music_on)
	set_bus_mute(SFX_BUS, not sfx_on)
	set_bus_mute(UI_BUS, not sfx_on)


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var player := sfx_pool[sfx_pool_index]
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	sfx_pool_index = (sfx_pool_index + 1) % SFX_POOL_SIZE


func play_ui_sound(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	ui_player.stream = stream
	ui_player.volume_db = volume_db
	ui_player.play()


func set_music_layer_target(layer: MusicLayer, volume_linear: float) -> void:
	target_volumes[layer] = clampf(volume_linear, 0.0, 1.0)


func update_music_for_depth_zone(zone: int) -> void:
	# zone values: 0=DEEP, 1=LIGHT, 2=RESTLESS, 3=CRITICAL
	match zone:
		0: # Deep Sleep - minimal
			set_music_layer_target(MusicLayer.BASE, 1.0)
			set_music_layer_target(MusicLayer.DRUMS, 0.0)
			set_music_layer_target(MusicLayer.BASS, 0.0)
			set_music_layer_target(MusicLayer.TENSION, 0.0)
		1: # Light Sleep - add drums
			set_music_layer_target(MusicLayer.BASE, 1.0)
			set_music_layer_target(MusicLayer.DRUMS, 0.6)
			set_music_layer_target(MusicLayer.BASS, 0.0)
			set_music_layer_target(MusicLayer.TENSION, 0.0)
		2: # Restless - add bass
			set_music_layer_target(MusicLayer.BASE, 1.0)
			set_music_layer_target(MusicLayer.DRUMS, 0.8)
			set_music_layer_target(MusicLayer.BASS, 0.7)
			set_music_layer_target(MusicLayer.TENSION, 0.0)
		3: # Critical - full tension
			set_music_layer_target(MusicLayer.BASE, 1.0)
			set_music_layer_target(MusicLayer.DRUMS, 1.0)
			set_music_layer_target(MusicLayer.BASS, 1.0)
			set_music_layer_target(MusicLayer.TENSION, 1.0)


func play_sfx_by_name(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if _suppress_combat_attack_sfx(sfx_name):
		return
	var stream: AudioStream = sfx_cache.get(sfx_name)
	if stream:
		play_sfx(stream, volume_db, pitch)


func _suppress_combat_attack_sfx(sfx_name: String) -> bool:
	if not sfx_name in COMBAT_ATTACK_SFX_NAMES:
		return false
	return GameManager.run_state != GameManager.RunState.PLAYING


func play_ui_by_name(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = sfx_cache.get(sfx_name)
	if stream:
		play_ui_sound(stream, volume_db)


func play_bgm(track_key: String, volume_db: float = -6.0) -> void:
	if track_key == _current_bgm_key and bgm_player.playing:
		return
	_current_bgm_key = track_key
	var path: String = BGM_PATHS.get(track_key, "")
	if path == "":
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	bgm_player.play()


func stop_bgm(fade_time: float = 0.5) -> void:
	if not bgm_player.playing:
		return
	_current_bgm_key = ""
	if fade_time <= 0.0:
		bgm_player.stop()
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_time)
	tween.tween_callback(bgm_player.stop)


func stop_all_music() -> void:
	for player: AudioStreamPlayer in music_players.values():
		player.stop()
	bgm_player.stop()
	_current_bgm_key = ""


func set_bus_volume(bus_name: String, volume_linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume_linear))


func set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


# --- Internal ---

func _setup_buses() -> void:
	# Ensure audio buses exist. In production these should be defined in
	# default_bus_layout.tres, but we guard against missing buses here.
	for bus_name in [MUSIC_BUS, SFX_BUS, UI_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _create_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sfx_pool.append(player)


func _create_ui_player() -> void:
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = UI_BUS
	add_child(ui_player)


func _create_music_players() -> void:
	for layer: MusicLayer in MusicLayer.values():
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		player.volume_db = linear_to_db(0.0)
		add_child(player)
		music_players[layer] = player
		target_volumes[layer] = 0.0
		current_volumes[layer] = 0.0


func _create_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = MUSIC_BUS
	bgm_player.finished.connect(func() -> void:
		if _current_bgm_key != "":
			bgm_player.play()
	)
	add_child(bgm_player)


func _preload_sfx() -> void:
	for key: String in SFX_PATHS:
		var stream: AudioStream = load(SFX_PATHS[key])
		if stream:
			sfx_cache[key] = stream


func _fade_music_layers(delta: float) -> void:
	for layer: MusicLayer in music_players:
		var target: float = target_volumes.get(layer, 0.0)
		var current: float = current_volumes.get(layer, 0.0)
		if not is_equal_approx(current, target):
			current = move_toward(current, target, VOLUME_FADE_SPEED * delta)
			current_volumes[layer] = current
			var player: AudioStreamPlayer = music_players[layer]
			if current <= 0.001:
				player.volume_db = -80.0
			else:
				player.volume_db = linear_to_db(current)
