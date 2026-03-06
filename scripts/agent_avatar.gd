## EVE-style robot avatar — CSG-based body with state-driven animations.
## States: idle, listening, recording, thinking, speaking
## Connects to VoiceChat signals and ChatUI status for state transitions.
## Children expected: Head, Visor, LeftEye, RightEye, Body, LeftArm, RightArm, Base
## @export room_name: must match room detection names
extends Node3D

@export var room_name: String = ""

# Node references
var head: Node3D
var visor: Node3D
var left_eye: Node3D
var right_eye: Node3D
var body_node: Node3D
var left_arm: Node3D
var right_arm: Node3D
var base_node: Node3D

# Cached materials for animation
var left_eye_mat: StandardMaterial3D
var right_eye_mat: StandardMaterial3D
var base_eye_energy: float = 2.0

# State machine
enum AvatarState { IDLE, LISTENING, RECORDING, THINKING, SPEAKING }
var current_state: AvatarState = AvatarState.IDLE

# Animation timing
var time: float = 0.0
var base_y: float = 0.0
var bob_amplitude: float = 0.08
var bob_speed: float = 1.5

# Arm base rotations (saved from scene)
var left_arm_base_rot: Vector3 = Vector3.ZERO
var right_arm_base_rot: Vector3 = Vector3.ZERO

# Head base rotation (local)
var head_base_rot: Vector3 = Vector3.ZERO

# Idle personality micro-animations
var next_personality_time: float = 10.0
var personality_active: bool = false
var personality_timer: float = 0.0
var personality_type: int = 0  # 0=head tilt, 1=arm adjust, 2=look around
var personality_duration: float = 1.5

# Thinking blink
var blink_timer: float = 0.0
var blink_interval: float = 2.0
var is_blinking: bool = false
var blink_progress: float = 0.0

# Speaking animation
var speak_head_tilt_dir: float = 1.0
var speak_tilt_timer: float = 0.0

func _ready():
	base_y = position.y
	
	head = get_node_or_null("Head")
	visor = get_node_or_null("Visor")
	left_eye = get_node_or_null("LeftEye")
	right_eye = get_node_or_null("RightEye")
	body_node = get_node_or_null("Body")
	left_arm = get_node_or_null("LeftArm")
	right_arm = get_node_or_null("RightArm")
	base_node = get_node_or_null("Base")
	
	# Cache eye materials for emission animation
	if left_eye and left_eye is CSGShape3D:
		left_eye_mat = (left_eye as CSGShape3D).material
	if right_eye and right_eye is CSGShape3D:
		right_eye_mat = (right_eye as CSGShape3D).material
	
	if left_eye_mat:
		base_eye_energy = left_eye_mat.emission_energy_multiplier
	
	if left_arm:
		left_arm_base_rot = left_arm.rotation
	if right_arm:
		right_arm_base_rot = right_arm.rotation
	if head:
		head_base_rot = head.rotation
	
	_schedule_next_personality()

func _schedule_next_personality():
	next_personality_time = time + randf_range(10.0, 20.0)

func _process(delta: float):
	time += delta
	_update_state()
	_animate_bob(delta)
	_animate_face_player(delta)
	_animate_eyes(delta)
	_animate_head(delta)
	_animate_arms(delta)
	_animate_personality(delta)

# === State Detection ===
func _update_state():
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	var player = get_node_or_null("/root/Main/Player")
	
	var player_in_room := false
	if player and "current_room" in player:
		player_in_room = (player.current_room == room_name)
	
	if not player_in_room:
		current_state = AvatarState.IDLE
		return
	
	# Check states in priority order: speaking > thinking > recording > listening
	if voice_chat and voice_chat.is_speaking and voice_chat.current_room == room_name:
		current_state = AvatarState.SPEAKING
	elif chat_ui and chat_ui.is_thinking and chat_ui.current_room == room_name:
		current_state = AvatarState.THINKING
	elif voice_chat and voice_chat.is_speech_active and voice_chat.current_room == room_name:
		current_state = AvatarState.RECORDING
	else:
		current_state = AvatarState.LISTENING

# === Hover Bob ===
func _animate_bob(_delta: float):
	position.y = base_y + sin(time * bob_speed) * bob_amplitude

# === Face Player / Idle Rotate ===
func _animate_face_player(delta: float):
	var player = get_node_or_null("/root/Main/Player")
	if not player:
		return
	
	var player_in_room := false
	if "current_room" in player:
		player_in_room = (player.current_room == room_name)
	
	if player_in_room:
		var target_pos = player.global_position
		target_pos.y = global_position.y
		var dir = (target_pos - global_position).normalized()
		if dir.length() > 0.01:
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, delta * 3.0)
	else:
		# Subtle idle rotation
		rotation.y += sin(time * 0.3) * delta * 0.5

# === Eye Emission Animation ===
func _animate_eyes(delta: float):
	if not left_eye_mat or not right_eye_mat:
		return
	
	var target_energy := base_eye_energy
	
	match current_state:
		AvatarState.IDLE:
			target_energy = base_eye_energy
		AvatarState.LISTENING, AvatarState.RECORDING:
			# Steady full brightness
			target_energy = 3.0
		AvatarState.THINKING:
			# Dim with blink
			target_energy = 0.5
			_animate_thinking_blink(delta)
		AvatarState.SPEAKING:
			# Rapid pulse
			var pulse = (sin(time * 8.0) + 1.0) * 0.5  # 0-1
			target_energy = lerp(1.5, 3.0, pulse)
	
	# Apply to eyes (thinking blink handles its own scale)
	left_eye_mat.emission_energy_multiplier = target_energy
	right_eye_mat.emission_energy_multiplier = target_energy

