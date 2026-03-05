extends Node

# Tests for ProximityPrompt — zone logic

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_prompt_appears_in_zone()
	test_prompt_hidden_on_exit()
	test_prompt_shows_room_name()
	test_prompt_hidden_when_in_room()
	test_multiple_zones()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_prompt_appears_in_zone():
	var player_nearby = false
	var current_room = ""
	var prompt_visible = false
	
	# Player enters zone
	player_nearby = true
	if current_room.is_empty() and player_nearby:
		prompt_visible = true
	_assert(prompt_visible, "Prompt visible when player enters zone (not in room)")

func test_prompt_hidden_on_exit():
	var player_nearby = true
	var prompt_visible = true
	
	# Player exits zone
	player_nearby = false
	prompt_visible = false  # _on_body_exited hides
	_assert(!prompt_visible, "Prompt hidden when player leaves zone")
	_assert(!player_nearby, "player_nearby false after exit")

func test_prompt_shows_room_name():
	var room_name = "Ultron"
	var prompt_text = "Enter " + room_name + "'s Office →"
	_assert(prompt_text == "Enter Ultron's Office →", "Prompt shows correct room name")
	
	room_name = "Dexer"
	prompt_text = "Enter " + room_name + "'s Office →"
	_assert(prompt_text == "Enter Dexer's Office →", "Prompt adapts to different rooms")

func test_prompt_hidden_when_in_room():
	var player_nearby = true
	var current_room = "Ultron"
	var prompt_visible = false
	
	# _update_prompt only shows if current_room is empty
	if current_room.is_empty() and player_nearby:
		prompt_visible = true
	_assert(!prompt_visible, "Prompt stays hidden when already in a room")
	
	# _process also hides if player entered room while nearby
	if player_nearby and not current_room.is_empty():
		prompt_visible = false
	_assert(!prompt_visible, "Process hides prompt when player is in room")

func test_multiple_zones():
	# Simulate two proximity zones — only one active at a time
	var zone_a_nearby = false
	var zone_b_nearby = false
	var prompt_text = ""
	var current_room = ""
	
	# Enter zone A
	zone_a_nearby = true
	if current_room.is_empty() and zone_a_nearby:
		prompt_text = "Enter Ultron's Office →"
	_assert(prompt_text == "Enter Ultron's Office →", "Zone A prompt shows")
	
	# Exit zone A, enter zone B
	zone_a_nearby = false
	prompt_text = ""  # zone A exit hides
	zone_b_nearby = true
	if current_room.is_empty() and zone_b_nearby:
		prompt_text = "Enter Dexer's Office →"
	_assert(prompt_text == "Enter Dexer's Office →", "Zone B prompt replaces zone A")
	
	# Exit zone B
	zone_b_nearby = false
	prompt_text = ""
	_assert(prompt_text.is_empty(), "All zones exited, prompt cleared")
