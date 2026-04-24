class_name HealthComponent
extends Node

## Reusable health component for enemies. Attach to any entity that can take damage.

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 10.0

var current_health: float


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func set_max_health(value: float) -> void:
	max_health = value
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)


func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health


func is_alive() -> bool:
	return current_health > 0.0
