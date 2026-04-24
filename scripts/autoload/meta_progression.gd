extends Node

## Manages persistent out-of-run progression: Dream Shards, permanent upgrades,
## unlockables, achievements, and daily tracking.
## Autoload singleton — access via MetaProgression anywhere.

signal shards_changed(new_total: int)
signal furniture_upgraded(furniture_id: String, new_level: int)
signal item_unlocked(item_id: String)
signal achievement_completed(achievement_id: String)

# --- Currency ---

var dream_shards: int = 0

# --- Permanent furniture upgrades ---
# furniture_id -> current_level (0 = not purchased)

var furniture_levels: Dictionary = {
	"mattress": 0,         # Max Sleep Meter buffer +5%/lvl (max 10)
	"pillow": 0,           # Base damage +3%/lvl (max 15)
	"blanket": 0,          # Damage reduction +2%/lvl (max 10)
	"nightstand_lamp": 0,  # Pickup radius +10%/lvl (max 8)
	"alarm_clock": 0,      # XP gain +5%/lvl (max 10)
	"white_noise": 0,      # Sleep Meter regen +10%/lvl (max 10)
	"slippers": 0,         # Movement speed +4%/lvl (max 8)
	"dream_journal": 0,    # Rerolls per run +1/lvl (max 3)
}

const FURNITURE_MAX_LEVELS: Dictionary = {
	"mattress": 10,
	"pillow": 15,
	"blanket": 10,
	"nightstand_lamp": 8,
	"alarm_clock": 10,
	"white_noise": 10,
	"slippers": 8,
	"dream_journal": 3,
}

const FURNITURE_BASE_COST: Dictionary = {
	"mattress": 50,
	"pillow": 30,
	"blanket": 40,
	"nightstand_lamp": 30,
	"alarm_clock": 40,
	"white_noise": 60,
	"slippers": 30,
	"dream_journal": 200,
}

# --- Unlocks ---

var unlocked_beds: Array[String] = ["standard_bed"]
var unlocked_pajamas: Array[String] = ["classic_stripes"]
var unlocked_themes: Array[String] = ["cozy_bedroom"]
var unlocked_decorations: Array[String] = []

var selected_bed: String = "standard_bed"
var selected_pajama: String = "classic_stripes"
var selected_theme: String = "cozy_bedroom"

# --- Catalog data ---

const FURNITURE_DISPLAY: Dictionary = {
	"mattress":        { "name": "Mattress",        "icon": "bed",   "desc": "+5% Sleep Meter / lvl" },
	"pillow":          { "name": "Pillow",           "icon": "star",  "desc": "+3% Damage / lvl" },
	"blanket":         { "name": "Blanket",          "icon": "shield","desc": "+2% Defense / lvl" },
	"nightstand_lamp": { "name": "Night Lamp",       "icon": "bulb",  "desc": "+10% Pickup Radius / lvl" },
	"alarm_clock":     { "name": "Alarm Clock",      "icon": "clock", "desc": "+5% XP Gain / lvl" },
	"white_noise":     { "name": "White Noise",      "icon": "wave",  "desc": "+10% Regen / lvl" },
	"slippers":        { "name": "Slippers",         "icon": "shoe",  "desc": "+4% Speed / lvl" },
	"dream_journal":   { "name": "Dream Journal",    "icon": "book",  "desc": "+1 Reroll / lvl" },
}

## In-run bed sprite paths (`standard_bed` uses legacy path at `res://art/sprites/bed_standard.png`).
const BED_TEXTURE_PATHS: Dictionary = {
	"standard_bed": "res://art/sprites/bed_standard.png",
	"cloud_bed": "res://art/sprites/beds/bed_cloud.png",
	"race_car_bed": "res://art/sprites/beds/bed_race_car.png",
	"bunk_bed": "res://art/sprites/beds/bed_bunk.png",
	"hammock": "res://art/sprites/beds/bed_hammock.png",
	"waterbed": "res://art/sprites/beds/bed_waterbed.png",
	"canopy_bed": "res://art/sprites/beds/bed_canopy.png",
	"futon": "res://art/sprites/beds/bed_futon.png",
}

## Which ability scene keys the bed starts with (order matters for manual pillow button). Must match `Game._grant_ability` keys and `BaseAbility.ability_id`.
const BED_STARTING_ABILITY_KEYS: Dictionary = {
	"standard_bed": ["pillow_toss", "snore_wave"],
	"cloud_bed": ["snore_wave"],
	"race_car_bed": ["pillow_toss"],
	"bunk_bed": ["pillow_toss", "snore_wave"],
	"hammock": ["dream_beam"],
	"waterbed": ["snore_wave"],
	"canopy_bed": ["dream_beam"],
	"futon": ["snore_wave", "pillow_toss"],
}

