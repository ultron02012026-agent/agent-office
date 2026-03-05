extends CanvasLayer

var current_room: String = ""
var chat_history: Array = []

@onready var panel = $Panel
@onready var chat_log = $Panel/VBoxContainer/ChatLog
@onready var input_field = $Panel/VBoxContainer/HBoxContainer/LineEdit
@onready var send_button = $Panel/VBoxContainer/HBoxContainer/SendButton
@onready var room_label = $Panel/VBoxContainer/RoomLabel
@onready var http_request = $HTTPRequest

func _ready():
	panel.visible = false
	send_button.pressed.connect(_on_send)
	input_field.text_submitted.connect(_on_text_submitted)
	http_request.request_completed.connect(_on_request_completed)

func show_chat(room_name: String):
	current_room = room_name
	chat_history.clear()
	room_label.text = "📍 " + room_name + "'s Office"
	chat_log.text = "[color=gray]You entered " + room_name + "'s office. Say hello![/color]\n"
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	input_field.grab_focus()

func hide_chat():
	panel.visible = false
	current_room = ""
	chat_history.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_text_submitted(text: String):
	_on_send()

func _on_send():
	var text = input_field.text.strip_edges()
	if text.is_empty():
		return
	
	input_field.text = ""
	chat_log.text += "\n[color=cyan]You:[/color] " + text + "\n"
	
	chat_history.append({"role": "user", "content": text})
	_send_to_openclaw(text)

func _send_to_openclaw(_user_msg: String):
	var messages = [
		{
			"role": "system",
			"content": "You are " + current_room + ", an AI agent. The user has walked into your office in Agent Office. Keep responses concise (2-3 sentences). Be conversational and in-character."
		}
	]
	messages.append_array(chat_history)
	
	var body = JSON.stringify({
		"model": "anthropic/claude-sonnet-4-20250514",
		"messages": messages,
		"max_tokens": 200
	})
	
	var headers = ["Content-Type: application/json"]
	var err = http_request.request("http://localhost:3007/v1/chat/completions", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		chat_log.text += "[color=red]Error connecting to OpenClaw[/color]\n"

func _on_request_completed(result, response_code, _headers, body_bytes):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		chat_log.text += "[color=red]Error: " + str(response_code) + "[/color]\n"
		return
	
	var json = JSON.parse_string(body_bytes.get_string_from_utf8())
	if json and json.has("choices") and json["choices"].size() > 0:
		var reply = json["choices"][0]["message"]["content"]
		chat_history.append({"role": "assistant", "content": reply})
		chat_log.text += "[color=yellow]" + current_room + ":[/color] " + reply + "\n"
	else:
		chat_log.text += "[color=red]No response from agent[/color]\n"
