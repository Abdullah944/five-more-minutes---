extends CharacterBody2D

## The player entity — a hero sleeping in a bed.
## Intro: shows bed + sleeping hero, hero wakes up, bed fades, hero fights.

signal intro_finished

@export var base_move_speed: float = 200.0

# --- Node references ---

@onready var hero_sprite: Sprite2D = $HeroSprite
@onready var bed_sprite: Sprite2D = $BedSprite
@onready var zzz_label: Label = $ZZZLabel
@onready var camera: Camera2D = $Camera2D
@onready var ability_mount: Node2D = $AbilityMount
@onready var hurtbox: Area2D = $Hurtbox
@onready var pickup_magnet: PickupMagnet = $PickupMagnet
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var _settings_manager: Node = get_node_or_null("/root/SettingsManager")

# --- State ---

var is_intro_playing: bool = false
var can_move: bool = false
var _zzz_timer: float = 0.0
## Ad / power-up: no sleep damage (ranged or contact) for this many seconds.
var _invulnerable_time_left: float = 0.0


const DESIGN_VP_W: float = 720.0
const DESIGN_VP_H: float = 1280.0


func _ready() -> void:
	add_to_group("player")
	global_position = Vector2.ZERO
	_assign_placeholder_textures()
	_update_stats_from_manager()
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	_adapt_camera_zoom()
	get_tree().root.size_changed.connect(_adapt_camera_zoom)


func _process(_delta: float) -> void:
	if _invulnerable_time_left > 0.0:
		_invulnerable_time_left -= _delta
		_apply_invulnerable_visual()
		if _invulnerable_time_left <= 0.0:
			_invulnerable_time_left = 0.0
			_clear_invulnerable_visual()


func grant_invulnerable(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_invulnerable_time_left = maxf(_invulnerable_time_left, seconds)
	_apply_invulnerable_visual()


func _apply_invulnerable_visual() -> void:
	var t := Time.get_ticks_msec() * 0.001
	var flicker_a := 0.32 + 0.28 * sin(t * 9.0)
	hero_sprite.modulate = Color(0.82, 0.92, 1.02, flicker_a)


func _clear_invulnerable_visual() -> void:
	hero_sprite.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	if not can_move:
		return

	var input_dir := _get_joystick_input()
	var speed: float = GameManager.player_stats.get("move_speed", base_move_speed)
	velocity = input_dir * speed
	move_and_slide()

	if input_dir.x > 0.1:
		hero_sprite.flip_h = false
	elif input_dir.x < -0.1:
		hero_sprite.flip_h = true

	_animate_zzz(delta)


func play_intro(is_first_run: bool = true) -> void:
	is_intro_playing = true
	can_move = false

	bed_sprite.visible = true
	bed_sprite.modulate.a = 1.0
	hero_sprite.visible = false
	zzz_label.visible = true

	var sleep_dur := 2.0 if is_first_run else 0.8
	await get_tree().create_timer(sleep_dur).timeout

	zzz_label.visible = false
	hero_sprite.visible = true
	hero_sprite.modulate.a = 1.0

	var wake_tween := create_tween()
	wake_tween.tween_property(bed_sprite, "modulate:a", 0.0, 0.8)
	await wake_tween.finished
	bed_sprite.visible = false

	is_intro_playing = false
	can_move = true
	intro_finished.emit()


func skip_intro() -> void:
	if is_intro_playing:
		bed_sprite.visible = false
		hero_sprite.visible = true
		hero_sprite.modulate.a = 1.0
		zzz_label.visible = false
		is_intro_playing = false
		can_move = true
		intro_finished.emit()


func take_sleep_damage(amount: float) -> void:
	if GameManager.is_tester_invulnerable():
		return
	if _invulnerable_time_left > 0.0:
		return

	var reduction: float = GameManager.player_stats.get("damage_reduction", 0.0)
	var final_damage := amount * (1.0 - clampf(reduction, 0.0, 0.8))
	SleepMeter.add_meter(final_damage)

	_flash_hurt()
	AudioManager.play_sfx_by_name("enemy_hit", -3.0, randf_range(0.9, 1.1))
	if _settings_manager and _settings_manager.has_method("play_haptic_ms"):
		_settings_manager.play_haptic_ms(50)


func _assign_placeholder_textures() -> void:
	if bed_sprite.texture == null:
		var bed_id: String = MetaProgression.selected_bed
		var path: String = "res://art/sprites/bed_standard.png"
		if MetaProgression.BED_TEXTURE_PATHS.has(bed_id):
			path = MetaProgression.BED_TEXTURE_PATHS[bed_id] as String
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
		if tex:
			bed_sprite.texture = tex
		else:
			var fb := load("res://art/sprites/bed_standard.png") as Texture2D
			bed_sprite.texture = fb if fb else _make_rect_texture(56, 72, Color(0.28, 0.35, 0.55, 1.0))
	if hero_sprite.texture == null:
		var hero_tex := load("res://art/sprites/hero_idle.png") as Texture2D
		if hero_tex:
			hero_sprite.texture = hero_tex
			@warning_ignore("integer_division")
			var frame_w := hero_tex.get_width() / 2
			@warning_ignore("integer_division")
			var frame_h := hero_tex.get_height() / 2
			hero_sprite.region_enabled = true
			hero_sprite.region_rect = Rect2(0, 0, frame_w, frame_h)
		else:
			hero_sprite.texture = _make_rect_texture(32, 32, Color(0.95, 0.75, 0.6, 1.0))
	hero_sprite.scale = Vector2(2.8, 2.8)
	bed_sprite.scale = Vector2(2.4, 2.4)


static func _make_rect_texture(w: int, h: int, color: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var border := color.darkened(0.3)
	for x in w:
		img.set_pixel(x, 0, border)
		img.set_pixel(x, h - 1, border)
	for y in h:
		img.set_pixel(0, y, border)
		img.set_pixel(w - 1, y, border)
	return ImageTexture.create_from_image(img)


func _update_stats_from_manager() -> void:
	var radius: float = GameManager.player_stats.get("pickup_radius", 80.0)
	pickup_magnet.update_radius(radius)


func get_facing_angle() -> float:
	## Dream beam / directional effects: hero looks left or right from sprite flip.
	return PI if hero_sprite.flip_h else 0.0


func get_facing_vector() -> Vector2:
	return Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT


func _get_joystick_input() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _adapt_camera_zoom() -> void:
	# Below 1.0 = zoom out (more world visible, smaller on-screen sprites).
	camera.zoom = Vector2(0.78, 0.78)


func _animate_zzz(delta: float) -> void:
	if not zzz_label.visible:
		return
	_zzz_timer += delta
	zzz_label.position.y = -50.0 + sin(_zzz_timer * 2.0) * 4.0
	zzz_label.modulate.a = 0.5 + sin(_zzz_timer * 3.0) * 0.3


func _flash_hurt() -> void:
	var tween := create_tween()
	tween.tween_property(hero_sprite, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(hero_sprite, "modulate", Color.WHITE, 0.15)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		take_sleep_damage(hitbox.damage)
		var p: Node = hitbox.get_parent()
		if p and bool(p.get("locks_sleep_meter")):
			SleepMeter.lock_meter(4.0)
