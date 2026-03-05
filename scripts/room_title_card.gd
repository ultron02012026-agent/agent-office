## Room title card — shows agent name + role center-screen on room entry, fades after 2s.
## Called by player.gd on enter_room/exit_room.
extends CanvasLayer

@onready var label: Label
@onready var sub_label: Label
var fade_timer: float = 0.0
var is_showing: bool = false

func _ready():
	_build_ui()

func _build_ui():
	var container = CenterContainer.new()
	container.name = "TitleContainer"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left = -400
	container.offset_top = -100
	container.offset_right = 400
	container.offset_bottom = 100
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(vbox)
	
	label = Label.new()
	label.name = "TitleLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)
	
	sub_label = Label.new()
	sub_label.name = "SubLabel"
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 22)
	sub_label.modulate = Color(0.7, 0.7, 0.75, 1)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_label)
	
	_hide_card()

func show_room(room_name: String):
	var role = "AI Agent"
	if SettingsManager.agent_configs.has(room_name):
		var cfg = SettingsManager.agent_configs[room_name]
		role = cfg.get("agent_name", room_name) + " — AI Agent"
	
	label.text = room_name + "'s Office"
	sub_label.text = role
	label.modulate = Color(1, 1, 1, 1)
	sub_label.modulate = Color(0.7, 0.7, 0.75, 1)
	label.visible = true
	sub_label.visible = true
	is_showing = true
	fade_timer = 2.0
	
	# Audio cue stub
	print("[AudioCue] Entering room: " + room_name)

func show_exit():
	print("[AudioCue] Exiting room")

func _hide_card():
	if label:
		label.visible = false
	if sub_label:
		sub_label.visible = false
	is_showing = false

func _process(delta):
	if not is_showing:
		return
	fade_timer -= delta
	if fade_timer <= 0:
		_hide_card()
	elif fade_timer < 0.5:
		var alpha = fade_timer / 0.5
		label.modulate.a = alpha
		sub_label.modulate.a = alpha * 0.75
