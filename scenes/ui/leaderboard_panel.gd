extends Control

## Offline "Dream Hall" — sleepy heroes ranked by longest single-run survival.

signal closed

@onready var back_btn: Button = $Panel/Layout/TopBar/BackButton
@onready var item_list: VBoxContainer = $Panel/Layout/Scroll/ItemList
@onready var subtitle: Label = $Panel/Layout/Subtitle
@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	visible = false
	back_btn.pressed.connect(func() -> void: visible = false; closed.emit())


func show_panel() -> void:
	visible = true
	_build_list()
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _build_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	subtitle.text = "On-device only — beat these sleepy legends by lasting longer in a single run."

	var rows: Array[Dictionary] = []
	for L in MetaProgression.DREAM_HALL_LEGENDS:
		rows.append({"name": str(L["name"]), "sec": float(L["sec"]), "is_you": false})
	rows.append({"name": "You", "sec": MetaProgression.best_survival_time, "is_you": true})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: float = float(a["sec"])
		var sb: float = float(b["sec"])
		if not is_equal_approx(sa, sb):
			return sa > sb
		return bool(a.get("is_you", false)) and not bool(b.get("is_you", false))
	)

	var limit := mini(rows.size(), 10)
	for i in limit:
		_add_row(i + 1, rows[i])


func _add_row(rank: int, data: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.SURFACE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	if bool(data.get("is_you", false)):
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = UIPalette.DREAM_VIOLET
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size = Vector2(52, 0)
	rank_lbl.add_theme_font_size_override("font_size", 22)
	rank_lbl.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
	hbox.add_child(rank_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(data["name"])
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override(
		"font_color",
		UIPalette.DREAM_VIOLET if bool(data.get("is_you", false)) else UIPalette.TEXT_PRIMARY
	)
	hbox.add_child(name_lbl)

	var time_lbl := Label.new()
	time_lbl.text = _format_time(float(data["sec"]))
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_font_size_override("font_size", 22)
	time_lbl.add_theme_color_override("font_color", UIPalette.MOON_GOLD)
	hbox.add_child(time_lbl)

	card.add_child(hbox)
	item_list.add_child(card)


func _format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var m := int(seconds) / 60
	@warning_ignore("integer_division")
	var s := int(seconds) % 60
	return "%d:%02d" % [m, s]
