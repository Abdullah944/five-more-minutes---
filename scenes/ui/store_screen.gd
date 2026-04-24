extends Control
class_name StoreScreen

## Store screen orchestrator: tabs, shard balance; list rows live under `scripts/ui/store/`.

signal closed

enum Tab { UPGRADES, BEDS, PAJAMAS, THEMES }

## Preloads avoid relying on global `class_name` registration order at parse time.
const _STORE_UI_KIT := preload("res://scripts/ui/store/store_ui_kit.gd")
const _TAB_UPGRADES := preload("res://scripts/ui/store/store_tab_upgrades.gd")
const _TAB_BEDS := preload("res://scripts/ui/store/store_tab_beds.gd")
const _TAB_PAJAMAS := preload("res://scripts/ui/store/store_tab_pajamas.gd")
const _TAB_THEMES := preload("res://scripts/ui/store/store_tab_themes.gd")
const _SHARD_OFFERS := preload("res://scripts/ui/store/store_shard_offers.gd")

@onready var back_btn: Button = $Panel/Layout/TopBar/BackButton
@onready var shards_btn: Button = $Panel/Layout/TopBar/ShardsButton
@onready var tab_container: HBoxContainer = $Panel/Layout/TabBar
@onready var scroll: ScrollContainer = $Panel/Layout/Scroll
@onready var item_list: VBoxContainer = $Panel/Layout/Scroll/ItemList
@onready var panel: PanelContainer = $Panel

var _active_tab: Tab = Tab.UPGRADES
var _tab_buttons: Array[Button] = []
var _ui_kit: RefCounted = _STORE_UI_KIT.new() as RefCounted

const TAB_NAMES: Array[String] = ["Upgrades", "Beds", "Pajamas", "Themes"]


func _ready() -> void:
	visible = false
	back_btn.pressed.connect(_on_back)
	shards_btn.pressed.connect(_on_shards_header_pressed)
	MetaProgression.shards_changed.connect(_on_shards_changed)

	var empty_sb := StyleBoxEmpty.new()
	shards_btn.add_theme_stylebox_override("normal", empty_sb)
	shards_btn.add_theme_stylebox_override("hover", empty_sb)
	shards_btn.add_theme_stylebox_override("pressed", empty_sb)
	shards_btn.add_theme_stylebox_override("focus", empty_sb)
	shards_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	shards_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_build_tab_buttons()
	_update_shards_display()


func show_store() -> void:
	visible = true
	_switch_tab(Tab.UPGRADES)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)


func _on_back() -> void:
	AudioManager.play_ui_by_name("menu_close")
	visible = false
	closed.emit()


func _on_shards_changed(_total: int) -> void:
	_update_shards_display()
	if visible:
		_populate_tab()


func _update_shards_display() -> void:
	shards_btn.text = "%d Shards" % MetaProgression.dream_shards
	var bal: int = int(MetaProgression.dream_shards)
	var c: Color = UIPalette.DANGER if bal <= 0 else UIPalette.MOON_GOLD
	StoreUiKit.apply_button_label_tint(shards_btn, c)


func _on_shards_header_pressed() -> void:
	AudioManager.play_ui_by_name("menu_open")
	open_shard_packs()


# --- Tab system ---

func _build_tab_buttons() -> void:
	for child in tab_container.get_children():
		child.queue_free()
	_tab_buttons.clear()

	for i in TAB_NAMES.size():
		var btn := Button.new()
		btn.text = TAB_NAMES[i]
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style := StyleBoxFlat.new()
		style.bg_color = UIPalette.NIGHT_NAVY
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		btn.add_theme_stylebox_override("normal", style)

		var style_hover := style.duplicate() as StyleBoxFlat
		style_hover.bg_color = UIPalette.SURFACE_HOVER
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)

		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_switch_tab.bind(i as int))
		tab_container.add_child(btn)
		_tab_buttons.append(btn)


func _switch_tab(tab: int) -> void:
	_active_tab = tab as Tab
	_highlight_active_tab()
	_populate_tab()


func _highlight_active_tab() -> void:
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i]
		var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if i == _active_tab:
			style.bg_color = UIPalette.SURFACE
			btn.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
		else:
			style.bg_color = UIPalette.NIGHT_NAVY
			btn.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		btn.add_theme_stylebox_override("normal", style)


func _populate_tab() -> void:
	for child in item_list.get_children():
		child.queue_free()

	match _active_tab:
		Tab.UPGRADES:
			_TAB_UPGRADES.populate(item_list, _ui_kit, self)
		Tab.BEDS:
			_TAB_BEDS.populate(item_list, _ui_kit, self)
		Tab.PAJAMAS:
			_TAB_PAJAMAS.populate(item_list, _ui_kit, self)
		Tab.THEMES:
			_TAB_THEMES.populate(item_list, _ui_kit, self)


# --- Actions for tab builders ---

func buy_furniture_upgrade(furniture_id: String) -> void:
	if MetaProgression.upgrade_furniture(furniture_id):
		_populate_tab()
		_update_shards_display()
		play_purchase_feedback()


func open_shard_shortage_overlay(cost: int) -> void:
	_SHARD_OFFERS.show_overlay(self, cost, false)


func open_shard_packs() -> void:
	_SHARD_OFFERS.show_overlay(self, 0, true)


func buy_bed(bed_id: String) -> void:
	var cost: int = MetaProgression.BED_CATALOG[bed_id]["cost"]
	if MetaProgression.spend_shards(cost):
		MetaProgression.unlock_bed(bed_id)
		MetaProgression.selected_bed = bed_id
		_populate_tab()
		_update_shards_display()
		play_purchase_feedback()


func equip_bed(bed_id: String) -> void:
	MetaProgression.selected_bed = bed_id
	SaveManager.save_game()
	_populate_tab()


func buy_pajama(pj_id: String) -> void:
	var cost: int = MetaProgression.PAJAMA_CATALOG[pj_id]["cost"]
	if MetaProgression.spend_shards(cost):
		MetaProgression.unlock_pajama(pj_id)
		MetaProgression.selected_pajama = pj_id
		_populate_tab()
		_update_shards_display()
		play_purchase_feedback()


func equip_pajama(pj_id: String) -> void:
	MetaProgression.selected_pajama = pj_id
	SaveManager.save_game()
	_populate_tab()


func buy_theme(theme_id: String) -> void:
	var cost: int = MetaProgression.THEME_CATALOG[theme_id]["cost"]
	if MetaProgression.spend_shards(cost):
		MetaProgression.unlock_theme(theme_id)
		MetaProgression.selected_theme = theme_id
		_populate_tab()
		_update_shards_display()
		play_purchase_feedback()


func equip_theme(theme_id: String) -> void:
	MetaProgression.selected_theme = theme_id
	SaveManager.save_game()
	_populate_tab()


func refresh_shards_display() -> void:
	_update_shards_display()


func play_purchase_feedback() -> void:
	AudioManager.play_ui_by_name("purchase")
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.15)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
