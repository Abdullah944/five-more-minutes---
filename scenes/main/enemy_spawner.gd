extends Node

## Spawns enemies in waves with increasing variety.
## Early waves: zombies only. Later waves mix in alarm clocks, pups, ghosts.

var enemy_scene: PackedScene
var xp_pickup_scene: PackedScene
var warm_milk_scene: PackedScene
const WARM_MILK_CHANCE: float = 0.03

var _enemy_textures: Dictionary = {}

var _player: Node2D
var _entities_node: Node2D
var _pickups_node: Node2D

var current_wave: int = 0
var _enemies_to_spawn: int = 0
var _enemies_alive: int = 0
var _spawn_index: int = 0
var _spawn_timer: float = 0.0
var _wave_clear: bool = false
var _wave_delay_timer: float = 0.0
var _active: bool = false

const SPAWN_MARGIN: float = 60.0
const WAVE_DELAY: float = 2.5
const SPAWN_STAGGER: float = 0.2

## Boss roster: **3** unique boss PNGs (espresso → DJ rooster → thunder), then repeats in that order forever.
## Every **15 waves** (three boss waves) the game advances one **color round** so repeats look visually distinct.
const BOSS_COUNT: int = 3
const BOSS_WAVE_INTERVAL: int = 5
## Small first-enemy adds on boss waves before the main boss spawns.
const BOSS_WAVE_SMALL_ADDS: int = 3
## Stat template for the large boss (slow silhouette reads well at scale).
const BOSS_CHASSIS: EnemyType = EnemyType.NEIGHBOR

const BOSS_TEXTURE_PATHS: PackedStringArray = [
	"res://art/sprites/boss_espresso_golem.png",
	"res://art/sprites/boss_dj_rooster.png",
	"res://art/sprites/boss_thunder_cloud.png",
]

enum EnemyType {
	ZOMBIE,
	ALARM_CLOCK,
	BARKING_PUP,
	GHOST,
	MOSQUITO,
	NEIGHBOR,
	DELIVERY_DRONE,
	MINI_BOSS_0,
	MINI_BOSS_1,
	MINI_BOSS_2,
}

const ENEMY_CONFIGS: Dictionary = {
	EnemyType.ZOMBIE: {
		"color": Color(0.55, 0.75, 0.35, 1.0),
		"size": Vector2(26, 26),
		"health": 12.0,
		"speed_min": 40.0,
		"speed_max": 60.0,
		"meter_damage": 0.03,
		"xp": 1.0,
		"move_pattern": 0,  # CHASE
		"is_ranged": false,
		"defeat_text": "zzz",
	},
	EnemyType.ALARM_CLOCK: {
		"color": Color(0.9, 0.7, 0.15, 1.0),
		"size": Vector2(22, 22),
		"health": 20.0,
		"speed_min": 50.0,
		"speed_max": 65.0,
		"meter_damage": 0.06,
		"xp": 2.0,
		"move_pattern": 0,  # CHASE
		"is_ranged": false,
		"defeat_text": "zzz",
		"locks_sleep_meter": true,
	},
	EnemyType.BARKING_PUP: {
		"color": Color(0.85, 0.55, 0.25, 1.0),
		"size": Vector2(18, 18),
		"health": 6.0,
		"speed_min": 90.0,
		"speed_max": 120.0,
		"meter_damage": 0.02,
		"xp": 0.8,
		"move_pattern": 1,  # ZIGZAG
		"is_ranged": false,
		"defeat_text": "zzz",
	},
	EnemyType.GHOST: {
		"color": Color(0.6, 0.55, 0.85, 1.0),
		"size": Vector2(24, 28),
		"health": 8.0,
		"speed_min": 35.0,
		"speed_max": 50.0,
		"meter_damage": 0.04,
		"xp": 1.5,
		"move_pattern": 3,  # PHASE
		"is_ranged": true,
		"defeat_text": "zzz",
	},
	EnemyType.MOSQUITO: {
		"color": Color(0.42, 0.62, 0.48, 1.0),
		"size": Vector2(16, 16),
		"health": 5.0,
		"speed_min": 72.0,
		"speed_max": 110.0,
		"meter_damage": 0.02,
		"xp": 0.75,
		"move_pattern": 0,
		"is_ranged": false,
		"defeat_text": "zzz",
	},
	EnemyType.NEIGHBOR: {
		"color": Color(0.72, 0.52, 0.45, 1.0),
		"size": Vector2(30, 32),
		"health": 28.0,
		"speed_min": 28.0,
		"speed_max": 44.0,
		"meter_damage": 0.055,
		"xp": 2.2,
		"move_pattern": 0,
		"is_ranged": false,
		"defeat_text": "zzz",
	},
	EnemyType.DELIVERY_DRONE: {
		"color": Color(0.55, 0.58, 0.72, 1.0),
		"size": Vector2(22, 20),
		"health": 14.0,
		"speed_min": 55.0,
		"speed_max": 78.0,
		"meter_damage": 0.035,
		"xp": 1.35,
		"move_pattern": 1,
		"is_ranged": true,
		"defeat_text": "zzz",
	},
	EnemyType.MINI_BOSS_0: {
		"color": Color(0.72, 0.58, 0.55, 1.0),
		"size": Vector2(20, 20),
		"health": 16.0,
		"speed_min": 38.0,
		"speed_max": 52.0,
		"meter_damage": 0.038,
		"xp": 1.6,
		"move_pattern": 0,
		"is_ranged": false,
		"defeat_text": "zzz",
		"boss_tex_idx": 0,
	},
	EnemyType.MINI_BOSS_1: {
		"color": Color(0.62, 0.58, 0.78, 1.0),
		"size": Vector2(20, 20),
		"health": 18.0,
		"speed_min": 40.0,
		"speed_max": 54.0,
		"meter_damage": 0.04,
		"xp": 1.75,
		"move_pattern": 0,
		"is_ranged": false,
		"defeat_text": "zzz",
		"boss_tex_idx": 1,
	},
	EnemyType.MINI_BOSS_2: {
		"color": Color(0.58, 0.68, 0.82, 1.0),
		"size": Vector2(20, 20),
		"health": 20.0,
		"speed_min": 36.0,
		"speed_max": 50.0,
		"meter_damage": 0.042,
		"xp": 1.9,
		"move_pattern": 0,
		"is_ranged": false,
		"defeat_text": "zzz",
		"boss_tex_idx": 2,
	},
}

