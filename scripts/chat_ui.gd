## Chat panel UI - text + voice conversation with agents via Gateway WebSocket.
## Chat history persists per room - leaving and returning restores previous conversation.
## Key methods: show_chat(room), hide_chat()
## Signals: connects to VoiceChat.transcription_received, GatewayWS signals
## Depends on: SettingsManager (autoload), VoiceChat, GatewayWS
extends CanvasLayer

var current_room: String = ""
var chat_history: Array = []
var is_thinking: bool = false

# Per-room chat history persistence
var room_histories: Dictionary = {}  # room_name -> Array of {role, content}
var room_logs: Dictionary = {}  # room_name -> String (BBCode chat log text)

# Streaming state
var _streaming_text: String = ""
var _is_streaming: bool = false

# Voice status indicator
var voice_status: String = "listening"  # listening, recording, processing

@onready var panel = $Panel
@onready var chat_log = $Panel/VBoxContainer/ChatLog
@onready var room_label = $Panel/VBoxContainer/RoomLabel
@onready var voice_indicator = $Panel/VBoxContainer/VoiceIndicator
@onready var text_input = $Panel/VBoxContainer/TextInput
@onready var http_request = $HTTPRequest

var _gateway_ws: Node = null
var _greeting_in_progress: bool = false
var _pending_image: Image = null  # Clipboard image waiting to be sent

func _ready():
	panel.visible = false
	http_request.request_completed.connect(_on_request_completed)

	# Connect text input
	if text_input:
		text_input.text_submitted.connect(_on_text_submitted)
		text_input.gui_input.connect(_on_text_gui_input)

	# Connect voice chat signals
	_connect_voice_chat.call_deferred()
	# Connect gateway WS signals
	_connect_gateway.call_deferred()

func _connect_gateway():
	_gateway_ws = get_node_or_null("/root/Main/GatewayWS")
	if _gateway_ws:
		_gateway_ws.message_delta.connect(_on_ws_delta)
		_gateway_ws.message_final.connect(_on_ws_final)
		_gateway_ws.connected.connect(_on_ws_connected)
		# Start connection
		if SettingsManager.gateway_url != "" and SettingsManager.gateway_token != "":
			_gateway_ws.start_connection()

func _connect_voice_chat():
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat:
		voice_chat.transcription_received.connect(_on_transcription)
		voice_chat.tts_started.connect(_on_tts_started)
		voice_chat.tts_finished.connect(_on_tts_finished)

func _get_current_agent_id() -> String:
	if _gateway_ws and _gateway_ws.agent_map.has(current_room):
		return _gateway_ws.agent_map[current_room]
	return ""

func show_chat(room_name: String):
	current_room = room_name
	is_thinking = false
	_is_streaming = false
	_streaming_text = ""
	var display_name = room_name
	if SettingsManager.agent_configs.has(room_name):
		display_name = SettingsManager.agent_configs[room_name].get("agent_name", room_name)
	room_label.text = "📍 " + display_name + "'s Office"

	# Restore previous chat history for this room, or start fresh
	var is_first_visit = false
	if room_histories.has(room_name) and room_histories[room_name].size() > 0:
		chat_history = room_histories[room_name].duplicate(true)
		chat_log.text = room_logs.get(room_name, "")
	else:
		is_first_visit = true
		chat_history = []
		chat_log.text = "[color=gray]You entered " + room_name + "'s office.[/color]\n"

	panel.visible = true
	# Keep mouse captured - player can still look around
	panel.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent overlay
	if voice_indicator:
		voice_indicator.visible = false
	if text_input:
		text_input.grab_focus.call_deferred()

	# Inject office context and auto-greet on first visit via WebSocket
	if is_first_visit and _gateway_ws and _gateway_ws.is_ws_connected():
		_gateway_ws.inject_office_context(room_name)
		_request_greeting(room_name)

