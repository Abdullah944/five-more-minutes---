extends Node2D

## Warm Milk pickup — rare drop that reduces Sleep Meter by 15%.

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

var _bob_timer: float = 0.0
var _is_collected: bool = false
var heal_amount: float = 0.15


func _ready() -> void:
	add_to_group("pickup")
	_assign_placeholder_texture()


func _process(delta: float) -> void:
	if _is_collected:
		return
	_bob_timer += delta
	sprite.position.y = sin(_bob_timer * 2.5) * 4.0
	sprite.rotation = sin(_bob_timer * 1.5) * 0.1


func collect(_collector: Node2D) -> void:
	if _is_collected:
		return
	_is_collected = true

	SleepMeter.reduce_meter(heal_amount)
	AudioManager.play_sfx_by_name("pickup_milk", -3.0)

	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.9, 0.6, 0.2)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(flash)
		var flash_tween := get_tree().create_tween()
		flash_tween.tween_property(flash, "color:a", 0.0, 0.5)
		flash_tween.tween_callback(flash.queue_free)

	_spawn_floating_text("+%d%% Sleep" % int(heal_amount * 100), Color(1.0, 0.85, 0.4, 1.0))

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
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
	label.position = Vector2(-40, -30)
	label.z_index = 100
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-30, -20)

	var float_tween := get_tree().create_tween()
	float_tween.tween_property(label, "position:y", label.position.y - 50.0, 0.8)
	float_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	float_tween.tween_callback(label.queue_free)


func _assign_placeholder_texture() -> void:
	if sprite.texture == null:
		var tex := load("res://art/sprites/pickup_warm_milk.png")
		if tex:
			sprite.texture = tex
		else:
			var img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(1.0, 0.95, 0.85, 1.0))
			sprite.texture = ImageTexture.create_from_image(img)
