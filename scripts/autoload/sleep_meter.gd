extends Node

## The central mechanic — tracks how close the player is to waking up.
## 0.0 = deep sleep (strongest), 1.0 = fully awake (game over).
## Autoload singleton — access via SleepMeter anywhere.

signal meter_changed(value: float)
signal zone_changed(new_zone: DepthZone)
signal game_over
signal snooze_activated
signal meter_locked(duration: float)

enum DepthZone { DEEP, LIGHT, RESTLESS, CRITICAL }

# --- Core state ---

var current_value: float = 0.0  # 0.0 = deep sleep, 1.0 = awake
var current_zone: DepthZone = DepthZone.DEEP

# --- Regen ---

var base_regen_rate: float = 0.002  # ~1% per 5 seconds
var regen_multiplier: float = 1.0
const REGEN_DELAY_AFTER_HIT: float = 2.0
var _regen_delay_timer: float = 0.0

# --- Damage ---

var damage_reduction: float = 0.0  # 0.0 to 0.8 max

# --- Lock (from caffeine enemies) ---

var is_locked: bool = false
var _lock_timer: float = 0.0

# --- Snooze button ---

var snooze_charges: int = 0
var max_snooze_charges: int = 1
const SNOOZE_FREEZE_DURATION: float = 8.0
const SNOOZE_COOLDOWN: float = 180.0
var _snooze_cooldown_timer: float = 0.0
var is_snooze_frozen: bool = false
var _snooze_freeze_timer: float = 0.0
var _game_over_emitted: bool = false

# --- Zone thresholds ---

const ZONE_THRESHOLDS: Dictionary = {
	DepthZone.DEEP: 0.0,
	DepthZone.LIGHT: 0.25,
	DepthZone.RESTLESS: 0.50,
	DepthZone.CRITICAL: 0.75,
}

# --- Zone gameplay modifiers ---

const ZONE_DAMAGE_MULTIPLIER: Dictionary = {
	DepthZone.DEEP: 1.3,
	DepthZone.LIGHT: 1.0,
	DepthZone.RESTLESS: 0.85,
	DepthZone.CRITICAL: 0.7,
}

const ZONE_AOE_MULTIPLIER: Dictionary = {
	DepthZone.DEEP: 1.2,
	DepthZone.LIGHT: 1.0,
	DepthZone.RESTLESS: 1.0,
	DepthZone.CRITICAL: 1.0,
}

const ZONE_ENEMY_SPEED_MULTIPLIER: Dictionary = {
	DepthZone.DEEP: 1.0,
	DepthZone.LIGHT: 1.0,
	DepthZone.RESTLESS: 1.1,
	DepthZone.CRITICAL: 1.0,
}

const ZONE_PICKUP_RADIUS_MULTIPLIER: Dictionary = {
	DepthZone.DEEP: 1.0,
	DepthZone.LIGHT: 1.0,
	DepthZone.RESTLESS: 1.0,
	DepthZone.CRITICAL: 2.0,  # Comeback mechanic
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return

	_update_lock(delta)
	_update_snooze(delta)
	_update_regen(delta)
	_update_zone()


# --- Public API ---

func reset() -> void:
	current_value = 0.0
	current_zone = DepthZone.DEEP
	is_locked = false
	_lock_timer = 0.0
	is_snooze_frozen = false
	_snooze_freeze_timer = 0.0
	_snooze_cooldown_timer = 0.0
	_regen_delay_timer = 0.0
	damage_reduction = 0.0
	regen_multiplier = 1.0
	snooze_charges = 0
	max_snooze_charges = 1
	_game_over_emitted = false
	meter_changed.emit(current_value)
	zone_changed.emit(current_zone)


func add_meter(amount: float) -> void:
	if is_snooze_frozen:
		return

	var reduced := amount * (1.0 - clampf(damage_reduction, 0.0, 0.8))
	current_value = clampf(current_value + reduced, 0.0, 1.0)
	_regen_delay_timer = REGEN_DELAY_AFTER_HIT
	meter_changed.emit(current_value)

	if current_value >= 1.0 and not _game_over_emitted:
		_game_over_emitted = true
		game_over.emit()


func reduce_meter(amount: float) -> void:
	if is_locked:
		return
	current_value = clampf(current_value - amount, 0.0, 1.0)
	meter_changed.emit(current_value)


func lock_meter(duration: float) -> void:
	is_locked = true
	_lock_timer = duration
	meter_locked.emit(duration)


func activate_snooze() -> bool:
	if snooze_charges <= 0 or is_snooze_frozen:
		return false
	if _snooze_cooldown_timer > 0.0:
		return false

	snooze_charges -= 1
	is_snooze_frozen = true
	_snooze_freeze_timer = SNOOZE_FREEZE_DURATION
	_snooze_cooldown_timer = SNOOZE_COOLDOWN
	snooze_activated.emit()
	return true


func get_damage_multiplier() -> float:
	return ZONE_DAMAGE_MULTIPLIER.get(current_zone, 1.0)


func get_aoe_multiplier() -> float:
	return ZONE_AOE_MULTIPLIER.get(current_zone, 1.0)


func get_enemy_speed_multiplier() -> float:
	return ZONE_ENEMY_SPEED_MULTIPLIER.get(current_zone, 1.0)


func get_pickup_radius_multiplier() -> float:
	return ZONE_PICKUP_RADIUS_MULTIPLIER.get(current_zone, 1.0)


func get_zone_ratio() -> float:
	return current_value


func is_deep_sleep() -> bool:
	return current_zone == DepthZone.DEEP


func is_critical() -> bool:
	return current_zone == DepthZone.CRITICAL


# --- Internal ---

func _update_regen(delta: float) -> void:
	if is_snooze_frozen or is_locked:
		return

	if _regen_delay_timer > 0.0:
		_regen_delay_timer -= delta
		return

	if current_value > 0.0:
		var rate: float = base_regen_rate * regen_multiplier
		current_value = clampf(current_value - rate * delta, 0.0, 1.0)
		meter_changed.emit(current_value)


func _update_lock(delta: float) -> void:
	if is_locked:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			is_locked = false


func _update_snooze(delta: float) -> void:
	if is_snooze_frozen:
		_snooze_freeze_timer -= delta
		if _snooze_freeze_timer <= 0.0:
			is_snooze_frozen = false

	if _snooze_cooldown_timer > 0.0:
		_snooze_cooldown_timer -= delta


func _update_zone() -> void:
	var new_zone := DepthZone.DEEP
	if current_value >= ZONE_THRESHOLDS[DepthZone.CRITICAL]:
		new_zone = DepthZone.CRITICAL
	elif current_value >= ZONE_THRESHOLDS[DepthZone.RESTLESS]:
		new_zone = DepthZone.RESTLESS
	elif current_value >= ZONE_THRESHOLDS[DepthZone.LIGHT]:
		new_zone = DepthZone.LIGHT

	if new_zone != current_zone:
		current_zone = new_zone
		zone_changed.emit(current_zone)
		AudioManager.update_music_for_depth_zone(current_zone)
