extends Node

## Tracks daily missions, weekly missions, and daily login rewards.
## Autoload singleton — access via MissionManager anywhere.

signal mission_completed(mission_id: String)
signal daily_reward_available
signal daily_reward_claimed(day: int, reward: int)

# --- Daily Missions (3 per day, reset at midnight) ---

const DAILY_MISSION_POOL: Array[Dictionary] = [
	{ "id": "survive_2min",    "name": "Survive 2 Minutes",    "desc": "Survive for 2 minutes in a run",       "goal": 120.0,  "stat": "elapsed_time",      "reward": 12 },
	{ "id": "survive_3min",    "name": "Survive 3 Minutes",    "desc": "Survive for 3 minutes in a run",       "goal": 180.0,  "stat": "elapsed_time",      "reward": 20 },
	{ "id": "survive_5min",    "name": "Survive 5 Minutes",    "desc": "Survive for 5 minutes in a run",       "goal": 300.0,  "stat": "elapsed_time",      "reward": 40 },
	{ "id": "survive_7min",    "name": "Survive 7 Minutes",    "desc": "Survive for 7 minutes in a run",       "goal": 420.0,  "stat": "elapsed_time",      "reward": 52 },
	{ "id": "survive_10min",   "name": "Survive 10 Minutes",   "desc": "Survive for 10 minutes in a run",      "goal": 600.0,  "stat": "elapsed_time",      "reward": 70 },
	{ "id": "kill_25",         "name": "Defeat 25 Enemies",    "desc": "Defeat 25 enemies in a single run",    "goal": 25.0,   "stat": "enemies_defeated",  "reward": 12 },
	{ "id": "kill_50",         "name": "Defeat 50 Enemies",    "desc": "Defeat 50 enemies in a single run",    "goal": 50.0,   "stat": "enemies_defeated",  "reward": 25 },
	{ "id": "kill_100",        "name": "Defeat 100 Enemies",   "desc": "Defeat 100 enemies in one run",        "goal": 100.0,  "stat": "enemies_defeated",  "reward": 45 },
	{ "id": "kill_150",        "name": "Defeat 150 Enemies",   "desc": "Defeat 150 enemies in one run",        "goal": 150.0,  "stat": "enemies_defeated",  "reward": 58 },
	{ "id": "reach_wave3",     "name": "Reach Wave 3",         "desc": "Reach wave 3 in a run",                "goal": 3.0,    "stat": "wave_number",       "reward": 14 },
	{ "id": "reach_wave5",     "name": "Reach Wave 5",         "desc": "Reach wave 5 in a run",                "goal": 5.0,    "stat": "wave_number",       "reward": 20 },
	{ "id": "reach_wave10",    "name": "Reach Wave 10",        "desc": "Reach wave 10 in a run",               "goal": 10.0,   "stat": "wave_number",       "reward": 35 },
	{ "id": "reach_wave15",    "name": "Reach Wave 15",        "desc": "Reach wave 15 in a run",               "goal": 15.0,   "stat": "wave_number",       "reward": 55 },
	{ "id": "play_1run",       "name": "Play 1 Run",           "desc": "Complete 1 run today",                 "goal": 1.0,    "stat": "runs_today",        "reward": 8 },
	{ "id": "play_2runs",      "name": "Play 2 Runs",          "desc": "Complete 2 runs today",                "goal": 2.0,    "stat": "runs_today",        "reward": 15 },
	{ "id": "play_3runs",      "name": "Play 3 Runs",          "desc": "Complete 3 runs today",                "goal": 3.0,    "stat": "runs_today",        "reward": 22 },
	{ "id": "play_5runs",      "name": "Play 5 Runs",          "desc": "Complete 5 runs today",                "goal": 5.0,    "stat": "runs_today",        "reward": 30 },
]

# --- Weekly Missions (3 per week) ---