func hide_chat():
	# Save chat history before hiding
	if not current_room.is_empty() and chat_history.size() > 0:
		room_histories[current_room] = chat_history.duplicate(true)
		room_logs[current_room] = chat_log.text

	panel.visible = false
	current_room = ""
	chat_history = []
	is_thinking = false
	_is_streaming = false
	_streaming_text = ""
	# Ensure typing mode is exited
	if text_input and text_input.has_focus():
		text_input.release_focus()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_voice_status(status: String):
	voice_status = status
	if not voice_indicator:
		return
	match status:
		"listening":
			voice_indicator.visible = false
			return
		"recording":
			voice_indicator.visible = true
			voice_indicator.text = "🔴 LIVE"
			voice_indicator.modulate = Color(1, 0.2, 0.2, 1)
		"processing":
			voice_indicator.visible = true
			voice_indicator.text = "⏳ Processing..."
			voice_indicator.modulate = Color(0.8, 0.8, 0.3, 0.9)
		"thinking":
			voice_indicator.visible = true
			voice_indicator.text = "💭 " + current_room + " is thinking..."
			voice_indicator.modulate = Color(0.6, 0.6, 0.8, 0.9)
		"speaking":
			voice_indicator.visible = true
			voice_indicator.text = "🔊 " + current_room + " is speaking..."
			voice_indicator.modulate = Color(0.8, 0.7, 0.3, 0.9)

func _on_text_gui_input(_event: InputEvent):
	pass

func _process(_delta):
	# Keep cursor in text input whenever chat panel is visible
	if not panel.visible or not text_input:
		return
	var welcome = get_node_or_null("/root/Main/WelcomeOverlay")
	if welcome and welcome.is_showing:
		return
	var settings_menu = get_node_or_null("/root/Main/SettingsMenu")
	if settings_menu and settings_menu.is_open:
		return
	if not text_input.has_focus():
		text_input.grab_focus()

func _unhandled_input(event: InputEvent):
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_V:
			_try_paste_image()

func _try_paste_image():
	var img = DisplayServer.clipboard_get_image()
	if img == null or img.is_empty():
		return  # No image on clipboard, let normal text paste happen
	_pending_image = img
	# Show preview indicator
	chat_log.text += "\n[color=green]📎 Image pasted (will send with next message)[/color]\n"
	if text_input:
		text_input.placeholder_text = "Type a message about this image, or press Enter to send..."
		text_input.grab_focus()

func _on_text_submitted(text: String):
	var msg = text.strip_edges()
	if msg.is_empty() and _pending_image == null:
		return
	text_input.text = ""
	if msg.is_empty():
		msg = "What's in this image?"
	_submit_message(msg)
	text_input.placeholder_text = "Type a message..."
	text_input.grab_focus.call_deferred()

func _on_transcription(text: String):
	if text.is_empty():
		chat_log.text += "[color=red]Could not understand audio[/color]\n"
		set_voice_status("listening")
		return
	_submit_message(text)

func _submit_message(text: String):
	if is_thinking:
		chat_log.text += "\n[color=gray][i](waiting for response...)[/i][/color]\n"
		return

	var has_image = _pending_image != null
	if has_image:
		chat_log.text += "\n[color=cyan]You:[/color] 📎 " + text + "\n"
	else:
		chat_log.text += "\n[color=cyan]You:[/color] " + text + "\n"
	chat_history.append({"role": "user", "content": text})

	is_thinking = true
	set_voice_status("thinking")
	chat_log.text += "[color=gray][i]...[/i][/color]\n"

	# Build attachments from pending image
	var attachments: Array = []
	if has_image:
		var png_data = _pending_image.save_png_to_buffer()
		var b64 = Marshalls.raw_to_base64(png_data)
		attachments.append({
			"type": "image",
			"source": {
				"type": "base64",
				"media_type": "image/png",
				"data": b64
			}
		})
		_pending_image = null

	# Send via WebSocket if connected, otherwise fall back to HTTP
	if _gateway_ws and _gateway_ws.is_ws_connected():
		_gateway_ws.send_message(current_room, text, attachments)
	else:
		_send_to_openclaw(text)

func _on_tts_started():
	set_voice_status("speaking")

func _on_tts_finished():
	if panel.visible:
		set_voice_status("listening")

func _on_ws_connected():
	print("[ChatUI] Gateway WebSocket connected")

func _agent_id_to_room(agent_id: String) -> String:
	if not _gateway_ws:
		return ""
	for room_name in _gateway_ws.agent_map:
		if _gateway_ws.agent_map[room_name] == agent_id:
			return room_name
	return ""

func _on_ws_delta(agent_id: String, text: String):
	# Only handle deltas for the current room's agent
	if _get_current_agent_id() != agent_id:
		# Buffer for the correct room if it's a different agent
		var target_room = _agent_id_to_room(agent_id)
		if not target_room.is_empty() and target_room != current_room:
			if not room_histories.has(target_room):
				room_histories[target_room] = []
			# Store streaming text in a buffer keyed by agent
			if not has_meta("stream_" + agent_id):
				set_meta("stream_" + agent_id, "")
			set_meta("stream_" + agent_id, get_meta("stream_" + agent_id) + text)
		return
	if not panel.visible:
		return

	if not _is_streaming:
		_is_streaming = true
		_streaming_text = ""
		# Remove thinking indicator
		_remove_thinking_indicator()
		# Start the agent's line
		chat_log.text += "[color=yellow]" + current_room + ":[/color] "

	_streaming_text += text
	# Update display with current streamed text (strip tags for display)
	_update_streaming_display()

