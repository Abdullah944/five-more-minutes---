extends Node

## Manages run state, wave logic, difficulty scaling, and Night progression.
## Autoload singleton — access via GameManager anywhere.

signal run_started
signal run_ended(stats: Dictionary)
signal night_changed(night: int)
signal wave_spawned(wave_number: int)
signal breathing_room_started
signal breathing_room_ended
@warning_ignore("unused_signal")
signal level_up_triggered(level: int)

# --- Run state ---

enum RunState { IDLE, PLAYING, PAUSED, GAME_OVER }
enum Night { LIGHT_SLEEP = 1, DEEP_SLEEP = 2, REM_PHASE = 3, LUCID_DREAM = 4, THE_ALARM = 5 }

var run_state: RunState = RunState.IDLE
var current_night: Night = Night.LIGHT_SLEEP
var elapsed_time: float = 0.0
var wave_number: int = 0
var enemies_defeated: int = 0
var bosses_defeated: int = 0
var is_breathing_room: bool = false

# --- Debug / local tester (no effect in release exports) ---

var tester_invulnerable: bool = false
var tester_mega_damage: bool = false

const _TESTER_DAMAGE_MULT: float = 35.0

# --- Threat budget spawning ---

var threat_budget: float = 0.0
var threat_accumulator: float = 0.0
const SPAWN_TICK_INTERVAL: float = 0.5
var spawn_tick_timer: float = 0.0

# --- Breathing room ---

const BREATHING_ROOM_INTERVAL: float = 90.0
const BREATHING_ROOM_DURATION: float = 4.0
var breathing_room_timer: float = 0.0
var breathing_room_cooldown: float = 0.0

# --- Night thresholds (seconds) ---

const NIGHT_THRESHOLDS: Dictionary = {
	Night.LIGHT_SLEEP: 0.0,
	Night.DEEP_SLEEP: 180.0,   # 3:00
	Night.REM_PHASE: 360.0,    # 6:00
	Night.LUCID_DREAM: 600.0,  # 10:00
	Night.THE_ALARM: 900.0,    # 15:00
}

# --- Threat budget per second by time bracket ---

const THREAT_CURVE: Array[Dictionary] = [
	{ "time": 0.0,   "budget_per_sec": 2.0 },
	{ "time": 60.0,  "budget_per_sec": 4.0 },
	{ "time": 180.0, "budget_per_sec": 7.0 },
	{ "time": 300.0, "budget_per_sec": 12.0 },
	{ "time": 480.0, "budget_per_sec": 20.0 },
	{ "time": 720.0, "budget_per_sec": 30.0 },
	{ "time": 900.0, "budget_per_sec": 32.0 },  # 30 + 2/min scaling starts here
]

# --- Night modifiers ---

enum NightModifier { NONE, THUNDERSTORM, SLEEPWALKING, NIGHTMARE_BLEED, COUNTING_SHEEP, FULL_MOON }

var active_modifiers: Array[NightModifier] = []

# --- Player stats (aggregated from meta + in-run upgrades) ---

var player_stats: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_stats()


func _process(delta: float) -> void:
	if run_state != RunState.PLAYING:
		return

	elapsed_time += delta
	_update_night()
	_update_breathing_room(delta)


func start_run() -> void:
	run_state = RunState.PLAYING
	elapsed_time = 0.0
	wave_number = 0
	enemies_defeated = 0
	bosses_defeated = 0
	current_night = Night.LIGHT_SLEEP
	threat_budget = 0.0
	threat_accumulator = 0.0
	spawn_tick_timer = 0.0
	breathing_room_timer = 0.0
	breathing_room_cooldown = 0.0
	is_breathing_room = false
	active_modifiers.clear()
	_reset_stats()
	run_started.emit()


func end_run() -> void:
	run_state = RunState.GAME_OVER
	var stats := {
		"elapsed_time": elapsed_time,
		"enemies_defeated": enemies_defeated,
		"bosses_defeated": bosses_defeated,
		"night_reached": current_night,
		"wave_number": wave_number,
	}
	run_ended.emit(stats)


