extends Node2D

## Main game scene controller. Orchestrates intro, run, pause, level-up, and game over.

@onready var player_bed: CharacterBody2D = $World/Bed
@onready var hud: CanvasLayer = $HUD
@onready var floating_joystick: Control = $UILayer/FloatingJoystick
@onready var attack_btn: Button = $UILayer/AttackButtonRoot/AttackButton
@onready var entities_node: Node2D = $Entities
@onready var pickups_node: Node2D = $Pickups
@onready var enemy_spawner: Node = $EnemySpawner
@onready var pause_menu: Control = $OverlayLayer/PauseMenu
@onready var game_over_screen: Control = $OverlayLayer/GameOverScreen
@onready var upgrade_selection: Control = $OverlayLayer/UpgradeSelection
@onready var rewarded_offer: Control = $OverlayLayer/RewardedAdOffer
@onready var dream_bg: Sprite2D = $DreamBackground
@onready var arena_boundary: Node2D = $ArenaBoundary
@onready var game_camera: Camera2D = $World/Bed/Camera2D
@onready var mission_manager: Node = get_node_or_null("/root/MissionManager")

const DREAM_BG_PATHS: Dictionary = {
	1: "res://art/backgrounds/dream_forest.png",
	2: "res://art/backgrounds/dream_clouds.png",
	3: "res://art/backgrounds/dream_nightmare.png",
	4: "res://art/backgrounds/dream_candy.png",
	5: "res://art/backgrounds/dream_space.png",
}

var pillow_toss_scene: PackedScene
var snore_wave_scene: PackedScene
var dream_beam_scene: PackedScene
var night_light_scene: PackedScene
var is_first_run: bool = true
var _game_over_sequence_started: bool = false
var _pillow_ability: BaseAbility = null
var _manual_attack_cooldown: float = 0.0
var _attack_ui_unlocked: bool = false

const MANUAL_ATTACK_COOLDOWN_SEC: float = 1.0

## Pillow attack button scales with the shorter viewport side (thumb-sized on phones).
const ATTACK_BTN_SIDE_MIN: float = 120.0
const ATTACK_BTN_SIDE_MAX: float = 196.0
const ATTACK_BTN_SHORT_SIDE_FRAC: float = 0.168
const ATTACK_BTN_EDGE_FRAC: float = 0.022
const ATTACK_BTN_EDGE_MIN: float = 14.0
const ATTACK_BTN_EDGE_MAX: float = 26.0
const ATTACK_BTN_ICON_FRAC: float = 0.72

const AD_OFFER_WAVE_INTERVAL: int = 4

func _ready() -> void:
	pillow_toss_scene = preload("res://scenes/abilities/pillow_toss.tscn")
	snore_wave_scene = preload("res://scenes/abilities/snore_wave.tscn")
	dream_beam_scene = preload("res://scenes/abilities/dream_beam.tscn")
	night_light_scene = preload("res://scenes/abilities/night_light.tscn")
	SleepMeter.game_over.connect(_on_game_over)
	GameManager.level_up_triggered.connect(_on_level_up)
	GameManager.night_changed.connect(_on_night_changed)
	player_bed.intro_finished.connect(_on_intro_finished)
	player_bed.pickup_magnet.pickup_collected.connect(_on_pickup_collected)

	hud.pause_requested.connect(_on_pause_requested)
	pause_menu.resume_pressed.connect(_on_resume)
	pause_menu.restart_pressed.connect(_on_restart)
	pause_menu.quit_pressed.connect(_on_quit_to_menu)
	game_over_screen.retry_pressed.connect(_on_restart)
	game_over_screen.home_pressed.connect(_on_quit_to_menu)
	upgrade_selection.upgrade_chosen.connect(_on_upgrade_chosen)

	enemy_spawner.setup(player_bed, entities_node, pickups_node)
	arena_boundary.setup(player_bed)

	get_viewport().size_changed.connect(_update_dream_bg_cover)

	_setup_attack_button()
	get_viewport().size_changed.connect(_refresh_attack_button_layout)
	_refresh_attack_button_layout()
	_start_game()


