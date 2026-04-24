extends Control

## Missions & Achievements panel — daily rewards, mission list, achievements.

signal closed

enum Tab { DAILY_REWARD, MISSIONS, ACHIEVEMENTS }

@onready var back_btn: Button = $Panel/Layout/TopBar/BackButton
@onready var tab_container: HBoxContainer = $Panel/Layout/TabBar
@onready var scroll: ScrollContainer = $Panel/Layout/Scroll
@onready var item_list: VBoxContainer = $Panel/Layout/Scroll/ItemList
@onready var panel: PanelContainer = $Panel
@onready var _mission_manager: Node = get_node_or_null("/root/MissionManager")

var _active_tab: Tab = Tab.DAILY_REWARD
var _tab_buttons: Array[Button] = []

const TAB_NAMES: Array[String] = ["Daily", "Missions", "Achievements"]


func _ready() -> void:
	visible = false
	back_btn.pressed.connect(func() -> void: visible = false; closed.emit())
	_build_tab_buttons()


func show_panel() -> void:
	visible = true
	_switch_tab(Tab.DAILY_REWARD)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _build_tab_buttons() -> void:
	for child in tab_container.get_children():
		child.queue_free()
	_tab_buttons.clear()

	for i in TAB_NAMES.size():
		var btn := Button.new()
		btn.text = TAB_NAMES[i]
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)

		var style := StyleBoxFlat.new()
		style.bg_color = UIPalette.NIGHT_NAVY
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

		btn.pressed.connect(_switch_tab.bind(i as int))
		tab_container.add_child(btn)
		_tab_buttons.append(btn)


func _switch_tab(tab: int) -> void:
	_active_tab = tab as Tab
	_highlight_active_tab()
	_populate_tab()


func _highlight_active_tab() -> void:
	for i in _tab_buttons.size():
		var style := _tab_buttons[i].get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if i == _active_tab:
			style.bg_color = UIPalette.SURFACE
			_tab_buttons[i].add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
		else:
			style.bg_color = UIPalette.NIGHT_NAVY
			_tab_buttons[i].add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		_tab_buttons[i].add_theme_stylebox_override("normal", style)


func _populate_tab() -> void:
	for child in item_list.get_children():
		child.queue_free()

	match _active_tab:
		Tab.DAILY_REWARD:
			_populate_daily_reward()
		Tab.MISSIONS:
			_populate_missions()
		Tab.ACHIEVEMENTS:
			_populate_achievements()


# --- Daily Reward ---

func _populate_daily_reward() -> void:
	var streak := MetaProgression.daily_streak
	var claimed: bool = _mission_manager.daily_reward_claimed_today if _mission_manager else false

	var header := Label.new()
	header.text = "Day %d Streak" % streak
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_list.add_child(header)

	var daily_rewards: Array = _mission_manager.DAILY_REWARDS if _mission_manager else [10, 15, 20, 25, 30, 40, 50]
	for i in daily_rewards.size():
		var day := i + 1
		var reward: int = daily_rewards[i]
		var is_today := (streak % 7 == day % 7) if streak > 0 else (day == 1)
		var is_past := (day < ((streak - 1) % 7) + 1) if streak > 0 else false

		var card := _create_card()
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var day_label := Label.new()
		day_label.text = "Day %d" % day
		day_label.add_theme_font_size_override("font_size", 20)
		day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_today and not claimed:
			day_label.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
		elif is_past or (is_today and claimed):
			day_label.add_theme_color_override("font_color", UIPalette.SUCCESS)
		else:
			day_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		hbox.add_child(day_label)

		var reward_label := Label.new()
		reward_label.text = "+%d Shards" % reward
		reward_label.add_theme_font_size_override("font_size", 20)
		reward_label.add_theme_color_override("font_color", UIPalette.MOON_GOLD if is_today else UIPalette.TEXT_MUTED)
		hbox.add_child(reward_label)

		if is_today and not claimed:
			var claim_btn := Button.new()
			claim_btn.text = "Claim!"
			claim_btn.add_theme_font_size_override("font_size", 20)
			claim_btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD)

			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = UIPalette.SURFACE_HOVER
			btn_style.corner_radius_top_left = 6
			btn_style.corner_radius_top_right = 6
			btn_style.corner_radius_bottom_right = 6
			btn_style.corner_radius_bottom_left = 6
			btn_style.content_margin_left = 12.0
			btn_style.content_margin_right = 12.0
			btn_style.content_margin_top = 4.0
			btn_style.content_margin_bottom = 4.0
			claim_btn.add_theme_stylebox_override("normal", btn_style)
			claim_btn.add_theme_stylebox_override("hover", btn_style)
			claim_btn.add_theme_stylebox_override("pressed", btn_style)
			claim_btn.pressed.connect(func() -> void:
				if _mission_manager and _mission_manager.has_method("claim_daily_reward"):
					_mission_manager.claim_daily_reward()
				_populate_tab()
			)
			hbox.add_child(claim_btn)

		card.add_child(hbox)
		item_list.add_child(card)


