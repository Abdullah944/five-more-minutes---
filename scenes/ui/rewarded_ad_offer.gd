extends Control

## Optional rewarded video offer (waves 4, 8, …). Simulated ad in all builds; replace `_play_rewarded_video` with your store SDK.

signal finished

const AD_SIMULATE_SECONDS: float = 0.85
const HINT_DEFAULT: String = "Optional — watch a short video for a perk. (Simulated here — wire AdMob rewarded in _play_rewarded_video.)"

@onready var panel: PanelContainer = $CenterPanel
@onready var hint_label: Label = $CenterPanel/VBox/HintLabel
@onready var xp_btn: Button = $CenterPanel/VBox/XpRow/XpButton
@onready var shield_btn: Button = $CenterPanel/VBox/ShieldRow/ShieldButton
@onready var skip_btn: Button = $CenterPanel/VBox/SkipButton

var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	xp_btn.pressed.connect(_on_xp_pressed)
	shield_btn.pressed.connect(_on_shield_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)


func _game_root() -> Node:
	return get_parent().get_parent()


func open_offer() -> void:
	if _busy or visible:
		return
	hint_label.text = HINT_DEFAULT
	_busy = false
	visible = true
	modulate.a = 1.0
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	get_tree().paused = true
	GameManager.pause_run()
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.14).set_ease(Tween.EASE_OUT)


func _close_without_reward() -> void:
	if not visible:
		return
	get_tree().paused = false
	GameManager.resume_run()
	visible = false
	finished.emit()


func _on_skip_pressed() -> void:
	if _busy:
		return
	_close_without_reward()


func _on_xp_pressed() -> void:
	if _busy:
		return
	await _grant_after_ad("xp")


func _on_shield_pressed() -> void:
	if _busy:
		return
	await _grant_after_ad("shield")


func _grant_after_ad(kind: String) -> void:
	if _busy or not visible:
		return
	_busy = true
	xp_btn.disabled = true
	shield_btn.disabled = true
	skip_btn.disabled = true
	hint_label.text = "Playing video…"

	await _play_rewarded_video()

	var root := _game_root()
	if root:
		match kind:
			"xp":
				var hud: Node = root.get_node_or_null("HUD")
				if hud and hud.has_method("add_xp"):
					hud.add_xp(10.0)
			"shield":
				var bed: Node = root.get_node_or_null("World/Bed")
				if bed and bed.has_method("grant_invulnerable"):
					bed.grant_invulnerable(3.0)

	AudioManager.play_ui_by_name("purchase", -4.0)

	get_tree().paused = false
	GameManager.resume_run()
	hint_label.text = HINT_DEFAULT
	visible = false
	xp_btn.disabled = false
	shield_btn.disabled = false
	skip_btn.disabled = false
	_busy = false
	finished.emit()


func _play_rewarded_video() -> void:
	# Swap for: load rewarded ad → show → on_user_earned_reward → resume.
	var timer := get_tree().create_timer(AD_SIMULATE_SECONDS, true)
	await timer.timeout
