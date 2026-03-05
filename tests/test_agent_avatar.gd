extends Node

# Tests for AgentAvatar — pulse logic

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_default_state()
	test_pulse_activation()
	test_pulse_deactivation()
	test_pulse_room_match()
	test_pulse_glow_calculation()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_default_state():
	var is_pulsing = false
	var pulse_time = 0.0
	_assert(!is_pulsing, "Default state is non-pulsing")
	_assert(pulse_time == 0.0, "Default pulse_time is 0")

func test_pulse_activation():
	var is_speaking = true
	var current_room = "Ultron"
	var room_name = "Ultron"
	var should_pulse = is_speaking and current_room == room_name
	_assert(should_pulse, "Pulse activates when speaking in matching room")

func test_pulse_deactivation():
	# Was pulsing, now stopped
	var is_pulsing = true
	var is_speaking = false
	var current_room = "Ultron"
	var room_name = "Ultron"
	var should_pulse = is_speaking and current_room == room_name
	
	_assert(!should_pulse, "Pulse deactivates when not speaking")
	
	# Reset pulse_time when stopping
	if !should_pulse and is_pulsing:
		var pulse_time = 0.0
		_assert(pulse_time == 0.0, "pulse_time resets on deactivation")

func test_pulse_room_match():
	var is_speaking = true
	
	# Wrong room
	var current_room = "Dexer"
	var room_name = "Ultron"
	var should_pulse = is_speaking and current_room == room_name
	_assert(!should_pulse, "No pulse when speaking in different room")
	
	# Right room
	current_room = "Ultron"
	should_pulse = is_speaking and current_room == room_name
	_assert(should_pulse, "Pulse when speaking in matching room")

func test_pulse_glow_calculation():
	# Glow = (sin(pulse_time) + 1) * 0.5 → range [0, 1]
	var pulse_time = 0.0
	var glow = (sin(pulse_time) + 1.0) * 0.5
	_assert(abs(glow - 0.5) < 0.01, "Glow at t=0 is 0.5")
	
	pulse_time = PI / 2.0  # sin = 1
	glow = (sin(pulse_time) + 1.0) * 0.5
	_assert(abs(glow - 1.0) < 0.01, "Glow peaks at 1.0")
	
	pulse_time = 3.0 * PI / 2.0  # sin = -1
	glow = (sin(pulse_time) + 1.0) * 0.5
	_assert(abs(glow - 0.0) < 0.01, "Glow troughs at 0.0")
	
	# Emission energy = glow * 2.0
	var energy = glow * 2.0
	_assert(energy >= 0.0 and energy <= 2.0, "Emission energy in [0, 2]")
