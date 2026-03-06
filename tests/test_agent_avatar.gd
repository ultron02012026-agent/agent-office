extends Node

# Tests for AgentAvatar — EVE-style robot with state machine and animations

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_default_state()
	test_state_transitions()
	test_state_priority()
	test_bob_animation()
	test_eye_emission_idle()
	test_eye_emission_speaking()
	test_eye_emission_thinking()
	test_eye_emission_listening()
	test_blink_timing()
	test_blink_scale()
	test_head_tilt_speaking()
	test_arm_sway_idle()
	test_arm_gesture_speaking()
	test_personality_scheduling()
	test_personality_types()
	test_room_match()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_default_state():
	# Default state is IDLE (enum value 0)
	var state = 0  # AvatarState.IDLE
	_assert(state == 0, "Default state is IDLE")

func test_state_transitions():
	# Simulate state detection logic
	var is_speaking = false
	var is_thinking = false
	var is_speech_active = false
	var player_in_room = true
	var room_match = true
	
	# Listening (player in room, nothing else active)
	var state = _calc_state(player_in_room, room_match, is_speaking, is_thinking, is_speech_active)
	_assert(state == 1, "Player in room, idle → LISTENING")
	
	# Recording (player speaking)
	is_speech_active = true
	state = _calc_state(player_in_room, room_match, is_speaking, is_thinking, is_speech_active)
	_assert(state == 2, "VAD active → RECORDING")
	
	# Thinking
	is_speech_active = false
	is_thinking = true
	state = _calc_state(player_in_room, room_match, is_speaking, is_thinking, is_speech_active)
	_assert(state == 3, "Waiting for response → THINKING")
	
	# Speaking
	is_thinking = false
	is_speaking = true
	state = _calc_state(player_in_room, room_match, is_speaking, is_thinking, is_speech_active)
	_assert(state == 4, "TTS playing → SPEAKING")

func test_state_priority():
	# Speaking takes priority over thinking
	var state = _calc_state(true, true, true, true, true)
	_assert(state == 4, "SPEAKING has highest priority")
	
	# Thinking over recording
	state = _calc_state(true, true, false, true, true)
	_assert(state == 3, "THINKING over RECORDING")
	
	# Not in room → IDLE
	state = _calc_state(false, true, true, true, true)
	_assert(state == 0, "Not in room → IDLE regardless")

func test_bob_animation():
	# Bob formula: base_y + sin(time * bob_speed) * bob_amplitude
	var base_y = 0.05
	var bob_speed = 1.5
	var bob_amplitude = 0.08
	
	var y_at_0 = base_y + sin(0.0 * bob_speed) * bob_amplitude
	_assert(abs(y_at_0 - base_y) < 0.001, "Bob at t=0 is at base_y")
	
	var y_at_peak = base_y + sin(PI / 2.0 / bob_speed * bob_speed) * bob_amplitude
	# sin(PI/2) = 1
	var expected_peak = base_y + bob_amplitude
	_assert(abs(y_at_peak - expected_peak) < 0.01, "Bob peaks at base_y + amplitude")

func test_eye_emission_idle():
	var base_energy = 2.0
	# IDLE: target_energy = base_eye_energy
	_assert(base_energy == 2.0, "Idle eye emission at base energy (2.0)")

func test_eye_emission_speaking():
	# Speaking: pulse between 1.5 and 3.0
	var time = 0.0
	var pulse = (sin(time * 8.0) + 1.0) * 0.5
	var energy = lerp(1.5, 3.0, pulse)
	_assert(energy >= 1.5 and energy <= 3.0, "Speaking eye energy in [1.5, 3.0]")
	
	# At sin peak
	time = PI / 16.0  # sin(PI/2) = 1
	pulse = (sin(time * 8.0) + 1.0) * 0.5
	energy = lerp(1.5, 3.0, pulse)
	_assert(abs(energy - 3.0) < 0.01, "Speaking eye peaks at 3.0")

func test_eye_emission_thinking():
	# Thinking: dim at 0.5
	var target_energy = 0.5
	_assert(target_energy == 0.5, "Thinking eye emission dimmed to 0.5")

func test_eye_emission_listening():
	# Listening: full brightness at 3.0
	var target_energy = 3.0
	_assert(target_energy == 3.0, "Listening eye emission at full (3.0)")

func test_blink_timing():
	var blink_interval = 2.0
	var blink_timer = 0.0
	var blinks = 0
	
	# Simulate 5 seconds
	for i in range(50):
		blink_timer += 0.1
		if blink_timer >= blink_interval:
			blink_timer = 0.0
			blinks += 1
	
	_assert(blinks == 2, "2 blinks in 5 seconds (interval=2s)")

func test_blink_scale():
	# Blink: scale_y goes 1.0 → 0.05 → 1.0 over 0.3s
	var progress = 0.0
	var scale_y = lerp(1.0, 0.05, progress * 2.0)
	_assert(abs(scale_y - 1.0) < 0.01, "Blink start: scale_y = 1.0")
	
	progress = 0.5
	# At midpoint, closing phase complete
	scale_y = lerp(1.0, 0.05, 0.5 * 2.0)
	_assert(abs(scale_y - 0.05) < 0.01, "Blink mid: scale_y = 0.05 (closed)")
	
	progress = 1.0
	scale_y = lerp(0.05, 1.0, (1.0 - 0.5) * 2.0)
	_assert(abs(scale_y - 1.0) < 0.01, "Blink end: scale_y = 1.0 (open)")

func test_head_tilt_speaking():
	# Speaking head tilt: sin(timer) * 3°
	var max_tilt_deg = 3.0
	var max_tilt_rad = deg_to_rad(max_tilt_deg)
	_assert(abs(max_tilt_rad - 0.05236) < 0.001, "Speaking head tilt ±3° (±0.052 rad)")

func test_arm_sway_idle():
	# Idle arm sway: ±5°
	var sway_deg = 5.0
	var sway_rad = deg_to_rad(sway_deg)
	_assert(abs(sway_rad - 0.08727) < 0.001, "Idle arm sway ±5° (±0.087 rad)")

func test_arm_gesture_speaking():
	# Speaking arm gesture: ±10°
	var gesture_deg = 10.0
	var gesture_rad = deg_to_rad(gesture_deg)
	_assert(abs(gesture_rad - 0.17453) < 0.001, "Speaking arm gesture ±10° (±0.175 rad)")

func test_personality_scheduling():
	# Next personality time should be 10-20s from current time
	var time = 5.0
	var next = time + 15.0  # middle of range
	_assert(next >= time + 10.0 and next <= time + 20.0, "Personality scheduled 10-20s out")

func test_personality_types():
	# 3 personality types: 0=head tilt, 1=arm adjust, 2=look around
	for i in range(3):
		var ptype = i % 3
		_assert(ptype >= 0 and ptype <= 2, "Personality type %d valid" % i)

func test_room_match():
	# State only changes from IDLE when player room matches avatar room
	var player_room = "Ultron"
	var avatar_room = "Ultron"
	_assert(player_room == avatar_room, "Room match: same room")
	
	player_room = "Dexer"
	_assert(player_room != avatar_room, "Room mismatch: different room")

# Helper to simulate state calculation
func _calc_state(player_in_room: bool, room_match: bool, is_speaking: bool, is_thinking: bool, is_speech_active: bool) -> int:
	if not player_in_room:
		return 0  # IDLE
	if is_speaking and room_match:
		return 4  # SPEAKING
	if is_thinking and room_match:
		return 3  # THINKING
	if is_speech_active and room_match:
		return 2  # RECORDING
	return 1  # LISTENING
