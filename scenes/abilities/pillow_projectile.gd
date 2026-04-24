extends Area2D

## A flying pillow that damages enemies on contact and can bounce once.

var damage: float = 5.0
var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var bounces_left: int = 1
var _lifetime: float = 0.0
const MAX_LIFETIME: float = 4.0


func _ready() -> void:
	_assign_placeholder_texture()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func setup(dmg: float, spd: float, target_pos: Vector2, max_bounces: int) -> void:
	damage = dmg
	speed = spd
	bounces_left = max_bounces
	direction = (target_pos - global_position).normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime += delta

	# Spin slightly for fun
	rotation += delta * 4.0

	if _lifetime > MAX_LIFETIME:
		queue_free()

	# World-space vs camera view (comparing world pos to viewport pixel rect was wrong — instant despawn).
	var vp := get_viewport()
	var cam := vp.get_camera_2d()
	if cam != null and cam.is_current():
		var half: Vector2 = vp.get_visible_rect().size * 0.5 / cam.zoom
		var center: Vector2 = cam.get_screen_center_position()
		var margin_world: float = 320.0
		var bounds := Rect2(center - half, half * 2.0).grow(margin_world)
		if not bounds.has_point(global_position):
			queue_free()


func _on_area_entered(_area: Area2D) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		_on_hit(body)


func _on_hit(hit_enemy: Node2D) -> void:
	if bounces_left > 0:
		bounces_left -= 1
		var next_target := _find_next_enemy(hit_enemy)
		if next_target:
			direction = (next_target.global_position - global_position).normalized()
		else:
			_destroy()
	else:
		_destroy()


func _find_next_enemy(exclude: Node2D) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in enemies:
		if enemy == exclude or not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist < 300.0:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _destroy() -> void:
	# Small squish animation on impact
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.5), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)


func _assign_placeholder_texture() -> void:
	var sprite := Sprite2D.new()
	var tex := load("res://art/sprites/effects/pillow_projectile.png") as Texture2D
	if tex:
		sprite.texture = tex
	else:
		var img := Image.create(20, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.95, 0.95, 1.0, 1.0))
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	# Slightly larger world pillow (mobile / readability)
	scale = Vector2(1.24, 1.24)
