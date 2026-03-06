## First-person player controller.
## Handles WASD movement, mouse look, camera bob, room enter/exit, voice input.
## Voice-only interaction: no text chat, voice auto-activates on room entry.
## Footstep system: timed audio cues synced to movement, different for hallway vs room.
## Key methods: enter_room(), exit_room(), _update_hud()
## Depends on: SettingsManager (autoload), ChatUI, VoiceChat, SettingsMenu, HUD (all via /root/Main/)
extends CharacterBody3D

const SPEED = 7.0
const BOB_FREQUENCY = 14.0
const BOB_AMPLITUDE = 0.03

var current_room: String = ""
var bob_timer: float = 0.0

# Footstep system
var footstep_timer: float = 0.0
var footstep_interval: float = 0.45  # seconds between footsteps at full speed
var is_moving: bool = false

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready():
	# Welcome overlay handles initial mouse mode
	var welcome = get_node_or_null("/root/Main/WelcomeOverlay")
	if not welcome or not welcome.is_showing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Apply FOV from settings
	camera.fov = SettingsManager.fov

func _unhandled_input(event):
	# Welcome overlay blocks all input
	var welcome = get_node_or_null("/root/Main/WelcomeOverlay")
	if welcome and welcome.is_showing:
		return
	
	# Settings menu takes priority
	var settings_menu = get_node_or_null("/root/Main/SettingsMenu")
	if settings_menu and settings_menu.is_open:
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = SettingsManager.mouse_sensitivity
		rotate_y(-event.relative.x * sens)
		var y_mult = -1.0 if SettingsManager.invert_y else 1.0
		camera_pivot.rotate_x(y_mult * -event.relative.y * sens)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/4, PI/4)
	
	if event.is_action_pressed("ui_cancel"):
		# If settings is open, close it
		if settings_menu and settings_menu.is_open:
			settings_menu.close_menu()
		# Otherwise open settings (room exit happens via walking out through Area3D)
		else:
			# Don't open settings if currently typing in chat
			var chat_ui = get_node_or_null("/root/Main/ChatUI")
			var is_chat_typing = chat_ui and chat_ui.text_input and chat_ui.text_input.has_focus()
			if not is_chat_typing and settings_menu and not settings_menu.is_open:
				settings_menu.open_menu()
	
	# Mic is always on via VAD when in a room — no push-to-talk needed

func _physics_process(delta):
	var welcome = get_node_or_null("/root/Main/WelcomeOverlay")
	if welcome and welcome.is_showing:
		return
	var settings_menu = get_node_or_null("/root/Main/SettingsMenu")
	if settings_menu and settings_menu.is_open:
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	var input_dir = Vector2.ZERO
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if not (chat_ui and chat_ui.text_input and chat_ui.text_input.has_focus() and not chat_ui.text_input.text.is_empty()):
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Camera bob while moving
	var was_moving = is_moving
	is_moving = direction.length() > 0.1 and is_on_floor()
	if is_moving:
		bob_timer += delta * BOB_FREQUENCY
		camera.position.y = sin(bob_timer) * BOB_AMPLITUDE
		
		# Footstep timing
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			footstep_timer = 0.0
			_play_footstep()
	else:
		bob_timer = 0.0
		footstep_timer = 0.0
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)
	
	_update_hud()

func _play_footstep():
	# Footsteps disabled — investigating audio overlap with bg music
	pass
	#var surface = get_surface_type()
	#if surface == "room":
	#	var player_node = get_node_or_null("/root/Main/FootstepRoom")
	#	if player_node and player_node.stream:
	#		player_node.play()
	#else:
	#	var player_node = get_node_or_null("/root/Main/FootstepHallway")
	#	if player_node and player_node.stream:
	#		player_node.play()

func get_surface_type() -> String:
	if current_room.is_empty():
		return "hallway"
	else:
		return "room"

func _update_hud():
	var hud_label = get_node_or_null("/root/Main/HUD/RoomHUD")
	if hud_label:
		var location = ""
		if current_room.is_empty():
			if global_position.z > 7:
				location = "📍 Lobby"
			else:
				location = "📍 Hallway"
		else:
			location = "📍 " + current_room + "'s Office"
		
		hud_label.text = location
	
	# Mic indicator
	var mic_indicator = get_node_or_null("/root/Main/HUD/MicIndicator")
	if mic_indicator:
		var voice_chat = get_node_or_null("/root/Main/VoiceChat")
		mic_indicator.visible = voice_chat != null and voice_chat.is_recording

func enter_room(room_name: String):
	current_room = room_name
	
	# Show title card
	var title_card = get_node_or_null("/root/Main/RoomTitleCard")
	if title_card:
		title_card.show_room(room_name)
	
	var chat_ui = get_node("/root/Main/ChatUI")
	if chat_ui:
		chat_ui.show_chat(room_name)
	
	# Set up voice chat for this room (auto-activate, no toggle needed)
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if voice_chat:
		var tts_player = get_node_or_null("/root/Main/" + room_name + "_TTSPlayer")
		voice_chat.set_room(room_name, tts_player)
	
	# Clear notification for this room
	var notif_mgr = get_node_or_null("/root/Main/NotificationManager")
	if notif_mgr:
		notif_mgr.clear_notification(room_name)

func exit_room(room_name: String):
	if current_room == room_name:
		current_room = ""
		
		var title_card = get_node_or_null("/root/Main/RoomTitleCard")
		if title_card:
			title_card.show_exit()
		
		var chat_ui = get_node("/root/Main/ChatUI")
		if chat_ui:
			chat_ui.hide_chat()
		
		var voice_chat = get_node_or_null("/root/Main/VoiceChat")
		if voice_chat:
			voice_chat.clear_room()
