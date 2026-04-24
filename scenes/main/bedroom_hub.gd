extends Control

## Bedroom Hub — the between-runs home screen.
## Shows the player's bedroom with furniture that visually upgrades,
## Dream Shards balance, and buttons to Play or open the Store.

@onready var shards_label: Label = $TopBar/ShardsLabel
@onready var play_btn: Button = $BottomBar/PlayButton
@onready var store_btn: Button = $BottomBar/StoreButton
@onready var missions_btn: Button = $BottomBar/MissionsButton
@onready var hall_btn: Button = $BottomBar/HallButton
@onready var settings_btn: TextureButton = $TopBar/SettingsButton
@onready var bell_btn: TextureButton = $TopBar/BellButton
@onready var bell_badge: Panel = $TopBar/BellButton/BellBadge
@onready var room_viewport: Control = $RoomViewport
@onready var store_screen: Control = $StoreScreen
@onready var missions_panel: Control = $MissionsPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var leaderboard_panel: Control = $LeaderboardPanel
@onready var runs_value: Label = $TopBar/StatsStrip/StatsRow/RunsBlock/RunsValue
@onready var best_value: Label = $TopBar/StatsStrip/StatsRow/BestBlock/BestValue
@onready var rank_value: Label = $TopBar/StatsStrip/StatsRow/RankBlock/RankValue
@onready var mission_manager: Node = get_node_or_null("/root/MissionManager")

var _furniture_nodes: Dictionary = {}
var _info_popup: PanelContainer = null

const FURNITURE_NODE_PATHS: Dictionary = {
	"mattress": NodePath("RoomViewport/FurnitureMattress"),
	"nightstand_lamp": NodePath("RoomViewport/FurnitureNightLamp"),
	"alarm_clock": NodePath("RoomViewport/FurnitureAlarmClock"),
	"white_noise": NodePath("RoomViewport/FurnitureWhiteNoise"),
	"slippers": NodePath("RoomViewport/FurnitureSlippers"),
	"dream_journal": NodePath("RoomViewport/FurnitureDreamJournal"),
}

const FURNITURE_STAT_ICONS: Dictionary = {
	"mattress": "[HP]", "pillow": "[ATK]", "blanket": "[DEF]",
	"nightstand_lamp": "[RNG]", "alarm_clock": "[XP]",
	"white_noise": "[REG]", "slippers": "[SPD]", "dream_journal": "[RR]",
}

const FALLBACK_FURNITURE_LAYOUT: Dictionary = {}


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	store_btn.pressed.connect(_on_store)
	missions_btn.pressed.connect(_on_missions)
	hall_btn.pressed.connect(_on_leaderboard)
	settings_btn.pressed.connect(func() -> void: settings_panel.show_panel())
	bell_btn.pressed.connect(_on_missions)
	store_screen.closed.connect(_on_store_closed)
	missions_panel.closed.connect(_on_missions_closed)
	settings_panel.closed.connect(func() -> void: _update_display())
	leaderboard_panel.closed.connect(func() -> void: _update_display())

	if mission_manager:
		mission_manager.mission_completed.connect(func(_mission_id: String) -> void: _update_bell_badge())
		mission_manager.daily_reward_claimed.connect(func(_day: int, _reward: int) -> void: _update_bell_badge())
		mission_manager.daily_reward_available.connect(func() -> void: _update_bell_badge())

	MetaProgression.shards_changed.connect(func(_t: int) -> void: _update_display())
	MetaProgression.furniture_upgraded.connect(func(_id: String, _lvl: int) -> void: _update_furniture_visuals())

	_cache_furniture_nodes()
	_style_stats_strip()
	_update_display()
	_update_furniture_visuals()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

	AudioManager.play_bgm("menu", -8.0)

	get_viewport().size_changed.connect(_apply_root_safe_area)
	_apply_root_safe_area()

	if mission_manager and not mission_manager.daily_reward_claimed_today:
		_show_daily_reward_popup()


