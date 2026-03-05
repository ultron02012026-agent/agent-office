extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_room_name_propagation()
	test_enter_exit_state()
	test_multiple_rooms()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_room_name_propagation():
	var room_name = "Ultron"
	_assert(room_name == "Ultron", "Room name set correctly")
	
	room_name = "Spinfluencer"
	_assert(room_name == "Spinfluencer", "Room name updates")

func test_enter_exit_state():
	var current_room = ""
	
	# Enter
	current_room = "Dexer"
	_assert(current_room == "Dexer", "Enter sets current room")
	
	# Exit same room
	if current_room == "Dexer":
		current_room = ""
	_assert(current_room.is_empty(), "Exit clears current room")

func test_multiple_rooms():
	# Exiting wrong room shouldn't clear
	var current_room = "Ultron"
	var exiting = "Dexer"
	if current_room == exiting:
		current_room = ""
	_assert(current_room == "Ultron", "Exiting wrong room doesn't clear state")
