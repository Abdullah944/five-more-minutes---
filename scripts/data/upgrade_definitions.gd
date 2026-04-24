class_name UpgradeDefinitions
extends RefCounted

## All in-run upgrades defined as dictionaries.
## Categories: SLEEP_STRENGTH (damage), CALMNESS (defense), COMFORT (utility)

enum Category { SLEEP_STRENGTH, CALMNESS, COMFORT }
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const CATEGORY_COLORS: Dictionary = {
	Category.SLEEP_STRENGTH: Color(0.9, 0.4, 0.4, 1),
	Category.CALMNESS: Color(0.4, 0.6, 0.9, 1),
	Category.COMFORT: Color(0.4, 0.85, 0.55, 1),
}

const CATEGORY_NAMES: Dictionary = {
	Category.SLEEP_STRENGTH: "Sleep Strength",
	Category.CALMNESS: "Calmness",
	Category.COMFORT: "Comfort",
}

const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.8, 0.8, 0.8, 1),
	Rarity.UNCOMMON: Color(0.4, 0.85, 0.4, 1),
	Rarity.RARE: Color(0.6, 0.4, 0.9, 1),
	Rarity.LEGENDARY: Color(1.0, 0.8, 0.2, 1),
}

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.UNCOMMON: "Uncommon",
	Rarity.RARE: "Rare",
	Rarity.LEGENDARY: "Legendary",
}

## Card art for level-up picker (`res://` paths). Fallback per category if id missing.
const CATEGORY_ICONS: Dictionary = {
	Category.SLEEP_STRENGTH: "res://art/ui/hud_sleep_moon.png",
	Category.CALMNESS: "res://art/sprites/effects/snore_wave.png",
	Category.COMFORT: "res://art/sprites/pickup_sleep_energy.png",
}

const UPGRADE_ICONS: Dictionary = {
	"heavy_sleeper": "res://art/sprites/bed_standard.png",
	"bigger_pillow": "res://art/sprites/effects/pillow_projectile.png",
	"rem_burst": "res://art/sprites/effects/dream_beam.png",
	"nightmare_fuel": "res://art/sprites/enemy_alarm_clock.png",
	"oversleep": "res://art/ui/hud_sleep_moon.png",
	"thick_blanket": "res://art/sprites/hub/mattress.png",
	"slow_breathing": "res://art/sprites/hub/white_noise.png",
	"sleep_shield": "res://art/sprites/effects/snore_wave.png",
	"memory_foam": "res://art/sprites/hub/slippers.png",
	"hibernation": "res://art/sprites/pickup_warm_milk.png",
	"long_arms": "res://art/sprites/pickup_sleep_energy.png",
	"speed_nap": "res://art/sprites/hub/slippers.png",
	"restful_sleep": "res://art/sprites/pickup_sleep_energy.png",
	"magnet_pillow": "res://art/sprites/effects/pillow_projectile.png",
	"lucid_dreamer": "res://art/sprites/hub/dream_journal.png",
	"unlock_night_light": "res://art/sprites/hub/night_lamp.png",
	"dream_milk_artist": "res://art/sprites/pickup_warm_milk.png",
	"evo_sleep_paralysis": "res://art/sprites/hub/white_noise.png",
}


static func resolve_icon_path(upgrade: Dictionary) -> String:
	var uid: String = upgrade.get("id", "") as String
	if UPGRADE_ICONS.has(uid):
		return UPGRADE_ICONS[uid] as String
	var cat: int = upgrade.get("category", Category.SLEEP_STRENGTH) as int
	return CATEGORY_ICONS.get(cat, CATEGORY_ICONS[Category.SLEEP_STRENGTH]) as String


