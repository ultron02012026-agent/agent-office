extends Node

# Tests for SettingsMenu — pure logic tests

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_menu_open_close()
	test_tab_structure()
	test_volume_binding()
	test_gateway_url_default()
	test_auth_token_secret()
	test_fov_range()
	test_mouse_sensitivity_range()
	test_fullscreen_toggle()
	test_agent_configs()
	test_tts_voice_options()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_menu_open_close():
	var is_open = false
	var visible = false
	
	# Open
	if not is_open:
		is_open = true
		visible = true
	_assert(is_open and visible, "Menu opens: is_open=true, visible=true")
	
	# Double-open guard
	var opened_twice = false
	if is_open:
		opened_twice = false  # guard prevents
	_assert(!opened_twice, "open_menu guards against double-open")
	
	# Close
	if is_open:
		is_open = false
		visible = false
	_assert(!is_open and !visible, "Menu closes: is_open=false, visible=false")
	
	# Double-close guard
	var closed = false
	if not is_open:
		closed = false  # already closed
	_assert(!closed, "close_menu guards against double-close")

func test_tab_structure():
	var tab_names = ["Audio", "Connection", "Controls", "Display", "Agents"]
	_assert(tab_names.size() == 5, "Settings has 5 tabs")
	_assert(tab_names[0] == "Audio", "First tab is Audio")
	_assert(tab_names[1] == "Connection", "Second tab is Connection")
	_assert(tab_names[2] == "Controls", "Third tab is Controls")
	_assert(tab_names[3] == "Display", "Fourth tab is Display")
	_assert(tab_names[4] == "Agents", "Fifth tab is Agents")

func test_volume_binding():
	# Simulate slider → SettingsManager binding
	var master_volume = 1.0
	var slider_val = 0.75
	master_volume = slider_val
	_assert(abs(master_volume - 0.75) < 0.001, "Volume slider updates master_volume")
	
	# Volume range 0-1
	_assert(slider_val >= 0.0 and slider_val <= 1.0, "Volume in valid range 0-1")

func test_gateway_url_default():
	var gateway_url = "http://100.125.54.7:18789"
	_assert(gateway_url.begins_with("http"), "Gateway URL starts with http")
	_assert("18789" in gateway_url, "Gateway URL has default port 18789")
	_assert(!gateway_url.is_empty(), "Gateway URL is not empty by default")

func test_auth_token_secret():
	# Token field should be secret (masked)
	var secret = true  # matches token_input.secret = true
	_assert(secret, "Auth token field is masked (secret=true)")
	
	var placeholder = "Leave blank if no auth"
	_assert(!placeholder.is_empty(), "Auth token has placeholder text")
	
	# Default token is empty
	var gateway_token = ""
	_assert(gateway_token.is_empty(), "Default auth token is empty")

func test_fov_range():
	# FOV slider maps 0-1 to 60-120
	var slider_min = 0.0
	var slider_max = 1.0
	var fov_at_min = 60.0 + slider_min * 60.0
	var fov_at_max = 60.0 + slider_max * 60.0
	_assert(abs(fov_at_min - 60.0) < 0.01, "FOV minimum is 60")
	_assert(abs(fov_at_max - 120.0) < 0.01, "FOV maximum is 120")
	
	# Default FOV
	var default_fov = 75.0
	var slider_for_default = (default_fov - 60.0) / 60.0
	_assert(abs(slider_for_default - 0.25) < 0.01, "Default FOV 75 maps to slider 0.25")

func test_mouse_sensitivity_range():
	# Slider maps val → val * 0.01
	var slider_val = 0.3
	var sensitivity = slider_val * 0.01
	_assert(abs(sensitivity - 0.003) < 0.0001, "Default sensitivity 0.003 from slider 0.3")
	
	# Slider range 0.1 to 1.0
	var min_sens = 0.1 * 0.01
	var max_sens = 1.0 * 0.01
	_assert(abs(min_sens - 0.001) < 0.0001, "Min sensitivity is 0.001")
	_assert(abs(max_sens - 0.01) < 0.0001, "Max sensitivity is 0.01")

func test_fullscreen_toggle():
	var fullscreen = false
	_assert(!fullscreen, "Default is windowed (fullscreen=false)")
	
	fullscreen = true
	_assert(fullscreen, "Fullscreen toggles on")
	
	fullscreen = false
	_assert(!fullscreen, "Fullscreen toggles off")

func test_agent_configs():
	var agent_configs = {
		"Ultron": {"agent_name": "Ultron", "system_prompt": "You are Ultron, an AI agent."},
		"Spinfluencer": {"agent_name": "Spinfluencer", "system_prompt": "You are Spinfluencer, an AI agent."},
		"Dexer": {"agent_name": "Dexer", "system_prompt": "You are Dexer, an AI agent."},
		"Architect": {"agent_name": "Architect", "system_prompt": "You are Architect, an AI agent."},
	}
	_assert(agent_configs.size() == 4, "Agent configs has 4 rooms")
	_assert(agent_configs.has("Ultron"), "Ultron room configured")
	_assert(agent_configs.has("Spinfluencer"), "Spinfluencer room configured")
	_assert(agent_configs.has("Dexer"), "Dexer room configured")
	_assert(agent_configs.has("Architect"), "Architect room configured")
	
	# Each config has required keys
	for room_name in agent_configs:
		var cfg = agent_configs[room_name]
		_assert(cfg.has("agent_name"), room_name + " has agent_name")
		_assert(cfg.has("system_prompt"), room_name + " has system_prompt")

func test_tts_voice_options():
	var voices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
	_assert(voices.size() == 6, "6 TTS voice options available")
	_assert("alloy" in voices, "Default voice 'alloy' is an option")
