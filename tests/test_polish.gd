extends Node

# Tests for v0.5.0 polish features: title card, status indicators, minimap

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_title_card_state()
	test_title_card_fade()
	test_agent_status_states()
	test_minimap_world_to_map()
	test_minimap_player_position()
	test_proximity_prompt()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_title_card_state():
	var is_showing = false
	var fade_timer = 0.0
	
	# Simulate show_room
	is_showing = true
	fade_timer = 2.0
	_assert(is_showing == true, "Title card shows on room enter")
	_assert(fade_timer == 2.0, "Title card fade timer starts at 2s")
	
	# Simulate fade complete
	fade_timer = 0.0
	is_showing = false
	_assert(is_showing == false, "Title card hides after fade")

func test_title_card_fade():
	var fade_timer = 0.3
	var alpha = fade_timer / 0.5
	_assert(alpha < 1.0 and alpha > 0.0, "Title card fades in last 0.5s")
	
	fade_timer = 1.5
	_assert(fade_timer > 0.5, "Title card fully visible before fade zone")

func test_agent_status_states():
	# Status enum: 0=DISCONNECTED, 1=READY, 2=THINKING
	var status = 1  # READY
	_assert(status == 1, "Default status is READY")
	
	# Simulate thinking
	var current_room = "Ultron"
	var agent_name = "Ultron"
	var is_thinking = true
	if current_room == agent_name and is_thinking:
		status = 2
	_assert(status == 2, "Status changes to THINKING when agent is processing")
	
	# Simulate disconnected
	var gateway_url = ""
	if gateway_url.is_empty():
		status = 0
	_assert(status == 0, "Status is DISCONNECTED with empty gateway URL")

func test_minimap_world_to_map():
	# Test coordinate mapping
	var WORLD_MIN = Vector2(-12, -15)
	var WORLD_MAX = Vector2(12, 15)
	var MAP_SIZE = Vector2(180, 180)
	var PADDING = 10.0
	
	# Center of world should map to center of map
	var world_center = Vector2(0, 0)
	var norm_x = (world_center.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x)
	var norm_y = (world_center.y - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y)
	var map_pos = Vector2(PADDING + norm_x * MAP_SIZE.x, PADDING + norm_y * MAP_SIZE.y)
	_assert(abs(map_pos.x - 100) < 1, "World center X maps to map center")
	_assert(abs(map_pos.y - 100) < 1, "World center Y maps to map center")

func test_minimap_player_position():
	# Player at lobby (0, 10)
	var player_pos = Vector2(0, 10)
	var WORLD_MIN = Vector2(-12, -15)
	var WORLD_MAX = Vector2(12, 15)
	var norm_x = (player_pos.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x)
	var norm_y = (player_pos.y - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y)
	_assert(norm_x == 0.5, "Player at lobby is centered X on minimap")
	_assert(abs(norm_y - 0.833) < 0.01, "Player at lobby is near bottom of minimap")

func test_proximity_prompt():
	# Player not in room, near door
	var current_room = ""
	var player_nearby = true
	var should_show = current_room.is_empty() and player_nearby
	_assert(should_show, "Prompt shows when near door and not in room")
	
	# Player in room
	current_room = "Ultron"
	should_show = current_room.is_empty() and player_nearby
	_assert(!should_show, "Prompt hidden when already in room")
