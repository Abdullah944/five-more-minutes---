extends BaseAbility

## Pillow Toss — fires a bouncing pillow at the nearest enemy.
## Stacking: faster fire rate, +1 bounce at stack 3 and 5.
## Player fires manually via the in-game attack button (no auto-fire).

@export var projectile_speed: float = 300.0

var pillow_scene: PackedScene


func _physics_process(_delta: float) -> void:
	# No auto-fire; [Game] attack button calls try_manual_fire().
	pass


func _ready() -> void:
	ability_id = "pillow_toss"
	base_damage = 5.0
	cooldown = 1.5
	pillow_scene = preload("res://scenes/abilities/pillow_projectile.tscn")


func _do_fire() -> void:
	var target := find_nearest_enemy()
	if target == null:
		return
	_fire_projectile_at(target)


func try_manual_fire() -> bool:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return false
	var target := find_nearest_enemy()
	var aim_pos: Vector2
	if target != null:
		aim_pos = target.global_position
	else:
		# No enemies yet: throw straight up in world space so the pillow is still visible.
		aim_pos = global_position + Vector2(0.0, -900.0)
	_fire_projectile_toward(aim_pos)
	return true


func _fire_projectile_at(target: Node2D) -> void:
	_fire_projectile_toward(target.global_position)


func _fire_projectile_toward(aim_world_pos: Vector2) -> void:
	AudioManager.play_sfx_by_name("pillow_toss", -8.0, randf_range(0.9, 1.1))

	var pillow := pillow_scene.instantiate() as Area2D

	var bounces := 1
	if stack_level >= 5:
		bounces = 3
	elif stack_level >= 3:
		bounces = 2

	get_effects_node().add_child(pillow)
	pillow.global_position = global_position
	pillow.setup(get_effective_damage(), projectile_speed, aim_world_pos, bounces)
	fired.emit()


func _on_stack_changed() -> void:
	projectile_speed = 300.0 + stack_level * 20.0
