extends CharacterBody3D

const SPEED = 7.0
const MOUSE_SENSITIVITY = 0.003
const BOB_FREQUENCY = 14.0
const BOB_AMPLITUDE = 0.03

var current_room: String = ""
var bob_timer: float = 0.0

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/4, PI/4)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	var input_dir = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
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
	var is_moving = direction.length() > 0.1 and is_on_floor()
	if is_moving:
		bob_timer += delta * BOB_FREQUENCY
		camera.position.y = sin(bob_timer) * BOB_AMPLITUDE
	else:
		bob_timer = 0.0
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)
	
	# Update HUD
	_update_hud()

func _update_hud():
	var hud_label = get_node_or_null("/root/Main/HUD/RoomHUD")
	if hud_label:
		if current_room.is_empty():
			# Check if in lobby area
			if global_position.z > 7:
				hud_label.text = "📍 Lobby"
			else:
				hud_label.text = "📍 Hallway"
		else:
			hud_label.text = "📍 " + current_room + "'s Office"

func enter_room(room_name: String):
	current_room = room_name
	var chat_ui = get_node("/root/Main/ChatUI")
	if chat_ui:
		chat_ui.show_chat(room_name)

func exit_room(room_name: String):
	if current_room == room_name:
		current_room = ""
		var chat_ui = get_node("/root/Main/ChatUI")
		if chat_ui:
			chat_ui.hide_chat()