func _on_ws_final(agent_id: String, text: String):
	if _get_current_agent_id() != agent_id:
		# Buffer the final response for the correct room
		var target_room = _agent_id_to_room(agent_id)
		if not target_room.is_empty() and target_room != current_room:
			var buffered = ""
			if has_meta("stream_" + agent_id):
				buffered = get_meta("stream_" + agent_id)
				remove_meta("stream_" + agent_id)
			var final_text = text if not text.is_empty() else buffered
			if not final_text.is_empty():
				if not room_histories.has(target_room):
					room_histories[target_room] = []
				room_histories[target_room].append({"role": "assistant", "content": final_text})
				var display = _strip_command_tags(final_text).strip_edges()
				var log_text = room_logs.get(target_room, "")
				log_text += "[color=yellow]" + target_room + ":[/color] " + display + "\n"
				room_logs[target_room] = log_text
		return
	if not panel.visible:
		return

	var final_text = text if not text.is_empty() else _streaming_text

	if not _is_streaming:
		# We got a final without deltas - remove thinking indicator first
		_remove_thinking_indicator()

	is_thinking = false
	_is_streaming = false
	_streaming_text = ""

	if final_text.is_empty():
		set_voice_status("listening")
		return

	# For greetings, only add assistant reply
	if _greeting_in_progress:
		_greeting_in_progress = false

	chat_history.append({"role": "assistant", "content": final_text})

	# Handle office command tags
	_handle_music_commands(final_text)
	_handle_tv_commands(final_text)
	_handle_light_commands(final_text)
	_handle_env_commands(final_text)

	var display_reply = _strip_command_tags(final_text).strip_edges()

	# Replace the streaming line with the final clean version
	# Remove any partial streaming content and rewrite
	var lines = chat_log.text.split("\n")
	# Find and remove the last agent line (streaming)
	var cleaned_lines := []
	var found_agent_line := false
	for i in range(lines.size() - 1, -1, -1):
		if not found_agent_line and lines[i].begins_with("[color=yellow]" + current_room + ":[/color]"):
			found_agent_line = true
			continue  # skip it, we'll re-add
		cleaned_lines.push_front(lines[i])

	if found_agent_line:
		chat_log.text = "\n".join(cleaned_lines) + "\n"

	chat_log.text += "[color=yellow]" + current_room + ":[/color] " + display_reply + "\n"

	# Play receive sound
	var recv_sound = get_node_or_null("/root/Main/ChatReceiveSound")
	if recv_sound and recv_sound.stream:
		recv_sound.play()

	# Request TTS
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat:
		voice_chat.request_tts(display_reply)

	set_voice_status("listening")

	# Re-grab focus so user can keep chatting
	if text_input and panel.visible:
		text_input.grab_focus.call_deferred()

func _remove_thinking_indicator():
	var lines = chat_log.text.split("\n")
	var cleaned_lines := []
	for line in lines:
		if not ("[i]...[/i]" in line):
			cleaned_lines.append(line)
	chat_log.text = "\n".join(cleaned_lines)

func _update_streaming_display():
	# Show stripped version of streaming text on the current line
	var display = _strip_command_tags(_streaming_text)
	# Replace the last agent line with updated streaming content
	var lines = chat_log.text.split("\n")
	var new_lines := []
	var replaced := false
	for i in range(lines.size() - 1, -1, -1):
		if not replaced and lines[i].begins_with("[color=yellow]" + current_room + ":[/color]"):
			new_lines.push_front("[color=yellow]" + current_room + ":[/color] " + display)
			replaced = true
		else:
			new_lines.push_front(lines[i])
	if not replaced:
		new_lines.append("[color=yellow]" + current_room + ":[/color] " + display)
	chat_log.text = "\n".join(new_lines)

