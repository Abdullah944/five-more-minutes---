extends Node

## Manages the in-run upgrade pool, rarity rolls, stack tracking,
## evolution eligibility, and upgrade presentation.
## Autoload singleton — access via UpgradeManager anywhere.

signal upgrades_offered(choices: Array)
signal upgrade_selected(upgrade: Resource)
@warning_ignore("unused_signal")
signal evolution_available(evolution: Resource)

# --- Rarity weights ---

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_WEIGHTS: Dictionary = {
	Rarity.COMMON: 60.0,
	Rarity.UNCOMMON: 25.0,
	Rarity.RARE: 12.0,
	Rarity.LEGENDARY: 3.0,
}

# --- Upgrade categories ---

enum Category { SLEEP_STRENGTH, CALMNESS, COMFORT }

# --- State ---

var upgrade_pool: Array[Resource] = []
var evolution_pool: Array[Resource] = []
var active_upgrades: Dictionary = {}  # upgrade_id -> stack_count
var active_abilities: Dictionary = {} # ability_id -> stack_count
var rerolls_remaining: int = 0

# Preloaded data (populated in _ready or from resource files)
var all_upgrades: Array[Resource] = []
var all_evolutions: Array[Resource] = []


func _ready() -> void:
	pass


func start_run(starting_rerolls: int = 0) -> void:
	active_upgrades.clear()
	active_abilities.clear()
	rerolls_remaining = starting_rerolls
	_rebuild_pool()


func offer_upgrades(count: int = 3) -> Array:
	var choices: Array = []
	var used_ids: Array[String] = []

	var evolution_option := _check_evolution_eligibility()

	for i in count:
		var rarity := _roll_rarity()
		var candidates := upgrade_pool.filter(func(u: Resource) -> bool:
			return u.get("rarity") == rarity and u.get("id") not in used_ids and not _is_maxed(u)
		)
		if candidates.is_empty():
			candidates = upgrade_pool.filter(func(u: Resource) -> bool:
				return u.get("id") not in used_ids and not _is_maxed(u)
			)
		if candidates.is_empty():
			continue
		var pick: Resource = candidates[randi() % candidates.size()]
		choices.append(pick)
		used_ids.append(pick.get("id"))

	if evolution_option != null:
		choices.append(evolution_option)

	upgrades_offered.emit(choices)
	return choices


func select_upgrade(upgrade: Resource) -> void:
	var uid: String = upgrade.get("id")
	if uid not in active_upgrades:
		active_upgrades[uid] = 0
	active_upgrades[uid] += 1
	upgrade_selected.emit(upgrade)
	_rebuild_pool()


func register_ability(ability_id: String, stack: int = 1) -> void:
	if ability_id not in active_abilities:
		active_abilities[ability_id] = 0
	active_abilities[ability_id] += stack


func get_upgrade_stack(upgrade_id: String) -> int:
	return active_upgrades.get(upgrade_id, 0)


func get_ability_stack(ability_id: String) -> int:
	return active_abilities.get(ability_id, 0)


func use_reroll() -> bool:
	if rerolls_remaining > 0:
		rerolls_remaining -= 1
		return true
	return false


## Min stacks of Snore Wave and Night Light before evolution appears (GDD: 3+; tune per balance).
const EVOLUTION_MIN_ABILITY_STACK: int = 1

## Picks 3 main cards (stats + possible Night Light unlock) + optional 4th evolution card.
func roll_level_up_choices() -> Array[Dictionary]:
	var used_ids: Array[String] = []
	var result: Array[Dictionary] = []
	var table_pool := _filter_available(UpgradeDefinitions.get_stat_table_upgrades(), used_ids)
	var ability_unlock_pool := _filter_available(UpgradeDefinitions.get_ability_unlock_upgrades(), used_ids)

	for slot: int in 3:
		var use_ability: bool = slot == 1 and not ability_unlock_pool.is_empty() and randf() < 0.42
		if use_ability:
			var ab_pick: Dictionary = ability_unlock_pool[randi() % ability_unlock_pool.size()]
			var can_ab: bool = get_ability_stack(str(ab_pick.get("ability_key", ""))) < 1
			if can_ab and get_upgrade_stack(str(ab_pick.get("id", ""))) < 1:
				result.append(ab_pick)
				used_ids.append(str(ab_pick.get("id", "")))
				_remove_id_from_array(ability_unlock_pool, str(ab_pick.get("id", "")))
				_remove_id_from_array(table_pool, str(ab_pick.get("id", "")))
				continue
		if table_pool.is_empty():
			break
		var pick: Dictionary = table_pool[randi() % table_pool.size()]
		result.append(pick)
		used_ids.append(str(pick.get("id", "")))
		_remove_id_from_array(table_pool, str(pick.get("id", "")))
		_remove_id_from_array(ability_unlock_pool, str(pick.get("id", "")))

	if can_offer_evolution() and not UpgradeDefinitions.EVOLUTIONS.is_empty():
		var evo: Dictionary = UpgradeDefinitions.EVOLUTIONS[0]
		if get_upgrade_stack(str(evo.get("id", ""))) < 1:
			result.append(evo)
	return result


