## Proximity prompt — shows "Enter [Room]'s Office →" when player is near a doorway.
## Uses a larger Area3D around doorways. Updates a HUD label.
extends Area3D

@export var room_name: String = ""
var player_nearby: bool = false

func _on_body_entered(body):
	if body is CharacterBody3D and body.has_method("enter_room"):
		player_nearby = true
		_update_prompt(body)

func _on_body_exited(body):
	if body is CharacterBody3D and body.has_method("enter_room"):
		player_nearby = false
		_hide_prompt()

func _update_prompt(player):
	# Only show if player is NOT already in a room
	if player.current_room.is_empty():
		var prompt_label = get_node_or_null("/root/Main/HUD/ProximityPrompt")
		if prompt_label:
			prompt_label.text = "Enter " + room_name + "'s Office →"
			prompt_label.visible = true

func _hide_prompt():
	var prompt_label = get_node_or_null("/root/Main/HUD/ProximityPrompt")
	if prompt_label:
		prompt_label.visible = false

func _process(_delta):
	if player_nearby:
		var player = get_node_or_null("/root/Main/Player")
		if player and not player.current_room.is_empty():
			_hide_prompt()
