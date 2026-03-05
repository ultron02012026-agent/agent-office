## Debug overlay — F3 toggles performance/debug info display.
## Shows FPS, player position, current room, active connections, memory usage.
extends Control

var is_visible: bool = false
var debug_label: RichTextLabel
var update_timer: float = 0.0
var update_interval: float = 0.25  # update 4x per second

func _ready():
	_build_ui()
	visible = false

func _build_ui():
	var panel = PanelContainer.new()
	panel.name = "DebugPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 16
	panel.offset_top = 80
	panel.offset_right = 320
	panel.offset_bottom = 280
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.border_color = Color(0.3, 1, 0.3, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	debug_label = RichTextLabel.new()
	debug_label.name = "DebugText"
	debug_label.bbcode_enabled = true
	debug_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_label.scroll_active = false
	panel.add_child(debug_label)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle_overlay()
		get_viewport().set_input_as_handled()

func toggle_overlay():
	is_visible = !is_visible
	visible = is_visible

func _process(delta):
	if not is_visible:
		return
	
	update_timer += delta
	if update_timer < update_interval:
		return
	update_timer = 0.0
	
	_update_debug_info()

func _update_debug_info():
	var info = "[color=lime]DEBUG OVERLAY[/color]\n"
	info += "[color=gray]─────────────────[/color]\n"
	
	# FPS
	var fps = Engine.get_frames_per_second()
	var fps_color = "lime" if fps >= 55 else ("yellow" if fps >= 30 else "red")
	info += "[color=" + fps_color + "]FPS: " + str(fps) + "[/color]\n"
	
	# Player position
	var player = get_node_or_null("/root/Main/Player")
	if player:
		var pos = player.global_position
		info += "Pos: (%.1f, %.1f, %.1f)\n" % [pos.x, pos.y, pos.z]
		info += "Room: " + (player.current_room if not player.current_room.is_empty() else "None") + "\n"
	
	# Connection
	info += "Gateway: " + ("✅" if not SettingsManager.gateway_url.is_empty() else "❌") + "\n"
	
	# Memory
	var mem = OS.get_static_memory_usage()
	info += "Memory: %.1f MB\n" % (mem / 1048576.0)
	
	# Day cycle
	var day_cycle = get_node_or_null("/root/Main/DayCycle")
	if day_cycle:
		info += "Time: " + day_cycle.get_time_of_day_name() + " (%.2f)\n" % day_cycle.current_time
	
	# Active visits
	var social = get_node_or_null("/root/Main/AgentSocial")
	if social:
		var status = social.get_visit_status()
		if status.is_visiting:
			info += "Visit: " + status.visitor + " → " + status.target + "\n"
	
	# Sprint
	var sprint = get_node_or_null("/root/Main/SprintTimer")
	if sprint and sprint.is_active:
		var mins = int(sprint.remaining_seconds) / 60
		var secs = int(sprint.remaining_seconds) % 60
		info += "Sprint: %02d:%02d\n" % [mins, secs]
	
	debug_label.text = info

func get_debug_data() -> Dictionary:
	var data := {}
	data["fps"] = Engine.get_frames_per_second()
	data["memory_mb"] = OS.get_static_memory_usage() / 1048576.0
	var player = get_node_or_null("/root/Main/Player")
	if player:
		data["player_pos"] = player.global_position
		data["current_room"] = player.current_room
	data["gateway_configured"] = not SettingsManager.gateway_url.is_empty()
	return data