func _start_game() -> void:
	_attack_ui_unlocked = false
	if attack_btn:
		attack_btn.visible = false
	_game_over_sequence_started = false
	SleepMeter.reset()
	hud.reset_xp()
	AudioManager.play_bgm("gameplay", -6.0)
	_set_dream_background(1)

	for child in entities_node.get_children():
		child.queue_free()
	for child in pickups_node.get_children():
		child.queue_free()

	var meta_b: Dictionary = MetaProgression.get_meta_bonuses()
	UpgradeManager.start_run(int(meta_b.get("rerolls", 0)))
	_apply_bed_starting_loadout()

	player_bed.play_intro(is_first_run)
	is_first_run = false


func _process(delta: float) -> void:
	_update_dream_bg_cover()
	_update_manual_attack_ui(delta)


func _setup_attack_button() -> void:
	_attack_ui_unlocked = false
	_manual_attack_cooldown = 0.0
	attack_btn.visible = false
	attack_btn.text = ""
	var pillow_tex := load("res://art/sprites/effects/pillow_projectile.png") as Texture2D
	if pillow_tex:
		attack_btn.icon = pillow_tex
		attack_btn.expand_icon = true
	attack_btn.flat = false
	attack_btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	if not attack_btn.pressed.is_connected(_on_attack_pressed):
		attack_btn.pressed.connect(_on_attack_pressed)


func _refresh_attack_button_layout() -> void:
	if attack_btn == null or not is_instance_valid(attack_btn):
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 16.0 or vp.y < 16.0:
		return
	var short_side: float = minf(vp.x, vp.y)
	var side_f: float = clampf(
		short_side * ATTACK_BTN_SHORT_SIDE_FRAC,
		ATTACK_BTN_SIDE_MIN,
		ATTACK_BTN_SIDE_MAX
	)
	var edge: float = clampf(
		short_side * ATTACK_BTN_EDGE_FRAC,
		ATTACK_BTN_EDGE_MIN,
		ATTACK_BTN_EDGE_MAX
	)
	var icon_max: int = maxi(1, int(floor(side_f * ATTACK_BTN_ICON_FRAC)))

	attack_btn.custom_minimum_size = Vector2(side_f, side_f)
	attack_btn.add_theme_constant_override("icon_max_width", icon_max)

	attack_btn.offset_left = -side_f - edge
	attack_btn.offset_top = -side_f - edge
	attack_btn.offset_right = -edge
	attack_btn.offset_bottom = -edge

	var pill_r: int = maxi(floori(side_f * 0.5), 1)
	var pad: float = clampf(side_f * 0.13, 12.0, 22.0)
	var pad_v: float = clampf(side_f * 0.11, 10.0, 18.0)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = UIPalette.DREAM_VIOLET
	btn_style.border_color = Color.BLACK
	btn_style.border_width_left = 3
	btn_style.border_width_top = 3
	btn_style.border_width_right = 3
	btn_style.border_width_bottom = 3
	btn_style.corner_radius_top_left = pill_r
	btn_style.corner_radius_top_right = pill_r
	btn_style.corner_radius_bottom_right = pill_r
	btn_style.corner_radius_bottom_left = pill_r
	btn_style.content_margin_left = pad
	btn_style.content_margin_right = pad
	btn_style.content_margin_top = pad_v
	btn_style.content_margin_bottom = pad_v
	attack_btn.add_theme_stylebox_override("normal", btn_style)
	var hover := btn_style.duplicate() as StyleBoxFlat
	hover.bg_color = UIPalette.SURFACE_HOVER
	hover.border_color = Color.BLACK
	attack_btn.add_theme_stylebox_override("hover", hover)
	attack_btn.add_theme_stylebox_override("pressed", hover)