# When each enemy type becomes available (wave number)
const UNLOCK_WAVES: Dictionary = {
	EnemyType.ZOMBIE: 1,
	EnemyType.ALARM_CLOCK: 4,
	EnemyType.BARKING_PUP: 3,
	EnemyType.GHOST: 6,
	EnemyType.MOSQUITO: 5,
	EnemyType.NEIGHBOR: 8,
	EnemyType.DELIVERY_DRONE: 11,
	EnemyType.MINI_BOSS_0: 6,
	EnemyType.MINI_BOSS_1: 6,
	EnemyType.MINI_BOSS_2: 6,
}


func _ready() -> void:
	enemy_scene = preload("res://scenes/enemies/base_enemy.tscn")
	xp_pickup_scene = preload("res://scenes/pickups/sleep_energy.tscn")
	warm_milk_scene = preload("res://scenes/pickups/warm_milk.tscn")
	_enemy_textures = {
		EnemyType.ZOMBIE: _try_load_texture("res://art/sprites/enemy_zombie.png"),
		EnemyType.ALARM_CLOCK: _try_load_texture("res://art/sprites/enemy_alarm_clock.png"),
		EnemyType.BARKING_PUP: _try_load_texture("res://art/sprites/enemy_barking_pup.png"),
		EnemyType.GHOST: _try_load_texture("res://art/sprites/enemy_ghost.png"),
		EnemyType.MOSQUITO: _try_load_texture("res://art/sprites/enemy_mosquito.png"),
		EnemyType.NEIGHBOR: _try_load_texture("res://art/sprites/enemy_neighbor.png"),
		EnemyType.DELIVERY_DRONE: _try_load_texture("res://art/sprites/enemy_delivery_drone.png"),
		EnemyType.MINI_BOSS_0: _try_load_texture(BOSS_TEXTURE_PATHS[0]),
		EnemyType.MINI_BOSS_1: _try_load_texture(BOSS_TEXTURE_PATHS[1]),
		EnemyType.MINI_BOSS_2: _try_load_texture(BOSS_TEXTURE_PATHS[2]),
	}
	GameManager.run_started.connect(_on_run_started)


func _try_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _boss_color_round_for_wave(wave: int) -> int:
	## One full "round" = three boss waves (15 waves) → new tint for the next repeat of the same PNG.
	@warning_ignore("integer_division")
	return int(max(0, (wave - 1) / (BOSS_WAVE_INTERVAL * BOSS_COUNT)))


func _pick_boss_texture(tier: int) -> Texture2D:
	if BOSS_TEXTURE_PATHS.is_empty():
		return null
	# Wave 5 → tier 1 → boss art 0; wave 10 → tier 2 → art 1; … then cycles back to 0.
	var idx: int = posmod(tier - 1, BOSS_COUNT)
	var path: String = BOSS_TEXTURE_PATHS[idx]
	return _try_load_texture(path)


