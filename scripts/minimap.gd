## Minimap — bottom-right HUD showing floor plan with player dot and room labels.
## Uses _draw() on a Control node. Updated every frame from player position.
extends Control

const MAP_SIZE := Vector2(180, 180)
const WORLD_MIN := Vector2(-15, -15)  # x_min, z_min in world
const WORLD_MAX := Vector2(15, 15)    # x_max, z_max in world
const PADDING := 10.0

# Room definitions: name, color, world rect (x, z, w, h)
var rooms := [
	{"name": "Spin", "color": Color(0.4, 1, 0.4, 0.4), "rect": Rect2(-5, -15, 10, 10)},
	{"name": "Dexer", "color": Color(0.3, 0.5, 1, 0.4), "rect": Rect2(5, -15, 10, 10)},
	{"name": "DJ Sam", "color": Color(0.7, 0.4, 0.9, 0.4), "rect": Rect2(-15, -5, 10, 10)},
	{"name": "Soon", "color": Color(0.4, 0.4, 0.4, 0.3), "rect": Rect2(-15, 5, 10, 10)},
	{"name": "Ultron", "color": Color(0.2, 0.8, 1, 0.4), "rect": Rect2(2, 2, 6, 6)},
]
var lobby_rect := Rect2(-5, -5, 20, 20)  # open area

var player_pos := Vector2.ZERO

func _ready():
	# Position bottom-right
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -(MAP_SIZE.x + PADDING * 2)
	offset_top = -(MAP_SIZE.y + PADDING * 2)
	offset_right = 0
	offset_bottom = 0
	custom_minimum_size = MAP_SIZE + Vector2(PADDING * 2, PADDING * 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	var player = get_node_or_null("/root/Main/Player")
	if player:
		player_pos = Vector2(player.global_position.x, player.global_position.z)
	queue_redraw()

func _world_to_map(world: Vector2) -> Vector2:
	var norm_x = (world.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x)
	var norm_y = (world.y - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y)
	return Vector2(PADDING + norm_x * MAP_SIZE.x, PADDING + norm_y * MAP_SIZE.y)

func _world_rect_to_map(wr: Rect2) -> Rect2:
	var tl = _world_to_map(Vector2(wr.position.x, wr.position.y))
	var br = _world_to_map(Vector2(wr.position.x + wr.size.x, wr.position.y + wr.size.y))
	return Rect2(tl, br - tl)

func _draw():
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.4, 0.5), false, 1.0)
	
	# Open area / lobby
	draw_rect(_world_rect_to_map(lobby_rect), Color(0.3, 0.5, 0.7, 0.2))
	
	# Rooms
	for room in rooms:
		var mr = _world_rect_to_map(room["rect"])
		draw_rect(mr, room["color"])
		draw_rect(mr, room["color"] * 1.5, false, 1.0)
		draw_string(ThemeDB.fallback_font, mr.position + Vector2(4, mr.size.y * 0.55), room["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.9, 0.9))
	
	# Entrance marker
	var entrance_pos = _world_to_map(Vector2(12, 14))
	draw_string(ThemeDB.fallback_font, entrance_pos + Vector2(-10, 0), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.3))
	
	# Player dot
	var player_map = _world_to_map(player_pos)
	draw_circle(player_map, 4.0, Color(1, 1, 1, 1))
	draw_circle(player_map, 4.0, Color(0.2, 0.6, 1, 1), false, 1.5)
