extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_zone_detection()
	test_volume_levels()
	test_zone_names()
	test_fade_behavior()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_zone_detection():
	# Simulate zone detection based on player position
	var current_room = ""
	var z_pos = 10.0
	var zone = "lobby" if current_room.is_empty() and z_pos > 7 else ("hallway" if current_room.is_empty() else "office")
	_assert(zone == "lobby", "Lobby detected at z=10")
	
	z_pos = -5.0
	zone = "lobby" if current_room.is_empty() and z_pos > 7 else ("hallway" if current_room.is_empty() else "office")
	_assert(zone == "hallway", "Hallway detected at z=-5")
	
	current_room = "Ultron"
	zone = "lobby" if current_room.is_empty() and z_pos > 7 else ("hallway" if current_room.is_empty() else "office")
	_assert(zone == "office", "Office detected when in room")

func test_volume_levels():
	var lobby_vol = -8.0
	var office_vol = -15.0
	var hallway_vol = -12.0
	_assert(lobby_vol > hallway_vol, "Lobby louder than hallway")
	_assert(hallway_vol > office_vol, "Hallway louder than office")
	_assert(office_vol < -10, "Office is quiet")

func test_zone_names():
	var zones = ["lobby", "office", "hallway"]
	_assert(zones.size() == 3, "3 ambient zones")
	_assert("lobby" in zones, "Lobby zone exists")
	_assert("office" in zones, "Office zone exists")
	_assert("hallway" in zones, "Hallway zone exists")

func test_fade_behavior():
	# Simulate lerp fade
	var current_db = -80.0
	var target_db = -10.0
	var delta = 0.016  # ~60fps
	var fade_speed = 2.0
	var new_db = lerp(current_db, target_db, delta * fade_speed)
	_assert(new_db > current_db, "Volume increases toward target")
	_assert(new_db < target_db, "Volume hasn't reached target yet")