func _process(delta: float) -> void:
	if not _active or GameManager.run_state != GameManager.RunState.PLAYING:
		return

	if _wave_clear:
		_wave_delay_timer -= delta
		if _wave_delay_timer <= 0.0:
			_wave_clear = false
			_start_next_wave()
		return

	if _enemies_to_spawn > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_do_spawn_one()
			_spawn_timer = SPAWN_STAGGER
		return

	if _enemies_alive <= 0:
		_wave_clear = true
		_wave_delay_timer = WAVE_DELAY


func setup(player: Node2D, entities: Node2D, pickups: Node2D) -> void:
	_player = player
	_entities_node = entities
	_pickups_node = pickups


func _on_run_started() -> void:
	current_wave = 0
	_enemies_to_spawn = 0
	_enemies_alive = 0
	_wave_clear = true
	_wave_delay_timer = 1.5
	_active = true


func _start_next_wave() -> void:
	current_wave += 1
	GameManager.wave_number = current_wave
	GameManager.wave_spawned.emit(current_wave)

	if _is_boss_wave(current_wave):
		_enemies_to_spawn = BOSS_WAVE_SMALL_ADDS + 1
		_enemies_alive = BOSS_WAVE_SMALL_ADDS + 1
	else:
		var count := _get_wave_enemy_count(current_wave)
		_enemies_to_spawn = count
		_enemies_alive = count
	_spawn_index = 0
	_spawn_timer = 0.0


func _get_wave_enemy_count(wave: int) -> int:
	if wave <= 10:
		return 3 + wave * 2
	else:
		return 23 + (wave - 10) * 3


func _is_boss_wave(wave: int) -> bool:
	return wave >= BOSS_WAVE_INTERVAL and wave % BOSS_WAVE_INTERVAL == 0


func _do_spawn_one() -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var is_bw: bool = _is_boss_wave(current_wave)
	var tier: int = current_wave / BOSS_WAVE_INTERVAL
	var is_main_boss: bool = is_bw and _spawn_index >= BOSS_WAVE_SMALL_ADDS

	var enemy_type: EnemyType
	var config: Dictionary

	if is_bw and not is_main_boss:
		enemy_type = EnemyType.ZOMBIE
		config = ENEMY_CONFIGS[enemy_type]
	elif is_main_boss:
		enemy_type = BOSS_CHASSIS
		config = ENEMY_CONFIGS[enemy_type]
	else:
		enemy_type = _pick_enemy_type()
		config = ENEMY_CONFIGS[enemy_type]

	var enemy := enemy_scene.instantiate() as CharacterBody2D
	enemy.global_position = _get_spawn_position()

	var wave_scale := 1.0 + (current_wave - 1) * 0.12
	if is_main_boss:
		if _spawn_index == BOSS_WAVE_SMALL_ADDS:
			AudioManager.play_sfx_by_name("wave_start", -10.0)
		enemy.is_boss = true
		enemy.boss_tier = tier
		var hp_mul: float = 5.5 + tier * 3.8
		enemy.max_health = config["health"] * wave_scale * hp_mul
		enemy.move_speed = (randf_range(config["speed_min"], config["speed_max"]) + current_wave * 1.8) * 0.87
		var base_xp: float = config["xp"] + current_wave * 0.35
		var reward_step: float = 5.0 + tier * 4.5
		enemy.xp_value = base_xp * reward_step
		enemy.meter_damage = (config["meter_damage"] + current_wave * 0.002) * (1.05 + tier * 0.1)
		enemy.enemy_size = config["size"] * 1.65
	else:
		enemy.max_health = config["health"] * wave_scale
		enemy.move_speed = randf_range(config["speed_min"], config["speed_max"]) + current_wave * 2.0
		enemy.xp_value = config["xp"] + current_wave * 0.3
		enemy.meter_damage = config["meter_damage"] + current_wave * 0.002
		enemy.enemy_size = config["size"]
	enemy.move_pattern = config["move_pattern"]
	enemy.enemy_color = config["color"]
	enemy.is_ranged = config["is_ranged"]
	if _enemy_textures.has(enemy_type) and _enemy_textures[enemy_type] != null:
		enemy.sprite_texture = _enemy_textures[enemy_type]
	if is_main_boss:
		var btex: Texture2D = _pick_boss_texture(tier)
		if btex != null:
			enemy.sprite_texture = btex
	elif enemy_type == EnemyType.MINI_BOSS_0 or enemy_type == EnemyType.MINI_BOSS_1 or enemy_type == EnemyType.MINI_BOSS_2:
		enemy.is_mini_boss = true

	if is_main_boss or enemy_type == EnemyType.MINI_BOSS_0 or enemy_type == EnemyType.MINI_BOSS_1 or enemy_type == EnemyType.MINI_BOSS_2:
		enemy.boss_color_round = _boss_color_round_for_wave(current_wave)

	enemy.clock_pulse_fx = enemy_type == EnemyType.ALARM_CLOCK
	enemy.locks_sleep_meter = bool(config.get("locks_sleep_meter", false))

	enemy.defeated.connect(_on_enemy_defeated)
	_entities_node.add_child(enemy)

	_enemies_to_spawn -= 1
	_spawn_index += 1


