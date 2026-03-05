## Agent avatar — capsule mesh with idle animations and speaking pulse.
## Idle: gentle bob, subtle rotation, faces player when they enter room.
## @export room_name: must match VoiceChat.current_room to trigger pulse.
## Depends on: VoiceChat (/root/Main/VoiceChat) — reads is_speaking and current_room
extends MeshInstance3D

var base_color: Color = Color.WHITE
var pulse_time: float = 0.0
var is_pulsing: bool = false
@export var room_name: String = ""

# Idle animation state
var idle_time: float = 0.0
var base_y: float = 0.0
var idle_rotation_speed: float = 0.3  # radians per second
var bob_amplitude: float = 0.1
var bob_speed: float = 1.5
var player_in_room: bool = false

func _ready():
	base_y = position.y
	if mesh and mesh is CapsuleMesh:
		var mat = get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			base_color = mat.albedo_color

func _process(delta):
	idle_time += delta
	
	# === Idle bob (sine wave) ===
	position.y = base_y + sin(idle_time * bob_speed) * bob_amplitude
	
	# === Face player or idle rotate ===
	var player = get_node_or_null("/root/Main/Player")
	if player:
		var player_room = player.current_room
		player_in_room = (player_room == room_name)
		
		if player_in_room:
			# Face toward player
			var target_pos = player.global_position
			target_pos.y = global_position.y  # only rotate on Y axis
			var dir = (target_pos - global_position).normalized()
			if dir.length() > 0.01:
				var target_angle = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, target_angle, delta * 3.0)
		else:
			# Subtle idle rotation (looking around)
			rotation.y += sin(idle_time * idle_rotation_speed) * delta * 0.5
	
	# === Speaking pulse ===
	var voice_chat = get_node_or_null("/root/Main/VoiceChat")
	if not voice_chat:
		return
	
	var should_pulse = voice_chat.is_speaking and voice_chat.current_room == room_name
	
	if should_pulse:
		pulse_time += delta * 4.0
		var glow = (sin(pulse_time) + 1.0) * 0.5  # 0-1
		var mat = get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = true
			mat.emission = base_color
			mat.emission_energy_multiplier = glow * 2.0
	elif is_pulsing:
		# Stop pulsing
		pulse_time = 0.0
		var mat = get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = false
	
	is_pulsing = should_pulse
