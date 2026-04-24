extends Node2D

## Heavy AOE attack — expanding ring around the hero that damages all nearby enemies.
## Triggers on a cooldown, alternating with other abilities.

@export var base_damage: float = 15.0
@export var base_cooldown: float = 8.0
@export var base_radius: float = 180.0

var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return

	_timer += delta
	var cooldown: float = base_cooldown * GameManager.player_stats.get("cooldown_mult", 1.0)
	if _timer >= cooldown:
		_timer = 0.0
		_fire_wave()


func _fire_wave() -> void:
	var dmg_mult: float = GameManager.player_stats.get("base_damage", 1.0)
	var damage := base_damage * dmg_mult
	var radius := base_radius

	AudioManager.play_sfx_by_name("snore_wave", -4.0, 0.7)

	var ring := _create_ring_visual(radius)
	add_child(ring)

	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage, global_position)


func _create_ring_visual(radius: float) -> Node2D:
	var ring := Node2D.new()
	ring.z_index = 5

	var tex := load("res://art/sprites/effects/snore_wave.png") as Texture2D
	if tex:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = Vector2.ONE * 0.5
		ring.add_child(sprite)

		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2.ONE * (radius / 32.0), 0.4)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(ring.queue_free)
	else:
		ring.queue_free()

	return ring