func can_offer_evolution() -> bool:
	if UpgradeDefinitions.EVOLUTIONS.is_empty():
		return false
	var e0: Dictionary = UpgradeDefinitions.EVOLUTIONS[0]
	if get_upgrade_stack(str(e0.get("id", ""))) > 0:
		return false
	# Standard bed starts with Snore; Night Light comes from a level-up card first.
	if get_ability_stack("snore_wave") < EVOLUTION_MIN_ABILITY_STACK:
		return false
	if get_ability_stack("night_light") < EVOLUTION_MIN_ABILITY_STACK:
		return false
	return true


## Picks [param count] distinct, non-maxed upgrades from [UpgradeDefinitions] for card UI.
## Single source of truth for level-up and reroll rolls.
func roll_dictionary_upgrade_choices(count: int = 3) -> Array[Dictionary]:
	return roll_level_up_choices() if count == 3 else _roll_raw_stat_choices(count)


func _roll_raw_stat_choices(count: int) -> Array[Dictionary]:
	var pool := UpgradeDefinitions.get_stat_table_upgrades().duplicate()
	var used_ids: Array[String] = []
	var result: Array[Dictionary] = []

	for _i in count:
		var filtered := pool.filter(func(u: Dictionary) -> bool:
			var uid: String = u.get("id", "")
			if uid in used_ids:
				return false
			var max_s: int = u.get("max_stack", 99)
			if get_upgrade_stack(uid) >= max_s:
				return false
			return true
		)
		if filtered.is_empty():
			break
		var pick: Dictionary = filtered[randi() % filtered.size()]
		result.append(pick)
		used_ids.append(pick.get("id", ""))
	return result


func _filter_available(from: Array[Dictionary], used_ids: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Dictionary in from:
		var uid: String = str(u.get("id", ""))
		if uid in used_ids:
			continue
		var max_s: int = u.get("max_stack", 99)
		if get_upgrade_stack(uid) >= max_s:
			continue
		if u.get("kind", "") == "unlock_ability":
			if get_ability_stack(str(u.get("ability_key", "none"))) > 0:
				continue
		out.append(u)
	return out


func _remove_id_from_array(arr: Array[Dictionary], id: String) -> void:
	if id.is_empty():
		return
	for i: int in range(arr.size() - 1, -1, -1):
		if str(arr[i].get("id", "")) == id:
			arr.remove_at(i)
			return


# --- Internal ---

func _roll_rarity() -> Rarity:
	var total := 0.0
	for weight in RARITY_WEIGHTS.values():
		total += weight
	var roll := randf() * total
	var cumulative := 0.0
	for rarity: Rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if roll <= cumulative:
			return rarity
	return Rarity.COMMON


func _is_maxed(upgrade: Resource) -> bool:
	var uid: String = upgrade.get("id")
	var max_stack: int = upgrade.get("max_stack") if upgrade.get("max_stack") else 99
	return get_upgrade_stack(uid) >= max_stack


func _check_evolution_eligibility() -> Resource:
	for evo in all_evolutions:
		var req_a: String = evo.get("requires_a")
		var req_b: String = evo.get("requires_b")
		var threshold: int = evo.get("stack_threshold") if evo.get("stack_threshold") else 3
		if get_ability_stack(req_a) >= threshold and get_ability_stack(req_b) >= threshold:
			var evo_id: String = evo.get("id")
			if evo_id not in active_upgrades:
				return evo
	return null


func _rebuild_pool() -> void:
	upgrade_pool = all_upgrades.filter(func(u: Resource) -> bool:
		return not _is_maxed(u)
	)