const BED_CATALOG: Dictionary = {
	"standard_bed":   { "name": "Standard Bed",   "desc": "A comfy starter bed.",           "cost": 0,   "perk": "" },
	"cloud_bed":      { "name": "Cloud Bed",       "desc": "Floaty and light.",              "cost": 300, "perk": "+10% Regen" },
	"race_car_bed":   { "name": "Race Car Bed",    "desc": "Vroom vroom!",                   "cost": 400, "perk": "+15% Speed" },
	"bunk_bed":       { "name": "Bunk Bed",         "desc": "Double the comfort.",            "cost": 500, "perk": "+1 Starting Ability" },
	"hammock":        { "name": "Hammock",           "desc": "Sway gently.",                  "cost": 350, "perk": "+8% Dodge Chance" },
	"waterbed":       { "name": "Water Bed",         "desc": "Ripple defense.",               "cost": 600, "perk": "AoE knockback on hit" },
	"canopy_bed":     { "name": "Canopy Bed",        "desc": "Majestic sleeping.",            "cost": 800, "perk": "+20% Dream Shards" },
	"futon":          { "name": "Futon",             "desc": "Compact and efficient.",         "cost": 250, "perk": "+5% All Stats" },
}

const PAJAMA_CATALOG: Dictionary = {
	"classic_stripes":  { "name": "Classic Stripes",  "desc": "Timeless look.",          "cost": 0,   "perk": "" },
	"starry_night":     { "name": "Starry Night",     "desc": "Painted dreams.",         "cost": 200, "perk": "+5% XP" },
	"bunny_onesie":     { "name": "Bunny Onesie",     "desc": "Hop hop!",                "cost": 250, "perk": "+8% Speed" },
	"dragon_robe":      { "name": "Dragon Robe",      "desc": "Fearsome sleeper.",        "cost": 350, "perk": "+10% Damage" },
	"invisible_pjs":    { "name": "Invisible PJs",    "desc": "Now you see me...",        "cost": 400, "perk": "-10% Aggro Range" },
	"royal_gown":       { "name": "Royal Gown",       "desc": "Sleep like royalty.",       "cost": 500, "perk": "+15% Shards" },
}

const THEME_CATALOG: Dictionary = {
	"cozy_bedroom":    { "name": "Cozy Bedroom",     "desc": "Home sweet home.",         "cost": 0 },
	"cloud_dream":     { "name": "Cloud Dream",      "desc": "Fluffy skies.",            "cost": 300 },
	"candy_sleep":     { "name": "Candy Sleep",       "desc": "Sweet dreams.",            "cost": 400 },
	"nightmare_lite":  { "name": "Nightmare Lite",    "desc": "Spooky but cute.",         "cost": 500 },
	"space_nap":       { "name": "Space Nap",         "desc": "Zero gravity rest.",       "cost": 600 },
	"underwater_doze": { "name": "Underwater Doze",   "desc": "Deep sea slumber.",        "cost": 700 },
}

# --- Achievements ---

var completed_achievements: Array[String] = []

# --- Daily tracking ---

var last_login_date: String = ""
var daily_streak: int = 0
var daily_missions_completed: Array[String] = []
var weekly_missions_completed: Array[String] = []
var runs_today: int = 0

# --- Lifetime stats ---

var total_enemies_defeated: int = 0
var total_runs: int = 0
var total_shards_earned: int = 0
var best_survival_time: float = 0.0
var best_night_reached: int = 1

## Dream Hall NPC entries (on-device). Used by `get_dream_hall_rank()` and the Dream Hall screen.
const DREAM_HALL_LEGENDS: Array[Dictionary] = [
	{"name": "Count Snoozula", "sec": 917.0},
	{"name": "Pillowton IV", "sec": 782.5},
	{"name": "REMmington Steele", "sec": 665.0},
	{"name": "Narcoleptic Ned", "sec": 542.0},
	{"name": "Sandarella", "sec": 481.0},
	{"name": "Doze Lightyear", "sec": 395.0},
	{"name": "Snorezilla", "sec": 318.0},
	{"name": "Nappuccino Sam", "sec": 267.0},
	{"name": "Light Sleeper Lou", "sec": 194.0},
	{"name": "Blink Once Bill", "sec": 121.0},
	{"name": "Wide Awake Wendy", "sec": 88.0},
]


func _ready() -> void:
	SaveManager.load_game()


# --- Shard economy ---

func add_shards(amount: int) -> void:
	var add_n: int = int(amount)
	dream_shards = int(dream_shards) + add_n
	total_shards_earned = int(total_shards_earned) + add_n
	shards_changed.emit(dream_shards)


func spend_shards(amount: int) -> bool:
	var need: int = int(amount)
	if int(dream_shards) < need:
		return false
	dream_shards = int(dream_shards) - need
	shards_changed.emit(dream_shards)
	return true


func calculate_run_shards(stats: Dictionary) -> int:
	var shards := 10  # Base reward

	# Time survived: 8 per minute
	var minutes: float = stats.get("elapsed_time", 0.0) / 60.0
	shards += int(minutes * 8.0)

	# Enemies: 5 per 50
	var kills: int = stats.get("enemies_defeated", 0)
	@warning_ignore("integer_division")
	shards += (kills / 50) * 5

	# Bosses: 25 each
	var bosses: int = stats.get("bosses_defeated", 0)
	shards += bosses * 25

	# Night milestones
	var night: int = stats.get("night_reached", 1)
	if night >= 3:
		shards += 20
	if night >= 5:
		shards += 50

	# First run of the day bonus
	if runs_today == 0:
		shards *= 2

	return shards


