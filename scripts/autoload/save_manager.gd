extends Node

## Handles save/load with encryption for persistent game data.
## Autoload singleton — access via SaveManager anywhere.

const SAVE_PATH := "user://save_data.cfg"
const ENV_PATH := "res://.env"
const DEFAULT_SAVE_ENCRYPTION_KEY := "five_more_minutes_2026_sleep_tight"

var _config := ConfigFile.new()
var _encryption_key: String = ""


func _ready() -> void:
	_encryption_key = _load_save_encryption_key_from_env()
	if _encryption_key.is_empty():
		_encryption_key = DEFAULT_SAVE_ENCRYPTION_KEY


func save_game() -> void:
	var meta := MetaProgression

	# Currency
	_config.set_value("currency", "dream_shards", meta.dream_shards)

	# Furniture levels
	for key: String in meta.furniture_levels:
		_config.set_value("furniture", key, meta.furniture_levels[key])

	# Unlocks
	_config.set_value("unlocks", "beds", meta.unlocked_beds)
	_config.set_value("unlocks", "pajamas", meta.unlocked_pajamas)
	_config.set_value("unlocks", "themes", meta.unlocked_themes)
	_config.set_value("unlocks", "decorations", meta.unlocked_decorations)

	# Selections
	_config.set_value("selection", "bed", meta.selected_bed)
	_config.set_value("selection", "pajama", meta.selected_pajama)
	_config.set_value("selection", "theme", meta.selected_theme)

	# Achievements
	_config.set_value("achievements", "completed", meta.completed_achievements)

	# Daily tracking
	_config.set_value("daily", "last_login_date", meta.last_login_date)
	_config.set_value("daily", "streak", meta.daily_streak)
	_config.set_value("daily", "missions_completed", meta.daily_missions_completed)
	_config.set_value("daily", "weekly_missions_completed", meta.weekly_missions_completed)
	_config.set_value("daily", "runs_today", meta.runs_today)

	# Lifetime stats
	_config.set_value("stats", "total_enemies_defeated", meta.total_enemies_defeated)
	_config.set_value("stats", "total_runs", meta.total_runs)
	_config.set_value("stats", "total_shards_earned", meta.total_shards_earned)
	_config.set_value("stats", "best_survival_time", meta.best_survival_time)
	_config.set_value("stats", "best_night_reached", meta.best_night_reached)

	var err := _config.save_encrypted_pass(SAVE_PATH, _encryption_key)
	if err != OK:
		push_warning("SaveManager: Failed to save game data (error %d)" % err)


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var err := _config.load_encrypted_pass(SAVE_PATH, _encryption_key)
	if err != OK:
		push_warning("SaveManager: Failed to load save data (error %d). Starting fresh." % err)
		return

	var meta := MetaProgression

	# Currency (must be int: String vs int `>=` uses lexicographic order and breaks store affordability)
	meta.dream_shards = _coerce_int_value(_config.get_value("currency", "dream_shards", 0))

	# Furniture levels
	for key: String in meta.furniture_levels:
		meta.furniture_levels[key] = _coerce_int_value(_config.get_value("furniture", key, 0))

	# Unlocks
	meta.unlocked_beds = _config.get_value("unlocks", "beds", ["standard_bed"])
	meta.unlocked_pajamas = _config.get_value("unlocks", "pajamas", ["classic_stripes"])
	meta.unlocked_themes = _config.get_value("unlocks", "themes", ["cozy_bedroom"])
	meta.unlocked_decorations = _config.get_value("unlocks", "decorations", [])

	# Selections
	meta.selected_bed = _config.get_value("selection", "bed", "standard_bed")
	meta.selected_pajama = _config.get_value("selection", "pajama", "classic_stripes")
	meta.selected_theme = _config.get_value("selection", "theme", "cozy_bedroom")

	# Achievements
	meta.completed_achievements = _config.get_value("achievements", "completed", [])

	# Daily tracking
	meta.last_login_date = _config.get_value("daily", "last_login_date", "")
	meta.daily_streak = _coerce_int_value(_config.get_value("daily", "streak", 0))
	meta.daily_missions_completed = _config.get_value("daily", "missions_completed", [])
	meta.weekly_missions_completed = _config.get_value("daily", "weekly_missions_completed", [])
	meta.runs_today = _coerce_int_value(_config.get_value("daily", "runs_today", 0))

	# Lifetime stats
	meta.total_enemies_defeated = _coerce_int_value(_config.get_value("stats", "total_enemies_defeated", 0))
	meta.total_runs = _coerce_int_value(_config.get_value("stats", "total_runs", 0))
	meta.total_shards_earned = _coerce_int_value(_config.get_value("stats", "total_shards_earned", 0))
	meta.best_survival_time = float(_config.get_value("stats", "best_survival_time", 0.0))
	meta.best_night_reached = _coerce_int_value(_config.get_value("stats", "best_night_reached", 1))

	_check_daily_reset()


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _coerce_int_value(v: Variant) -> int:
	if v is int:
		return v as int
	if v is float:
		return int(v)
	if v is String:
		var s: String = v
		if s.is_valid_int():
			return s.to_int()
		if s.is_valid_float():
			return int(s.to_float())
		return 0
	return int(v)


func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	var meta := MetaProgression
	if meta.last_login_date != today:
		if meta.last_login_date == _get_yesterday():
			meta.daily_streak += 1
		else:
			meta.daily_streak = 1 if meta.last_login_date != "" else 0
		meta.last_login_date = today
		meta.runs_today = 0
		meta.daily_missions_completed.clear()
		save_game()


func _get_yesterday() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	var dict := Time.get_date_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]


# --- .env ---

func _load_save_encryption_key_from_env() -> String:
	if not FileAccess.file_exists(ENV_PATH):
		return ""
	var file := FileAccess.open(ENV_PATH, FileAccess.READ)
	if file == null:
		return ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var eq := line.find("=")
		if eq < 1:
			continue
		var key := line.substr(0, eq).strip_edges()
		var val := line.substr(eq + 1).strip_edges()
		if key == "SAVE_ENCRYPTION_KEY":
			return val
	return ""
