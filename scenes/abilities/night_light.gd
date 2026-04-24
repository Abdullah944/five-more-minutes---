extends BaseAbility

## Night Light — periodic aura that slows nearby enemies. Stacks increase slow strength.


func _ready() -> void:
	ability_id = "night_light"
	base_damage = 0.0
	cooldown = 0.38
	auto_fire_enabled = true


func _do_fire() -> void:
	AudioManager.play_sfx_by_name("snore_wave", -12.0, 0.85)
	var r: float = 140.0 + float(stack_level) * 12.0
	var aura_mul: float = 1.0
	if float(GameManager.player_stats.get("paralysis_evolution", 0.0)) > 0.5:
		aura_mul = 1.5
	var slow_amt: float = (0.1 + 0.035 * float(stack_level - 1)) * aura_mul
	slow_amt = minf(0.42, slow_amt)
	for enemy in find_enemies_in_range(r):
		if is_instance_valid(enemy) and enemy.has_method("add_night_light_slow"):
			enemy.add_night_light_slow(slow_amt)
	fired.emit()
