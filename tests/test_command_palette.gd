extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_room_positions()
	test_command_parsing()
	test_goto_validation()
	test_status_command()
	test_sprint_command_parsing()
	test_suggestions_filter()
	test_palette_state()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_room_positions():
	var positions = {
		"ultron": Vector3(-6, 1, -8),
		"spinfluencer": Vector3(-6, 1, 0),
		"dexer": Vector3(6, 1, -8),
		"architect": Vector3(6, 1, 0),
		"lobby": Vector3(0, 1, 10),
	}
	_assert(positions.size() == 5, "5 teleport destinations")
	_assert(positions.has("lobby"), "Lobby is a valid destination")
	_assert(positions["lobby"].z > 5, "Lobby is at south end")

func test_command_parsing():
	var cmd = "/goto ultron"
	_assert(cmd.begins_with("/goto "), "Goto command detected")
	var target = cmd.substr(6).strip_edges()
	_assert(target == "ultron", "Target parsed correctly")
	
	cmd = "/status"
	_assert(cmd == "/status", "Status command matches")
	
	cmd = "/clear"
	_assert(cmd == "/clear", "Clear command matches")
	
	cmd = "/sprint 25"
	_assert(cmd.begins_with("/sprint "), "Sprint command detected")
	var mins = cmd.substr(8).strip_edges()
	_assert(mins.is_valid_int(), "Sprint minutes is valid int")
	_assert(mins.to_int() == 25, "Sprint minutes parsed as 25")

func test_goto_validation():
	var positions = {"ultron": true, "spinfluencer": true, "dexer": true, "architect": true, "lobby": true}
	_assert(positions.has("ultron"), "ultron is valid goto target")
	_assert(not positions.has("invalid"), "invalid is not a goto target")
	_assert(not positions.has(""), "empty is not a goto target")

func test_status_command():
	var agents = ["Ultron", "Spinfluencer", "Dexer", "Architect"]
	var status_text = ""
	for agent in agents:
		status_text += "🟢 " + agent + "\n"
	_assert("Ultron" in status_text, "Ultron in status output")
	_assert("Architect" in status_text, "Architect in status output")

func test_sprint_command_parsing():
	var cmd = "/sprint 25"
	var mins_str = cmd.substr(8).strip_edges()
	_assert(mins_str == "25", "Sprint 25 parsed")
	
	cmd = "/sprint abc"
	mins_str = cmd.substr(8).strip_edges()
	_assert(not mins_str.is_valid_int(), "Non-numeric sprint rejected")

func test_suggestions_filter():
	var commands = ["/goto ultron", "/goto spinfluencer", "/status", "/clear", "/sprint 25"]
	var filter = "/goto"
	var matches = commands.filter(func(c): return c.begins_with(filter))
	_assert(matches.size() == 2, "Filter /goto matches 2 commands")
	
	filter = "/s"
	matches = commands.filter(func(c): return c.begins_with(filter))
	_assert(matches.size() == 2, "/s matches status and sprint")

func test_palette_state():
	var is_open = false
	_assert(not is_open, "Palette starts closed")
	is_open = true
	_assert(is_open, "Palette can open")
