extends CanvasLayer

var is_open: bool = false
var current_tab: int = 0
var tab_names: Array = ["Audio", "Connection", "Controls", "Display", "Agents"]

@onready var panel: PanelContainer
@onready var tab_container: TabContainer

func _ready():
	_build_ui()
	visible = false

func _build_ui():
	# Main panel
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -250
	panel.offset_right = 350
	panel.offset_bottom = 250
	add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	panel.add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚙️ Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Tab container
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tab_container)
	
	_build_audio_tab()
	_build_connection_tab()
	_build_controls_tab()
	_build_display_tab()
	_build_agents_tab()
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close (Esc)"
	close_btn.pressed.connect(close_menu)
	main_vbox.add_child(close_btn)

func _build_audio_tab():
	var vbox = VBoxContainer.new()
	vbox.name = "Audio"
	tab_container.add_child(vbox)
	
	# Master volume
	_add_slider(vbox, "Master Volume", SettingsManager.master_volume, func(val):
		SettingsManager.master_volume = val
		AudioServer.set_bus_volume_db(0, linear_to_db(val))
	)
	
	# Voice volume
	_add_slider(vbox, "Voice Volume", SettingsManager.voice_volume, func(val):
		SettingsManager.voice_volume = val
	)
	
	# Mic toggle
	var mic_check = CheckBox.new()
	mic_check.text = "Microphone Enabled"
	mic_check.button_pressed = SettingsManager.mic_enabled
	mic_check.toggled.connect(func(on): SettingsManager.mic_enabled = on)
	vbox.add_child(mic_check)
	
	# TTS Voice
	var voice_hbox = HBoxContainer.new()
	vbox.add_child(voice_hbox)
	var voice_label = Label.new()
	voice_label.text = "TTS Voice: "
	voice_hbox.add_child(voice_label)
	var voice_select = OptionButton.new()
	for v in ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]:
		voice_select.add_item(v)
	var idx = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"].find(SettingsManager.tts_voice)
	if idx >= 0:
		voice_select.selected = idx
	voice_select.item_selected.connect(func(i):
		SettingsManager.tts_voice = voice_select.get_item_text(i)
	)
	voice_hbox.add_child(voice_select)

func _build_connection_tab():
	var vbox = VBoxContainer.new()
	vbox.name = "Connection"
	tab_container.add_child(vbox)
	
	var url_label = Label.new()
	url_label.text = "OpenClaw Gateway URL:"
	vbox.add_child(url_label)
	
	var url_input = LineEdit.new()
	url_input.name = "GatewayURL"
	url_input.text = SettingsManager.gateway_url
	url_input.text_changed.connect(func(t): SettingsManager.gateway_url = t)
	vbox.add_child(url_input)
	
	var status_label = Label.new()
	status_label.name = "ConnectionStatus"
	status_label.text = "Status: Unknown"
	status_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(status_label)
	
	var test_btn = Button.new()
	test_btn.text = "Test Connection"
	test_btn.pressed.connect(func():
		status_label.text = "Status: Testing..."
		var http = HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(func(_r, code, _h, _b):
			if code == 200:
				status_label.text = "Status: ✅ Connected"
				status_label.modulate = Color(0.3, 1, 0.3)
			else:
				status_label.text = "Status: ❌ Error (" + str(code) + ")"
				status_label.modulate = Color(1, 0.3, 0.3)
			http.queue_free()
		)
		http.request(SettingsManager.gateway_url + "/v1/models")
	)
	vbox.add_child(test_btn)