func _apply_root_safe_area() -> void:
	var e: Vector4i = SafeAreaUtil.compute_extra_margins_for_node(self)
	offset_left = e.x
	offset_top = e.y
	offset_right = -e.z
	offset_bottom = -e.w


func _style_stats_strip() -> void:
	var cap_r: Node = get_node_or_null("TopBar/StatsStrip/StatsRow/RunsBlock/RunsCaption")
	var cap_b: Node = get_node_or_null("TopBar/StatsStrip/StatsRow/BestBlock/BestCaption")
	var cap_k: Node = get_node_or_null("TopBar/StatsStrip/StatsRow/RankBlock/RankCaption")
	if cap_r is Label:
		cap_r.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	if cap_b is Label:
		cap_b.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	if cap_k is Label:
		cap_k.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	if is_instance_valid(runs_value):
		runs_value.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	if is_instance_valid(best_value):
		best_value.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	if is_instance_valid(rank_value):
		rank_value.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)


func _update_display() -> void:
	shards_label.text = "%d" % MetaProgression.dream_shards
	if is_instance_valid(runs_value):
		runs_value.text = str(MetaProgression.total_runs)
	if is_instance_valid(best_value):
		best_value.text = _format_time(MetaProgression.best_survival_time)
	if is_instance_valid(rank_value):
		rank_value.text = "#%d" % MetaProgression.get_dream_hall_rank()
	_update_bell_badge()


func _hub_missions_need_attention() -> bool:
	if mission_manager == null:
		return false
	if not bool(mission_manager.daily_reward_claimed_today):
		return true
	if mission_manager.has_method("get_all_missions"):
		for m: Variant in mission_manager.get_all_missions():
			if m is Dictionary:
				var d: Dictionary = m
				if bool(d.get("complete", false)) and not bool(d.get("claimed", false)):
					return true
	return false


func _update_bell_badge() -> void:
	if bell_badge:
		bell_badge.visible = _hub_missions_need_attention()


func _format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var m := int(seconds) / 60
	@warning_ignore("integer_division")
	var s := int(seconds) % 60
	return "%d:%02d" % [m, s]


# --- Room building ---

func _cache_furniture_nodes() -> void:
	_furniture_nodes.clear()
	for furniture_id: String in FURNITURE_NODE_PATHS:
		var container := get_node_or_null(FURNITURE_NODE_PATHS[furniture_id]) as Control
		if container == null:
			container = _create_missing_furniture_node(furniture_id)
		if container == null:
			continue
		_furniture_nodes[furniture_id] = container
		_make_furniture_clickable(container, furniture_id)


func _create_missing_furniture_node(furniture_id: String) -> Control:
	var config: Dictionary = FALLBACK_FURNITURE_LAYOUT.get(furniture_id, {})
	if config.is_empty():
		return null

	var container := Control.new()
	container.name = "Furniture%sAuto" % furniture_id.capitalize()
	var node_size: Vector2 = config.get("size", Vector2(32.0, 32.0))
	container.size = node_size
	container.position = config.get("position", Vector2.ZERO)

	var visual := TextureRect.new()
	visual.name = "FurnitureVisual"
	visual.size = node_size
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture_path: String = config.get("texture", "")
	if texture_path != "":
		var texture := load(texture_path) as Texture2D
		if texture:
			visual.texture = texture
	container.add_child(visual)
	room_viewport.add_child(container)
	return container


func _make_furniture_clickable(container: Control, furniture_id: String) -> void:
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_show_furniture_info(furniture_id, container)
	)