func _animate_thinking_blink(delta: float):
	blink_timer += delta
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		is_blinking = true
		blink_progress = 0.0
	
	if is_blinking:
		blink_progress += delta / 0.3  # 0.3s blink duration
		var scale_y: float
		if blink_progress < 0.5:
			# Closing
			scale_y = lerp(1.0, 0.05, blink_progress * 2.0)
		else:
			# Opening
			scale_y = lerp(0.05, 1.0, (blink_progress - 0.5) * 2.0)
		
		if left_eye:
			left_eye.scale.y = scale_y
		if right_eye:
			right_eye.scale.y = scale_y
		
		if blink_progress >= 1.0:
			is_blinking = false
			if left_eye:
				left_eye.scale.y = 1.0
			if right_eye:
				right_eye.scale.y = 1.0
	else:
		# Reset blink when not thinking
		if left_eye and left_eye.scale.y != 1.0:
			left_eye.scale.y = 1.0
		if right_eye and right_eye.scale.y != 1.0:
			right_eye.scale.y = 1.0

# === Head Tilt Animation ===
func _animate_head(delta: float):
	if not head:
		return
	
	var target_rot := head_base_rot
	
	match current_state:
		AvatarState.SPEAKING:
			# Alternating head tilt ±3°
			speak_tilt_timer += delta * 2.0
			var tilt = sin(speak_tilt_timer) * deg_to_rad(3.0)
			target_rot = head_base_rot + Vector3(0, 0, tilt)
		AvatarState.LISTENING, AvatarState.RECORDING:
			# Slight lean forward
			target_rot = head_base_rot + Vector3(deg_to_rad(3.0), 0, 0)
		AvatarState.THINKING:
			# Slight downward tilt
			target_rot = head_base_rot + Vector3(deg_to_rad(5.0), 0, 0)
		_:
			target_rot = head_base_rot
	
	head.rotation = head.rotation.lerp(target_rot, delta * 4.0)

# === Arm Sway Animation ===
func _animate_arms(delta: float):
	if not left_arm or not right_arm:
		return
	
	var left_target := left_arm_base_rot
	var right_target := right_arm_base_rot
	
	match current_state:
		AvatarState.IDLE:
			# Gentle sway ±5°
			var sway = sin(time * 1.2) * deg_to_rad(5.0)
			left_target = left_arm_base_rot + Vector3(sway, 0, 0)
			right_target = right_arm_base_rot + Vector3(-sway, 0, 0)
		AvatarState.SPEAKING:
			# Gesturing — raise/lower
			var gesture = sin(time * 3.0) * deg_to_rad(10.0)
			left_target = left_arm_base_rot + Vector3(gesture, 0, 0)
			right_target = right_arm_base_rot + Vector3(-gesture * 0.7, 0, 0)
		AvatarState.LISTENING, AvatarState.RECORDING:
			# Slight relaxed position
			var sway = sin(time * 0.8) * deg_to_rad(2.0)
			left_target = left_arm_base_rot + Vector3(sway, 0, 0)
			right_target = right_arm_base_rot + Vector3(-sway, 0, 0)
		AvatarState.THINKING:
			# Arms slightly raised (contemplative)
			left_target = left_arm_base_rot + Vector3(deg_to_rad(-8.0), 0, 0)
			right_target = right_arm_base_rot + Vector3(deg_to_rad(-8.0), 0, 0)
	
	left_arm.rotation = left_arm.rotation.lerp(left_target, delta * 5.0)
	right_arm.rotation = right_arm.rotation.lerp(right_target, delta * 5.0)

# === Idle Personality Micro-Animations ===
func _animate_personality(delta: float):
	if current_state != AvatarState.IDLE:
		personality_active = false
		return
	
	if not personality_active:
		if time >= next_personality_time:
			personality_active = true
			personality_timer = 0.0
			personality_type = randi() % 3
			personality_duration = randf_range(1.0, 2.0)
		return
	
	personality_timer += delta
	var t = personality_timer / personality_duration
	
	if t >= 1.0:
		personality_active = false
		_schedule_next_personality()
		return
	
	# Ease in-out curve
	var ease_t = sin(t * PI)
	
	match personality_type:
		0:  # Head tilt
			if head:
				var tilt = ease_t * deg_to_rad(5.0)
				head.rotation.z = head_base_rot.z + tilt
		1:  # Arm adjustment
			if left_arm:
				var adj = ease_t * deg_to_rad(8.0)
				left_arm.rotation.x = left_arm_base_rot.x - adj
		2:  # Look around (additive sway that returns to zero via ease curve)
			var look = sin(t * PI) * deg_to_rad(10.0) * (1.0 if personality_type % 2 == 0 else -1.0)
			# Apply as offset from base (no drift)
			pass  # Handled via rotation.y lerp in _animate_face_player
