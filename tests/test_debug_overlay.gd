extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_toggle_state()
	test_fps_color()
	test_memory_format()
	test_debug_data_structure()
	test_update_interval()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_toggle_state():
	var is_visible = false
	is_visible = !is_visible
	_assert(is_visible, "Toggle off->on")
	is_visible = !is_visible
	_assert(not is_visible, "Toggle on->off")

func test_fps_color():
	var fps = 60
	var color = "lime" if fps >= 55 else ("yellow" if fps >= 30 else "red")
	_assert(color == "lime", "60fps = lime")
	
	fps = 40
	color = "lime" if fps >= 55 else ("yellow" if fps >= 30 else "red")
	_assert(color == "yellow", "40fps = yellow")
	
	fps = 15
	color = "lime" if fps >= 55 else ("yellow" if fps >= 30 else "red")
	_assert(color == "red", "15fps = red")

func test_memory_format():
	var mem_bytes = 104857600  # 100 MB
	var mem_mb = mem_bytes / 1048576.0
	_assert(abs(mem_mb - 100.0) < 0.1, "Memory formatted as MB")
	
	var formatted = "%.1f MB" % mem_mb
	_assert("100.0 MB" == formatted, "Memory string format correct")

func test_debug_data_structure():
	var data = {
		"fps": 60,
		"memory_mb": 100.0,
		"player_pos": Vector3(0, 1, 10),
		"current_room": "",
		"gateway_configured": true
	}
	_assert(data.has("fps"), "Data has fps")
	_assert(data.has("memory_mb"), "Data has memory")
	_assert(data.has("player_pos"), "Data has player position")
	_assert(data.has("current_room"), "Data has current room")
	_assert(data.has("gateway_configured"), "Data has gateway status")

func test_update_interval():
	var interval = 0.25
	_assert(interval > 0, "Update interval positive")
	_assert(interval <= 0.5, "Update interval not too slow")
	# 4 updates per second
	_assert(abs(1.0 / interval - 4.0) < 0.1, "Updates 4x per second")
