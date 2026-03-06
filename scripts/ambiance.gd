## Ambiance system — background ambient sound per area.
## Different loops for lobby, offices, and hallway. Volume from settings.
## Audio stubs wired up — drop in .ogg/.wav files to hear actual audio.
extends Node

var current_zone: String = "lobby"
var target_volume_db: float = -10.0
var fade_speed: float = 2.0

# AudioStreamPlayer nodes (created in _ready)
var lobby_player: AudioStreamPlayer
var office_player: AudioStreamPlayer
var hallway_player: AudioStreamPlayer
var active_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	lobby_player = _create_player("LobbyAmbiance")
	office_player = _create_player("OfficeAmbiance")
	hallway_player = _create_player("HallwayAmbiance")
	active_player = lobby_player
	
	# Background music (loops) — process even when tree is paused
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.volume_db = -14.0
	music_player.bus = "Master"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	var bg_music = load("res://assets/audio/bg_music.mp3")
	if bg_music:
		music_player.stream = bg_music
		music_player.stream.loop = true
		music_player.play()
	# Load ambient audio files
	var office_stream = load("res://assets/audio/ambient_office.wav")
	var hallway_stream = load("res://assets/audio/ambient_hallway.wav")
	if office_stream:
		if office_stream is AudioStreamWAV:
			office_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		lobby_player.stream = office_stream  # lobby uses office hum too
		office_player.stream = office_stream
	if hallway_stream:
		if hallway_stream is AudioStreamWAV:
			hallway_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		hallway_player.stream = hallway_stream
	# Start playing the initial zone
	if active_player.stream:
		active_player.play()

func _create_player(pname: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = pname
	player.volume_db = -80  # start silent
	player.bus = "Master"
	add_child(player)
	return player

func _process(delta):
	var player_node = get_node_or_null("/root/Main/Player")
	if player_node:
		var new_zone = _get_zone(player_node)
		if new_zone != current_zone:
			current_zone = new_zone
			_switch_zone(new_zone)
	
	# Fade active player to target volume
	if active_player:
		active_player.volume_db = lerp(active_player.volume_db, target_volume_db, delta * fade_speed)
	
	# Fade out inactive players and stop them when silent
	for p in [lobby_player, office_player, hallway_player]:
		if p != active_player:
			p.volume_db = lerp(p.volume_db, -80.0, delta * fade_speed)
			if p.volume_db <= -60.0 and p.playing:
				p.stop()

func _get_zone(player_node) -> String:
	if not player_node.current_room.is_empty():
		return "office"
	elif player_node.global_position.z > 7:
		return "lobby"
	else:
		return "hallway"

func _switch_zone(zone: String):
	match zone:
		"lobby":
			active_player = lobby_player
		"office":
			active_player = office_player
		"hallway":
			active_player = hallway_player
	
	# Start playing if stream exists and not already playing
	if active_player.stream and not active_player.playing:
		active_player.play()
	
	target_volume_db = _get_volume_for_zone(zone)

func _get_volume_for_zone(zone: String) -> float:
	var base = -10.0
	match zone:
		"lobby":
			base = -8.0  # slightly louder hum
		"office":
			base = -15.0  # quiet
		"hallway":
			base = -12.0  # echo-y
	
	# Apply master volume setting
	return base + linear_to_db(SettingsManager.master_volume)

func set_stream(zone: String, stream: AudioStream):
	match zone:
		"lobby":
			lobby_player.stream = stream
		"office":
			office_player.stream = stream
		"hallway":
			hallway_player.stream = stream

func get_current_zone() -> String:
	return current_zone
