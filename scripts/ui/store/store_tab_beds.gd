extends Object
class_name StoreTabBeds

## Store tab: bed catalog rows (unlock / equip).

const BED_ICON := "[BED]"


static func populate(item_list: VBoxContainer, kit: Variant, host: Control) -> void:
	var vw: float = host.get_viewport().get_visible_rect().size.x
	var action_sz: Vector2 = StoreUiKit.scaled_action_button_size(vw)
	for bed_id: String in MetaProgression.BED_CATALOG:
		var info: Dictionary = MetaProgression.BED_CATALOG[bed_id]
		var owned := bed_id in MetaProgression.unlocked_beds
		var selected := bed_id == MetaProgression.selected_bed
		var cost: int = info["cost"]

		var card: PanelContainer = kit.create_card()
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 12)

		var icon_label := Label.new()
		icon_label.text = BED_ICON
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

		var perk_text: String = info.get("perk", "")
		if perk_text != "":
			var perk_label := Label.new()
			perk_label.text = perk_text
			perk_label.add_theme_font_size_override("font_size", 16)
			perk_label.add_theme_color_override("font_color", UIPalette.SUCCESS)
			left.add_child(perk_label)

		hbox.add_child(left)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = action_sz
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var btn_style: StyleBoxFlat = kit.make_button_style()

		if selected:
			action_btn.text = "Equipped"
			action_btn.disabled = true
			action_btn.add_theme_color_override("font_color", UIPalette.SUCCESS)
		elif owned:
			action_btn.text = "Equip"
			action_btn.add_theme_color_override("font_color", UIPalette.DREAM_VIOLET)
			action_btn.pressed.connect(host.equip_bed.bind(bed_id))
		else:
			action_btn.text = "%d" % cost
			var can_afford := int(MetaProgression.dream_shards) >= int(cost)
			if can_afford:
				StoreUiKit.apply_button_label_tint(action_btn, UIPalette.MOON_GOLD)
				action_btn.pressed.connect(host.buy_bed.bind(bed_id))
			else:
				StoreUiKit.apply_button_label_tint(action_btn, UIPalette.DANGER)
				action_btn.pressed.connect(host.open_shard_shortage_overlay.bind(cost))

		action_btn.add_theme_stylebox_override("normal", btn_style)
		action_btn.add_theme_stylebox_override("hover", btn_style)
		action_btn.add_theme_stylebox_override("pressed", btn_style)
		action_btn.add_theme_font_size_override("font_size", 20)

		hbox.add_child(action_btn)
		card.add_child(hbox)
		item_list.add_child(card)
