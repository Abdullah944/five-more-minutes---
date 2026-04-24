extends BaseAbility

## Dream Beam — a sweeping arc beam that deals continuous DPS.
## Sweeps toward the nearest enemy, damaging everything in the arc.
## Stacking: wider beam, more damage, longer duration.

@export var beam_length: float = 180.0
@export var beam_width: float = 20.0
@export var sweep_duration: float = 0.8
@export var sweep_arc: float = PI * 0.6

var _beam: _DreamBeamVisual = null
var _is_firing: bool = false


func _ready() -> void:
	ability_id = "dream_beam"
	base_damage = 3.0
	cooldown = 3.5


func _do_fire() -> void:
	if _is_firing:
		return
	AudioManager.play_sfx_by_name("dream_beam", -6.0)

	var aim_angle: float
	var bed := get_parent().get_parent() if get_parent() else null
	if bed and bed.has_method("get_facing_angle"):
		aim_angle = bed.get_facing_angle()
	else:
		var target := find_nearest_enemy()
		if target:
			aim_angle = global_position.angle_to_point(target.global_position) + PI
		else:
			aim_angle = randf() * TAU

	_is_firing = true

	_beam = _DreamBeamVisual.new()
	_beam.dps = get_effective_damage()
	_beam.length = beam_length + stack_level * 15.0
	_beam.width = beam_width + stack_level * 3.0
	_beam.sweep_dur = sweep_duration + stack_level * 0.05
	_beam.center_angle = aim_angle
	_beam.arc = sweep_arc + stack_level * 0.08
	_beam.finished.connect(_on_beam_finished)
	get_effects_node().add_child(_beam)
	_beam.global_position = global_position

	fired.emit()


func _on_beam_finished() -> void:
	_is_firing = false


func _on_stack_changed() -> void:
	beam_length = 180.0 + stack_level * 15.0


class _DreamBeamVisual extends Node2D:
	signal finished

	var dps: float = 3.0
	var length: float = 180.0
	var width: float = 20.0
	var sweep_dur: float = 0.8
	var center_angle: float = 0.0
	var arc: float = PI * 0.6

	var _elapsed: float = 0.0
	var _current_angle: float = 0.0
	var _damage_tick: float = 0.0
	const DAMAGE_INTERVAL: float = 0.1

	func _ready() -> void:
		z_index = 1
		_current_angle = center_angle - arc * 0.5

	func _process(delta: float) -> void:
		_elapsed += delta
		var progress := _elapsed / sweep_dur
		_current_angle = (center_angle - arc * 0.5) + arc * progress

		_damage_tick += delta
		if _damage_tick >= DAMAGE_INTERVAL:
			_damage_tick -= DAMAGE_INTERVAL
			_hit_enemies_in_beam()

		queue_redraw()

		if _elapsed >= sweep_dur:
			finished.emit()
			queue_free()

	func _draw() -> void:
		var progress := _elapsed / sweep_dur
		var alpha := 0.7 if progress < 0.8 else lerpf(0.7, 0.0, (progress - 0.8) / 0.2)

		var dir := Vector2.from_angle(_current_angle)
		var end := dir * length
		var perp := dir.rotated(PI * 0.5) * width * 0.5

		var core_color := Color(0.6, 0.4, 1.0, alpha)
		var glow_color := Color(0.7, 0.5, 1.0, alpha * 0.4)

		var points_glow: PackedVector2Array = [
			-perp * 1.5, end - perp * 1.5, end + perp * 1.5, perp * 1.5
		]
		draw_colored_polygon(points_glow, glow_color)

		var points_core: PackedVector2Array = [
			-perp, end - perp, end + perp, perp
		]
		draw_colored_polygon(points_core, core_color)

		# Bright center line
		draw_line(Vector2.ZERO, end, Color(0.9, 0.8, 1.0, alpha), 2.0, true)

	func _hit_enemies_in_beam() -> void:
		var enemies := get_tree().get_nodes_in_group("enemy")
		var dir := Vector2.from_angle(_current_angle)

		for enemy: Node2D in enemies:
			if not is_instance_valid(enemy):
				continue
			var to_enemy := enemy.global_position - global_position
			var proj := to_enemy.dot(dir)
			if proj < 0 or proj > length:
				continue
			var closest := global_position + dir * proj
			var dist := enemy.global_position.distance_to(closest)
			if dist <= width * 0.7:
				if enemy.has_method("take_damage"):
					enemy.take_damage(dps * DAMAGE_INTERVAL, global_position)