# --- Missions ---

func _populate_missions() -> void:
	var all_missions: Array = []
	if _mission_manager and _mission_manager.has_method("get_all_missions"):
		all_missions = _mission_manager.get_all_missions()

	if all_missions.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active missions. Play a run!"
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(empty_label)
		return

	if _has_claimable_missions():
		item_list.add_child(_create_claim_all_row())

	for mission in all_missions:
		var card := _create_card()
		var outer_hbox := HBoxContainer.new()
		outer_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer_hbox.add_theme_constant_override("separation", 10)

		var is_complete: bool = mission.get("complete", false)
		var is_claimed: bool = mission.get("claimed", false)
		var is_weekly: bool = mission.get("is_weekly", false)

		var icon_label := Label.new()
		if is_claimed:
			icon_label.text = "[OK]"
			icon_label.add_theme_color_override("font_color", UIPalette.SUCCESS)
		elif is_complete:
			icon_label.text = "[!]"
			icon_label.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
		elif is_weekly:
			icon_label.text = "[W]"
			icon_label.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
		else:
			icon_label.text = "[D]"
			icon_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)

		icon_label.add_theme_font_size_override("font_size", 20)
		icon_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_label.custom_minimum_size = Vector2(52, 52)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		outer_hbox.add_child(icon_label)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var top_row := HBoxContainer.new()
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = mission.get("name", "???")
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", UIPalette.SUCCESS if is_complete else UIPalette.TEXT_PRIMARY)
		top_row.add_child(name_label)

		var tag_label := Label.new()
		tag_label.text = "Weekly" if is_weekly else "Daily"
		tag_label.add_theme_font_size_override("font_size", 16)
		tag_label.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET if is_weekly else UIPalette.TEXT_MUTED)
		top_row.add_child(tag_label)

		vbox.add_child(top_row)

		var desc_label := Label.new()
		desc_label.text = mission.get("desc", "")
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		vbox.add_child(desc_label)

		var progress_row := HBoxContainer.new()
		var progress: float = mission.get("progress", 0.0)
		var goal: float = mission.get("goal", 1.0)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 24)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.max_value = goal
		bar.value = minf(progress, goal)
		bar.show_percentage = false

		var bar_bg := StyleBoxFlat.new()
		var bg_color := UIPalette.NIGHT_NAVY
		bg_color.a = 0.8
		bar_bg.bg_color = bg_color
		bar_bg.corner_radius_top_left = 3
		bar_bg.corner_radius_top_right = 3
		bar_bg.corner_radius_bottom_right = 3
		bar_bg.corner_radius_bottom_left = 3
		bar.add_theme_stylebox_override("background", bar_bg)

		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = UIPalette.SUCCESS if is_complete else UIPalette.DREAM_VIOLET
		bar_fill.corner_radius_top_left = 3
		bar_fill.corner_radius_top_right = 3
		bar_fill.corner_radius_bottom_right = 3
		bar_fill.corner_radius_bottom_left = 3
		bar.add_theme_stylebox_override("fill", bar_fill)
		progress_row.add_child(bar)

		var pct_label := Label.new()
		pct_label.text = " %d/%d" % [int(minf(progress, goal)), int(goal)]
		pct_label.add_theme_font_size_override("font_size", 16)
		pct_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		progress_row.add_child(pct_label)

		vbox.add_child(progress_row)

		var bottom_row := HBoxContainer.new()
		var reward_label := Label.new()
		reward_label.text = "+%d Shards" % mission.get("reward", 0)
		reward_label.add_theme_font_size_override("font_size", 16)
		reward_label.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
		reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_row.add_child(reward_label)

		if is_complete and not is_claimed:
			var claim_btn := Button.new()
			claim_btn.text = "Claim"
			claim_btn.add_theme_font_size_override("font_size", 16)
			claim_btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD)

			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = UIPalette.SURFACE_HOVER
			btn_style.corner_radius_top_left = 6
			btn_style.corner_radius_top_right = 6
			btn_style.corner_radius_bottom_right = 6
			btn_style.corner_radius_bottom_left = 6
			btn_style.content_margin_left = 10.0
			btn_style.content_margin_right = 10.0
			btn_style.content_margin_top = 4.0
			btn_style.content_margin_bottom = 4.0
			claim_btn.add_theme_stylebox_override("normal", btn_style)
			claim_btn.add_theme_stylebox_override("hover", btn_style)
			claim_btn.add_theme_stylebox_override("pressed", btn_style)

			var mid: String = mission.get("id", "")
			claim_btn.pressed.connect(func() -> void:
				if _mission_manager and _mission_manager.has_method("claim_mission"):
					_mission_manager.claim_mission(mid)
				_populate_tab()
			)
			bottom_row.add_child(claim_btn)
		elif is_claimed:
			var done_label := Label.new()
			done_label.text = "Claimed"
			done_label.add_theme_font_size_override("font_size", 16)
			done_label.add_theme_color_override("font_color", UIPalette.SUCCESS)
			bottom_row.add_child(done_label)

		vbox.add_child(bottom_row)
		outer_hbox.add_child(vbox)
		card.add_child(outer_hbox)
		item_list.add_child(card)


