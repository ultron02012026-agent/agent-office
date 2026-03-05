## Screenshot mode — F12 captures screenshot, hides HUD temporarily.
## Saves to user://screenshots/ with timestamp. Shows "📸 Saved!" indicator.
extends Node

var is_capturing: bool = false
var saved_indicator_timer: float = 0.0
var saved_label: Label

func _ready():
	# Create saved indicator label
	saved_label = Label.new()
	saved_label.name = "ScreenshotSaved"
	saved_label.text = "📸 Saved!"
	saved_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saved_label.add_theme_font_size_override("font_size", 28)
	saved_label.modulate = Color(0.2, 1, 0.4, 0)
	saved_label.set_anchors_preset(Control.PRESET_CENTER)
	saved_label.offset_top = -200
	saved_label.offset_bottom = -160
	saved_label.offset_left = -150
	saved_label.offset_right = 150
	
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		hud.add_child(saved_label)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		take_screenshot()
		get_viewport().set_input_as_handled()

func _process(delta):
	if saved_indicator_timer > 0:
		saved_indicator_timer -= delta
		if saved_indicator_timer > 1.0:
			saved_label.modulate.a = 1.0
		else:
			saved_label.modulate.a = saved_indicator_timer
		if saved_indicator_timer <= 0:
			saved_label.modulate.a = 0

func take_screenshot():
	if is_capturing:
		return
	is_capturing = true
	
	# Hide HUD elements
	var hud = get_node_or_null("/root/Main/HUD")
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	var hud_was_visible = true
	var chat_was_visible = false
	
	if hud:
		hud_was_visible = hud.visible
		hud.visible = false
	if chat_ui:
		chat_was_visible = chat_ui.visible
		chat_ui.visible = false
	
	# Wait one frame for render
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Capture
	var image = get_viewport().get_texture().get_image()
	
	# Restore HUD
	if hud:
		hud.visible = hud_was_visible
	if chat_ui:
		chat_ui.visible = chat_was_visible
	
	# Save
	_ensure_dir()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path = "user://screenshots/screenshot_" + timestamp + ".png"
	var err = image.save_png(path)
	
	is_capturing = false
	
	if err == OK:
		print("[Screenshot] Saved: " + path)
		_show_saved_indicator()
		return path
	else:
		print("[Screenshot] Error saving: " + str(err))
		return ""

func _ensure_dir():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")

func _show_saved_indicator():
	saved_indicator_timer = 2.0