func _request_greeting(room_name: String):
	_greeting_in_progress = true
	is_thinking = true
	set_voice_status("thinking")
	chat_log.text += "[color=gray][i]...[/i][/color]\n"

	if _gateway_ws and _gateway_ws.is_ws_connected():
		_gateway_ws.send_message(room_name, "The user just walked into your office. Give a brief, friendly greeting (1 sentence).")
	else:
		# Fallback to HTTP
		var messages = [
			{"role": "system", "content": _build_system_prompt()},
			{"role": "user", "content": "The user just walked into your office. Give a brief, friendly greeting (1 sentence)."}
		]
		_send_chat_request(messages, 100)

func clear_chat():
	chat_log.text = "[color=gray]Chat cleared.[/color]\n"
	chat_history = []
	if not current_room.is_empty():
		room_histories.erase(current_room)
		room_logs.erase(current_room)

# ===== HTTP Fallback (kept for when WS is not connected) =====

func _build_system_prompt() -> String:
	var system_prompt = "You are " + current_room + ", an AI agent in a virtual office. Keep responses concise (2-3 sentences). Be conversational."
	if SettingsManager.agent_configs.has(current_room):
		var cfg = SettingsManager.agent_configs[current_room]
		if cfg.has("system_prompt") and not cfg["system_prompt"].is_empty():
			system_prompt = cfg["system_prompt"]
	system_prompt += "\nYou can control your office environment using tags (they're stripped before display):"
	system_prompt += "\n\nMusic: [MUSIC_UP] [MUSIC_DOWN] [MUSIC_OFF] [MUSIC_ON]"
	if current_room == "Ultron":
		system_prompt += "\n\nMonitors (you have 3 desk monitors - left, center, right):"
		system_prompt += "\n[SCREEN1:url] - display image on left monitor"
		system_prompt += "\n[SCREEN2:url] - display image on center monitor (main)"
		system_prompt += "\n[SCREEN3:url] - display image on right monitor"
		system_prompt += "\n[TV_SHOW:url] - shortcut for center monitor"
		system_prompt += "\n[SCREEN_CLEAR:1] [SCREEN_CLEAR:2] [SCREEN_CLEAR:3] - clear specific monitor"
		system_prompt += "\n[TV_OFF] - clear all monitors"
	else:
		system_prompt += "\n\nTV Screen (your office has a wall-mounted TV you can display images on):"
		system_prompt += "\n[TV_SHOW:url] - display an image on your TV (use a direct image URL, png/jpg/webp)"
		system_prompt += "\n[TV_OFF] - clear the TV screen"
	system_prompt += "\n\nRoom Lights:"
	system_prompt += "\n[LIGHTS_COLOR:#hexcolor] - change your office light color (e.g. #FF0000 for red)"
	system_prompt += "\n[LIGHTS_BRIGHT:0-100] - set light brightness (0=off, 100=max)"
	return system_prompt

func _send_chat_request(messages: Array, max_tokens: int = 200):
	var body = JSON.stringify({
		"model": "anthropic/claude-sonnet-4-20250514",
		"messages": messages,
		"max_tokens": max_tokens
	})
	var headers = ["Content-Type: application/json"]
	if SettingsManager.gateway_token != "":
		headers.append("Authorization: Bearer " + SettingsManager.gateway_token)
	var url = SettingsManager.gateway_url + "/v1/chat/completions"
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		chat_log.text += "[color=red]Error connecting to OpenClaw[/color]\n"
		is_thinking = false
		_greeting_in_progress = false
		set_voice_status("listening")

func _send_to_openclaw(_user_msg: String):
	var messages = [{"role": "system", "content": _build_system_prompt()}]
	messages.append_array(chat_history)
	_send_chat_request(messages)

func _on_request_completed(result, response_code, _headers, body_bytes):
	is_thinking = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_greeting_in_progress = false
		chat_log.text += "[color=red]Error: " + str(response_code) + "[/color]\n"
		set_voice_status("listening")
		return

	var json = JSON.parse_string(body_bytes.get_string_from_utf8())
	if json and json.has("choices") and json["choices"].size() > 0:
		var reply = json["choices"][0]["message"]["content"]

		if _greeting_in_progress:
			_greeting_in_progress = false
		chat_history.append({"role": "assistant", "content": reply})

		_remove_thinking_indicator()

		_handle_music_commands(reply)
		_handle_tv_commands(reply)
		_handle_light_commands(reply)
		_handle_env_commands(reply)
		var display_reply = _strip_command_tags(reply).strip_edges()

		chat_log.text += "[color=yellow]" + current_room + ":[/color] " + display_reply + "\n"
		var recv_sound = get_node_or_null("/root/Main/ChatReceiveSound")
		if recv_sound and recv_sound.stream:
			recv_sound.play()

		var voice_chat = get_node_or_null("/root/Main/VoiceChat")
		if voice_chat:
			voice_chat.request_tts(display_reply)
	else:
		chat_log.text += "[color=red]No response from agent[/color]\n"
		set_voice_status("listening")

