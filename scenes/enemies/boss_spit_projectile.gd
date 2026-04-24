extends Node2D

## Small blob thrown by an enraged boss toward the hero (sleep damage).

var _speed: float = 420.0
var _dir: Vector2 = Vector2.RIGHT
var _damage: float = 0.05
var _lifetime: float = 0.0

const MAX_LIFETIME_SEC: float = 5.0
const HIT_RADIUS: float = 42.0


func setup(from_global: Vector2, aim_at: Vector2, damage: float, speed: float = 420.0) -> void:
	global_position = from_global
	_damage = damage
	_speed = speed
	_dir = (aim_at - from_global)
	if _dir.length_squared() < 1.0:
		_dir = Vector2.RIGHT
	else:
		_dir = _dir.normalized()
	rotation = _dir.angle()
	z_index = 3


func _physics_process(delta: float) -> void:
	_lifetime += delta
	global_position += _dir * _speed * delta

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var bed: Node = players[0]
		if is_instance_valid(bed) and bed.global_position.distance_to(global_position) < HIT_RADIUS:
			if bed.has_method("take_sleep_damage"):
				bed.take_sleep_damage(_damage)
			queue_free()
			return

	if _lifetime >= MAX_LIFETIME_SEC:
		queue_free()

	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.95, 0.15, 0.12, 0.92))
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, Color(1.0, 0.55, 0.45, 0.85), 2.0, true)