func _build_controls_tab():
	var vbox = VBoxContainer.new()
	vbox.name = "Controls"
	tab_container.add_child(vbox)
	
	# Mouse sensitivity
	_add_slider(vbox, "Mouse Sensitivity", SettingsManager.mouse_sensitivity / 0.01, func(val):
		SettingsManager.mouse_sensitivity = val * 0.01
	, 0.1, 1.0, 0.01)
	
	# Invert Y
	var invert_check = CheckBox.new()
	invert_check.text = "Invert Y Axis"
	invert_check.button_pressed = SettingsManager.invert_y
	invert_check.toggled.connect(func(on): SettingsManager.invert_y = on)
	vbox.add_child(invert_check)
	
	# Push to talk key
	var ptt_hbox = HBoxContainer.new()
	vbox.add_child(ptt_hbox)
	var ptt_label = Label.new()
	ptt_label.text = "Push-to-Talk Key: "
	ptt_hbox.add_child(ptt_label)
	var ptt_btn = Button.new()
	ptt_btn.name = "PTTButton"
	ptt_btn.text = SettingsManager.push_to_talk_key
	var waiting_for_key = false
	ptt_btn.pressed.connect(func():
		ptt_btn.text = "Press a key..."
		waiting_for_key = true
	)
	ptt_hbox.add_child(ptt_btn)

func _build_display_tab():
	var vbox = VBoxContainer.new()
	vbox.name = "Display"
	tab_container.add_child(vbox)
	
	# Fullscreen
	var fs_check = CheckBox.new()
	fs_check.text = "Fullscreen"
	fs_check.button_pressed = SettingsManager.fullscreen
	fs_check.toggled.connect(func(on):
		SettingsManager.fullscreen = on
		if on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	vbox.add_child(fs_check)
	
	# FOV
	_add_slider(vbox, "FOV", (SettingsManager.fov - 60.0) / 60.0, func(val):
		SettingsManager.fov = 60.0 + val * 60.0
		var cam = get_viewport().get_camera_3d()
		if cam:
			cam.fov = SettingsManager.fov
	, 0.0, 1.0, 0.01)
	
	# VSync
	var vsync_check = CheckBox.new()
	vsync_check.text = "VSync"
	vsync_check.button_pressed = SettingsManager.vsync
	vsync_check.toggled.connect(func(on):
		SettingsManager.vsync = on
		if on:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	)
	vbox.add_child(vsync_check)

func _build_agents_tab():
	var scroll = ScrollContainer.new()
	scroll.name = "Agents"
	tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	for room_name in SettingsManager.agent_configs:
		var cfg = SettingsManager.agent_configs[room_name]
		
		var room_vbox = VBoxContainer.new()
		vbox.add_child(room_vbox)
		
		var name_hbox = HBoxContainer.new()
		room_vbox.add_child(name_hbox)
		
		var room_label = Label.new()
		room_label.text = room_name + " → "
		name_hbox.add_child(room_label)
		
		var name_edit = LineEdit.new()
		name_edit.text = cfg["agent_name"]
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rn = room_name  # capture
		name_edit.text_changed.connect(func(t):
			SettingsManager.agent_configs[rn]["agent_name"] = t
		)
		name_hbox.add_child(name_edit)
		
		var prompt_label = Label.new()
		prompt_label.text = "System prompt preview:"
		prompt_label.modulate = Color(0.7, 0.7, 0.7)
		room_vbox.add_child(prompt_label)
		
		var prompt_preview = Label.new()
		prompt_preview.text = cfg["system_prompt"].substr(0, 80) + "..."
		prompt_preview.autowrap_mode = TextServer.AUTOWRAP_WORD
		room_vbox.add_child(prompt_preview)
		
		var sep = HSeparator.new()
		room_vbox.add_child(sep)

func _add_slider(parent: Control, label_text: String, initial: float, callback: Callable, min_val: float = 0.0, max_val: float = 1.0, step: float = 0.01):
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text + ": "
	label.custom_minimum_size.x = 150
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	var val_label = Label.new()
	val_label.text = "%.2f" % initial
	val_label.custom_minimum_size.x = 40
	hbox.add_child(val_label)
	
	slider.value_changed.connect(func(v): val_label.text = "%.2f" % v)

func open_menu():
	if is_open:
		return
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func close_menu():
	if not is_open:
		return
	is_open = false
	visible = false
	SettingsManager.save_settings()
	get_tree().paused = false
	
	# Restore mouse mode based on chat state
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if chat_ui and chat_ui.panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and is_open:
		close_menu()
		get_viewport().set_input_as_handled()
