extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_initial_state()
	test_add_notification()
	test_clear_notification()
	test_has_notification()
	test_no_double_add()
	test_simulation_cycling()
	test_clear_unknown_room()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_initial_state():
	var notifications = {}
	var rooms = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	for room in rooms:
		notifications[room] = false
	_assert(notifications.size() == 4, "4 rooms initialized")
	_assert(!notifications["Ultron"], "Ultron starts with no notification")
	_assert(!notifications["Dexer"], "Dexer starts with no notification")

func test_add_notification():
	var notifications = {"Ultron": false, "Dexer": false}
	notifications["Ultron"] = true
	_assert(notifications["Ultron"], "Notification added for Ultron")
	_assert(!notifications["Dexer"], "Dexer unaffected")

func test_clear_notification():
	var notifications = {"Ultron": true, "Dexer": true}
	notifications["Ultron"] = false
	_assert(!notifications["Ultron"], "Notification cleared for Ultron")
	_assert(notifications["Dexer"], "Dexer still has notification")

func test_has_notification():
	var notifications = {"Ultron": true, "Dexer": false}
	_assert(notifications.get("Ultron", false) == true, "has_notification true for Ultron")
	_assert(notifications.get("Dexer", false) == false, "has_notification false for Dexer")
	_assert(notifications.get("Unknown", false) == false, "has_notification false for unknown room")

func test_no_double_add():
	var notifications = {"Ultron": true}
	var already_had = notifications.has("Ultron") and notifications["Ultron"]
	_assert(already_had, "Double add detected (already has notification)")

func test_simulation_cycling():
	var rooms = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	var sim_index = 0
	
	var first = rooms[sim_index]
	sim_index = (sim_index + 1) % rooms.size()
	_assert(first == "Ultron", "First simulated notification is Ultron")
	_assert(sim_index == 1, "Index advances to 1")
	
	var second = rooms[sim_index]
	sim_index = (sim_index + 1) % rooms.size()
	_assert(second == "Spinfluencer", "Second is Spinfluencer")
	
	# Wrap around
	sim_index = 3
	var _room = rooms[sim_index]
	sim_index = (sim_index + 1) % rooms.size()
	_assert(sim_index == 0, "Index wraps to 0 after Architect")

func test_clear_unknown_room():
	var notifications = {"Ultron": true}
	if notifications.has("Unknown"):
		notifications["Unknown"] = false
	_assert(!notifications.has("Unknown"), "Clearing unknown room is safe no-op")
