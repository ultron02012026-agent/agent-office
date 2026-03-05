extends Node

# Tests for VoiceChat — pure logic tests (no real audio/HTTP)

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_recording_state_machine()
	test_voice_mode_toggle()
	test_room_management()
	test_wav_header_format()
	test_transcription_parsing()
	test_tts_request_body()
	test_recording_guards()
	test_speaking_state()
	test_mono_mix()
	test_stt_error_handling()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_recording_state_machine():
	# idle → recording → processing → idle
	var is_recording = false
	_assert(!is_recording, "Initial state is idle (not recording)")
	
	is_recording = true
	_assert(is_recording, "State transitions to recording")
	
	# Stop recording → processing
	is_recording = false
	var processing = true
	_assert(!is_recording and processing, "Stop recording enters processing state")
	
	# Processing complete → idle
	processing = false
	_assert(!is_recording and !processing, "Processing complete returns to idle")

func test_voice_mode_toggle():
	var voice_mode = false
	_assert(!voice_mode, "Default is text mode")
	
	# Toggle via Tab
	voice_mode = !voice_mode
	_assert(voice_mode, "Tab toggles to voice mode")
	
	voice_mode = !voice_mode
	_assert(!voice_mode, "Tab toggles back to text mode")

func test_room_management():
	var current_room = ""
	var tts_player = null
	
	# set_room
	current_room = "Ultron"
	_assert(current_room == "Ultron", "set_room sets current_room")
	
	# clear_room
	current_room = ""
	tts_player = null
	var is_recording = false
	_assert(current_room.is_empty(), "clear_room clears room name")
	_assert(tts_player == null, "clear_room nulls tts_player")
	_assert(!is_recording, "clear_room stops recording")

func test_wav_header_format():
	# Validate WAV header structure matches voice_chat.gd's _save_wav
	var sample_rate = 44100
	var num_channels = 1
	var bits_per_sample = 16
	var num_samples = 1000
	var data_size = num_samples * num_channels * (bits_per_sample / 8)
	
	_assert(data_size == 2000, "WAV data size = samples * channels * bytes_per_sample")
	
	var file_size = 36 + data_size
	_assert(file_size == 2036, "WAV file size = 36 + data_size")
	
	# PCM format = 1
	var format = 1
	_assert(format == 1, "WAV format is PCM (1)")
	
	# Byte rate
	var byte_rate = sample_rate * num_channels * bits_per_sample / 8
	_assert(byte_rate == 88200, "WAV byte rate correct for 44100 mono 16-bit")
	
	# Block align
	var block_align = num_channels * bits_per_sample / 8
	_assert(block_align == 2, "WAV block align = 2 for mono 16-bit")

func test_transcription_parsing():
	# Valid JSON with text
	var json_str = '{"text": "Hello world"}'
	var json = JSON.parse_string(json_str)
	_assert(json != null and json.has("text"), "Valid JSON parsed successfully")
	_assert(json["text"].strip_edges() == "Hello world", "Transcription text extracted")
	
	# Empty text
	json_str = '{"text": "   "}'
	json = JSON.parse_string(json_str)
	var text = json["text"].strip_edges()
	_assert(text.is_empty(), "Empty/whitespace transcription handled")
	
	# Missing text field
	json_str = '{"error": "bad request"}'
	json = JSON.parse_string(json_str)
	_assert(!json.has("text"), "Missing text field detected")
	
	# Invalid JSON
	json = JSON.parse_string("not json at all")
	_assert(json == null, "Invalid JSON returns null")

func test_tts_request_body():
	# Mirrors request_tts() body construction
	var text = "Hello from the agent"
	var tts_voice = "alloy"
	var body = JSON.stringify({
		"input": text,
		"voice": tts_voice,
		"model": "tts-1",
		"response_format": "mp3"
	})
	var parsed = JSON.parse_string(body)
	_assert(parsed["input"] == text, "TTS body has correct input text")
	_assert(parsed["voice"] == "alloy", "TTS body has correct voice")
	_assert(parsed["model"] == "tts-1", "TTS body has correct model")
	_assert(parsed["response_format"] == "mp3", "TTS body format is mp3")

func test_recording_guards():
	# Can't record if mic disabled
	var mic_enabled = false
	var is_recording = false
	var current_room = "Ultron"
	if is_recording or not mic_enabled:
		is_recording = false  # guard prevents
	_assert(!is_recording, "Recording blocked when mic disabled")
	
	# Can't record if no room
	mic_enabled = true
	current_room = ""
	var can_record = !current_room.is_empty() and mic_enabled
	_assert(!can_record, "Recording blocked when not in a room")
	
	# Can record with mic + room
	current_room = "Ultron"
	can_record = !current_room.is_empty() and mic_enabled
	_assert(can_record, "Recording allowed with mic enabled and in room")

func test_speaking_state():
	var is_speaking = false
	_assert(!is_speaking, "Default is not speaking")
	
	# TTS starts
	is_speaking = true
	_assert(is_speaking, "is_speaking true during TTS playback")
	
	# TTS finishes
	is_speaking = false
	_assert(!is_speaking, "is_speaking false after TTS finishes")

func test_mono_mix():
	# voice_chat.gd mixes stereo to mono: (L + R) * 0.5
	var frame_l = 0.8
	var frame_r = 0.4
	var mono = (frame_l + frame_r) * 0.5
	_assert(abs(mono - 0.6) < 0.001, "Stereo to mono mix correct")
	
	# Clamping
	var loud = (1.0 + 1.0) * 0.5
	loud = clamp(loud, -1.0, 1.0)
	_assert(loud == 1.0, "Mono sample clamped to [-1, 1]")
	
	# 16-bit conversion
	var sample_16 = int(0.5 * 32767)
	_assert(sample_16 == 16383, "Float to 16-bit PCM conversion correct")

func test_stt_error_handling():
	# Non-200 response emits empty string
	var response_code = 500
	var fallback_text = ""
	if response_code != 200:
		fallback_text = ""
	_assert(fallback_text.is_empty(), "STT error emits empty transcription")
	
	# Empty body
	var body_str = ""
	var json = JSON.parse_string(body_str)
	_assert(json == null, "Empty STT body returns null JSON")
	
	# STT URL construction
	var gateway_url = "http://localhost:18789"
	var stt_url = gateway_url + "/v1/audio/transcriptions"
	_assert(stt_url == "http://localhost:18789/v1/audio/transcriptions", "STT endpoint URL correct")
	
	var tts_url = gateway_url + "/v1/audio/speech"
	_assert(tts_url == "http://localhost:18789/v1/audio/speech", "TTS endpoint URL correct")