# --- Furniture upgrades ---

func get_furniture_cost(furniture_id: String) -> int:
	var level: int = int(furniture_levels.get(furniture_id, 0))
	var base: int = int(FURNITURE_BASE_COST.get(furniture_id, 50))
	var max_lvl: int = FURNITURE_MAX_LEVELS.get(furniture_id, 10)
	if level >= max_lvl:
		return -1  # Already maxed
	# Cost scales: base_cost * (1 + level * 0.8)
	return int(base * (1.0 + level * 0.8))


func upgrade_furniture(furniture_id: String) -> bool:
	var cost := get_furniture_cost(furniture_id)
	if cost < 0:
		return false
	if not spend_shards(cost):
		return false
	furniture_levels[furniture_id] += 1
	furniture_upgraded.emit(furniture_id, furniture_levels[furniture_id])
	SaveManager.save_game()
	return true


func get_bed_starting_ability_keys() -> Array[String]:
	var bed_id: String = selected_bed
	var raw: Variant = BED_STARTING_ABILITY_KEYS.get(bed_id, BED_STARTING_ABILITY_KEYS["standard_bed"])
	var out: Array[String] = []
	if raw is Array:
		for x: Variant in (raw as Array):
			out.append(str(x))
	else:
		out.append("pillow_toss")
	return out


func get_meta_bonuses() -> Dictionary:
	return {
		"max_sleep_buffer": 1.0 + furniture_levels["mattress"] * 0.05,
		"base_damage": 1.0 + furniture_levels["pillow"] * 0.03,
		"damage_reduction": furniture_levels["blanket"] * 0.02,
		"pickup_radius": 80.0 * (1.0 + furniture_levels["nightstand_lamp"] * 0.10),
		"xp_multiplier": 1.0 + furniture_levels["alarm_clock"] * 0.05,
		"regen_rate": 0.002 * (1.0 + furniture_levels["white_noise"] * 0.10),
		"move_speed": 200.0 * (1.0 + furniture_levels["slippers"] * 0.04),
		"rerolls": furniture_levels["dream_journal"],
	}


# --- Unlocks ---

func unlock_bed(bed_id: String) -> void:
	if bed_id not in unlocked_beds:
		unlocked_beds.append(bed_id)
		item_unlocked.emit(bed_id)
		SaveManager.save_game()


func unlock_pajama(pajama_id: String) -> void:
	if pajama_id not in unlocked_pajamas:
		unlocked_pajamas.append(pajama_id)
		item_unlocked.emit(pajama_id)
		SaveManager.save_game()


func unlock_theme(theme_id: String) -> void:
	if theme_id not in unlocked_themes:
		unlocked_themes.append(theme_id)
		item_unlocked.emit(theme_id)
		SaveManager.save_game()


func get_dream_hall_rank() -> int:
	## 1 = best (longest single-run time among You + all legends), higher number = lower placement.
	var rows: Array[Dictionary] = []
	for L in DREAM_HALL_LEGENDS:
		rows.append({"sec": float(L.get("sec", 0.0)), "is_you": false})
	rows.append({"sec": best_survival_time, "is_you": true})
	rows.sort_custom(_dream_hall_row_before)
	for i: int in rows.size():
		if bool(rows[i].get("is_you", false)):
			return i + 1
	return rows.size()


func _dream_hall_row_before(a: Dictionary, b: Dictionary) -> bool:
	var sa: float = float(a.get("sec", 0.0))
	var sb: float = float(b.get("sec", 0.0))
	if not is_equal_approx(sa, sb):
		return sa > sb
	return bool(a.get("is_you", false)) and not bool(b.get("is_you", false))


# --- Run tracking ---

func record_run(stats: Dictionary) -> int:
	total_runs += 1
	runs_today += 1
	total_enemies_defeated += stats.get("enemies_defeated", 0)

	var time: float = stats.get("elapsed_time", 0.0)
	if time > best_survival_time:
		best_survival_time = time

	var night: int = stats.get("night_reached", 1)
	if night > best_night_reached:
		best_night_reached = night

	var shards := calculate_run_shards(stats)
	add_shards(shards)
	_check_achievements(stats)
	SaveManager.save_game()
	return shards


# --- Achievements ---

func _check_achievements(_stats: Dictionary) -> void:
	var checks: Dictionary = {
		"light_sleeper": best_survival_time >= 300.0,
		"dream_warrior": total_enemies_defeated >= 10000,
		"insomniac": total_runs >= 50,
	}
	for achievement_id: String in checks:
		if checks[achievement_id] and achievement_id not in completed_achievements:
			completed_achievements.append(achievement_id)
			achievement_completed.emit(achievement_id)
