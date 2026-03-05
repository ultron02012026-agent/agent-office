## Voice chat: push-to-talk mic capture → WAV → STT → TTS → spatial audio playback.
## Key methods: start/stop_recording(), request_tts(), toggle_voice_mode(), set_room(), clear_room()
## Signals: transcription_received(text), tts_started(), tts_finished()
## Depends on: SettingsManager (autoload), room's AudioStreamPlayer3D for spatial TTS
extends Node

signal transcription_received(text: String)
signal tts_started()
signal tts_finished()

var is_recording: bool = false
var voice_mode: bool = false  # false = text mode, true = voice mode
var audio_effect: AudioEffectCapture
var record_bus_idx: int = -1
var recorded_frames: PackedVector2Array = PackedVector2Array()

var stt_http: HTTPRequest
var tts_http: HTTPRequest
var current_room: String = ""

# Audio playback
var tts_player: AudioStreamPlayer3D  # Set by room when entering
var is_speaking: bool = false

func _ready():
	stt_http = HTTPRequest.new()
	stt_http.name = "STTRequest"
	add_child(stt_http)
	stt_http.request_completed.connect(_on_stt_completed)
	
	tts_http = HTTPRequest.new()
	tts_http.name = "TTSRequest"
	tts_http.download_file = "/tmp/agent_office_response.ogg"
	add_child(tts_http)
	tts_http.request_completed.connect(_on_tts_completed)
	
	_setup_mic_bus()

func _setup_mic_bus():
	# Create a "Record" bus with AudioEffectCapture
	record_bus_idx = AudioServer.get_bus_index("Record")
	if record_bus_idx < 0:
		AudioServer.add_bus()
		record_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(record_bus_idx, "Record")
		AudioServer.set_bus_mute(record_bus_idx, true)  # Don't play mic back
	
	# Add capture effect if not present
	var has_capture = false
	for i in AudioServer.get_bus_effect_count(record_bus_idx):
		if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectCapture:
			audio_effect = AudioServer.get_bus_effect(record_bus_idx, i)
			has_capture = true
			break
	
	if not has_capture:
		audio_effect = AudioEffectCapture.new()
		audio_effect.buffer_length = 30.0  # 30 seconds max
		AudioServer.add_bus_effect(record_bus_idx, audio_effect)

func set_room(room_name: String, tts_player_node: AudioStreamPlayer3D = null):
	current_room = room_name
	tts_player = tts_player_node

func clear_room():
	current_room = ""
	tts_player = null
	stop_recording()

func toggle_voice_mode():
	voice_mode = !voice_mode

func start_recording():
	if is_recording or not SettingsManager.mic_enabled:
		return
	if current_room.is_empty():
		return
	
	is_recording = true
	recorded_frames.clear()
	
	# Clear any buffered audio
	if audio_effect:
		audio_effect.clear_buffer()
	
	# Start mic input
	var mic_player = get_node_or_null("MicPlayer")
	if not mic_player:
		mic_player = AudioStreamPlayer.new()
		mic_player.name = "MicPlayer"
		mic_player.bus = "Record"
		var mic_stream = AudioStreamMicrophone.new()
		mic_player.stream = mic_stream
		add_child(mic_player)
	
	if not mic_player.playing:
		mic_player.play()

func stop_recording():
	if not is_recording:
		return
	is_recording = false
	
	var mic_player = get_node_or_null("MicPlayer")
	if mic_player and mic_player.playing:
		mic_player.stop()
	
	# Grab captured audio
	if audio_effect:
		var frames = audio_effect.get_frames_available()
		if frames > 0:
			recorded_frames = audio_effect.get_buffer(frames)
			_save_and_transcribe()
		else:
			push_warning("VoiceChat: No audio frames captured")

func _save_and_transcribe():
	if recorded_frames.size() == 0:
		return
	
	# Save as WAV
	var wav_path = "/tmp/agent_office_voice.wav"
	_save_wav(wav_path, recorded_frames)
	
	# Send to STT
	_send_to_stt(wav_path)

