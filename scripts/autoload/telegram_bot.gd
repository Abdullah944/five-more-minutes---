extends Node

## Dev-only Telegram bot for remote control and monitoring.
## Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from res://.env at runtime.
## Polls getUpdates every 3 seconds and only responds to the authorised chat.
## Autoload singleton — access via TelegramBot anywhere.

const ENV_PATH := "res://.env"
const POLL_INTERVAL: float = 3.0
const TELEGRAM_API := "https://api.telegram.org/bot"

# --- State ---

var _token: String = ""
var _chat_id: String = ""
var _update_offset: int = 0
var _poll_timer: float = 0.0
var _enabled: bool = false
var _polling: bool = false

var _poll_request: HTTPRequest
var _send_request: HTTPRequest


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		return

	_load_env()
	if _token.is_empty() or _chat_id.is_empty():
		push_warning("TelegramBot: Missing token or chat_id in %s — bot disabled." % ENV_PATH)
		set_process(false)
		return

	_poll_request = HTTPRequest.new()
	_poll_request.request_completed.connect(_on_poll_completed)
	add_child(_poll_request)

	_send_request = HTTPRequest.new()
	add_child(_send_request)

	_enabled = true
	_send_message("Five More Minutes! bot online.")


func _process(delta: float) -> void:
	if not _enabled:
		return
	_poll_timer += delta
	if _poll_timer >= POLL_INTERVAL:
		_poll_timer = 0.0
		_poll_updates()


# --- Public API ---

func send_message(text: String) -> void:
	if _enabled:
		_send_message(text)


# --- Telegram I/O ---

func _poll_updates() -> void:
	if _polling:
		return
	_polling = true
	var url := "%s%s/getUpdates?offset=%d&timeout=0" % [TELEGRAM_API, _token, _update_offset]
	_poll_request.request(url)


func _send_message(text: String) -> void:
	var url := "%s%s/sendMessage" % [TELEGRAM_API, _token]
	var body := JSON.stringify({ "chat_id": _chat_id, "text": text, "parse_mode": "HTML" })
	var headers := ["Content-Type: application/json"]
	_send_request.request(url, headers, HTTPClient.METHOD_POST, body)


func _on_poll_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_polling = false
	if response_code != 200:
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return

	var data: Dictionary = json.data
	if not data.get("ok", false):
		return

	var updates: Array = data.get("result", [])
	for update: Dictionary in updates:
		var update_id: int = update.get("update_id", 0)
		_update_offset = update_id + 1

		var message: Dictionary = update.get("message", {})
		var chat: Dictionary = message.get("chat", {})
		var sender_id := str(chat.get("id", 0))

		if sender_id != _chat_id:
			continue

		var text: String = message.get("text", "").strip_edges()
		if text.begins_with("/"):
			_handle_command(text)


# --- Command dispatch ---

func _handle_command(text: String) -> void:
	var parts := text.split(" ", false, 2)
	var cmd := parts[0].to_lower()
	var arg := parts[1] if parts.size() > 1 else ""

	match cmd:
		"/status":
			_cmd_status()
		"/spawn":
			_cmd_spawn(arg)
		"/pause":
			_cmd_pause()
		"/screenshot":
			_cmd_screenshot()
		"/build":
			_cmd_build()
		_:
			_send_message("Unknown command: %s" % cmd)


func _cmd_status() -> void:
	var state: String = GameManager.RunState.keys()[GameManager.run_state]
	var time_str := "%.1fs" % GameManager.elapsed_time
	var night: int = GameManager.current_night
	var kills: int = GameManager.enemies_defeated
	var meter := "%.0f%%" % (SleepMeter.current_value * 100.0)
	var zone: String = SleepMeter.DepthZone.keys()[SleepMeter.current_zone]
	var shards: int = MetaProgression.dream_shards

	var msg := "<b>Status</b>\n"
	msg += "State: %s\n" % state
	msg += "Time: %s | Night: %d\n" % [time_str, night]
	msg += "Kills: %d\n" % kills
	msg += "Sleep: %s (%s)\n" % [meter, zone]
	msg += "Shards: %d" % shards
	_send_message(msg)


func _cmd_spawn(enemy_name: String) -> void:
	if enemy_name.is_empty():
		_send_message("Usage: /spawn <enemy_name>")
		return
	# Spawn request — the game scene listens and handles actual instantiation
	if GameManager.run_state != GameManager.RunState.PLAYING:
		_send_message("Can't spawn — no active run.")
		return
	_send_message("Spawn request: %s (wire up EnemySpawner listener)" % enemy_name)


func _cmd_pause() -> void:
	match GameManager.run_state:
		GameManager.RunState.PLAYING:
			GameManager.pause_run()
			get_tree().paused = true
			_send_message("Game paused.")
		GameManager.RunState.PAUSED:
			GameManager.resume_run()
			get_tree().paused = false
			_send_message("Game resumed.")
		_:
			_send_message("No active run to pause/resume.")


func _cmd_screenshot() -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "user://screenshot_%s.png" % Time.get_unix_time_from_system()
	img.save_png(path)
	_send_message("Screenshot saved: %s" % path)


func _cmd_build() -> void:
	var info := {
		"engine": Engine.get_version_info().get("string", "?"),
		"debug": OS.is_debug_build(),
		"os": OS.get_name(),
		"locale": OS.get_locale(),
		"video": RenderingServer.get_video_adapter_name(),
	}
	var msg := "<b>Build Info</b>\n"
	for key: String in info:
		msg += "%s: %s\n" % [key, str(info[key])]
	_send_message(msg)


# --- .env parser ---

func _load_env() -> void:
	if not FileAccess.file_exists(ENV_PATH):
		return
	var file := FileAccess.open(ENV_PATH, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var eq := line.find("=")
		if eq < 1:
			continue
		var key := line.substr(0, eq).strip_edges()
		var val := line.substr(eq + 1).strip_edges()
		match key:
			"TELEGRAM_BOT_TOKEN":
				_token = val
			"TELEGRAM_CHAT_ID":
				_chat_id = val