func _update_manual_attack_ui(delta: float) -> void:
	if not _attack_ui_unlocked:
		attack_btn.visible = false
		return
	if GameManager.run_state == GameManager.RunState.GAME_OVER:
		attack_btn.visible = false
		return

	attack_btn.visible = true
	_manual_attack_cooldown = maxf(0.0, _manual_attack_cooldown - delta)

	var playing: bool = GameManager.run_state == GameManager.RunState.PLAYING
	var attack_ready: bool = playing and _manual_attack_cooldown <= 0.0
	attack_btn.disabled = not attack_ready
	attack_btn.modulate = Color(1.0, 1.0, 1.0, 0.42) if _manual_attack_cooldown > 0.0 else Color.WHITE


func _on_attack_pressed() -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return
	if _manual_attack_cooldown > 0.0:
		return
	if _pillow_ability == null or not is_instance_valid(_pillow_ability):
		_assign_pillow_ability_from_mount()
	if _pillow_ability == null or not is_instance_valid(_pillow_ability):
		return
	if _pillow_ability.try_manual_fire():
		_manual_attack_cooldown = MANUAL_ATTACK_COOLDOWN_SEC
		AudioManager.play_ui_by_name("button_tap")


func _apply_bed_starting_loadout() -> void:
	# `queue_free()` defers removal: children can still be in the mount this frame, so
	# _grant_ability() would see a "duplicate" pillow, add_stack, return — never wiring
	# _pillow_ability, then the old node is freed. Detach first so the mount is empty.
	_pillow_ability = null
	var mount: Node2D = player_bed.ability_mount
	for c: Node in mount.get_children().duplicate(true):
		mount.remove_child(c)
		c.queue_free()
	var keys: Array[String] = MetaProgression.get_bed_starting_ability_keys()
	for key: String in keys:
		_grant_ability(key)
	_assign_pillow_ability_from_mount()
	for child: Node in player_bed.ability_mount.get_children():
		if child is BaseAbility:
			var ab: BaseAbility = child as BaseAbility
			UpgradeManager.register_ability(ab.ability_id, 1)
	call_deferred("_deferred_ensure_pillow_ability")


func _assign_pillow_ability_from_mount() -> void:
	_pillow_ability = null
	for c: Node in player_bed.ability_mount.get_children():
		if c is BaseAbility and _ability_node_is_pillow_toss(c):
			_pillow_ability = c as BaseAbility
			return


func _ability_node_is_pillow_toss(c: Node) -> bool:
	if not (c is BaseAbility):
		return false
	var ab: BaseAbility = c as BaseAbility
	if ab.ability_id == "pillow_toss":
		return true
	# Root node from pillow_toss.tscn; ability_id is set in _ready (may be pending same frame).
	return c.name == "PillowToss"


## Matches GameManager / grant_ability `scene_key` to an ability node (handles pre-_ready `ability_id`).
func _ability_mount_child_matches_key(c: Node, scene_key: String) -> bool:
	if not (c is BaseAbility):
		return false
	if (c as BaseAbility).ability_id == scene_key:
		return true
	if scene_key == "pillow_toss":
		return _ability_node_is_pillow_toss(c)
	return false


func _deferred_ensure_pillow_ability() -> void:
	if not is_instance_valid(player_bed) or not is_instance_valid(player_bed.ability_mount):
		return
	_assign_pillow_ability_from_mount()
	if _pillow_ability != null and is_instance_valid(_pillow_ability):
		return
	var has_pillow: bool = false
	for c: Node in player_bed.ability_mount.get_children():
		if c is BaseAbility and _ability_node_is_pillow_toss(c):
			has_pillow = true
			break
	if not has_pillow:
		_grant_ability("pillow_toss")
		UpgradeManager.register_ability("pillow_toss", 1)
	_assign_pillow_ability_from_mount()


