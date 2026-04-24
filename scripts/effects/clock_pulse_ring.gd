extends Node2D

## Cosmetic pulsing rings around alarm-clock enemies — snore-wave style arcs + drifting Zs.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 0.5 + 0.5 * sin(t * 3.2)
	var r1: float = 22.0 + pulse * 14.0
	draw_arc(Vector2.ZERO, r1, 0.0, TAU, 56, Color(1.0, 0.82, 0.35, 0.42 + pulse * 0.28), 3.5, true)
	draw_arc(Vector2.ZERO, r1 * 0.52, 0.0, TAU, 40, Color(1.0, 0.92, 0.55, 0.26), 2.0, true)
	var r2: float = r1 * 0.72
	var z_col := Color(1.0, 0.88, 0.45, 0.38 * pulse)
	var font := ThemeDB.fallback_font
	if font:
		for i in 3:
			var ang: float = t * 2.4 + float(i) * TAU / 3.0
			var pos := Vector2(cos(ang), sin(ang)) * r2
			draw_string(font, pos - Vector2(5, 6), "z", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, z_col)
