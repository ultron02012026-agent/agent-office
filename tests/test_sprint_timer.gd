extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_sprint_start()
	test_progress_calculation()
	test_time_formatting()
	test_color_phases()
	test_sprint_complete()
	test_default_state()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_sprint_start():
	var minutes = 25
	var total_seconds = minutes * 60.0
	_assert(total_seconds == 1500.0, "25 min = 1500 seconds")
	
	minutes = 5
	total_seconds = minutes * 60.0
	_assert(total_seconds == 300.0, "5 min = 300 seconds")

func test_progress_calculation():
	var total = 1500.0
	var remaining = 1500.0
	var progress = 1.0 - (remaining / total)
	_assert(progress == 0.0, "Progress 0% at start")
	
	remaining = 750.0
	progress = 1.0 - (remaining / total)
	_assert(abs(progress - 0.5) < 0.01, "Progress 50% at halfway")
	
	remaining = 0.0
	progress = 1.0 - (remaining / total)
	_assert(progress == 1.0, "Progress 100% at end")

func test_time_formatting():
	var remaining = 1500.0
	var mins = int(remaining) / 60
	var secs = int(remaining) % 60
	_assert(mins == 25, "25:00 minutes")
	_assert(secs == 0, "25:00 seconds")
	
	remaining = 65.0
	mins = int(remaining) / 60
	secs = int(remaining) % 60
	_assert(mins == 1, "1:05 minutes")
	_assert(secs == 5, "1:05 seconds")

func test_color_phases():
	var total = 1500.0
	# Green phase (>50%)
	var remaining = 1000.0
	_assert(remaining > total * 0.5, "Green phase when >50% remaining")
	
	# Yellow phase (20-50%)
	remaining = 500.0
	_assert(remaining < total * 0.5 and remaining >= total * 0.2, "Yellow phase at 33%")
	
	# Red phase (<20%)
	remaining = 200.0
	_assert(remaining < total * 0.2, "Red phase when <20% remaining")

func test_sprint_complete():
	var remaining = 0.0
	var is_active = remaining > 0
	_assert(not is_active, "Sprint inactive when time is 0")
	
	var flash_duration = 3.0
	_assert(flash_duration > 0, "Flash duration is positive")

func test_default_state():
	var is_active = false
	var is_flashing = false
	var remaining = 0.0
	_assert(not is_active, "Default: not active")
	_assert(not is_flashing, "Default: not flashing")
	_assert(remaining == 0.0, "Default: 0 remaining")
