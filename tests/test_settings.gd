extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_default_values()
	test_save_load()
	test_agent_configs()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_default_values():
	# Test defaults match expected
	var config = ConfigFile.new()
	
	_assert(config.get_value("audio", "master_volume", 1.0) == 1.0, "Default master volume is 1.0")
	_assert(config.get_value("audio", "tts_voice", "alloy") == "alloy", "Default TTS voice is alloy")
	_assert(config.get_value("connection", "gateway_url", "http://localhost:3007") == "http://localhost:3007", "Default gateway URL")
	_assert(config.get_value("controls", "mouse_sensitivity", 0.003) == 0.003, "Default mouse sensitivity")
	_assert(config.get_value("display", "fov", 75.0) == 75.0, "Default FOV is 75")

func test_save_load():
	var config = ConfigFile.new()
	var test_path = "/tmp/agent_office_test_settings.cfg"
	
	config.set_value("audio", "master_volume", 0.5)
	config.set_value("display", "fov", 90.0)
	config.save(test_path)
	
	var config2 = ConfigFile.new()
	var err = config2.load(test_path)
	_assert(err == OK, "Settings file loads without error")
	_assert(config2.get_value("audio", "master_volume", 1.0) == 0.5, "Saved master volume persists")
	_assert(config2.get_value("display", "fov", 75.0) == 90.0, "Saved FOV persists")
	
	# Cleanup
	DirAccess.remove_absolute(test_path)

func test_agent_configs():
	var configs = {
		"Ultron": {"agent_name": "Ultron", "system_prompt": "You are Ultron."},
		"Dexer": {"agent_name": "Dexer", "system_prompt": "You are Dexer."},
	}
	
	_assert(configs.has("Ultron"), "Agent config has Ultron")
	_assert(configs["Ultron"]["agent_name"] == "Ultron", "Agent name correct")
	_assert(!configs.has("Unknown"), "No config for unknown agent")
	
	# Modify
	configs["Ultron"]["agent_name"] = "CustomName"
	_assert(configs["Ultron"]["agent_name"] == "CustomName", "Agent name editable")