func _show_furniture_info(furniture_id: String, anchor: Control) -> void:
	if _info_popup:
		_info_popup.queue_free()
		_info_popup = null

	var display: Dictionary = MetaProgression.FURNITURE_DISPLAY.get(furniture_id, {})
	var level: int = MetaProgression.furniture_levels.get(furniture_id, 0)
	var max_lvl: int = MetaProgression.FURNITURE_MAX_LEVELS.get(furniture_id, 10)
	var icon_tag: String = FURNITURE_STAT_ICONS.get(furniture_id, "")

	_info_popup = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.NIGHT_NAVY
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = UIPalette.DREAM_VIOLET
	_info_popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "%s %s" % [icon_tag, display.get("name", furniture_id)]
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = display.get("desc", "")
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var lvl := Label.new()
	if level > 0:
		lvl.text = "Lv %d / %d" % [level, max_lvl]
		lvl.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
	else:
		lvl.text = "Not upgraded yet"
		lvl.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	lvl.add_theme_font_size_override("font_size", 16)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lvl)

	_info_popup.add_child(vbox)
	_info_popup.size = Vector2(340, 0)
	add_child(_info_popup)

	var vp := get_viewport_rect().size
	var popup_x := clampf(anchor.global_position.x + anchor.size.x * 0.5 - 110.0, 10.0, vp.x - 230.0)
	var popup_y := clampf(anchor.global_position.y - 80.0, 10.0, vp.y - 120.0)
	_info_popup.global_position = Vector2(popup_x, popup_y)

	_info_popup.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_info_popup, "modulate:a", 1.0, 0.15)

	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(_info_popup):
			var fade := create_tween()
			fade.tween_property(_info_popup, "modulate:a", 0.0, 0.2)
			fade.tween_callback(_info_popup.queue_free)
			_info_popup = null
	)


func _update_furniture_visuals() -> void:
	for furniture_id: String in _furniture_nodes:
		var container: Control = _furniture_nodes[furniture_id]
		var level: int = MetaProgression.furniture_levels.get(furniture_id, 0)
		if level == 0:
			container.modulate.a = 0.4
		else:
			container.modulate.a = 1.0


# --- Navigation ---

func _on_play() -> void:
	AudioManager.play_ui_by_name("button_tap")
	play_btn.disabled = true
	store_btn.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)


func _on_store() -> void:
	AudioManager.play_ui_by_name("menu_open")
	store_screen.show_store()


func _on_missions() -> void:
	AudioManager.play_ui_by_name("menu_open")
	missions_panel.show_panel()


func _on_leaderboard() -> void:
	AudioManager.play_ui_by_name("menu_open")
	leaderboard_panel.show_panel()


func _on_missions_closed() -> void:
	_update_display()


func _show_daily_reward_popup() -> void:
	await get_tree().create_timer(1.0).timeout
	var reward := 0
	if mission_manager and mission_manager.has_method("get_daily_reward_amount"):
		reward = mission_manager.get_daily_reward_amount()

	var popup := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	popup.add_theme_stylebox_override("panel", style)

	var vp := get_viewport_rect().size
	popup.size = Vector2(minf(600, vp.x - 60), 260)
	popup.position = Vector2((vp.x - popup.size.x) * 0.5, (vp.y - popup.size.y) * 0.5)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "Daily Reward!"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Day %d — +%d Shards" % [maxi(MetaProgression.daily_streak, 1), reward]
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var btn := Button.new()
	btn.text = "Claim!"
	btn.add_theme_font_size_override("font_size", 22)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = UIPalette.SURFACE_HOVER
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.content_margin_left = 20.0
	btn_style.content_margin_right = 20.0
	btn_style.content_margin_top = 8.0
	btn_style.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.pressed.connect(func() -> void:
		if mission_manager and mission_manager.has_method("claim_daily_reward"):
			mission_manager.claim_daily_reward()
		_update_display()
		var popup_close_tween := create_tween()
		popup_close_tween.tween_property(popup, "modulate:a", 0.0, 0.3)
		popup_close_tween.tween_callback(popup.queue_free)
	)
	vbox.add_child(btn)

	popup.add_child(vbox)
	add_child(popup)

	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)
	popup.pivot_offset = popup.size * 0.5
	var popup_open_tween := create_tween()
	popup_open_tween.tween_property(popup, "modulate:a", 1.0, 0.3)
	popup_open_tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_store_closed() -> void:
	_update_display()
	_update_furniture_visuals()