func _has_claimable_missions() -> bool:
	if _mission_manager == null or not _mission_manager.has_method("get_all_missions"):
		return false
	for mission: Variant in _mission_manager.get_all_missions():
		if mission is Dictionary:
			var d: Dictionary = mission
			if bool(d.get("complete", false)) and not bool(d.get("claimed", false)):
				return true
	return false


func _create_claim_all_row() -> PanelContainer:
	var card := _create_card()
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = "Rewards ready!"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	var claim_all_btn := Button.new()
	claim_all_btn.text = "Claim all"
	claim_all_btn.add_theme_font_size_override("font_size", 20)
	claim_all_btn.add_theme_color_override("font_color", UIPalette.MOON_GOLD)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = UIPalette.SURFACE_HOVER
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.content_margin_left = 18.0
	btn_style.content_margin_right = 18.0
	btn_style.content_margin_top = 10.0
	btn_style.content_margin_bottom = 10.0
	claim_all_btn.add_theme_stylebox_override("normal", btn_style)
	claim_all_btn.add_theme_stylebox_override("hover", btn_style)
	claim_all_btn.add_theme_stylebox_override("pressed", btn_style)
	claim_all_btn.pressed.connect(func() -> void:
		var gained: int = 0
		if _mission_manager and _mission_manager.has_method("claim_all_completed_missions"):
			gained = _mission_manager.claim_all_completed_missions()
		if gained > 0:
			AudioManager.play_ui_by_name("purchase")
		_populate_tab()
	)
	hbox.add_child(claim_all_btn)

	card.add_child(hbox)
	return card


# --- Achievements ---

func _populate_achievements() -> void:
	var all_checks: Array[Dictionary] = [
		{ "id": "first_sleep",     "name": "First Sleep",        "desc": "Complete your first run",             "check": MetaProgression.total_runs >= 1 },
		{ "id": "light_sleeper",   "name": "Light Sleeper",      "desc": "Survive 5 minutes in a single run",  "check": MetaProgression.best_survival_time >= 300.0 },
		{ "id": "deep_dreamer",    "name": "Deep Dreamer",       "desc": "Survive 10 minutes in a single run", "check": MetaProgression.best_survival_time >= 600.0 },
		{ "id": "insomniac",       "name": "Insomniac",          "desc": "Complete 50 runs",                   "check": MetaProgression.total_runs >= 50 },
		{ "id": "enemy_100",       "name": "Pest Control",       "desc": "Defeat 100 enemies total",           "check": MetaProgression.total_enemies_defeated >= 100 },
		{ "id": "enemy_1000",      "name": "Exterminator",       "desc": "Defeat 1,000 enemies total",         "check": MetaProgression.total_enemies_defeated >= 1000 },
		{ "id": "dream_warrior",   "name": "Dream Warrior",      "desc": "Defeat 10,000 enemies total",        "check": MetaProgression.total_enemies_defeated >= 10000 },
		{ "id": "shard_hoarder",   "name": "Shard Hoarder",      "desc": "Earn 1,000 Dream Shards total",      "check": MetaProgression.total_shards_earned >= 1000 },
		{ "id": "shard_mogul",     "name": "Shard Mogul",        "desc": "Earn 10,000 Dream Shards total",     "check": MetaProgression.total_shards_earned >= 10000 },
		{ "id": "streak_7",        "name": "Week Warrior",       "desc": "Achieve a 7-day login streak",       "check": MetaProgression.daily_streak >= 7 },
		{ "id": "night_3",         "name": "REM Reached",        "desc": "Reach Night 3 (REM Phase)",          "check": MetaProgression.best_night_reached >= 3 },
		{ "id": "night_5",         "name": "The Alarm Survived", "desc": "Reach Night 5 (The Alarm)",          "check": MetaProgression.best_night_reached >= 5 },
	]

	for ach in all_checks:
		var is_done: bool = ach["check"]
		var card := _create_card()
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = ach["name"]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", UIPalette.MOON_GOLD if is_done else UIPalette.TEXT_PRIMARY)
		left.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ach["desc"]
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		left.add_child(desc_label)

		hbox.add_child(left)

		var status := Label.new()
		if is_done:
			status.text = "Done"
			status.add_theme_color_override("font_color", UIPalette.SUCCESS)
		else:
			status.text = "..."
			status.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		status.add_theme_font_size_override("font_size", 20)
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(status)

		card.add_child(hbox)
		item_list.add_child(card)


# --- Helpers ---

func _create_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 22.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	card.add_theme_stylebox_override("panel", style)

	return card
