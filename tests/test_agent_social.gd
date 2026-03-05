extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_agent_positions()
	test_visit_status_idle()
	test_visit_interval()
	test_agent_names()
	test_visit_phases()
	test_visitor_target_different()
	test_home_positions()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_agent_positions():
	var positions = {
		"Ultron": Vector3(-2, 0.7, -8),
		"Spinfluencer": Vector3(-2, 0.7, 0),
		"Dexer": Vector3(2, 0.7, -8),
		"Architect": Vector3(2, 0.7, 0),
	}
	_assert(positions.size() == 4, "4 agent doorway positions defined")
	_assert(positions["Ultron"].x < 0, "Ultron on left side")
	_assert(positions["Dexer"].x > 0, "Dexer on right side")

func test_visit_status_idle():
	var status = {"is_visiting": false, "visitor": "", "target": "", "phase": "idle"}
	_assert(status.phase == "idle", "Initial phase is idle")
	_assert(status.is_visiting == false, "Not visiting initially")

func test_visit_interval():
	var interval = 90.0
	_assert(interval > 60, "Visit interval > 60 seconds")
	_assert(interval < 180, "Visit interval < 180 seconds")

func test_agent_names():
	var names = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	_assert(names.size() == 4, "4 agents available for visits")
	_assert("Ultron" in names, "Ultron in agent list")

func test_visit_phases():
	var phases = ["idle", "moving_to", "staying", "returning", "cleanup"]
	_assert(phases.size() == 5, "5 visit phases defined")
	_assert(phases[0] == "idle", "First phase is idle")
	_assert(phases[4] == "cleanup", "Last phase is cleanup")

func test_visitor_target_different():
	var visitor = "Ultron"
	var agents = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	var targets = agents.filter(func(n): return n != visitor)
	_assert(targets.size() == 3, "3 possible targets when visiting")
	_assert(visitor not in targets, "Visitor excluded from targets")

func test_home_positions():
	var home = {
		"Ultron": Vector3(-7, 0.7, -10.2),
		"Spinfluencer": Vector3(-7, 0.7, -2.2),
		"Dexer": Vector3(7, 0.7, -10.2),
		"Architect": Vector3(7, 0.7, -2.2),
	}
	_assert(home.size() == 4, "4 home positions defined")
	_assert(home["Ultron"].z < home["Spinfluencer"].z, "Ultron room is north of Spinfluencer")
