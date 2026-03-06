## WebSocket client for OpenClaw Gateway protocol.
## Manages connection, request/response tracking, and chat event routing.
## Add as a child node of Main scene. Access via get_node("/root/Main/GatewayWS").
extends Node

signal connected
signal disconnected
signal message_delta(agent_id: String, text: String)
signal message_final(agent_id: String, text: String)

var _ws := WebSocketPeer.new()
var _connected := false
var _request_id := 0
var _pending_requests := {}  # id -> callback info
var _reconnect_timer := 0.0
var _should_connect := false
var _injected_rooms := {}  # track which rooms got office context injected

# Map room names to agent session key IDs
var agent_map := {
	"Spinfluencer": "spinfluencer",
	"Dexer": "dexer",
	"DJ Sam": "dj-sam",
	"Ultron": "main",
}

func _ready():
	set_process(true)

func start_connection():
	_should_connect = true
	_do_connect()

func stop_connection():
	_should_connect = false
	_ws.close()
	_connected = false

func _do_connect():
	var url = SettingsManager.gateway_url
	if url.begins_with("http://"):
		url = "ws://" + url.substr(7)
	elif url.begins_with("https://"):
		url = "wss://" + url.substr(8)
	# Ensure trailing slash for WS path
	if not url.ends_with("/"):
		url += "/"
	print("[GatewayWS] Connecting to: ", url)
	var err = _ws.connect_to_url(url)
	if err != OK:
		print("[GatewayWS] Connection error: ", err)
		_reconnect_timer = 5.0

func is_ws_connected() -> bool:
	return _connected

func _next_id() -> int:
	_request_id += 1
	return _request_id

func _send_request(method: String, params: Dictionary) -> int:
	var id = _next_id()
	var frame = JSON.stringify({"type": "req", "id": id, "method": method, "params": params})
	_ws.send_text(frame)
	return id

func send_message(room_name: String, message: String):
	var agent_id = agent_map.get(room_name, "main")
	var session_key = "agent:" + agent_id + ":main"
	_send_request("chat.send", {"sessionKey": session_key, "message": message, "deliver": false})

func inject_context(room_name: String, context: String):
	var agent_id = agent_map.get(room_name, "main")
	var session_key = "agent:" + agent_id + ":main"
	_send_request("chat.inject", {"sessionKey": session_key, "message": context, "role": "system"})

func inject_office_context(room_name: String):
	if _injected_rooms.has(room_name):
		return
	_injected_rooms[room_name] = true
	var context: String
	if room_name == "Ultron":
		context = "[System: You are in Agent Office, a 3D virtual office building. You're at the front desk as the Office Manager. Ethan just walked in. You know all the agents: Spinfluencer (Room 2, green robot, music feedback), Dexer (Room 3, blue robot, label submissions), DJ Sam (Room 4, purple robot, DJ/music). You can control the building with tags (stripped before display):\n\nMusic: [MUSIC_UP] [MUSIC_DOWN] [MUSIC_OFF] [MUSIC_ON]\nTV Screen: [TV_SHOW:url] (direct image URL) | [TV_OFF]\nRoom Lights: [LIGHTS_COLOR:#hexcolor] | [LIGHTS_BRIGHT:0-100]\n\nKeep responses concise. You run this place.]"
	else:
		context = "[System: You are currently in your office in Agent Office, a 3D virtual office building. The user (Ethan) has entered your room. You can control your office environment using tags in your responses (tags are stripped before display):\n\nMusic: [MUSIC_UP] [MUSIC_DOWN] [MUSIC_OFF] [MUSIC_ON]\nTV Screen: [TV_SHOW:url] (direct image URL) | [TV_OFF]\nRoom Lights: [LIGHTS_COLOR:#hexcolor] | [LIGHTS_BRIGHT:0-100]\n\nKeep responses concise (2-3 sentences). Be conversational.]"
	inject_context(room_name, context)

func abort(room_name: String):
	var agent_id = agent_map.get(room_name, "main")
	var session_key = "agent:" + agent_id + ":main"
	_send_request("chat.abort", {"sessionKey": session_key})

func _process(_delta: float):
	_ws.poll()
	var state = _ws.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				# Just connected, send auth
				_send_connect_frame()
			# Process incoming packets
			while _ws.get_available_packet_count() > 0:
				var pkt = _ws.get_packet().get_string_from_utf8()
				_handle_message(pkt)
		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				print("[GatewayWS] Disconnected")
				disconnected.emit()
			if _should_connect:
				_reconnect_timer -= _delta
				if _reconnect_timer <= 0:
					_reconnect_timer = 5.0
					_do_connect()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CONNECTING:
			pass

func _send_connect_frame():
	var params = {
		"minProtocol": 1,
		"maxProtocol": 1,
		"client": {
			"id": "agent-office",
			"displayName": "Agent Office",
			"version": "1.0",
			"platform": "macos",
			"mode": "backend"
		},
		"caps": [],
		"auth": {"token": SettingsManager.gateway_token}
	}
	_send_request("connect", params)

func _handle_message(raw: String):
	var json = JSON.parse_string(raw)
	if json == null:
		return
	
	# Response to a request
	if json.has("ok") and json.has("id"):
		var id = json["id"]
		if id == 1 and json.get("ok", false):
			# Connect response
			_connected = true
			_reconnect_timer = 0.0
			print("[GatewayWS] Connected and authenticated")
			connected.emit()
		elif not json.get("ok", false):
			print("[GatewayWS] Request ", id, " failed: ", json.get("error", {}).get("message", "unknown"))
		return
	
	# Event
	if json.get("type") == "event" and json.get("event") == "chat":
		_handle_chat_event(json.get("payload", {}))

func _handle_chat_event(payload: Dictionary):
	var state = payload.get("state", "")
	var session_key = str(payload.get("sessionKey", ""))
	var raw_message = payload.get("message", "")
	
	# Extract agent_id from session key "agent:ID:main"
	var agent_id = ""
	var parts = session_key.split(":")
	if parts.size() >= 2:
		agent_id = parts[1]
	
	var text = _extract_text_from_message(raw_message)
	
	match state:
		"delta":
			message_delta.emit(agent_id, text)
		"final":
			message_final.emit(agent_id, text)

func _extract_text_from_message(msg) -> String:
	if msg is String:
		return msg
	if msg is Dictionary:
		# Claude API format: {content: [{type: "text", text: "..."}, ...]}
		if msg.has("content") and msg["content"] is Array:
			var texts := []
			for block in msg["content"]:
				if block is Dictionary and block.get("type") == "text":
					texts.append(str(block.get("text", "")))
			return "\n".join(texts)
		# Simple {text: "..."} format
		if msg.has("text"):
			return str(msg["text"])
	return str(msg)
