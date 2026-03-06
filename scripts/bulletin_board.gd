## Bulletin board — shared whiteboard in lobby showing recent activity across all rooms.
## Shows last message sent/received per room. Auto-updates as you chat.
## Visual: Label3D on the lobby back wall.
extends Node

# Room activity tracking
var room_activity: Dictionary = {}  # room_name -> {last_message, timestamp, sender}
var board_label: Label3D = null
var update_timer: float = 0.0
var update_interval: float = 2.0  # refresh every 2 seconds

func _ready():
	_create_board()
	# Initialize empty activity
	for room in ["Ultron", "Spinfluencer", "Dexer", "DJ Sam", "Mollie"]:
		room_activity[room] = {"last_message": "No activity yet", "timestamp": 0.0, "sender": ""}

func _create_board():
	var main = get_node_or_null("/root/Main")
	if not main:
		return
	
	# Whiteboard background (already exists as lobby back wall area)
	var board_bg = CSGBox3D.new()
	board_bg.name = "BulletinBoardBG"
	board_bg.size = Vector3(4, 2.5, 0.05)
	board_bg.position = Vector3(0, 1.8, 14.85)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.95, 0.95, 0.9, 1)
	bg_mat.emission_enabled = true
	bg_mat.emission = Color(0.9, 0.9, 0.85, 1)
	bg_mat.emission_energy_multiplier = 0.2
	board_bg.material = bg_mat
	main.add_child(board_bg)
	
	# Title
	var title = Label3D.new()
	title.name = "BulletinTitle"
	title.text = "📋 What's Happening"
	title.font_size = 32
	title.modulate = Color(0.2, 0.2, 0.3, 1)
	title.position = Vector3(0, 2.85, 14.84)
	main.add_child(title)
	
	# Activity text
	board_label = Label3D.new()
	board_label.name = "BulletinContent"
	board_label.font_size = 18
	board_label.modulate = Color(0.15, 0.15, 0.2, 1)
	board_label.position = Vector3(0, 1.8, 14.83)
	board_label.width = 350
	board_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	main.add_child(board_label)
	
	_update_board_text()

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_poll_chat_activity()
		_update_board_text()

func _poll_chat_activity():
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if not chat_ui:
		return
	
	# Check each room's chat history
	for room_name in room_activity.keys():
		if chat_ui.room_histories.has(room_name):
			var history = chat_ui.room_histories[room_name]
			if history.size() > 0:
				var last = history[history.size() - 1]
				var msg = last.get("content", "")
				if msg.length() > 60:
					msg = msg.substr(0, 57) + "..."
				var sender = "You" if last.get("role", "") == "user" else room_name
				room_activity[room_name] = {
					"last_message": msg,
					"timestamp": Time.get_unix_time_from_system(),
					"sender": sender
				}

func record_activity(room_name: String, message: String, sender: String):
	var msg = message
	if msg.length() > 60:
		msg = msg.substr(0, 57) + "..."
	room_activity[room_name] = {
		"last_message": msg,
		"timestamp": Time.get_unix_time_from_system(),
		"sender": sender
	}

func _update_board_text():
	if not board_label:
		return
	
	var text = ""
	for room_name in ["Ultron", "Spinfluencer", "Dexer", "Architect"]:
		var activity = room_activity.get(room_name, {})
		var msg = activity.get("last_message", "No activity")
		var sender = activity.get("sender", "")
		var prefix = sender + ": " if not sender.is_empty() else ""
		text += room_name + "\n  " + prefix + msg + "\n\n"
	
	board_label.text = text.strip_edges()

func get_activity() -> Dictionary:
	return room_activity.duplicate(true)
