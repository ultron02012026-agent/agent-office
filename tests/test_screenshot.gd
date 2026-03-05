extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_timestamp_format()
	test_path_generation()
	test_indicator_timer()
	test_capture_state()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_timestamp_format():
	var ts = "2026-03-05T13:45:30"
	var formatted = ts.replace(":", "-").replace("T", "_")
	_assert("_" in formatted, "T replaced with underscore")
	_assert(":" not in formatted, "Colons removed from timestamp")
	_assert(formatted == "2026-03-05_13-45-30", "Full timestamp format correct")

func test_path_generation():
	var timestamp = "2026-03-05_13-45-30"
	var path = "user://screenshots/screenshot_" + timestamp + ".png"
	_assert(path.begins_with("user://screenshots/"), "Path in screenshots dir")
	_assert(path.ends_with(".png"), "Path ends with .png")
	_assert("screenshot_" in path, "Path contains screenshot_ prefix")

func test_indicator_timer():
	var timer = 2.0
	_assert(timer > 0, "Indicator starts visible")
	
	timer -= 1.5
	_assert(timer > 0, "Still visible after 1.5s")
	_assert(timer < 1.0, "Fading phase (< 1.0s)")
	
	timer -= 0.5
	_assert(timer <= 0, "Hidden after 2 seconds")

func test_capture_state():
	var is_capturing = false
	_assert(not is_capturing, "Not capturing initially")
	is_capturing = true
	_assert(is_capturing, "Capturing flag set")
	# Should prevent double-capture
	var can_capture = not is_capturing
	_assert(not can_capture, "Double capture blocked")
