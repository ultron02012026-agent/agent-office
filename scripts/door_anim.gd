## Door animation — thin CSGBox slides open when player is in proximity zone.
## Attach to the door CSGBox3D node. Set room_name to match the proximity area.
extends CSGBox3D

@export var room_name: String = ""
@export var open_offset: Vector3 = Vector3(0, 2.5, 0)  # slides up by default
@export var open_speed: float = 3.0

var is_open: bool = false
var target_open: bool = false
var closed_position: Vector3
var open_position: Vector3

func _ready():
	closed_position = position
	open_position = position + open_offset

func _process(delta):
	# Check if player is in proximity
	var player = get_node_or_null("/root/Main/Player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		target_open = dist < 3.0
	
	# Animate
	if target_open:
		position = position.lerp(open_position, delta * open_speed)
	else:
		position = position.lerp(closed_position, delta * open_speed)
	
	is_open = target_open