func _save_wav(path: String, frames: PackedVector2Array):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("VoiceChat: Cannot write WAV to " + path)
		return
	
	var sample_rate = int(AudioServer.get_mix_rate())
	var num_channels = 1  # mono
	var bits_per_sample = 16
	var num_samples = frames.size()
	var data_size = num_samples * num_channels * (bits_per_sample / 8)
	
	# WAV header
	file.store_string("RIFF")
	file.store_32(36 + data_size)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)  # chunk size
	file.store_16(1)   # PCM
	file.store_16(num_channels)
	file.store_32(sample_rate)
	file.store_32(sample_rate * num_channels * bits_per_sample / 8)
	file.store_16(num_channels * bits_per_sample / 8)
	file.store_16(bits_per_sample)
	file.store_string("data")
	file.store_32(data_size)
	
	# Write samples (mix to mono)
	for frame in frames:
		var sample = (frame.x + frame.y) * 0.5
		sample = clamp(sample, -1.0, 1.0)
		file.store_16(int(sample * 32767))
	
	file.close()

func _send_to_stt(wav_path: String):
	# Multipart form upload
	var file = FileAccess.open(wav_path, FileAccess.READ)
	if not file:
		push_error("VoiceChat: Cannot read WAV for STT")
		return
	
	var file_data = file.get_buffer(file.get_length())
	file.close()
	
	var boundary = "----AgentOfficeBoundary"
	var body = PackedByteArray()
	
	# Build multipart body
	var part_header = "--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"voice.wav\"\r\nContent-Type: audio/wav\r\n\r\n" % boundary
	body.append_array(part_header.to_utf8_buffer())
	body.append_array(file_data)
	
	var model_part = "\r\n--%s\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1" % boundary
	body.append_array(model_part.to_utf8_buffer())
	
	var closing = "\r\n--%s--\r\n" % boundary
	body.append_array(closing.to_utf8_buffer())
	
	var headers = [
		"Content-Type: multipart/form-data; boundary=%s" % boundary
	]
	if SettingsManager.gateway_token != "":
		headers.append("Authorization: Bearer " + SettingsManager.gateway_token)
	
	var url = SettingsManager.gateway_url + "/v1/audio/transcriptions"
	var err = stt_http.request_raw(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("VoiceChat: STT request failed: " + str(err))

func _on_stt_completed(_result, response_code, _headers, body_bytes):
	if response_code != 200:
		push_warning("VoiceChat: STT returned " + str(response_code))
		# Fall back — emit empty
		transcription_received.emit("")
		return
	
	var json = JSON.parse_string(body_bytes.get_string_from_utf8())
	if json and json.has("text"):
		var text = json["text"].strip_edges()
		if not text.is_empty():
			transcription_received.emit(text)
	else:
		transcription_received.emit("")

func request_tts(text: String):
	if text.is_empty():
		return
	
	var body = JSON.stringify({
		"input": text,
		"voice": SettingsManager.tts_voice,
		"model": "tts-1",
		"response_format": "mp3"
	})
	
	var headers = ["Content-Type: application/json"]
	if SettingsManager.gateway_token != "":
		headers.append("Authorization: Bearer " + SettingsManager.gateway_token)
	var url = SettingsManager.gateway_url + "/v1/audio/speech"
	tts_http.download_file = "/tmp/agent_office_response.mp3"
	var err = tts_http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("VoiceChat: TTS request failed: " + str(err))

func _on_tts_completed(_result, response_code, _headers, _body_bytes):
	if response_code != 200:
		push_warning("VoiceChat: TTS returned " + str(response_code))
		tts_finished.emit()
		return
	
	# Load and play the audio
	var file_path = "/tmp/agent_office_response.mp3"
	if not FileAccess.file_exists(file_path):
		tts_finished.emit()
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		tts_finished.emit()
		return
	
	var mp3_data = file.get_buffer(file.get_length())
	file.close()
	
	var stream = AudioStreamMP3.new()
	stream.data = mp3_data
	
	is_speaking = true
	tts_started.emit()
	
	if tts_player and is_instance_valid(tts_player):
		tts_player.stream = stream
		tts_player.play()
		tts_player.finished.connect(_on_tts_playback_finished, CONNECT_ONE_SHOT)
	else:
		# Fallback: use a non-spatial player
		var fallback = AudioStreamPlayer.new()
		fallback.name = "TTSFallback"
		add_child(fallback)
		fallback.stream = stream
		fallback.play()
		fallback.finished.connect(func():
			is_speaking = false
			tts_finished.emit()
			fallback.queue_free()
		)

func _on_tts_playback_finished():
	is_speaking = false
	tts_finished.emit()
