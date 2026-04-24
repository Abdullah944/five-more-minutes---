extends BaseAbility

## Snore Wave — expanding ring of snore energy that damages all enemies it touches.
## Stacking: larger radius, more damage, adds extra rings at stack 3+.


func _ready() -> void:
	ability_id = "snore_wave"
	base_damage = 8.0
	cooldown = 2.0


func _do_fire() -> void:
	AudioManager.play_sfx_by_name("snore_wave", -6.0)
	var ring_count := 1
	if stack_level >= 5:
		ring_count = 3
	elif stack_level >= 3:
		ring_count = 2

	for i in ring_count:
		_spawn_ring(i * 0.2)

	fired.emit()


func _spawn_ring(delay: float) -> void:
	var ring := _SnoreRing.new()
	ring.damage = get_effective_damage()
	ring.max_radius = get_effective_radius()
	if delay > 0.0:
		ring.start_delay = delay

	get_effects_node().add_child(ring)
	ring.global_position = global_position
	ring.origin = global_position


func get_effective_radius() -> float:
	var aoe_mult := SleepMeter.get_aoe_multiplier()
	var r: float = (120.0 + stack_level * 15.0) * aoe_mult
	# Soft cap so the ring cannot screen-wipe the entire arena at extreme stacks/upgrades.
	return minf(r, 280.0)


class _SnoreRing extends Node2D:
	var damage: float = 8.0
	var max_radius: float = 120.0
	var origin: Vector2
	var start_delay: float = 0.0

	var _current_radius: float = 0.0
	var _expand_speed: float = 250.0
	var _hit_enemies: Array[Node2D] = []
	var _alpha: float = 0.8
	var _delay_timer: float = 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		if _delay_timer < start_delay:
			_delay_timer += delta
			return

		_current_radius += _expand_speed * delta

		var progress := _current_radius / max_radius
		_alpha = lerpf(0.8, 0.0, progress)

		_damage_enemies_in_ring()
		queue_redraw()

		if _current_radius >= max_radius:
			queue_free()

	func _draw() -> void:
		if _alpha <= 0.0:
			return
		var color := Color(0.5, 0.6, 1.0, _alpha)
		var width := lerpf(6.0, 2.0, _current_radius / max_radius)
		draw_arc(Vector2.ZERO, _current_radius, 0, TAU, 48, color, width, true)

		var z_color := Color(0.6, 0.7, 1.0, _alpha * 0.7)
		var font := ThemeDB.fallback_font
		if font:
			var angle_offset := Time.get_ticks_msec() * 0.002
			for i in 3:
				var angle: float = angle_offset + i * (TAU / 3.0)
				var pos := Vector2(cos(angle), sin(angle)) * (_current_radius * 0.8)
				draw_string(font, pos - Vector2(5, -4), "Z", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, z_color)

	func _damage_enemies_in_ring() -> void:
		var enemies := get_tree().get_nodes_in_group("enemy")
		for enemy: Node2D in enemies:
			if not is_instance_valid(enemy) or enemy in _hit_enemies:
				continue
			var dist := global_position.distance_to(enemy.global_position)
			if dist <= _current_radius + 15.0 and dist >= _current_radius - 25.0:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, global_position)
				_hit_enemies.append(enemy)