func _pick_enemy_type() -> EnemyType:
	var available: Array[EnemyType] = []
	for type: EnemyType in UNLOCK_WAVES:
		if current_wave >= UNLOCK_WAVES[type]:
			available.append(type)

	if available.is_empty():
		return EnemyType.ZOMBIE

	# Zombies are always the most common, others sprinkle in
	var weights: Array[float] = []
	for type in available:
		match type:
			EnemyType.ZOMBIE:
				weights.append(5.0)
			EnemyType.ALARM_CLOCK:
				weights.append(1.5)
			EnemyType.BARKING_PUP:
				weights.append(2.5)
			EnemyType.GHOST:
				weights.append(1.0)
			EnemyType.MOSQUITO:
				weights.append(2.0)
			EnemyType.NEIGHBOR:
				weights.append(0.85)
			EnemyType.DELIVERY_DRONE:
				weights.append(1.2)
			EnemyType.MINI_BOSS_0:
				weights.append(0.75)
			EnemyType.MINI_BOSS_1:
				weights.append(0.7)
			EnemyType.MINI_BOSS_2:
				weights.append(0.65)

	return available[_weighted_random(weights)]


func _weighted_random(weights: Array[float]) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var cumulative := 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return weights.size() - 1


func _on_enemy_defeated(enemy: CharacterBody2D) -> void:
	var pos := enemy.global_position
	var xp_val: float = enemy.xp_value
	var was_boss: bool = bool(enemy.get("is_boss"))
	call_deferred("_finalize_enemy_loot", pos, xp_val, was_boss)
	_enemies_alive -= 1


func _finalize_enemy_loot(pos: Vector2, xp_val: float, was_boss: bool) -> void:
	_spawn_xp_pickup(pos, xp_val)
	if was_boss:
		_spawn_boss_bonus_rewards(pos, xp_val)


func _spawn_boss_bonus_rewards(pos: Vector2, boss_xp: float) -> void:
	var bonus: float = boss_xp * 0.42
	_spawn_xp_pickup(pos + Vector2(randf_range(-36, 36), randf_range(-28, 28)), bonus)
	_spawn_xp_pickup(pos + Vector2(randf_range(-36, 36), randf_range(-28, 28)), bonus)
	if randf() < 0.55:
		_spawn_warm_milk(pos + Vector2(randf_range(-20, 20), randf_range(-16, 16)))


func _spawn_xp_pickup(pos: Vector2, xp: float) -> void:
	var pickup := xp_pickup_scene.instantiate()
	pickup.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	pickup.xp_amount = xp
	_pickups_node.add_child(pickup)

	if randf() < WARM_MILK_CHANCE:
		_spawn_warm_milk(pos)


func _spawn_warm_milk(pos: Vector2) -> void:
	var milk := warm_milk_scene.instantiate()
	milk.global_position = pos + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	_pickups_node.add_child(milk)


func _get_spawn_position() -> Vector2:
	const ARENA_HALF_W: float = 600.0
	const ARENA_HALF_H: float = 900.0

	var vp := get_viewport().get_visible_rect().size
	var cam_pos := _player.global_position
	var half_w := vp.x * 0.5
	var half_h := vp.y * 0.5

	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0:
			pos.x = cam_pos.x + randf_range(-half_w, half_w)
			pos.y = cam_pos.y - half_h - SPAWN_MARGIN
		1:
			pos.x = cam_pos.x + randf_range(-half_w, half_w)
			pos.y = cam_pos.y + half_h + SPAWN_MARGIN
		2:
			pos.x = cam_pos.x - half_w - SPAWN_MARGIN
			pos.y = cam_pos.y + randf_range(-half_h, half_h)
		3:
			pos.x = cam_pos.x + half_w + SPAWN_MARGIN
			pos.y = cam_pos.y + randf_range(-half_h, half_h)

	pos.x = clampf(pos.x, -ARENA_HALF_W, ARENA_HALF_W)
	pos.y = clampf(pos.y, -ARENA_HALF_H, ARENA_HALF_H)
	return pos