const WEEKLY_MISSION_POOL: Array[Dictionary] = [
	{ "id": "w_kill_250",      "name": "250 Enemies This Week", "desc": "Defeat 250 enemies total this week",  "goal": 250.0,  "stat": "weekly_kills",      "reward": 55 },
	{ "id": "w_kill_500",      "name": "500 Enemies This Week", "desc": "Defeat 500 enemies total this week", "goal": 500.0,  "stat": "weekly_kills",      "reward": 100 },
	{ "id": "w_kill_1000",     "name": "1000 Enemies This Week", "desc": "Defeat 1,000 enemies total this week", "goal": 1000.0, "stat": "weekly_kills",    "reward": 140 },
	{ "id": "w_play_5",        "name": "5 Runs This Week",     "desc": "Complete 5 runs this week",           "goal": 5.0,    "stat": "weekly_runs",       "reward": 45 },
	{ "id": "w_play_10",       "name": "10 Runs This Week",    "desc": "Complete 10 runs this week",         "goal": 10.0,   "stat": "weekly_runs",       "reward": 80 },
	{ "id": "w_play_20",       "name": "20 Runs This Week",    "desc": "Complete 20 runs this week",         "goal": 20.0,   "stat": "weekly_runs",       "reward": 110 },
	{ "id": "w_survive_15min", "name": "15 Min Total",          "desc": "Survive 15 minutes total this week", "goal": 900.0,  "stat": "weekly_time",       "reward": 55 },
	{ "id": "w_survive_30min", "name": "30 Min Total",         "desc": "Survive 30 minutes total this week", "goal": 1800.0, "stat": "weekly_time",       "reward": 120 },
	{ "id": "w_survive_60min", "name": "60 Min Total",         "desc": "Survive 60 minutes total this week", "goal": 3600.0, "stat": "weekly_time",       "reward": 160 },
	{ "id": "w_shards_100",    "name": "Earn 100 Shards",      "desc": "Earn 100 Dream Shards this week",    "goal": 100.0,  "stat": "weekly_shards",     "reward": 40 },
	{ "id": "w_shards_200",    "name": "Earn 200 Shards",      "desc": "Earn 200 Dream Shards this week",    "goal": 200.0,  "stat": "weekly_shards",     "reward": 60 },
	{ "id": "w_shards_500",    "name": "Earn 500 Shards",      "desc": "Earn 500 Dream Shards this week",    "goal": 500.0,  "stat": "weekly_shards",     "reward": 95 },
	{ "id": "w_wave10",        "name": "Reach Wave 10",        "desc": "Reach wave 10 in a single run",      "goal": 10.0,   "stat": "wave_number",       "reward": 75 },
	{ "id": "w_wave15",        "name": "Reach Wave 15",        "desc": "Reach wave 15 in a single run",      "goal": 15.0,   "stat": "wave_number",       "reward": 90 },
	{ "id": "w_wave20",        "name": "Reach Wave 20",        "desc": "Reach wave 20 in a single run",      "goal": 20.0,   "stat": "wave_number",       "reward": 115 },
]

# --- Daily Login Rewards (7-day cycle) ---

const DAILY_REWARDS: Array[int] = [10, 15, 20, 25, 30, 40, 75]

# --- State ---

var active_daily_missions: Array[Dictionary] = []
var active_weekly_missions: Array[Dictionary] = []
var daily_reward_claimed_today: bool = false
## Calendar date when the login daily reward was last claimed (prevents stale flags across days).
var daily_reward_claim_date: String = ""
## Calendar date (YYYY-MM-DD) when daily missions were last rolled; not tied to MetaProgression login.
var daily_missions_reset_date: String = ""

# Weekly tracking
var weekly_kills: int = 0
var weekly_runs: int = 0
var weekly_time: float = 0.0
var weekly_shards: int = 0
var week_start_date: String = ""


func _ready() -> void:
	_load_state()
	_sync_daily_login_reward_for_calendar()
	_check_daily_reset()
	_check_weekly_reset()
	_ensure_missions_active()


func check_run_missions(stats: Dictionary) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []

	# Update weekly trackers
	weekly_kills += stats.get("enemies_defeated", 0)
	weekly_runs += 1
	weekly_time += stats.get("elapsed_time", 0.0)
	weekly_shards += MetaProgression.calculate_run_shards(stats)

	# Check daily missions
	for mission in active_daily_missions:
		if mission.get("claimed", false):
			continue
		var stat_key: String = mission["stat"]
		var value: float = 0.0
		if stat_key == "runs_today":
			value = float(MetaProgression.runs_today)
		elif stat_key in stats:
			value = float(stats[stat_key])
		if value >= mission["goal"]:
			mission["progress"] = mission["goal"]
			mission["complete"] = true
		else:
			mission["progress"] = value
			mission["complete"] = false

	# Check weekly missions
	for mission in active_weekly_missions:
		if mission.get("claimed", false):
			continue
		var stat_key: String = mission["stat"]
		var value: float = 0.0
		match stat_key:
			"weekly_kills": value = float(weekly_kills)
			"weekly_runs": value = float(weekly_runs)
			"weekly_time": value = weekly_time
			"weekly_shards": value = float(weekly_shards)
			_:
				if stat_key in stats:
					value = float(stats[stat_key])
		if value >= mission["goal"]:
			mission["progress"] = mission["goal"]
			mission["complete"] = true
		else:
			mission["progress"] = value
			mission["complete"] = false

	_save_state()
	return completed


func claim_mission(mission_id: String) -> int:
	for mission in active_daily_missions + active_weekly_missions:
		if mission["id"] == mission_id and mission.get("complete", false) and not mission.get("claimed", false):
			mission["claimed"] = true
			var reward: int = mission["reward"]
			MetaProgression.add_shards(reward)
			mission_completed.emit(mission_id)
			_save_state()
			SaveManager.save_game()
			return reward
	return 0


