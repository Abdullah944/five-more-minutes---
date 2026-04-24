extends Control

## Game Over screen — "You Woke Up!" with stats and buttons.

signal retry_pressed
signal home_pressed

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var time_label: Label = $Panel/VBox/StatsBox/TimeLabel
@onready var enemies_label: Label = $Panel/VBox/StatsBox/EnemiesLabel
@onready var wave_label: Label = $Panel/VBox/StatsBox/WaveLabel
@onready var shards_label: Label = $Panel/VBox/ShardsLabel
@onready var retry_btn: Button = $Panel/VBox/ButtonBox/RetryButton
@onready var home_btn: Button = $Panel/VBox/ButtonBox/HomeButton
@onready var panel: PanelContainer = $Panel

var _shards_earned: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_btn.pressed.connect(_on_retry)
	home_btn.pressed.connect(_on_home)


@onready var best_label: Label = $Panel/VBox/StatsBox/BestLabel


func show_results(stats: Dictionary, shards: int) -> void:
	visible = true
	_shards_earned = shards

	@warning_ignore("integer_division")
	var total_sec := int(stats.get("elapsed_time", 0.0))
	@warning_ignore("integer_division")
	var mins := total_sec / 60
	@warning_ignore("integer_division")
	var secs := total_sec % 60
	time_label.text = "[T] Time: %d:%02d" % [mins, secs]
	enemies_label.text = "[X] Enemies: %d" % stats.get("enemies_defeated", 0)
	wave_label.text = "[W] Wave: %d" % stats.get("wave_number", 0)
	shards_label.text = "[*] Dream Shards: +%d" % shards

	@warning_ignore("integer_division")
	var best_sec := int(MetaProgression.best_survival_time)
	@warning_ignore("integer_division")
	var best_m := best_sec / 60
	@warning_ignore("integer_division")
	var best_s := best_sec % 60
	if best_label:
		best_label.text = "[!] Best Run: %d:%02d" % [best_m, best_s]

	# Slide in animation
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.7, 0.7)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Count up the shards number
	shards_label.text = "Dream Shards: +0"
	_animate_shard_count(shards)


func _animate_shard_count(target: int) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_update_shard_text, 0, target, 0.8).set_delay(0.5)


func _update_shard_text(value: int) -> void:
	shards_label.text = "[*] Dream Shards: +%d" % value


func _on_retry() -> void:
	visible = false
	retry_pressed.emit()


func _on_home() -> void:
	visible = false
	home_pressed.emit()
