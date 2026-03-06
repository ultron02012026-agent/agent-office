## Chat panel UI — text + voice conversation with agents.
## Chat history persists per room — leaving and returning restores previous conversation.
## Key methods: show_chat(room), hide_chat(), _send_to_openclaw()
## Signals: connects to VoiceChat.transcription_received
## Depends on: SettingsManager (autoload), VoiceChat (/root/Main/VoiceChat), HTTPRequest child
extends CanvasLayer

var current_room: String = ""
var chat_history: Array = []
var is_thinking: bool = false

# Per-room chat history persistence
var room_histories: Dictionary = {}  # room_name -> Array of {role, content}
var room_logs: Dictionary = {}  # room_name -> String (BBCode chat log text)

# Voice status indicator
var voice_status: String = "listening"  # listening, recording, processing

@onready var panel = $Panel
@onready var chat_log = $Panel/VBoxContainer/ChatLog
@onready var room_label = $Panel/VBoxContainer/RoomLabel
@onready var voice_indicator = $Panel/VBoxContainer/VoiceIndicator
@onready var text_input = $Panel/VBoxContainer/TextInput
@onready var http_request = $HTTPRequest

func _ready():
	panel.visible = false
	http_request.request_completed.connect(_on_request_completed)
	
	# Connect text input
	if text_input:
		text_input.text_submitted.connect(_on_text_submitted)
	
	# Connect voice chat signals
	_connect_voice_chat.call_deferred()

func _connect_voice_chat():
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat:
		voice_chat.transcription_received.connect(_on_transcription)
		voice_chat.tts_started.connect(_on_tts_started)
		voice_chat.tts_finished.connect(_on_tts_finished)

func show_chat(room_name: String):
	current_room = room_name
	is_thinking = false
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_voice_status("listening")
	if text_input:
		text_input.grab_focus()
	
	# Auto-greet on first visit (agent says hello)
	if is_first_visit and SettingsManager.gateway_url != "" and SettingsManager.gateway_token != "":
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
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_voice_status(status: String):
	voice_status = status
	if not voice_indicator:
		return
	match status:
		"listening":
			voice_indicator.text = "🎙️ Listening..."
			voice_indicator.modulate = Color(0.6, 0.8, 0.6, 0.8)
		"recording":
			voice_indicator.text = "🔴 LIVE"
			voice_indicator.modulate = Color(1, 0.2, 0.2, 1)
		"processing":
			voice_indicator.text = "⏳ Processing..."
			voice_indicator.modulate = Color(0.8, 0.8, 0.3, 0.9)
		"thinking":
			voice_indicator.text = "💭 " + current_room + " is thinking..."
			voice_indicator.modulate = Color(0.6, 0.6, 0.8, 0.9)
		"speaking":
			voice_indicator.text = "🔊 " + current_room + " is speaking..."
			voice_indicator.modulate = Color(0.8, 0.7, 0.3, 0.9)

func _on_text_submitted(text: String):
	if text.strip_edges().is_empty():
		return
	text_input.text = ""
	_submit_message(text.strip_edges())

func _on_transcription(text: String):
	if text.is_empty():
		chat_log.text += "[color=red]Could not understand audio[/color]\n"
		set_voice_status("listening")
		return
	_submit_message(text)

func _submit_message(text: String):
	# Guard against sending while already waiting for a response
	if is_thinking:
		chat_log.text += "\n[color=gray][i](waiting for response...)[/i][/color]\n"
		return
	
	# Add user text to transcript
	chat_log.text += "\n[color=cyan]You:[/color] " + text + "\n"
	chat_history.append({"role": "user", "content": text})
	
	# Show thinking indicator
	is_thinking = true
	set_voice_status("thinking")
	chat_log.text += "[color=gray][i]...[/i][/color]\n"
	_send_to_openclaw(text)

func _on_tts_started():
	set_voice_status("speaking")

func _on_tts_finished():
	if panel.visible:
		set_voice_status("listening")

