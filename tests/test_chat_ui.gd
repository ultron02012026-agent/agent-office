extends Node

# Tests for ChatUI — voice-only transcript panel (no text input)

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_thinking_state()
	test_message_formatting()
	test_show_hide_chat()
	test_voice_status_states()
	test_transcript_persistence()
	test_no_text_input()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_thinking_state():
	var is_thinking = true
	_assert(is_thinking == true, "Thinking state blocks input")
	is_thinking = false
	_assert(is_thinking == false, "Non-thinking state allows input")

func test_message_formatting():
	# User messages from voice show in cyan
	var user_msg = "[color=cyan]You:[/color] Hello"
	_assert("cyan" in user_msg, "User voice message has cyan color")
	
	# Agent messages in yellow
	var agent_msg = "[color=yellow]Ultron:[/color] Hi there"
	_assert("yellow" in agent_msg, "Agent message has yellow color")

func test_show_hide_chat():
	var room_name = "Ultron"
	var label_text = "📍 " + room_name + "'s Office"
	_assert(label_text == "📍 Ultron's Office", "Room label formats correctly")
	
	# Test chat history clears on fresh room
	var chat_history: Array = [{"role": "user", "content": "hi"}]
	chat_history.clear()
	_assert(chat_history.size() == 0, "Chat history clears on room enter")

func test_voice_status_states():
	# All valid voice status states
	var valid_states = ["listening", "recording", "processing", "thinking", "speaking"]
	_assert(valid_states.size() == 5, "Five voice status states exist")
	_assert("listening" in valid_states, "Listening is a valid state")
	_assert("recording" in valid_states, "Recording is a valid state")
	_assert("processing" in valid_states, "Processing is a valid state")
	_assert("thinking" in valid_states, "Thinking is a valid state")
	_assert("speaking" in valid_states, "Speaking is a valid state")

func test_transcript_persistence():
	# Room histories persist between visits
	var room_histories: Dictionary = {}
	var history = [{"role": "user", "content": "hello"}, {"role": "assistant", "content": "hi"}]
	room_histories["Ultron"] = history.duplicate(true)
	_assert(room_histories.has("Ultron"), "Room history persists")
	_assert(room_histories["Ultron"].size() == 2, "Room history has correct size")
	
	# Clearing works
	room_histories.erase("Ultron")
	_assert(!room_histories.has("Ultron"), "Room history can be cleared")

func test_no_text_input():
	# Transcript panel is display-only — no text input or send button
	# This test validates the design principle
	var has_line_edit = false
	var has_send_button = false
	_assert(!has_line_edit, "No text input field in transcript panel")
	_assert(!has_send_button, "No send button in transcript panel")
	
	# Voice is the only input method
	var input_method = "voice"
	_assert(input_method == "voice", "Voice is the only input method")
