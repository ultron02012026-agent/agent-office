## Agent avatar — capsule mesh that pulses emission glow when the agent is speaking.
## @export room_name: must match VoiceChat.current_room to trigger pulse.
## Depends on: VoiceChat (/root/Main/VoiceChat) — reads is_speaking and current_room
extends MeshInstance3D

var base_color: Color = Color.WHITE
var pulse_time: float = 0.0
var is_pulsing: bool = false
@export var room_name: String = ""

func _ready():
	if mesh and mesh is CapsuleMesh:
		var mat = get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			base_color = mat.albedo_color

func _process(delta):
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
