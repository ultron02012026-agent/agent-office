## Voice chat: always-on mic with voice activity detection (VAD).
## Mic is live whenever player is in a room. Detects speech start/stop via amplitude threshold.
## Flow: detect speech → record → silence gap → STT → OpenClaw → TTS → spatial audio
## Key methods: set_room(), clear_room(), request_tts()
## Signals: transcription_received(text), tts_started(), tts_finished()
## Depends on: SettingsManager (autoload)
extends Node

signal transcription_received(text: String)
signal tts_started()
signal tts_finished()

var is_recording: bool = false
var audio_effect: AudioEffectCapture
var record_bus_idx: int = -1
var recorded_frames: PackedVector2Array = PackedVector2Array()

var stt_http: HTTPRequest
var tts_http: HTTPRequest
var current_room: String = ""

# Audio playback
var tts_player: AudioStreamPlayer3D
var is_speaking: bool = false

# VAD (Voice Activity Detection)
var vad_enabled: bool = false
var vad_threshold: float = 0.01  # amplitude threshold to detect speech
var silence_timeout: float = 1.2  # seconds of silence before we consider speech done
var silence_timer: float = 0.0
var is_speech_active: bool = false
var min_speech_duration: float = 0.3  # minimum seconds of speech to process (ignore short noise)
var max_speech_duration: float = 30.0  # auto-send after this many seconds
var speech_start_time: float = 0.0
var mic_player: AudioStreamPlayer
var stt_in_flight: bool = false  # guard against overlapping STT requests

func _ready():
	stt_http = HTTPRequest.new()
	stt_http.name = "STTRequest"
	add_child(stt_http)
	stt_http.request_completed.connect(_on_stt_completed)
	
	tts_http = HTTPRequest.new()
	tts_http.name = "TTSRequest"
	add_child(tts_http)
	tts_http.request_completed.connect(_on_tts_completed)
	
	_setup_mic_bus()

func _setup_mic_bus():
	record_bus_idx = AudioServer.get_bus_index("Record")
	if record_bus_idx < 0:
		AudioServer.add_bus()
		record_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(record_bus_idx, "Record")
		AudioServer.set_bus_mute(record_bus_idx, true)
	
	var has_capture = false
	for i in AudioServer.get_bus_effect_count(record_bus_idx):
		if AudioServer.get_bus_effect(record_bus_idx, i) is AudioEffectCapture:
			audio_effect = AudioServer.get_bus_effect(record_bus_idx, i)
			has_capture = true
			break
	
	if not has_capture:
		audio_effect = AudioEffectCapture.new()
		audio_effect.buffer_length = 30.0
		AudioServer.add_bus_effect(record_bus_idx, audio_effect)

func set_room(room_name: String, tts_player_node: AudioStreamPlayer3D = null):
	current_room = room_name
	tts_player = tts_player_node
	# Always restart listening to update tts_player reference
	if vad_enabled:
		vad_enabled = false
	_start_listening()

func clear_room():
	current_room = ""
	tts_player = null
	_stop_listening()

func _start_listening():
	if vad_enabled:
		return
	vad_enabled = true
	is_speech_active = false
	silence_timer = 0.0
	recorded_frames.clear()
	
	# Start mic
	if not mic_player:
		mic_player = AudioStreamPlayer.new()
		mic_player.name = "MicPlayer"
		mic_player.bus = "Record"
		mic_player.stream = AudioStreamMicrophone.new()
		add_child(mic_player)
	
	if audio_effect:
		audio_effect.clear_buffer()
	
	if not mic_player.playing:
		mic_player.play()

func _stop_listening():
	vad_enabled = false
	is_speech_active = false
	is_recording = false
	silence_timer = 0.0
	recorded_frames.clear()
	
	if mic_player and mic_player.playing:
		mic_player.stop()

