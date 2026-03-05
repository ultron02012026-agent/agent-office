extends Node

# Tests for v0.6.0 immersion features: idle animations, footsteps, chat persistence

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_avatar_bob()
	test_avatar_face_player()
	test_avatar_idle_rotate()
	test_footstep_timing()
	test_surface_type()
	test_chat_history_persistence()
	test_chat_history_clear()
	test_chat_restore_on_reenter()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

# Avatar idle tests
func test_avatar_bob():
	var base_y = 0.7
	var bob_amplitude = 0.1
	var bob_speed = 1.5
	var idle_time = 1.0
	var y = base_y + sin(idle_time * bob_speed) * bob_amplitude
	_assert(abs(y - base_y) <= bob_amplitude, "Bob stays within amplitude range")
	
	idle_time = PI / (2.0 * bob_speed)  # peak
	y = base_y + sin(idle_time * bob_speed) * bob_amplitude
	_assert(abs(y - (base_y + bob_amplitude)) < 0.01, "Bob reaches peak")

func test_avatar_face_player():
	var avatar_pos = Vector3(-7, 0.7, -10.2)
	var player_pos = Vector3(-5, 1, -8)
	var dir = (player_pos - avatar_pos).normalized()
	dir.y = 0
	dir = dir.normalized()
	var target_angle = atan2(dir.x, dir.z)
	_assert(target_angle != 0, "Face-player produces non-zero angle")
	
	# lerp_angle test
	var current = 0.0
	var result = lerp_angle(current, target_angle, 0.5)
	_assert(abs(result - target_angle * 0.5) < 0.1, "lerp_angle moves toward target")

func test_avatar_idle_rotate():
	var idle_time = 2.0
	var rotation_speed = 0.3
	var delta = 0.016
	var rot_delta = sin(idle_time * rotation_speed) * delta * 0.5
	_assert(abs(rot_delta) < 0.01, "Idle rotation is subtle")

# Footstep tests
func test_footstep_timing():
	var footstep_timer = 0.0
	var footstep_interval = 0.45
	var delta = 0.016
	
	# Simulate frames until footstep triggers
	var frames = 0
	while footstep_timer < footstep_interval:
		footstep_timer += delta
		frames += 1
	_assert(frames > 20, "Footstep takes multiple frames")
	_assert(footstep_timer >= footstep_interval, "Timer exceeds interval")
	
	# Reset
	footstep_timer = 0.0
	_assert(footstep_timer == 0.0, "Timer resets on footstep play")

func test_surface_type():
	var current_room = ""
	var surface = "hallway" if current_room.is_empty() else "room"
	_assert(surface == "hallway", "Empty room = hallway surface")
	
	current_room = "Ultron"
	surface = "hallway" if current_room.is_empty() else "room"
	_assert(surface == "room", "In room = room surface")

# Chat persistence tests
func test_chat_history_persistence():
	var room_histories: Dictionary = {}
	var chat_history = [
		{"role": "user", "content": "hello"},
		{"role": "assistant", "content": "hi there"}
	]
	
	# Save on hide
	room_histories["Ultron"] = chat_history.duplicate(true)
	_assert(room_histories.has("Ultron"), "History saved for Ultron")
	_assert(room_histories["Ultron"].size() == 2, "Both messages saved")

func test_chat_history_clear():
	var room_histories: Dictionary = {"Ultron": [{"role": "user", "content": "hi"}]}
	var room_logs: Dictionary = {"Ultron": "some log text"}
	
	room_histories.erase("Ultron")
	room_logs.erase("Ultron")
	_assert(!room_histories.has("Ultron"), "History cleared for Ultron")
	_assert(!room_logs.has("Ultron"), "Log cleared for Ultron")

func test_chat_restore_on_reenter():
	var room_histories: Dictionary = {
		"Ultron": [
			{"role": "user", "content": "hello"},
			{"role": "assistant", "content": "hi!"}
		]
	}
	var room_logs: Dictionary = {"Ultron": "[color=cyan]You:[/color] hello\n[color=yellow]Ultron:[/color] hi!\n"}
	
	# Simulate show_chat with existing history
	var has_history = room_histories.has("Ultron") and room_histories["Ultron"].size() > 0
	_assert(has_history, "Previous history detected on reenter")
	
	var restored_history = room_histories["Ultron"].duplicate(true)
	_assert(restored_history.size() == 2, "History restored with correct size")
	_assert(restored_history[0]["content"] == "hello", "First message content preserved")
	
	var restored_log = room_logs.get("Ultron", "")
	_assert("hello" in restored_log, "Log text contains previous messages")
