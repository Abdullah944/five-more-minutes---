extends Node

## Autoload singleton: safe-area insets → viewport pixels for UI roots (notches, home bar).


func compute_extra_margins_for_node(node: Node) -> Vector4i:
	var vp: Viewport = node.get_viewport()
	if vp == null:
		return Vector4i.ZERO
	var win: Window = node.get_window()
	if win == null:
		return Vector4i.ZERO

	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win_pos := Vector2i(win.position)
	var win_size := Vector2i(win.size)
	if win_size.x < 1 or win_size.y < 1:
		return Vector4i.ZERO

	var global_win := Rect2i(win_pos, win_size)
	var inter := global_win.intersection(safe)
	if inter.size.x < 1 or inter.size.y < 1:
		return Vector4i.ZERO

	var left := inter.position.x - global_win.position.x
	var top := inter.position.y - global_win.position.y
	var right := global_win.end.x - inter.end.x
	var bottom := global_win.end.y - inter.end.y

	var vp_size := vp.get_visible_rect().size
	var sx := vp_size.x / float(win_size.x)
	var sy := vp_size.y / float(win_size.y)

	var ml := int(round(clampf(float(left) * sx, 0.0, 160.0)))
	var mt := int(round(clampf(float(top) * sy, 0.0, 200.0)))
	var mr := int(round(clampf(float(right) * sx, 0.0, 160.0)))
	var mb := int(round(clampf(float(bottom) * sy, 0.0, 200.0)))
	return Vector4i(ml, mt, mr, mb)