func _process(delta):
	if not vad_enabled or not audio_effect:
		return
	
	# Don't listen while agent is speaking (avoid feedback)
	if is_speaking:
		if audio_effect:
			audio_effect.clear_buffer()
		return
	
	# Read available audio frames
	var frames_available = audio_effect.get_frames_available()
	if frames_available == 0:
		return
	
	var frames = audio_effect.get_buffer(frames_available)
	
	# Calculate RMS amplitude
	var rms = _calculate_rms(frames)
	
	if rms > vad_threshold:
		# Speech detected
		if not is_speech_active:
			# Speech just started
			is_speech_active = true
			is_recording = true
			speech_start_time = Time.get_ticks_msec() / 1000.0
			recorded_frames.clear()
			# Notify UI
			var chat_ui = get_node_or_null("/root/Main/ChatUI")
			if chat_ui and chat_ui.has_method("set_voice_status"):
				chat_ui.set_voice_status("recording")
		
		silence_timer = 0.0
		recorded_frames.append_array(frames)
		
		# Auto-send if recording too long (prevent memory issues)
		var speech_duration = (Time.get_ticks_msec() / 1000.0) - speech_start_time
		if speech_duration >= max_speech_duration:
			is_speech_active = false
			is_recording = false
			_save_and_transcribe()
			return
	else:
		if is_speech_active:
			# Still recording but silence detected
			recorded_frames.append_array(frames)  # keep the tail
			silence_timer += delta
			
			if silence_timer >= silence_timeout:
				# Speech ended — process it
				is_speech_active = false
				is_recording = false
				silence_timer = 0.0
				
				var speech_duration = (Time.get_ticks_msec() / 1000.0) - speech_start_time
				if speech_duration >= min_speech_duration and recorded_frames.size() > 0:
					_save_and_transcribe()
				else:
					recorded_frames.clear()
					var chat_ui = get_node_or_null("/root/Main/ChatUI")
					if chat_ui and chat_ui.has_method("set_voice_status"):
						chat_ui.set_voice_status("listening")

func _calculate_rms(frames: PackedVector2Array) -> float:
	if frames.size() == 0:
		return 0.0
	var sum_sq: float = 0.0
	for frame in frames:
		var mono = (frame.x + frame.y) * 0.5
		sum_sq += mono * mono
	return sqrt(sum_sq / frames.size())

# Legacy methods for compatibility (push-to-talk fallback)
func start_recording():
	pass  # Now handled by VAD

func stop_recording():
	pass  # Now handled by VAD

func _save_and_transcribe():
	if recorded_frames.size() == 0:
		return
	if stt_in_flight:
		# Drop this recording — previous one still processing
		recorded_frames.clear()
		return
	
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if chat_ui and chat_ui.has_method("set_voice_status"):
		chat_ui.set_voice_status("processing")
	
	var wav_path = "/tmp/agent_office_voice.wav"
	_save_wav(wav_path, recorded_frames)
	recorded_frames.clear()
	_send_to_stt(wav_path)

func _save_wav(path: String, frames: PackedVector2Array):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("VoiceChat: Cannot write WAV to " + path)
		return
	
	var sample_rate = int(AudioServer.get_mix_rate())
	var num_channels = 1
	var bits_per_sample = 16
	var num_samples = frames.size()
	var data_size = num_samples * num_channels * (bits_per_sample / 8)
	
	file.store_string("RIFF")
	file.store_32(36 + data_size)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)
	file.store_16(1)  # PCM
	file.store_16(num_channels)
	file.store_32(sample_rate)
	file.store_32(sample_rate * num_channels * bits_per_sample / 8)
	file.store_16(num_channels * bits_per_sample / 8)
	file.store_16(bits_per_sample)
	file.store_string("data")
	file.store_32(data_size)
	
	for frame in frames:
		var sample = (frame.x + frame.y) * 0.5
		sample = clamp(sample, -1.0, 1.0)
		file.store_16(int(sample * 32767))
	
	file.close()

func _send_to_stt(wav_path: String):
	var file = FileAccess.open(wav_path, FileAccess.READ)
	if not file:
		push_error("VoiceChat: Cannot read WAV for STT")
		return
	
	var file_data = file.get_buffer(file.get_length())
	file.close()
	
	var boundary = "----AgentOfficeBoundary"
	var body = PackedByteArray()
	
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
	stt_in_flight = true
	var err = stt_http.request_raw(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		stt_in_flight = false
		push_error("VoiceChat: STT request failed: " + str(err))

func _on_stt_completed(_result, response_code, _headers, body_bytes):
	stt_in_flight = false
	if response_code != 200:
		push_warning("VoiceChat: STT returned " + str(response_code))
		transcription_received.emit("")
		return
	
	var json = JSON.parse_string(body_bytes.get_string_from_utf8())
	if json and json.has("text"):
		var text = json["text"].strip_edges()
		if not text.is_empty():
			transcription_received.emit(text)
		else:
			transcription_received.emit("")
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
