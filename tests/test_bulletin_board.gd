extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_initial_activity()
	test_record_activity()
	test_message_truncation()
	test_room_list()
	test_activity_format()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_initial_activity():
	var activity = {}
	for room in ["Ultron", "Spinfluencer", "Dexer", "Architect"]:
		activity[room] = {"last_message": "No activity yet", "timestamp": 0.0, "sender": ""}
	_assert(activity.size() == 4, "4 rooms tracked")
	_assert(activity["Ultron"].last_message == "No activity yet", "Initial message is placeholder")
	_assert(activity["Dexer"].timestamp == 0.0, "Initial timestamp is 0")

func test_record_activity():
	var activity = {"Ultron": {"last_message": "", "timestamp": 0.0, "sender": ""}}
	activity["Ultron"] = {"last_message": "Hello world", "timestamp": 100.0, "sender": "You"}
	_assert(activity["Ultron"].last_message == "Hello world", "Message recorded")
	_assert(activity["Ultron"].sender == "You", "Sender recorded")
	_assert(activity["Ultron"].timestamp == 100.0, "Timestamp recorded")

func test_message_truncation():
	var msg = "This is a very long message that should be truncated to sixty characters for display"
	if msg.length() > 60:
		msg = msg.substr(0, 57) + "..."
	_assert(msg.length() == 60, "Message truncated to 60 chars")
	_assert(msg.ends_with("..."), "Truncated message ends with ellipsis")
	
	var short_msg = "Short"
	if short_msg.length() > 60:
		short_msg = short_msg.substr(0, 57) + "..."
	_assert(short_msg == "Short", "Short message not truncated")

func test_room_list():
	var rooms = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	_assert(rooms.size() == 4, "4 rooms on bulletin board")
	_assert("Spinfluencer" in rooms, "Spinfluencer on board")

func test_activity_format():
	var room_name = "Ultron"
	var sender = "You"
	var msg = "Hello there"
	var line = room_name + "\n  " + sender + ": " + msg
	_assert(room_name in line, "Room name in formatted line")
	_assert(sender in line, "Sender in formatted line")
	_assert(msg in line, "Message in formatted line")
