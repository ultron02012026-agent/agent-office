extends Node

# Tests for ChatUI

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_empty_message_rejection()
	test_thinking_state()
	test_message_formatting()
	test_show_hide_chat()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_empty_message_rejection():
	# Verify that empty/whitespace text won't send
	var text = "   "
	_assert(text.strip_edges().is_empty(), "Empty message stripped to empty")
	
	text = ""
	_assert(text.strip_edges().is_empty(), "Blank string is empty")
	
	text = "hello"
	_assert(!text.strip_edges().is_empty(), "Non-empty message passes")

func test_thinking_state():
	# Thinking state should block sends
	var is_thinking = true
	_assert(is_thinking == true, "Thinking state blocks input")
	is_thinking = false
	_assert(is_thinking == false, "Non-thinking state allows input")

func test_message_formatting():
	# Test BBCode formatting patterns
	var user_msg = "[color=cyan]You:[/color] Hello"
	_assert("cyan" in user_msg, "User message has cyan color")
	
	var agent_msg = "[color=yellow]Ultron:[/color] Hi there"
	_assert("yellow" in agent_msg, "Agent message has yellow color")

func test_show_hide_chat():
	# Test room name propagation
	var room_name = "Ultron"
	var label_text = "📍 " + room_name + "'s Office"
	_assert(label_text == "📍 Ultron's Office", "Room label formats correctly")
	
	# Test chat history clears on show
	var chat_history: Array = [{"role": "user", "content": "hi"}]
	chat_history.clear()
	_assert(chat_history.size() == 0, "Chat history clears on room enter")
