## Command palette — VS Code-style overlay triggered by `/` key.
## Commands: /goto <room>, /status, /clear, /sprint <minutes>
## Teleports player, shows agent status, clears chat, starts sprint timer.
extends CanvasLayer

var is_open: bool = false
var commands_list := ["/goto spinfluencer", "/goto dexer", "/goto djsam", "/goto ultron", "/goto lobby", "/goto entrance", "/status", "/clear", "/sprint 25"]

@onready var panel: PanelContainer
@onready var input_field: LineEdit
@onready var suggestions_label: RichTextLabel
@onready var result_label: Label

# Room teleport positions
var room_positions := {
	"spinfluencer": Vector3(-5, 1, -10),
	"dexer": Vector3(10, 1, -10),
	"djsam": Vector3(-10, 1, 0),
	"ultron": Vector3(5, 1, 5),
	"lobby": Vector3(5, 1, 8),
	"entrance": Vector3(12, 1, 13),
}

func _ready():
	_build_ui()
	visible = false

func _build_ui():
	panel = PanelContainer.new()
	panel.name = "PalettePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -300
	panel.offset_top = 80
	panel.offset_right = 300
	panel.offset_bottom = 320
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "⌘ Command Palette"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	input_field = LineEdit.new()
	input_field.name = "CommandInput"
	input_field.placeholder_text = "Type a command... (e.g. /goto ultron)"
	input_field.text_submitted.connect(_on_command_submitted)
	input_field.text_changed.connect(_on_text_changed)
	vbox.add_child(input_field)
	
	suggestions_label = RichTextLabel.new()
	suggestions_label.name = "Suggestions"
	suggestions_label.bbcode_enabled = true
	suggestions_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	suggestions_label.scroll_following = true
	vbox.add_child(suggestions_label)
	
	result_label = Label.new()
	result_label.name = "Result"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.modulate = Color(0.5, 1, 0.5, 1)
	vbox.add_child(result_label)
	
	_update_suggestions("")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		# Open with `/` when not in chat
		if event.keycode == KEY_SLASH or event.physical_keycode == KEY_SLASH:
			var chat_ui = get_node_or_null("/root/Main/ChatUI")
			var settings = get_node_or_null("/root/Main/SettingsMenu")
			if chat_ui and chat_ui.panel.visible:
				return
			if settings and settings.is_open:
				return
			if not is_open:
				open_palette()
				get_viewport().set_input_as_handled()
		
		# Close with Escape
		if event.keycode == KEY_ESCAPE and is_open:
			close_palette()
			get_viewport().set_input_as_handled()

func open_palette():
	if is_open:
		return
	is_open = true
	visible = true
	input_field.text = "/"
	input_field.caret_column = 1
	result_label.text = ""
	_update_suggestions("/")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	input_field.grab_focus()

func close_palette():
	if not is_open:
		return
	is_open = false
	visible = false
	
	# Restore mouse mode
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if chat_ui and chat_ui.panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_text_changed(text: String):
	_update_suggestions(text)

func _update_suggestions(filter: String):
	if not suggestions_label:
		return
	suggestions_label.text = ""
	var f = filter.to_lower().strip_edges()
	for cmd in commands_list:
		if f.is_empty() or cmd.begins_with(f) or f.begins_with(cmd.split(" ")[0]):
			suggestions_label.text += "[color=gray]" + cmd + "[/color]\n"

func _on_command_submitted(text: String):
	var cmd = text.strip_edges().to_lower()
	result_label.text = execute_command(cmd)
	# Auto-close after command
	await get_tree().create_timer(0.8).timeout
	if is_open:
		close_palette()

func execute_command(cmd: String) -> String:
	if cmd.begins_with("/goto "):
		var target = cmd.substr(6).strip_edges()
		return _cmd_goto(target)
	elif cmd == "/status":
		return _cmd_status()
	elif cmd == "/clear":
		return _cmd_clear()
	elif cmd.begins_with("/sprint "):
		var minutes_str = cmd.substr(8).strip_edges()
		if minutes_str.is_valid_int():
			return _cmd_sprint(minutes_str.to_int())
		return "❌ Usage: /sprint <minutes>"
	else:
		return "❌ Unknown command: " + cmd

func _cmd_goto(target: String) -> String:
	if not room_positions.has(target):
		return "❌ Unknown room: " + target
	
	var player = get_node_or_null("/root/Main/Player")
	if not player:
		return "❌ Player not found"
	
	# Exit current room first
	if not player.current_room.is_empty():
		player.exit_room(player.current_room)
	
	player.global_position = room_positions[target]
	return "✅ Teleported to " + target

func _cmd_status() -> String:
	var status_text = "Agent Status:\n"
	var agents = ["Ultron", "Spinfluencer", "Dexer", "DJ Sam"]
	for agent in agents:
		var dot = get_node_or_null("/root/Main/" + agent.replace(" ", "") + "_StatusDot") 
		if not dot:
			# Try Room1-4 naming
			pass
		var icon = "🟢"
		if SettingsManager.gateway_url.is_empty():
			icon = "🔴"
		status_text += icon + " " + agent + "\n"
	return status_text

func _cmd_clear() -> String:
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if chat_ui and not chat_ui.current_room.is_empty():
		chat_ui.clear_chat()
		return "✅ Chat cleared"
	return "❌ Not in a room"

func _cmd_sprint(minutes: int) -> String:
	var sprint_timer = get_node_or_null("/root/Main/SprintTimer")
	if sprint_timer and sprint_timer.has_method("start_sprint"):
		sprint_timer.start_sprint(minutes)
		return "✅ Sprint started: " + str(minutes) + " min"
	return "❌ Sprint timer not available"
