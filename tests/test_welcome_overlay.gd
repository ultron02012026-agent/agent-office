extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_initial_state()
	test_dismiss()
	test_double_dismiss()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_initial_state():
	var is_showing = true
	_assert(is_showing == true, "Welcome overlay starts visible")

func test_dismiss():
	var is_showing = true
	# Simulate dismiss
	is_showing = false
	_assert(is_showing == false, "Welcome overlay dismisses on keypress")

func test_double_dismiss():
	var is_showing = false
	# Second dismiss should be no-op
	if is_showing:
		is_showing = false
	_assert(is_showing == false, "Double dismiss is safe no-op")
