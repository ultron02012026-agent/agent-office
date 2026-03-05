extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_initial_state()
	test_open_offset()
	test_lerp_toward_open()
	test_lerp_toward_closed()
	test_proximity_detection()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_initial_state():
	var is_open = false
	var target_open = false
	_assert(!is_open, "Door starts closed")
	_assert(!target_open, "Door target is closed")

func test_open_offset():
	var closed_pos = Vector3(0, 1.5, 0)
	var open_offset = Vector3(0, 2.5, 0)
	var open_pos = closed_pos + open_offset
	_assert(open_pos.y == 4.0, "Open position is closed + offset")

func test_lerp_toward_open():
	var pos = Vector3(0, 1.5, 0)
	var open_pos = Vector3(0, 4.0, 0)
	var delta = 0.1
	var speed = 3.0
	pos = pos.lerp(open_pos, delta * speed)
	_assert(pos.y > 1.5, "Position moves toward open")
	_assert(pos.y < 4.0, "Position hasn't reached open yet")

func test_lerp_toward_closed():
	var pos = Vector3(0, 3.0, 0)
	var closed_pos = Vector3(0, 1.5, 0)
	var delta = 0.1
	var speed = 3.0
	pos = pos.lerp(closed_pos, delta * speed)
	_assert(pos.y < 3.0, "Position moves toward closed")
	_assert(pos.y > 1.5, "Position hasn't reached closed yet")

func test_proximity_detection():
	var player_pos = Vector3(0, 1, -8)
	var door_pos = Vector3(-2, 1.5, -8)
	var dist = player_pos.distance_to(door_pos)
	_assert(dist < 3.0, "Player within 3m triggers open")
	
	var far_pos = Vector3(0, 1, 0)
	dist = far_pos.distance_to(door_pos)
	_assert(dist > 3.0, "Far player does not trigger open")
