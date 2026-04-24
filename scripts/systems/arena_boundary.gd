extends Node2D

## Defines the visible play area. Draws a border and clamps the player inside.

const ARENA_HALF_W: float = 1000.0
const ARENA_HALF_H: float = 1000.0
const BORDER_WIDTH: float = 4.0
const BORDER_COLOR: Color = Color(0.5, 0.5, 0.8, 0.35)
const CORNER_RADIUS: float = 24.0

var _player: CharacterBody2D


func setup(player: CharacterBody2D) -> void:
	_player = player


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.global_position.x = clampf(
		_player.global_position.x, -ARENA_HALF_W, ARENA_HALF_W
	)
	_player.global_position.y = clampf(
		_player.global_position.y, -ARENA_HALF_H, ARENA_HALF_H
	)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(
		Vector2(-ARENA_HALF_W, -ARENA_HALF_H),
		Vector2(ARENA_HALF_W * 2, ARENA_HALF_H * 2)
	)
	_draw_rounded_border(rect, BORDER_COLOR, BORDER_WIDTH, CORNER_RADIUS)

	# Soft purple vignette — fills entire visible viewport outside the arena (edge-to-edge).
	var fade_color := Color(0.09, 0.08, 0.14, 0.32)
	_draw_fade_outside_arena_to_viewport(rect, fade_color)


## Fades from viewport edges inward to the arena rect (no gaps on wide/tall windows).
func _draw_fade_outside_arena_to_viewport(rect: Rect2, fade_color: Color) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var half_screen: Vector2 = (get_viewport().get_visible_rect().size / cam.zoom) * 0.5
	var center_world: Vector2 = cam.get_screen_center_position()
	var tl_world: Vector2 = center_world - half_screen
	var br_world: Vector2 = center_world + half_screen
	var a: Vector2 = to_local(tl_world)
	var b: Vector2 = to_local(br_world)
	var vx_min: float = minf(a.x, b.x)
	var vx_max: float = maxf(a.x, b.x)
	var vy_min: float = minf(a.y, b.y)
	var vy_max: float = maxf(a.y, b.y)

	# Top strip: full width of view, from top of view down to arena top.
	var top_h: float = rect.position.y - vy_min
	if top_h > 0.0:
		draw_rect(Rect2(Vector2(vx_min, vy_min), Vector2(vx_max - vx_min, top_h)), fade_color)

	# Bottom strip: full width, from arena bottom to bottom of view.
	var bot_h: float = vy_max - rect.end.y
	if bot_h > 0.0:
		draw_rect(Rect2(Vector2(vx_min, rect.end.y), Vector2(vx_max - vx_min, bot_h)), fade_color)

	# Left strip: between arena left and view left, middle vertical band only.
	var left_w: float = rect.position.x - vx_min
	if left_w > 0.0:
		draw_rect(
			Rect2(Vector2(vx_min, rect.position.y), Vector2(left_w, rect.size.y)),
			fade_color
		)

	# Right strip: arena right to view right.
	var right_w: float = vx_max - rect.end.x
	if right_w > 0.0:
		draw_rect(
			Rect2(Vector2(rect.end.x, rect.position.y), Vector2(right_w, rect.size.y)),
			fade_color
		)


func _draw_rounded_border(rect: Rect2, color: Color, width: float, radius: float) -> void:
	var tl := rect.position + Vector2(radius, radius)
	var top_right := Vector2(rect.end.x - radius, rect.position.y + radius)
	var br := rect.end - Vector2(radius, radius)
	var bl := Vector2(rect.position.x + radius, rect.end.y - radius)

	draw_arc(tl, radius, PI, PI * 1.5, 12, color, width, true)
	draw_arc(top_right, radius, PI * 1.5, TAU, 12, color, width, true)
	draw_arc(br, radius, 0, PI * 0.5, 12, color, width, true)
	draw_arc(bl, radius, PI * 0.5, PI, 12, color, width, true)

	draw_line(Vector2(tl.x, rect.position.y), Vector2(top_right.x, rect.position.y), color, width, true)
	draw_line(Vector2(tl.x, rect.end.y), Vector2(bl.x, rect.end.y), color, width, true)
	draw_line(Vector2(rect.position.x, tl.y), Vector2(rect.position.x, bl.y), color, width, true)
	draw_line(Vector2(rect.end.x, top_right.y), Vector2(rect.end.x, br.y), color, width, true)