# ===== Office Command Handlers =====

func _handle_music_commands(text: String):
	var ambiance = get_node_or_null("/root/Main/Ambiance")
	if not ambiance or not ambiance.has_node("BackgroundMusic"):
		return
	var music = ambiance.get_node("BackgroundMusic")
	if "[MUSIC_UP]" in text:
		music.volume_db = min(music.volume_db + 3.0, 0.0)
	if "[MUSIC_DOWN]" in text:
		music.volume_db = max(music.volume_db - 3.0, -40.0)
	if "[MUSIC_OFF]" in text:
		music.stream_paused = true
	if "[MUSIC_ON]" in text:
		music.stream_paused = false
		if not music.playing:
			music.play()

func _handle_tv_commands(text: String):
	var tv_display = get_node_or_null("/root/Main/TVDisplay")
	if not tv_display:
		return
	# Standard TV_SHOW (wall TV for other agents, center monitor for Ultron)
	var regex = RegEx.new()
	regex.compile("\\[TV_SHOW:(https?://[^\\]]+)\\]")
	var tv_match = regex.search(text)
	if tv_match:
		tv_display.show_image_on_tv(current_room, tv_match.get_string(1))
	# Ultron-specific: [SCREEN1:url] [SCREEN2:url] [SCREEN3:url]
	var screen_regex = RegEx.new()
	screen_regex.compile("\\[SCREEN([123]):(https?://[^\\]]+)\\]")
	var screen_matches = screen_regex.search_all(text)
	for m in screen_matches:
		var screen_num = int(m.get_string(1))
		var url = m.get_string(2)
		tv_display.show_on_screen(screen_num, url)
	# [SCREEN_CLEAR:N]
	var clear_regex = RegEx.new()
	clear_regex.compile("\\[SCREEN_CLEAR:([123])\\]")
	var clear_matches = clear_regex.search_all(text)
	for m in clear_matches:
		tv_display.clear_screen(int(m.get_string(1)))
	# TV_OFF clears all
	if "[TV_OFF]" in text:
		tv_display.clear_tv(current_room)

func _handle_env_commands(text: String):
	var regex = RegEx.new()
	regex.compile("\\[ENV:([^\\]]+)\\]")
	var m = regex.search(text)
	if m:
		var preset_name = m.get_string(1).strip_edges()
		var env_mgr = get_node_or_null("/root/Main/EnvironmentManager")
		if env_mgr:
			env_mgr.switch_env(preset_name)

func _handle_light_commands(text: String):
	var room_prefix = ""
	match current_room:
		"Spinfluencer": room_prefix = "Room2"
		"Dexer": room_prefix = "Room3"
		"DJ Sam": room_prefix = "Room4"
		_: return

	var color_regex = RegEx.new()
	color_regex.compile("\\[LIGHTS_COLOR:#([0-9a-fA-F]{6})\\]")
	var color_match = color_regex.search(text)
	if color_match:
		var hex = color_match.get_string(1)
		var color = Color(hex)
		for suffix in ["_Light", "_Light2"]:
			var light = get_node_or_null("/root/Main/" + room_prefix + suffix)
			if light and light is OmniLight3D:
				light.light_color = color

	var bright_regex = RegEx.new()
	bright_regex.compile("\\[LIGHTS_BRIGHT:(\\d+)\\]")
	var bright_match = bright_regex.search(text)
	if bright_match:
		var val = clamp(int(bright_match.get_string(1)), 0, 100)
		var energy = val / 100.0 * 2.0
		for suffix in ["_Light", "_Light2"]:
			var light = get_node_or_null("/root/Main/" + room_prefix + suffix)
			if light and light is OmniLight3D:
				light.light_energy = energy

func _strip_command_tags(text: String) -> String:
	var result = text
	for tag in ["[MUSIC_UP]", "[MUSIC_DOWN]", "[MUSIC_OFF]", "[MUSIC_ON]", "[TV_OFF]"]:
		result = result.replace(tag, "")
	var regex = RegEx.new()
	regex.compile("\\[TV_SHOW:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[LIGHTS_COLOR:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[LIGHTS_BRIGHT:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[SCREEN[123]:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[SCREEN_CLEAR:[123]\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[ENV:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	return result.strip_edges()
