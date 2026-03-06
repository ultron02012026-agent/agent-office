## Autoload singleton — persistent settings (audio, connection, controls, display, agents).
## Access as SettingsManager.property from any script. Call save_settings() to persist.
## Persists to user://settings.cfg via ConfigFile.
extends Node

var config := ConfigFile.new()
var settings_path := "user://settings.cfg"

# Audio
var master_volume: float = 1.0
var voice_volume: float = 1.0
var mic_enabled: bool = true
var tts_voice: String = "alloy"

# Connection
var gateway_url: String = "http://100.125.54.7:18789"
var gateway_token: String = ""

# Controls
var mouse_sensitivity: float = 0.003
var invert_y: bool = false
var push_to_talk_key: String = "V"

# Display
var fullscreen: bool = false
var fov: float = 75.0
var vsync: bool = true

# Agent config (room_name -> {agent_name, system_prompt})
var agent_configs: Dictionary = {
	"Ultron": {"agent_name": "Ultron", "system_prompt": "You are Ultron, an AI agent."},
	"Spinfluencer": {"agent_name": "Spinfluencer", "system_prompt": "You are Spinfluencer, an AI agent."},
	"Dexer": {"agent_name": "Dexer", "system_prompt": "You are Dexer, an AI agent."},
	"DJ Sam": {"agent_name": "DJ Sam", "system_prompt": "You are DJ Sam, an AI agent and music specialist."},
	"Mollie": {"agent_name": "Mollie", "system_prompt": "You are Mollie, the office manager and secretary for Agent Office. You help the user navigate the office, manage settings, add new agents, and control the environment. You're friendly, organized, and the first face people see."},
}

func _ready():
	load_settings()

func load_settings():
	var err = config.load(settings_path)
	if err != OK:
		save_settings()  # Create default
		return
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	voice_volume = config.get_value("audio", "voice_volume", 1.0)
	mic_enabled = config.get_value("audio", "mic_enabled", true)
	tts_voice = config.get_value("audio", "tts_voice", "alloy")
	
	gateway_url = config.get_value("connection", "gateway_url", "http://100.125.54.7:18789")
	gateway_token = config.get_value("connection", "gateway_token", "")
	
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.003)
	invert_y = config.get_value("controls", "invert_y", false)
	push_to_talk_key = config.get_value("controls", "push_to_talk_key", "V")
	
	fullscreen = config.get_value("display", "fullscreen", false)
	fov = config.get_value("display", "fov", 75.0)
	vsync = config.get_value("display", "vsync", true)
	
	var saved_agents = config.get_value("agents", "configs", {})
	if saved_agents.size() > 0:
		agent_configs = saved_agents
	
	_apply_settings()

func save_settings():
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	config.set_value("audio", "mic_enabled", mic_enabled)
	config.set_value("audio", "tts_voice", tts_voice)
	
	config.set_value("connection", "gateway_url", gateway_url)
	config.set_value("connection", "gateway_token", gateway_token)
	
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("controls", "invert_y", invert_y)
	config.set_value("controls", "push_to_talk_key", push_to_talk_key)
	
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "fov", fov)
	config.set_value("display", "vsync", vsync)
	
	config.set_value("agents", "configs", agent_configs)
	
	config.save(settings_path)

func _apply_settings():
	# Audio
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	var voice_bus = AudioServer.get_bus_index("Voice")
	if voice_bus >= 0:
		AudioServer.set_bus_volume_db(voice_bus, linear_to_db(voice_volume))
	
	# Display
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
