## Notification manager — badge above agent doors when they have something to tell you.
## Simulated notifications for now. Walking into the room clears the notification.
## Manages notification badges (Label3D "!" nodes) and an AudioStreamPlayer stub.
extends Node

# Room name → bool (has notification)
var notifications: Dictionary = {}

# Simulated notification timer
var sim_timer: float = 0.0
var sim_interval: float = 60.0  # simulate a notification every 60 seconds
var sim_rooms: Array = ["Ultron", "Spinfluencer", "Dexer", "DJ Sam", "Mollie"]
var sim_index: int = 0

func _ready():
	for room in sim_rooms:
		notifications[room] = false

func _process(delta):
	# Simulated notification system
	sim_timer += delta
	if sim_timer >= sim_interval:
		sim_timer = 0.0
		_simulate_notification()

func _simulate_notification():
	var room = sim_rooms[sim_index]
	sim_index = (sim_index + 1) % sim_rooms.size()
	
	# Don't notify if player is already in this room
	var player = get_node_or_null("/root/Main/Player")
	if player and player.current_room == room:
		return
	
	add_notification(room)

func add_notification(room_name: String):
	if notifications.has(room_name) and notifications[room_name]:
		return  # Already has notification
	
	notifications[room_name] = true
	_update_badge(room_name, true)
	
	# Play notification sound
	var sound = get_node_or_null("/root/Main/NotificationSound")
	if sound and sound.stream:
		sound.play()
	
	print("[Notification] " + room_name + " wants your attention!")

func clear_notification(room_name: String):
	if notifications.has(room_name):
		notifications[room_name] = false
		_update_badge(room_name, false)

func has_notification(room_name: String) -> bool:
	return notifications.get(room_name, false)

func _update_badge(room_name: String, show: bool):
	var badge = get_node_or_null("/root/Main/" + room_name + "_NotifBadge")
	if badge:
		badge.visible = show
