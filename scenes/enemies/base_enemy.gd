extends CharacterBody2D

## Base enemy with support for different types and movement patterns.
## On defeat: plays sleep animation, drops XP pickup, then frees itself.

signal defeated(enemy: CharacterBody2D)

enum MovePattern { CHASE, ZIGZAG, ORBIT, PHASE }

@export var max_health: float = 10.0
@export var move_speed: float = 60.0
@export var meter_damage: float = 0.03
@export var xp_value: float = 1.0
@export var threat_cost: float = 1.0
@export var move_pattern: MovePattern = MovePattern.CHASE
@export var enemy_color: Color = Color(0.85, 0.2, 0.2, 1.0)
@export var enemy_size: Vector2 = Vector2(24, 24)
@export var sprite_texture: Texture2D = null
@export var is_ranged: bool = false
@export var ranged_range: float = 200.0
@export var ranged_cooldown: float = 2.0
@export var is_boss: bool = false
@export var boss_tier: int = 1
@export var clock_pulse_fx: bool = false
## Shrunk boss art used as a normal enemy (spawned after that boss was introduced).
@export var is_mini_boss: bool = false
## Contact/ranged attacks lock regen (caffeine-style); set from spawner (e.g. alarm clock).
@export var locks_sleep_meter: bool = false
## Which full "color round" (every 3 boss waves) — shifts tint when the same boss PNG repeats.
@export var boss_color_round: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: Area2D = $Hitbox
@onready var defeat_label: Label = $DefeatLabel

var _target: Node2D = null
var _is_dying: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _zigzag_timer: float = 0.0
var _zigzag_dir: float = 1.0
var _orbit_angle: float = 0.0
var _ranged_timer: float = 0.0
var _phase_alpha: float = 1.0
var _contact_damage_radius: float = 50.0

const BOSS_ENRAGE_HEALTH_RATIO: float = 0.35
const BossSpitProjectile := preload("res://scenes/enemies/boss_spit_projectile.gd")
const ClockPulseRingScript := preload("res://scripts/effects/clock_pulse_ring.gd")

var _boss_base_modulate: Color = Color.WHITE
var _boss_throw_cd: float = 0.0

## From this wave onward, melee/chase enemies occasionally lob projectiles if they cannot reach the hero (Snore/AoE stalemate).
const PRESSURE_LOB_WAVE: int = 20
var _pressure_lob_cd: float = 0.0
## Night Light aura: 0–~0.55 effective slow factor on move speed.
var _night_light_slow: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	_assign_placeholder_texture()
	sprite.scale = Vector2(2.0, 2.0)
	if is_mini_boss and not is_boss:
		sprite.scale *= 0.44
		_boss_base_modulate = _boss_round_tint(boss_color_round)
		sprite.modulate = _boss_base_modulate
	_night_light_slow = 0.0
	if is_boss:
		_apply_boss_visual_scale()
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(_on_died)
	_find_target()

	# PHASE (ghost): stay physically hittable — pillow uses body_entered vs this CharacterBody2D.
	# Visibility “phases” via sprite alpha only (was collision_layer 0, which blocked all pillow hits).

	if move_pattern == MovePattern.ORBIT:
		if _target and is_instance_valid(_target):
			_orbit_angle = global_position.angle_to_point(_target.global_position)

	if clock_pulse_fx:
		var ring_node := Node2D.new()
		ring_node.set_script(ClockPulseRingScript)
		add_child(ring_node)
		move_child(ring_node, 0)
		ring_node.z_index = -2

	_pressure_lob_cd = randf_range(0.4, 2.2)


func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 400.0 * delta)

	if not _target or not is_instance_valid(_target):
		_find_target()
		velocity = _knockback_velocity
		move_and_slide()
		return

	_night_light_slow = move_toward(_night_light_slow, 0.0, delta * 1.35)
	var speed_mult := SleepMeter.get_enemy_speed_multiplier()
	var slow_k: float = clampf(1.0 - _night_light_slow, 0.48, 1.0)
	var effective_speed := move_speed * speed_mult * slow_k

	match move_pattern:
		MovePattern.CHASE:
			_move_chase(effective_speed)
		MovePattern.ZIGZAG:
			_move_zigzag(effective_speed, delta)
		MovePattern.ORBIT:
			_move_orbit(effective_speed, delta)
		MovePattern.PHASE:
			_move_phase(effective_speed, delta)

	velocity += _knockback_velocity
	move_and_slide()

	if velocity.x > 0.1:
		sprite.flip_h = false
	elif velocity.x < -0.1:
		sprite.flip_h = true

	if is_ranged:
		_update_ranged_attack(delta)
	else:
		_update_wave_pressure_lob(delta)

	if is_boss and not _is_dying:
		_process_boss_enrage(delta)