func claim_all_completed_missions() -> int:
	var total: int = 0
	var claimed_any := false
	for mission in active_daily_missions + active_weekly_missions:
		if mission.get("complete", false) and not mission.get("claimed", false):
			mission["claimed"] = true
			total += int(mission.get("reward", 0))
			MetaProgression.add_shards(int(mission.get("reward", 0)))
			mission_completed.emit(str(mission["id"]))
			claimed_any = true
	if claimed_any:
		_save_state()
		SaveManager.save_game()
	return total


func claim_daily_reward() -> int:
	if daily_reward_claimed_today:
		return 0
	daily_reward_claimed_today = true
	daily_reward_claim_date = Time.get_date_string_from_system()
	var day_index := (MetaProgression.daily_streak - 1) % DAILY_REWARDS.size()
	if day_index < 0:
		day_index = 0
	var reward := DAILY_REWARDS[day_index]
	MetaProgression.add_shards(reward)
	daily_reward_claimed.emit(day_index + 1, reward)
	_save_state()
	SaveManager.save_game()
	return reward


func get_daily_reward_amount() -> int:
	var day_index := (MetaProgression.daily_streak - 1) % DAILY_REWARDS.size()
	if day_index < 0:
		day_index = 0
	return DAILY_REWARDS[day_index]


func get_all_missions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append_array(active_daily_missions)
	result.append_array(active_weekly_missions)
	return result


# --- Internal ---

func _ensure_missions_active() -> void:
	if active_daily_missions.is_empty():
		_roll_daily_missions()
	if active_weekly_missions.is_empty():
		_roll_weekly_missions()


func _roll_daily_missions() -> void:
	active_daily_missions.clear()
	var pool := DAILY_MISSION_POOL.duplicate()
	pool.shuffle()
	for i in mini(3, pool.size()):
		var mission: Dictionary = pool[i].duplicate()
		mission["progress"] = 0.0
		mission["complete"] = false
		mission["claimed"] = false
		mission["is_weekly"] = false
		active_daily_missions.append(mission)


func _roll_weekly_missions() -> void:
	active_weekly_missions.clear()
	var pool := WEEKLY_MISSION_POOL.duplicate()
	pool.shuffle()
	for i in mini(3, pool.size()):
		var mission: Dictionary = pool[i].duplicate()
		mission["progress"] = 0.0
		mission["complete"] = false
		mission["claimed"] = false
		mission["is_weekly"] = true
		active_weekly_missions.append(mission)


func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if daily_missions_reset_date == today:
		return
	_roll_daily_missions()
	daily_reward_available.emit()
	daily_missions_reset_date = today
	_save_state()


func _sync_daily_login_reward_for_calendar() -> void:
	var today := Time.get_date_string_from_system()
	if daily_reward_claim_date.is_empty():
		if daily_reward_claimed_today:
			daily_reward_claim_date = today
			_save_state()
		return
	if daily_reward_claim_date != today:
		daily_reward_claimed_today = false


func _check_weekly_reset() -> void:
	var today := Time.get_date_string_from_system()
	var dict := Time.get_datetime_dict_from_system()
	var weekday: int = dict.get("weekday", 0)
	# Reset weekly on Monday (weekday 1)
	if week_start_date == "":
		week_start_date = today
	# Simple check: if it's been 7+ days
	if weekday == 1 and week_start_date != today:
		weekly_kills = 0
		weekly_runs = 0
		weekly_time = 0.0
		weekly_shards = 0
		week_start_date = today
		_roll_weekly_missions()
		_save_state()


func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("missions", "daily", active_daily_missions)
	config.set_value("missions", "weekly", active_weekly_missions)
	config.set_value("missions", "daily_reward_claimed", daily_reward_claimed_today)
	config.set_value("missions", "daily_reward_claim_date", daily_reward_claim_date)
	config.set_value("missions", "weekly_kills", weekly_kills)
	config.set_value("missions", "weekly_runs", weekly_runs)
	config.set_value("missions", "weekly_time", weekly_time)
	config.set_value("missions", "weekly_shards", weekly_shards)
	config.set_value("missions", "week_start_date", week_start_date)
	config.set_value("missions", "daily_missions_reset_date", daily_missions_reset_date)
	config.save("user://missions.cfg")


func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load("user://missions.cfg") != OK:
		return
	active_daily_missions = config.get_value("missions", "daily", [])
	active_weekly_missions = config.get_value("missions", "weekly", [])
	daily_reward_claimed_today = config.get_value("missions", "daily_reward_claimed", false)
	daily_reward_claim_date = config.get_value("missions", "daily_reward_claim_date", "")
	weekly_kills = config.get_value("missions", "weekly_kills", 0)
	weekly_runs = config.get_value("missions", "weekly_runs", 0)
	weekly_time = config.get_value("missions", "weekly_time", 0.0)
	weekly_shards = config.get_value("missions", "weekly_shards", 0)
	week_start_date = config.get_value("missions", "week_start_date", "")
	daily_missions_reset_date = config.get_value("missions", "daily_missions_reset_date", "")