func _on_intro_finished() -> void:
	_attack_ui_unlocked = true
	GameManager.start_run()
	var b: Dictionary = MetaProgression.get_meta_bonuses()
	for key: String in b:
		GameManager.player_stats[key] = b[key]
	if player_bed.has_method("pickup_magnet"):
		player_bed.pickup_magnet.update_radius(GameManager.player_stats.get("pickup_radius", 80.0))
	var rr: float = float(GameManager.player_stats.get("regen_rate", 0.002))
	SleepMeter.regen_multiplier = rr / 0.002
	SleepMeter.damage_reduction = float(GameManager.player_stats.get("damage_reduction", 0.0))


# --- Level Up ---

func _on_level_up(_level: int) -> void:
	AudioManager.play_sfx_by_name("level_up", -3.0)
	var choices := UpgradeManager.roll_level_up_choices()
	if choices.size() > 0:
		upgrade_selection.show_selection(choices, UpgradeManager.rerolls_remaining)


func _on_night_changed(night: int) -> void:
	if night == GameManager.Night.THE_ALARM:
		AudioManager.play_bgm("boss", -5.0)
	else:
		AudioManager.play_bgm("gameplay", -6.0)
	_transition_dream_background(night)


func _transition_dream_background(night: int) -> void:
	var fade_out := create_tween()
	fade_out.tween_property(dream_bg, "modulate:a", 0.0, 0.8)
	await fade_out.finished
	_set_dream_background(night)
	var fade_in := create_tween()
	fade_in.tween_property(dream_bg, "modulate:a", 1.0, 0.8)


func _set_dream_background(night: int) -> void:
	var path: String = DREAM_BG_PATHS.get(night, DREAM_BG_PATHS[1])
	var tex := load(path) as Texture2D
	if tex:
		dream_bg.texture = tex
		_update_dream_bg_cover()


## Scales/center dream art so it always covers the full camera view (any aspect / zoom).
func _update_dream_bg_cover() -> void:
	if dream_bg.texture == null:
		return
	if game_camera == null or not is_instance_valid(game_camera):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size.x < 1.0 or vp_size.y < 1.0:
		return
	var z: Vector2 = game_camera.zoom
	if z.x < 0.001 or z.y < 0.001:
		return
	var half_w: float = vp_size.x / (2.0 * z.x)
	var half_h: float = vp_size.y / (2.0 * z.y)
	var tex_sz: Vector2 = dream_bg.texture.get_size()
	if tex_sz.x < 1.0 or tex_sz.y < 1.0:
		return
	const PAD: float = 1.12
	var sx: float = (2.0 * half_w * PAD) / tex_sz.x
	var sy: float = (2.0 * half_h * PAD) / tex_sz.y
	var s: float = maxf(sx, sy)
	dream_bg.scale = Vector2(s, s)
	dream_bg.global_position = game_camera.get_screen_center_position()


func _on_upgrade_chosen(upgrade: Dictionary) -> void:
	var uid: String = upgrade.get("id", "")
	var kind: String = str(upgrade.get("kind", "stat"))
	if kind == "unlock_ability":
		UpgradeManager.active_upgrades[uid] = UpgradeManager.get_upgrade_stack(uid) + 1
		_grant_ability(str(upgrade.get("ability_key", "")))
		UpgradeManager.register_ability(str(upgrade.get("ability_key", "")), 1)
		if str(upgrade.get("ability_key", "")) == "pillow_toss":
			_assign_pillow_ability_from_mount()
		return
	if kind == "evolution":
		UpgradeManager.active_upgrades[uid] = UpgradeManager.get_upgrade_stack(uid) + 1
		_apply_paralysis_evolution()
		return
	UpgradeManager.active_upgrades[uid] = UpgradeManager.get_upgrade_stack(uid) + 1
	_apply_upgrade(upgrade)