func _build_system_prompt() -> String:
	var system_prompt = "You are " + current_room + ", an AI agent in a virtual office. Keep responses concise (2-3 sentences). Be conversational."
	if SettingsManager.agent_configs.has(current_room):
		var cfg = SettingsManager.agent_configs[current_room]
		if cfg.has("system_prompt") and not cfg["system_prompt"].is_empty():
			system_prompt = cfg["system_prompt"]
	system_prompt += "\nYou can control your office environment using tags (they're stripped before display):"
	system_prompt += "\n\nMusic: [MUSIC_UP] [MUSIC_DOWN] [MUSIC_OFF] [MUSIC_ON]"
	system_prompt += "\n\nTV Screen (your office has a wall-mounted TV you can display images on):"
	system_prompt += "\n[TV_SHOW:url] — display an image on your TV (use a direct image URL, png/jpg/webp)"
	system_prompt += "\n[TV_OFF] — clear the TV screen"
	system_prompt += "\n\nRoom Lights:"
	system_prompt += "\n[LIGHTS_COLOR:#hexcolor] — change your office light color (e.g. #FF0000 for red)"
	system_prompt += "\n[LIGHTS_BRIGHT:0-100] — set light brightness (0=off, 100=max)"
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
		
		# For greetings, only add the assistant reply (no fake user message)
		if _greeting_in_progress:
			_greeting_in_progress = false
		chat_history.append({"role": "assistant", "content": reply})
		
		# Remove the "..." thinking indicator (last line)
		var lines = chat_log.text.split("\n")
		var cleaned_lines = []
		for i in range(lines.size()):
			if not ("[i]...[/i]" in lines[i]):
				cleaned_lines.append(lines[i])
		chat_log.text = "\n".join(cleaned_lines)
		
		# Handle office command tags
		_handle_music_commands(reply)
		_handle_tv_commands(reply)
		_handle_light_commands(reply)
		# Strip tags before display
		var display_reply = _strip_command_tags(reply)
		display_reply = display_reply.strip_edges()
		
		chat_log.text += "[color=yellow]" + current_room + ":[/color] " + display_reply + "\n"
		# Play receive sound
		var recv_sound = get_node_or_null("/root/Main/ChatReceiveSound")
		if recv_sound and recv_sound.stream:
			recv_sound.play()
		
		# Request TTS for the response (without tags)
		var voice_chat = get_node_or_null("/root/Main/VoiceChat")
		if voice_chat:
			voice_chat.request_tts(display_reply)
	else:
		chat_log.text += "[color=red]No response from agent[/color]\n"
		set_voice_status("listening")

var _greeting_in_progress: bool = false

func _request_greeting(_room_name: String):
	# Agent auto-greets on first visit via a hidden system-level prompt
	_greeting_in_progress = true
	is_thinking = true
	set_voice_status("thinking")
	chat_log.text += "[color=gray][i]...[/i][/color]\n"
	
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
	# [TV_SHOW:url]
	var regex = RegEx.new()
	regex.compile("\\[TV_SHOW:(https?://[^\\]]+)\\]")
	var match = regex.search(text)
	if match:
		tv_display.show_image_on_tv(current_room, match.get_string(1))
	if "[TV_OFF]" in text:
		tv_display.clear_tv(current_room)

func _handle_light_commands(text: String):
	# Find room light nodes
	var room_prefix = ""
	match current_room:
		"Spinfluencer": room_prefix = "Room2"
		"Dexer": room_prefix = "Room3"
		"DJ Sam": room_prefix = "Room4"
		_: return
	
	# [LIGHTS_COLOR:#hexcolor]
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
	
	# [LIGHTS_BRIGHT:0-100]
	var bright_regex = RegEx.new()
	bright_regex.compile("\\[LIGHTS_BRIGHT:(\\d+)\\]")
	var bright_match = bright_regex.search(text)
	if bright_match:
		var val = clamp(int(bright_match.get_string(1)), 0, 100)
		var energy = val / 100.0 * 2.0  # 0-100 maps to 0.0-2.0 energy
		for suffix in ["_Light", "_Light2"]:
			var light = get_node_or_null("/root/Main/" + room_prefix + suffix)
			if light and light is OmniLight3D:
				light.light_energy = energy

func _strip_command_tags(text: String) -> String:
	var result = text
	for tag in ["[MUSIC_UP]", "[MUSIC_DOWN]", "[MUSIC_OFF]", "[MUSIC_ON]", "[TV_OFF]"]:
		result = result.replace(tag, "")
	# Strip parameterized tags
	var regex = RegEx.new()
	regex.compile("\\[TV_SHOW:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[LIGHTS_COLOR:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	regex.compile("\\[LIGHTS_BRIGHT:[^\\]]+\\]")
	result = regex.sub(result, "", true)
	return result.strip_edges()
