extends Object
class_name StoreTabUpgrades

## Builds the Meta furniture / stat upgrade list for the store.

const FURNITURE_ICONS: Dictionary = {
	"mattress": "[HP]", "pillow": "[ATK]", "blanket": "[DEF]",
	"nightstand_lamp": "[RNG]", "alarm_clock": "[XP]",
	"white_noise": "[REG]", "slippers": "[SPD]", "dream_journal": "[RR]",
}


static func populate(item_list: VBoxContainer, kit: Variant, host: Control) -> void:
	var vw: float = host.get_viewport().get_visible_rect().size.x
	var action_sz: Vector2 = StoreUiKit.scaled_action_button_size(vw)
	for furniture_id: String in MetaProgression.FURNITURE_DISPLAY:
		var info: Dictionary = MetaProgression.FURNITURE_DISPLAY[furniture_id]
		var level: int = MetaProgression.furniture_levels.get(furniture_id, 0)
		var max_lvl: int = MetaProgression.FURNITURE_MAX_LEVELS.get(furniture_id, 10)
		var cost: int = MetaProgression.get_furniture_cost(furniture_id)
		var is_maxed := cost < 0
		var icon_tag: String = FURNITURE_ICONS.get(furniture_id, "")

		var card: PanelContainer = kit.create_card()
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 12)

		var icon_label := Label.new()
		icon_label.text = icon_tag
		icon_label.add_theme_font_size_override("font_size", 22)
		icon_label.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
		icon_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_label.custom_minimum_size = Vector2(60, 60)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_label)

		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = info["name"]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", UIPalette.TEXT_PRIMARY)
		left.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = info["desc"]
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		left.add_child(desc_label)

		var level_label := Label.new()
		level_label.text = "Lv %d / %d" % [level, max_lvl]
		level_label.add_theme_font_size_override("font_size", 16)
		level_label.add_theme_color_override(
			"font_color",
			UIPalette.DREAM_VIOLET if not is_maxed else UIPalette.TEXT_MUTED
		)
		left.add_child(level_label)

		hbox.add_child(left)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = action_sz
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if is_maxed:
			buy_btn.text = "MAX"
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_color", UIPalette.TEXT_MUTED)
		else:
			buy_btn.text = "%d" % cost
			var bal: int = int(MetaProgression.dream_shards)
			var can_afford := bal >= int(cost)
			if can_afford:
				StoreUiKit.apply_button_label_tint(buy_btn, UIPalette.MOON_GOLD)
				buy_btn.pressed.connect(host.buy_furniture_upgrade.bind(furniture_id))
			else:
				StoreUiKit.apply_button_label_tint(buy_btn, UIPalette.DANGER)
				buy_btn.pressed.connect(host.open_shard_shortage_overlay.bind(cost))

		var btn_style: StyleBoxFlat = kit.make_button_style()
		buy_btn.add_theme_stylebox_override("normal", btn_style)
		buy_btn.add_theme_stylebox_override("hover", btn_style)
		buy_btn.add_theme_stylebox_override("pressed", btn_style)
		buy_btn.add_theme_font_size_override("font_size", 20)

		hbox.add_child(buy_btn)
		card.add_child(hbox)
		item_list.add_child(card)
