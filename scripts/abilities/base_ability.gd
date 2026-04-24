class_name BaseAbility
extends Node2D

## Base class for all player abilities. Handles auto-fire timer, targeting,
## damage calculation with depth zone multipliers, and stacking.

signal fired
signal stack_changed(new_stack: int)

@export var ability_id: String = ""
@export var base_damage: float = 10.0
@export var cooldown: float = 2.0
@export var max_stack: int = 99
@export var auto_fire_enabled: bool = true

var stack_level: int = 1
var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not auto_fire_enabled:
		return
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return

	_timer += delta
	if _timer >= get_effective_cooldown():
		_timer = 0.0
		_do_fire()


## Manual trigger (e.g. attack button). Override in subclasses that support it.
func try_manual_fire() -> bool:
	return false


func add_stack() -> void:
	if stack_level < max_stack:
		stack_level += 1
		stack_changed.emit(stack_level)
		_on_stack_changed()


func get_effective_damage() -> float:
	var zone_mult := SleepMeter.get_damage_multiplier()
	var base_dmg: float = GameManager.player_stats.get("base_damage", 1.0)
	return base_damage * (1.0 + (stack_level - 1) * 0.2) * zone_mult * base_dmg


func get_effective_cooldown() -> float:
	var reduction := 1.0 - (stack_level - 1) * 0.05
	return cooldown * maxf(reduction, 0.4)


func get_effective_radius() -> float:
	var aoe_mult := SleepMeter.get_aoe_multiplier()
	return 100.0 * (1.0 + (stack_level - 1) * 0.1) * aoe_mult


func find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func find_enemies_in_range(radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result


func get_effects_node() -> Node:
	var game := get_tree().current_scene
	var effects := game.get_node_or_null("Effects")
	return effects if effects else game


## Override in subclasses to define what happens on fire.
func _do_fire() -> void:
	fired.emit()


## Override for custom stack-up behavior (visual scaling, etc).
func _on_stack_changed() -> void:
	pass