func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dying:
		return

	var dmg_mult := SleepMeter.get_damage_multiplier()
	var base_dmg: float = GameManager.player_stats.get("base_damage", 1.0)
	var tester_out: float = GameManager.get_tester_outgoing_damage_multiplier()
	var final_damage := amount * dmg_mult * base_dmg * tester_out
	health.take_damage(final_damage)

	if from_position != Vector2.ZERO:
		var kb_dir := (global_position - from_position).normalized()
		_knockback_velocity = kb_dir * 150.0

	_flash_hit()


func apply_contact_damage() -> void:
	if _is_dying or _target == null or not is_instance_valid(_target):
		return
	if is_ranged:
		return
	if global_position.distance_to(_target.global_position) < _contact_damage_radius:
		if _target.has_method("take_sleep_damage"):
			_target.take_sleep_damage(meter_damage)
		if locks_sleep_meter:
			SleepMeter.lock_meter(4.0)


# --- Movement patterns ---

func _move_chase(spd: float) -> void:
	var dir := (_target.global_position - global_position).normalized()
	velocity = dir * spd


func _move_zigzag(spd: float, delta: float) -> void:
	_zigzag_timer += delta
	if _zigzag_timer >= 0.4:
		_zigzag_timer = 0.0
		_zigzag_dir *= -1.0

	var to_target := (_target.global_position - global_position).normalized()
	var perp := to_target.rotated(PI * 0.5) * _zigzag_dir
	velocity = (to_target * 0.7 + perp * 0.5).normalized() * spd


func _move_orbit(spd: float, delta: float) -> void:
	var orbit_radius := global_position.distance_to(_target.global_position)
	var desired_radius := 130.0

	_orbit_angle += (spd / desired_radius) * delta

	var target_pos := _target.global_position + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * desired_radius
	var dir := (target_pos - global_position).normalized()

	if orbit_radius > desired_radius + 20.0:
		var close_dir := (_target.global_position - global_position).normalized()
		dir = (dir + close_dir).normalized()

	velocity = dir * spd


func _move_phase(spd: float, _delta: float) -> void:
	var dir := (_target.global_position - global_position).normalized()
	velocity = dir * spd * 0.7

	# Slower pulse, higher floor — ghost reads “solid” longer; collision always on for pillow hits.
	_phase_alpha = 0.72 + sin(Time.get_ticks_msec() * 0.0022) * 0.22
	if sprite:
		sprite.modulate.a = clampf(_phase_alpha, 0.5, 0.98)


# --- Ranged attack ---

func _update_ranged_attack(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	var cd: float = ranged_cooldown
	if GameManager.wave_number >= PRESSURE_LOB_WAVE:
		cd *= 0.62
	_ranged_timer += delta
	if _ranged_timer >= cd:
		_ranged_timer = 0.0
		var dist := global_position.distance_to(_target.global_position)
		if dist <= ranged_range:
			if _target.has_method("take_sleep_damage"):
				_target.take_sleep_damage(meter_damage)
			if locks_sleep_meter:
				SleepMeter.lock_meter(4.0)
			_flash_ranged()


func _flash_ranged() -> void:
	var base_scale := sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * 1.2, 0.1)
	tween.tween_property(sprite, "scale", base_scale, 0.15)


# --- Death ---

func _on_died() -> void:
	if _is_dying:
		return
	_is_dying = true
	_try_drop_dream_milk()
	GameManager.register_enemy_defeated()
	if is_boss:
		GameManager.register_boss_defeated()
	AudioManager.play_sfx_by_name("enemy_death", -6.0, randf_range(0.85, 1.15))
	defeated.emit(self)
	_play_defeat_animation()


func _play_defeat_animation() -> void:
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	defeat_label.visible = true

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.3)
	tween.parallel().tween_property(sprite, "rotation", 1.2, 0.3)
	tween.parallel().tween_property(defeat_label, "position:y", defeat_label.position.y - 20.0, 0.5)
	tween.parallel().tween_property(defeat_label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.tween_callback(queue_free).set_delay(0.1)


func _flash_hit() -> void:
	var restore: Color = Color.WHITE
	if is_boss or is_mini_boss:
		restore = _boss_base_modulate
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.04)
	tween.tween_property(sprite, "modulate", restore, 0.1)


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]


func add_night_light_slow(amount: float) -> void:
	var add_amt: float = maxf(0.0, amount)
	_night_light_slow = minf(0.55, _night_light_slow + add_amt)


func _try_drop_dream_milk() -> void:
	var p: float = float(GameManager.player_stats.get("dream_milk_drop_chance", 0.0))
	if p <= 0.0:
		return
	if is_boss and randf() > 0.35:
		return
	if randf() >= p:
		return
	var scene: PackedScene = load("res://scenes/pickups/warm_milk.tscn") as PackedScene
	if scene == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var pickups := parent.get_node_or_null("Pickups")
	if pickups == null:
		return
	var drop: Node2D = scene.instantiate() as Node2D
	if drop:
		pickups.add_child(drop)
		drop.global_position = global_position