func _apply_upgrade(upgrade: Dictionary) -> void:
	var stat: String = upgrade.get("stat", "")
	var per_stack: float = upgrade.get("per_stack", 0.0)
	var mode: String = upgrade.get("mode", "add")

	if stat == "":
		return

	# Initialize stat if it doesn't exist yet
	if stat not in GameManager.player_stats:
		GameManager.player_stats[stat] = 1.0 if mode == "multiply" else 0.0

	if mode == "multiply":
		GameManager.player_stats[stat] *= (1.0 + per_stack)
	else:
		GameManager.player_stats[stat] += per_stack

	if stat == "pickup_radius":
		player_bed.pickup_magnet.update_radius(GameManager.player_stats["pickup_radius"])

	if stat == "regen_rate":
		SleepMeter.regen_multiplier = GameManager.player_stats["regen_rate"] / 0.002

	if stat == "damage_reduction":
		SleepMeter.damage_reduction = GameManager.player_stats["damage_reduction"]

	if stat == "dream_milk_drop_chance":
		GameManager.player_stats["dream_milk_drop_chance"] = minf(0.45, float(GameManager.player_stats.get("dream_milk_drop_chance", 0.0)))


func _apply_paralysis_evolution() -> void:
	GameManager.player_stats["paralysis_evolution"] = 1.0
	GameManager.player_stats["base_damage"] = float(GameManager.player_stats.get("base_damage", 1.0)) * 1.3


func _grant_ability(scene_key: String) -> void:
	if scene_key.is_empty():
		return
	var has_already := false
	for c: Node in player_bed.ability_mount.get_children():
		if c is BaseAbility and _ability_mount_child_matches_key(c, scene_key):
			(c as BaseAbility).add_stack()
			has_already = true
			break
	if has_already:
		if scene_key == "pillow_toss":
			_assign_pillow_ability_from_mount()
		return
	var scene: PackedScene
	match scene_key:
		"snore_wave":
			scene = snore_wave_scene
		"dream_beam":
			scene = dream_beam_scene
		"night_light":
			scene = night_light_scene
		"pillow_toss":
			scene = pillow_toss_scene
		_:
			return
	var ability: BaseAbility = scene.instantiate() as BaseAbility
	player_bed.ability_mount.add_child(ability)
	if scene_key == "pillow_toss" and _pillow_ability == null:
		_pillow_ability = ability


# --- Pickups ---

func _on_pickup_collected(pickup: Node2D) -> void:
	if pickup.has_method("collect"):
		pickup.collect(player_bed)


func _on_wave_spawned_reward_offer(wave: int) -> void:
	if wave <= 0:
		return
	if wave % AD_OFFER_WAVE_INTERVAL != 0:
		return
	if _game_over_sequence_started:
		return
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return
	if pause_menu.visible or game_over_screen.visible or upgrade_selection.visible:
		return
	call_deferred("_try_open_reward_offer")


func _try_open_reward_offer() -> void:
	if _game_over_sequence_started:
		return
	if pause_menu.visible or game_over_screen.visible or upgrade_selection.visible:
		return
	if rewarded_offer == null or not rewarded_offer.has_method("open_offer"):
		return
	rewarded_offer.open_offer()


# --- Pause ---

func _on_pause_requested() -> void:
	if GameManager.run_state == GameManager.RunState.PLAYING:
		GameManager.pause_run()
		pause_menu.show_pause()


func _on_resume() -> void:
	GameManager.resume_run()


# --- Game Over ---

func _on_game_over() -> void:
	if _game_over_sequence_started:
		return
	_game_over_sequence_started = true
	_attack_ui_unlocked = false
	attack_btn.visible = false
	AudioManager.stop_bgm(1.0)
	AudioManager.play_sfx_by_name("game_over", -3.0)
	GameManager.end_run()
	var stats := {
		"elapsed_time": GameManager.elapsed_time,
		"enemies_defeated": GameManager.enemies_defeated,
		"bosses_defeated": GameManager.bosses_defeated,
		"night_reached": GameManager.current_night,
		"wave_number": GameManager.wave_number,
	}
	var shards := MetaProgression.record_run(stats)
	if mission_manager and mission_manager.has_method("check_run_missions"):
		mission_manager.check_run_missions(stats)

	await get_tree().create_timer(1.5).timeout
	game_over_screen.show_results(stats, shards)


# --- Restart / Quit ---

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/bedroom_hub.tscn")
