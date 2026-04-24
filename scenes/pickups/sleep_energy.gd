extends Node2D

## XP gem dropped by defeated enemies. Attracted by PickupMagnet.

@export var xp_amount: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

var _bob_timer: float = 0.0
var _start_y: float = 0.0
var _is_collected: bool = false


func _ready() -> void:
	add_to_group("pickup")
	_start_y = position.y
	_assign_placeholder_texture()


func _process(delta: float) -> void:
	if _is_collected:
		return
	_bob_timer += delta
	sprite.position.y = sin(_bob_timer * 3.0) * 3.0


func collect(_collector: Node2D) -> void:
	if _is_collected:
		return
	_is_collected = true

	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("add_xp"):
		hud.add_xp(xp_amount)

	AudioManager.play_sfx_by_name("pickup_xp", -4.0, randf_range(0.9, 1.1))
	_spawn_floating_text("+%d XP" % int(xp_amount), Color(0.3, 0.8, 1.0, 1.0))

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)


func _spawn_floating_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -30)
	label.z_index = 100
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-20, -20)

	var tween := get_tree().create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)


func _assign_placeholder_texture() -> void:
	if sprite.texture == null:
		var tex := load("res://art/sprites/pickup_sleep_energy.png")
		if tex:
			sprite.texture = tex
		else:
			var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.3, 0.8, 1.0, 1.0))
			sprite.texture = ImageTexture.create_from_image(img)
