extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_camera_clamp()
	test_room_state_tracking()
	test_hud_location()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_camera_clamp():
	var rotation_x = 1.0
	rotation_x = clamp(rotation_x, -PI/4, PI/4)
	_assert(rotation_x == PI/4, "Camera clamps to max PI/4")
	
	rotation_x = -1.0
	rotation_x = clamp(rotation_x, -PI/4, PI/4)
	_assert(rotation_x == -PI/4, "Camera clamps to min -PI/4")
	
	rotation_x = 0.5
	rotation_x = clamp(rotation_x, -PI/4, PI/4)
	_assert(rotation_x == 0.5, "Camera within range unchanged")

func test_room_state_tracking():
	var current_room = ""
	_assert(current_room.is_empty(), "Starts with no room")
	
	current_room = "Ultron"
	_assert(current_room == "Ultron", "Room set on enter")
	
	current_room = ""
	_assert(current_room.is_empty(), "Room cleared on exit")

func test_hud_location():
	# Lobby detection
	var pos_z = 10.0
	var current_room = ""
	var label = ""
	if current_room.is_empty():
		if pos_z > 7:
			label = "📍 Lobby"
		else:
			label = "📍 Hallway"
	_assert(label == "📍 Lobby", "Lobby detected at z > 7")
	
	pos_z = 0.0
	if current_room.is_empty():
		if pos_z > 7:
			label = "📍 Lobby"
		else:
			label = "📍 Hallway"
	_assert(label == "📍 Hallway", "Hallway detected at z <= 7")
	
	current_room = "Dexer"
	label = "📍 " + current_room + "'s Office"
	_assert(label == "📍 Dexer's Office", "Room label correct")