func _boss_tier_modulate(tier: int) -> Color:
	var palette: Array[Color] = [
		Color(1.12, 1.05, 0.88),
		Color(0.82, 1.08, 1.12),
		Color(1.12, 0.82, 1.15),
		Color(0.88, 1.12, 0.85),
		Color(1.15, 0.92, 0.72),
		Color(0.95, 0.88, 1.18),
	]
	var idx: int = posmod(tier - 1, palette.size())
	return palette[idx]


func _boss_round_tint(round_idx: int) -> Color:
	## Multiplier applied so each full cycle of 3 bosses (same PNG order) reads as a new "edition".
	var tints: Array[Color] = [
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.08, 0.95, 1.12, 1.0),
		Color(0.92, 1.1, 1.05, 1.0),
		Color(1.1, 1.05, 0.9, 1.0),
		Color(0.95, 1.0, 1.15, 1.0),
		Color(1.12, 0.98, 0.95, 1.0),
		Color(0.9, 1.05, 1.1, 1.0),
		Color(1.05, 1.1, 0.95, 1.0),
	]
	return tints[posmod(round_idx, tints.size())]


func _apply_boss_visual_scale() -> void:
	var tier: int = maxi(1, boss_tier)
	_boss_base_modulate = _boss_tier_modulate(tier) * _boss_round_tint(boss_color_round)
	sprite.modulate = _boss_base_modulate
	var size_mul: float = clampf(1.38 + tier * 0.14, 1.38, 2.05)
	sprite.scale *= size_mul
	_contact_damage_radius = 50.0 * sqrt(size_mul)

	var body_shape := $CollisionShape2D.shape as CircleShape2D
	if body_shape:
		body_shape.radius *= size_mul
	var hit_shape := $Hitbox/HitboxShape.shape as CircleShape2D
	if hit_shape:
		hit_shape.radius *= size_mul

	defeat_label.text = "BOSS!"
	defeat_label.add_theme_font_size_override("font_size", 26)
	defeat_label.position.y -= 12.0
	ranged_range *= 1.0 + tier * 0.06


func _process_boss_enrage(delta: float) -> void:
	var ratio: float = health.get_health_ratio()
	if ratio > BOSS_ENRAGE_HEALTH_RATIO:
		_boss_throw_cd = 0.0
		if move_pattern != MovePattern.PHASE:
			sprite.modulate = _boss_base_modulate
		return

	_boss_throw_cd -= delta
	if _boss_throw_cd <= 0.0:
		_boss_throw_cd = 0.42 + randf() * 0.38
		_spawn_boss_spit_at_hero()

	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.011)
	var c: Color = Color.RED.lerp(_boss_base_modulate, pulse)
	if move_pattern == MovePattern.PHASE:
		c.a = clampf(_phase_alpha, 0.45, 0.98)
	sprite.modulate = c


func _spawn_boss_spit_at_hero() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var spit: Node2D = BossSpitProjectile.new()
	var dmg: float = clampf(meter_damage * (2.0 + boss_tier * 0.35), 0.02, 0.22)
	var spd: float = 400.0 + boss_tier * 14.0
	spit.setup(global_position, _target.global_position, dmg, spd)
	_attach_spit_to_scene(spit)


func _update_wave_pressure_lob(delta: float) -> void:
	if is_boss or _is_dying:
		return
	if GameManager.wave_number < PRESSURE_LOB_WAVE:
		return
	if _target == null or not is_instance_valid(_target):
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist < 115.0:
		return
	if _pressure_lob_cd > 0.0:
		_pressure_lob_cd -= delta
		return
	_pressure_lob_cd = randf_range(2.0, 3.6)
	var spit: Node2D = BossSpitProjectile.new()
	var dmg: float = clampf(meter_damage * 0.48, 0.018, 0.08)
	var spd: float = 340.0 + mini(GameManager.wave_number - PRESSURE_LOB_WAVE, 18) * 3.5
	spit.setup(global_position, _target.global_position + Vector2(randf_range(-18, 18), randf_range(-14, 14)), dmg, spd)
	_attach_spit_to_scene(spit)


func _attach_spit_to_scene(spit: Node2D) -> void:
	var fx := _get_effects_root()
	if fx:
		fx.add_child(spit)
	elif get_parent():
		get_parent().add_child(spit)


func _get_effects_root() -> Node2D:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.get_node_or_null("Effects") as Node2D


func _assign_placeholder_texture() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture
		return
	if sprite.texture == null:
		var w := int(enemy_size.x)
		var h := int(enemy_size.y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(enemy_color)
		var border := enemy_color.darkened(0.4)
		for x in w:
			img.set_pixel(x, 0, border)
			img.set_pixel(x, h - 1, border)
		for y in h:
			img.set_pixel(0, y, border)
			img.set_pixel(w - 1, y, border)
		sprite.texture = ImageTexture.create_from_image(img)
