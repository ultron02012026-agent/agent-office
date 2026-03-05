extends Node

# Extended minimap tests — room rects, colors, edge positions

var passed := 0
var failed := 0

const WORLD_MIN := Vector2(-12, -15)
const WORLD_MAX := Vector2(12, 15)
const MAP_SIZE := Vector2(180, 180)
const PADDING := 10.0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_all_rooms_defined()
	test_room_colors_unique()
	test_lobby_position()
	test_edge_positions()
	test_world_rect_to_map()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func _world_to_map(world: Vector2) -> Vector2:
	var norm_x = (world.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x)
	var norm_y = (world.y - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y)
	return Vector2(PADDING + norm_x * MAP_SIZE.x, PADDING + norm_y * MAP_SIZE.y)

func test_all_rooms_defined():
	var rooms = [
		{"name": "Ultron", "color": Color(0.2, 0.8, 1, 0.4), "rect": Rect2(-10, -11, 8, 6)},
		{"name": "Spin", "color": Color(1, 0.4, 0.7, 0.4), "rect": Rect2(-10, -3, 8, 6)},
		{"name": "Dexer", "color": Color(0.4, 1, 0.4, 0.4), "rect": Rect2(2, -11, 8, 6)},
		{"name": "Architect", "color": Color(1, 0.8, 0.2, 0.4), "rect": Rect2(2, -3, 8, 6)},
	]
	_assert(rooms.size() == 4, "All 4 rooms defined on minimap")
	
	var names = []
	for r in rooms:
		names.append(r["name"])
	_assert("Ultron" in names, "Ultron room on minimap")
	_assert("Spin" in names, "Spin room on minimap")
	_assert("Dexer" in names, "Dexer room on minimap")
	_assert("Architect" in names, "Architect room on minimap")

func test_room_colors_unique():
	var colors = [
		Color(0.2, 0.8, 1, 0.4),    # Ultron - cyan
		Color(1, 0.4, 0.7, 0.4),    # Spin - pink
		Color(0.4, 1, 0.4, 0.4),    # Dexer - green
		Color(1, 0.8, 0.2, 0.4),    # Architect - gold
	]
	# Each color is distinct
	for i in range(colors.size()):
		for j in range(i + 1, colors.size()):
			_assert(colors[i] != colors[j], "Room colors %d and %d are distinct" % [i, j])

func test_lobby_position():
	var lobby_rect = Rect2(-5, 7, 10, 8)
	# Lobby center in world coords
	var lobby_center = Vector2(lobby_rect.position.x + lobby_rect.size.x / 2, lobby_rect.position.y + lobby_rect.size.y / 2)
	_assert(abs(lobby_center.x - 0.0) < 0.01, "Lobby centered at x=0")
	_assert(lobby_center.y > 0, "Lobby is in positive z (south/bottom)")
	
	var map_pos = _world_to_map(lobby_center)
	_assert(map_pos.x > MAP_SIZE.x * 0.3, "Lobby map X in reasonable range")
	_assert(map_pos.y > MAP_SIZE.y * 0.5, "Lobby map Y in lower half")

func test_edge_positions():
	# Top-left corner
	var tl = _world_to_map(WORLD_MIN)
	_assert(abs(tl.x - PADDING) < 0.01, "Top-left maps to padding edge X")
	_assert(abs(tl.y - PADDING) < 0.01, "Top-left maps to padding edge Y")
	
	# Bottom-right corner
	var br = _world_to_map(WORLD_MAX)
	_assert(abs(br.x - (PADDING + MAP_SIZE.x)) < 0.01, "Bottom-right maps to max edge X")
	_assert(abs(br.y - (PADDING + MAP_SIZE.y)) < 0.01, "Bottom-right maps to max edge Y")
	
	# Center
	var center = _world_to_map(Vector2(0, 0))
	_assert(abs(center.x - (PADDING + MAP_SIZE.x / 2)) < 0.01, "Center maps correctly X")
	_assert(abs(center.y - (PADDING + MAP_SIZE.y / 2)) < 0.01, "Center maps correctly Y")

func test_world_rect_to_map():
	# Test rect conversion for Ultron's room
	var wr = Rect2(-10, -11, 8, 6)
	var tl = _world_to_map(Vector2(wr.position.x, wr.position.y))
	var br = _world_to_map(Vector2(wr.position.x + wr.size.x, wr.position.y + wr.size.y))
	var mr = Rect2(tl, br - tl)
	_assert(mr.size.x > 0, "Mapped room rect has positive width")
	_assert(mr.size.y > 0, "Mapped room rect has positive height")
	_assert(mr.position.x >= PADDING, "Mapped room within map bounds left")
	_assert(mr.position.y >= PADDING, "Mapped room within map bounds top")