static var ALL_UPGRADES: Array[Dictionary] = [
	# --- SLEEP STRENGTH (damage) ---
	{
		"id": "heavy_sleeper",
		"name": "Heavy Sleeper",
		"desc": "+15% damage per stack",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.COMMON,
		"max_stack": 5,
		"stat": "base_damage",
		"per_stack": 0.15,
		"mode": "multiply",
	},
	{
		"id": "bigger_pillow",
		"name": "Bigger Pillow",
		"desc": "+20% projectile damage",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.UNCOMMON,
		"max_stack": 4,
		"stat": "base_damage",
		"per_stack": 0.20,
		"mode": "multiply",
	},
	{
		"id": "rem_burst",
		"name": "R.E.M. Burst",
		"desc": "+25% AoE radius",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "aoe_bonus",
		"per_stack": 0.25,
		"mode": "multiply",
	},
	{
		"id": "nightmare_fuel",
		"name": "Nightmare Fuel",
		"desc": "+10% damage, +5% meter vulnerability",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "base_damage",
		"per_stack": 0.10,
		"mode": "multiply",
	},
	{
		"id": "oversleep",
		"name": "Oversleep",
		"desc": "+30% damage in Deep Sleep zone",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.LEGENDARY,
		"max_stack": 2,
		"stat": "deep_sleep_damage",
		"per_stack": 0.30,
		"mode": "multiply",
	},

	# --- CALMNESS (defense) ---
	{
		"id": "thick_blanket",
		"name": "Thick Blanket",
		"desc": "+5% damage reduction per stack",
		"category": Category.CALMNESS,
		"rarity": Rarity.COMMON,
		"max_stack": 5,
		"stat": "damage_reduction",
		"per_stack": 0.05,
		"mode": "add",
	},
	{
		"id": "slow_breathing",
		"name": "Slow Breathing",
		"desc": "+20% Sleep Meter regen",
		"category": Category.CALMNESS,
		"rarity": Rarity.UNCOMMON,
		"max_stack": 4,
		"stat": "regen_rate",
		"per_stack": 0.20,
		"mode": "multiply",
	},
	{
		"id": "sleep_shield",
		"name": "Sleep Shield",
		"desc": "Block 1 hit every 15s",
		"category": Category.CALMNESS,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "shield_charges",
		"per_stack": 1,
		"mode": "add",
	},
	{
		"id": "memory_foam",
		"name": "Memory Foam",
		"desc": "-10% enemy speed near sleepy head",
		"category": Category.CALMNESS,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "enemy_slow_aura",
		"per_stack": 0.10,
		"mode": "add",
	},
	{
		"id": "hibernation",
		"name": "Hibernation",
		"desc": "+40% regen when below 25% meter",
		"category": Category.CALMNESS,
		"rarity": Rarity.LEGENDARY,
		"max_stack": 2,
		"stat": "low_meter_regen",
		"per_stack": 0.40,
		"mode": "multiply",
	},

	# --- COMFORT (utility) ---
	{
		"id": "long_arms",
		"name": "Long Arms",
		"desc": "+20% pickup radius",
		"category": Category.COMFORT,
		"rarity": Rarity.COMMON,
		"max_stack": 5,
		"stat": "pickup_radius",
		"per_stack": 0.20,
		"mode": "multiply",
	},
	{
		"id": "speed_nap",
		"name": "Speed Nap",
		"desc": "+10% move speed",
		"category": Category.COMFORT,
		"rarity": Rarity.COMMON,
		"max_stack": 5,
		"stat": "move_speed",
		"per_stack": 0.10,
		"mode": "multiply",
	},
	{
		"id": "restful_sleep",
		"name": "Restful Sleep",
		"desc": "+15% XP gain",
		"category": Category.COMFORT,
		"rarity": Rarity.UNCOMMON,
		"max_stack": 4,
		"stat": "xp_multiplier",
		"per_stack": 0.15,
		"mode": "multiply",
	},
	{
		"id": "magnet_pillow",
		"name": "Magnet Pillow",
		"desc": "+30% pickup radius, +10% attract speed",
		"category": Category.COMFORT,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "pickup_radius",
		"per_stack": 0.30,
		"mode": "multiply",
	},
	{
		"id": "lucid_dreamer",
		"name": "Lucid Dreamer",
		"desc": "-10% ability cooldowns",
		"category": Category.COMFORT,
		"rarity": Rarity.LEGENDARY,
		"max_stack": 3,
		"stat": "cooldown_reduction",
		"per_stack": 0.10,
		"mode": "add",
	},
	{
		"id": "unlock_night_light",
		"kind": "unlock_ability",
		"ability_key": "night_light",
		"name": "Night Light",
		"desc": "Soft aura: slows enemies near the bed. Stacks increase slow strength.",
		"category": Category.CALMNESS,
		"rarity": Rarity.RARE,
		"max_stack": 1,
		"stat": "",
		"per_stack": 0.0,
		"mode": "add",
	},
	{
		"id": "dream_milk_artist",
		"kind": "stat",
		"name": "Dream Catcher",
		"desc": "Defeated enemies have a 15% chance per stack to drop warm milk (max 45%).",
		"category": Category.COMFORT,
		"rarity": Rarity.RARE,
		"max_stack": 3,
		"stat": "dream_milk_drop_chance",
		"per_stack": 0.15,
		"mode": "add",
	},
]

## Fourth-card evolution offers (separate from normal stat table).
static var EVOLUTIONS: Array[Dictionary] = [
	{
		"id": "evo_sleep_paralysis",
		"kind": "evolution",
		"name": "Sleep Paralysis Field",
		"desc": "Snore + Night Light merge: +30% damage, +50% Night Light slow.",
		"category": Category.SLEEP_STRENGTH,
		"rarity": Rarity.LEGENDARY,
		"max_stack": 1,
		"stat": "paralysis_evolution",
		"per_stack": 1.0,
		"mode": "add",
	},
]


static func get_stat_table_upgrades() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Dictionary in ALL_UPGRADES:
		if u.get("kind", "stat") == "unlock_ability":
			continue
		out.append(u)
	return out


static func get_ability_unlock_upgrades() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Dictionary in ALL_UPGRADES:
		if u.get("kind", "") == "unlock_ability":
			out.append(u)
	return out
