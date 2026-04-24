extends Control

## Floating joystick that spawns wherever the player touches.
## Works in the bottom 60% of the screen. Feeds input actions.

@export var dead_zone: float = 15.0
@export var max_radius: float = 80.0
@export var touch_region_ratio: float = 0.6  # Bottom 60% of screen
@export var fade_speed: float = 8.0

@onready var base_ring: Control = $BaseRing
@onready var thumb_knob: Control = $BaseRing/ThumbKnob

var _active_touch_index: int = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _current_output: Vector2 = Vector2.ZERO
var _visible_alpha: float = 0.0


func _ready() -> void:
	base_ring.modulate.a = 0.0
	base_ring.visible = false


func _process(delta: float) -> void:
	# Fade in/out
	var target_alpha := 1.0 if _active_touch_index >= 0 else 0.0
	_visible_alpha = move_toward(_visible_alpha, target_alpha, fade_speed * delta)
	base_ring.modulate.a = _visible_alpha * 0.6
	if _visible_alpha < 0.01:
		base_ring.visible = false

	# Push input to the action system
	_update_input_actions()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_index >= 0:
			return  # Already tracking a touch
		# Only accept touches in the bottom portion of the screen
		var screen_size := get_viewport_rect().size
		var touch_threshold := screen_size.y * (1.0 - touch_region_ratio)
		if event.position.y < touch_threshold:
			return

		_active_touch_index = event.index
		_touch_origin = event.position
		base_ring.visible = true
		base_ring.global_position = event.position - base_ring.size * 0.5
		thumb_knob.position = base_ring.size * 0.5
		_current_output = Vector2.ZERO
	else:
		if event.index == _active_touch_index:
			_release_touch()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_touch_index:
		return

	var delta_vec := event.position - _touch_origin
	var distance := delta_vec.length()

	if distance < dead_zone:
		_current_output = Vector2.ZERO
		thumb_knob.position = base_ring.size * 0.5
		return

	var clamped_distance := minf(distance, max_radius)
	var direction := delta_vec.normalized()
	_current_output = direction * ((clamped_distance - dead_zone) / (max_radius - dead_zone))

	# Visual: move thumb knob
	var visual_offset := direction * clamped_distance
	thumb_knob.position = base_ring.size * 0.5 + visual_offset


func _release_touch() -> void:
	_active_touch_index = -1
	_current_output = Vector2.ZERO


func _update_input_actions() -> void:
	# Feed joystick output into Godot's input action system
	# so the player script can read it via Input.get_axis()
	_set_action_strength("move_left", maxf(-_current_output.x, 0.0))
	_set_action_strength("move_right", maxf(_current_output.x, 0.0))
	_set_action_strength("move_up", maxf(-_current_output.y, 0.0))
	_set_action_strength("move_down", maxf(_current_output.y, 0.0))


func _set_action_strength(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)


func get_output() -> Vector2:
	return _current_output


func is_active() -> bool:
	return _active_touch_index >= 0
