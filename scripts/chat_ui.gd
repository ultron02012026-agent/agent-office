## Chat panel UI — sends messages to OpenClaw chat completions API.
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

@onready var panel = $Panel
@onready var chat_log = $Panel/VBoxContainer/ChatLog
@onready var input_field = $Panel/VBoxContainer/HBoxContainer/LineEdit
@onready var send_button = $Panel/VBoxContainer/HBoxContainer/SendButton
@onready var clear_button = $Panel/VBoxContainer/HBoxContainer/ClearButton
@onready var room_label = $Panel/VBoxContainer/RoomLabel
@onready var http_request = $HTTPRequest

func _ready():
	panel.visible = false
	send_button.pressed.connect(_on_send)
	input_field.text_submitted.connect(_on_text_submitted)
	http_request.request_completed.connect(_on_request_completed)
	
	# Clear button
	if clear_button:
		clear_button.pressed.connect(_on_clear)
	
	# Connect voice chat signals
	_connect_voice_chat.call_deferred()

func _connect_voice_chat():
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat:
		voice_chat.transcription_received.connect(_on_transcription)

func show_chat(room_name: String):
	current_room = room_name
	is_thinking = false
	room_label.text = "📍 " + room_name + "'s Office"
	
	# Restore previous chat history for this room, or start fresh
	if room_histories.has(room_name) and room_histories[room_name].size() > 0:
		chat_history = room_histories[room_name].duplicate(true)
		chat_log.text = room_logs.get(room_name, "")
		chat_log.text += "[color=gray][i]Welcome back![/i][/color]\n"
	else:
		chat_history = []
		chat_log.text = "[color=gray]You entered " + room_name + "'s office. Say hello![/color]\n"
	
	# Show voice mode hint
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat and voice_chat.voice_mode:
		chat_log.text += "[color=gray][i]🎙️ Voice mode active — hold V to talk, Tab to switch to text[/i][/color]\n"
	else:
		chat_log.text += "[color=gray][i]⌨️ Text mode — Tab to switch to voice[/i][/color]\n"
	
	panel.visible = true
	_set_input_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	input_field.grab_focus()

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

func _on_clear():
	if current_room.is_empty():
		return
	# Clear history for current room
	chat_history.clear()
	room_histories.erase(current_room)
	room_logs.erase(current_room)
	chat_log.text = "[color=gray]Chat cleared. Say hello![/color]\n"

func _on_transcription(text: String):
	if text.is_empty():
		chat_log.text += "[color=red]Could not understand audio[/color]\n"
		return
	
	# Process transcribed text like a typed message
	chat_log.text += "\n[color=cyan]You (🎙️):[/color] " + text + "\n"
	chat_history.append({"role": "user", "content": text})
	_set_thinking(true)
	_send_to_openclaw(text)

func _on_text_submitted(_text: String):
	_on_send()

func _on_send():
	if is_thinking:
		return
	var text = input_field.text.strip_edges()
	if text.is_empty():
		return
	
	input_field.text = ""
	chat_log.text += "\n[color=cyan]You:[/color] " + text + "\n"
	
	chat_history.append({"role": "user", "content": text})
	_set_thinking(true)
	# Play send sound
	var send_sound = get_node_or_null("/root/Main/ChatSendSound")
	if send_sound and send_sound.stream:
		send_sound.play()
	_send_to_openclaw(text)

func _set_thinking(thinking: bool):
	is_thinking = thinking
	_set_input_enabled(!thinking)
	if thinking:
		chat_log.text += "[color=gray][i]" + current_room + " is thinking...[/i][/color]\n"

func _set_input_enabled(enabled: bool):
	input_field.editable = enabled
	send_button.disabled = !enabled
	if enabled:
		input_field.placeholder_text = "Type a message..."
	else:
		input_field.placeholder_text = "Waiting for response..."

func _send_to_openclaw(_user_msg: String):
	# Use agent config for system prompt
	var agent_name = current_room
	var system_prompt = "You are " + current_room + ", an AI agent. The user has walked into your office in Agent Office. Keep responses concise (2-3 sentences). Be conversational and in-character."
	
	if SettingsManager.agent_configs.has(current_room):
		var cfg = SettingsManager.agent_configs[current_room]
		agent_name = cfg.get("agent_name", current_room)
		if cfg.has("system_prompt") and not cfg["system_prompt"].is_empty():
			system_prompt = cfg["system_prompt"]
	
	var messages = [{"role": "system", "content": system_prompt}]
	messages.append_array(chat_history)
	
	var body = JSON.stringify({
		"model": "anthropic/claude-sonnet-4-20250514",
		"messages": messages,
		"max_tokens": 200
	})
	
	var headers = ["Content-Type: application/json"]
	if SettingsManager.gateway_token != "":
		headers.append("Authorization: Bearer " + SettingsManager.gateway_token)
	var url = SettingsManager.gateway_url + "/v1/chat/completions"
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		chat_log.text += "[color=red]Error connecting to OpenClaw[/color]\n"
		_set_thinking(false)

func _on_request_completed(result, response_code, _headers, body_bytes):
	_set_thinking(false)
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		chat_log.text += "[color=red]Error: " + str(response_code) + "[/color]\n"
		return
	
	var json = JSON.parse_string(body_bytes.get_string_from_utf8())
	if json and json.has("choices") and json["choices"].size() > 0:
		var reply = json["choices"][0]["message"]["content"]
		chat_history.append({"role": "assistant", "content": reply})
		chat_log.text += "[color=yellow]" + current_room + ":[/color] " + reply + "\n"
		# Play receive sound
		var recv_sound = get_node_or_null("/root/Main/ChatReceiveSound")
		if recv_sound and recv_sound.stream:
			recv_sound.play()
		
		# If voice mode, request TTS for the response
		var voice_chat = get_node_or_null("/root/Main/VoiceChat")
		if voice_chat and voice_chat.voice_mode:
			voice_chat.request_tts(reply)
	else:
		chat_log.text += "[color=red]No response from agent[/color]\n"