func pause_run() -> void:
	if run_state == RunState.PLAYING:
		run_state = RunState.PAUSED


func resume_run() -> void:
	if run_state == RunState.PAUSED:
		run_state = RunState.PLAYING


func register_enemy_defeated() -> void:
	enemies_defeated += 1


func register_boss_defeated() -> void:
	bosses_defeated += 1


func is_tester_hud_enabled() -> bool:
	# Re-enable for local QA: `return OS.is_debug_build()`
	# (DEV row: "No sleep dmg" / "Strong hits" — off while validating real difficulty for deploy.)
	# return OS.is_debug_build()
	return false


func is_tester_invulnerable() -> bool:
	# Re-enable for local QA: `return OS.is_debug_build() and tester_invulnerable`
	# return OS.is_debug_build() and tester_invulnerable
	return false


func get_tester_outgoing_damage_multiplier() -> float:
	if not OS.is_debug_build() or not tester_mega_damage:
		return 1.0
	return _TESTER_DAMAGE_MULT


func get_current_threat_rate() -> float:
	var rate := THREAT_CURVE[0]["budget_per_sec"] as float
	for entry in THREAT_CURVE:
		if elapsed_time >= entry["time"]:
			rate = entry["budget_per_sec"] as float
		else:
			break
	# After 15 min, add +2 per minute of extra time
	if elapsed_time > 900.0:
		rate += ((elapsed_time - 900.0) / 60.0) * 2.0
	return rate


# --- Internal ---

func _update_night() -> void:
	var new_night := current_night
	for night_key: Night in NIGHT_THRESHOLDS:
		if elapsed_time >= NIGHT_THRESHOLDS[night_key]:
			new_night = night_key
	if new_night != current_night:
		current_night = new_night
		night_changed.emit(current_night)
		if current_night == Night.REM_PHASE:
			_roll_night_modifiers()


func _roll_night_modifiers() -> void:
	var pool: Array[NightModifier] = [
		NightModifier.THUNDERSTORM,
		NightModifier.SLEEPWALKING,
		NightModifier.NIGHTMARE_BLEED,
		NightModifier.COUNTING_SHEEP,
		NightModifier.FULL_MOON,
	]
	pool.shuffle()
	var count := randi_range(1, 2)
	active_modifiers = pool.slice(0, count)


func _update_breathing_room(delta: float) -> void:
	if is_breathing_room:
		breathing_room_cooldown -= delta
		if breathing_room_cooldown <= 0.0:
			is_breathing_room = false
			breathing_room_ended.emit()
		return

	breathing_room_timer += delta
	if breathing_room_timer >= BREATHING_ROOM_INTERVAL:
		breathing_room_timer = 0.0
		is_breathing_room = true
		breathing_room_cooldown = BREATHING_ROOM_DURATION
		breathing_room_started.emit()


func _accumulate_threat(delta: float) -> void:
	threat_accumulator += get_current_threat_rate() * delta


func _process_spawn_tick(delta: float) -> void:
	spawn_tick_timer += delta
	if spawn_tick_timer >= SPAWN_TICK_INTERVAL:
		spawn_tick_timer -= SPAWN_TICK_INTERVAL
		threat_budget += threat_accumulator
		threat_accumulator = 0.0
		if threat_budget > 0.0:
			wave_number += 1
			wave_spawned.emit(wave_number)


func _reset_stats() -> void:
	player_stats = {
		"max_sleep_buffer": 1.0,
		"base_damage": 1.0,
		"damage_reduction": 0.0,
		"pickup_radius": 80.0,
		"xp_multiplier": 1.0,
		"regen_rate": 0.002,
		"move_speed": 200.0,
		"rerolls": 0,
		"aoe_bonus": 1.0,
		"deep_sleep_damage": 1.0,
		"shield_charges": 0.0,
		"enemy_slow_aura": 0.0,
		"low_meter_regen": 1.0,
		"cooldown_reduction": 0.0,
		"dream_milk_drop_chance": 0.0,
		"paralysis_evolution": 0.0,
	}
