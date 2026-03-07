## Welcome overlay — shown on game start, dismisses on any keypress.
## Captures mouse after dismissal. Blocks player input while visible.
extends CanvasLayer

var is_showing: bool = true

@onready var panel: ColorRect

func _ready():
	_build_ui()

func _build_ui():
	panel = ColorRect.new()
	panel.name = "Overlay"
	panel.color = Color(0.05, 0.05, 0.1, 0.92)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_top = -200
	vbox.offset_right = 300
	vbox.offset_bottom = 200
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Welcome to Agent Office"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 30
	vbox.add_child(spacer)
	
	var lines = [
		"Arrow keys to move, Mouse to look",
		"Walk into an office to start chatting",
		"Esc = Settings",
	]
	for line in lines:
		var lbl = Label.new()
		lbl.text = line
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.modulate = Color(0.8, 0.8, 0.85, 1)
		vbox.add_child(lbl)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 40
	vbox.add_child(spacer2)
	
	var prompt = Label.new()
	prompt.name = "PressAnyKey"
	prompt.text = "Press any key to begin"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.modulate = Color(0.4, 0.8, 1, 1)
	vbox.add_child(prompt)
	
	# Prevent mouse capture while overlay is up
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	if not is_showing:
		return
	if event is InputEventKey and event.pressed:
		dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		dismiss()
		get_viewport().set_input_as_handled()

func dismiss():
	if not is_showing:
		return
	is_showing = false
	panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
