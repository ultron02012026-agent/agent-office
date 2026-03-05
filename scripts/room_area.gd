## Room detection trigger — calls enter_room()/exit_room() on the player.
## @export room_name: set per-instance in main.tscn
## Depends on: player.gd (expects enter_room/exit_room methods on CharacterBody3D)
extends Area3D

@export var room_name: String = "Unknown"

func _on_body_entered(body):
	if body is CharacterBody3D and body.has_method("enter_room"):
		body.enter_room(room_name)

func _on_body_exited(body):
	if body is CharacterBody3D and body.has_method("exit_room"):
		body.exit_room(room_name)
