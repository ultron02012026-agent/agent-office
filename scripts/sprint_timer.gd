## Sprint timer — pomodoro-style countdown HUD element.
## Activated via command palette: /sprint <minutes>
## Shows progress bar at top of screen, flashes when done.
extends Control

var is_active: bool = false
var total_seconds: float = 0.0
var remaining_seconds: float = 0.0
var flash_timer: float = 0.0
var flash_duration: float = 3.0
var is_flashing: bool = false

var progress_bar: ColorRect
var progress_bg: ColorRect
var time_label: Label
var flash_overlay: ColorRect

func _ready():
	_build_ui()
	visible = false

func _build_ui():
	# Background bar (full width at top)
	progress_bg = ColorRect.new()
	progress_bg.name = "ProgressBG"
	progress_bg.color = Color(0.15, 0.15, 0.2, 0.7)
	progress_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress_bg.offset_bottom = 8
	add_child(progress_bg)
	
	# Progress fill
	progress_bar = ColorRect.new()
	progress_bar.name = "ProgressFill"
	progress_bar.color = Color(0.2, 0.8, 0.4, 0.9)
	progress_bar.anchor_left = 0
	progress_bar.anchor_top = 0
	progress_bar.anchor_right = 1
	progress_bar.anchor_bottom = 0
	progress_bar.offset_bottom = 8
	add_child(progress_bar)
	
	# Time remaining label
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	time_label.offset_top = 12
	time_label.offset_left = -100
	time_label.offset_right = 100
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.modulate = Color(0.9, 0.9, 0.95, 1)
	add_child(time_label)
	
	# Flash overlay (full screen)
	flash_overlay = ColorRect.new()
	flash_overlay.name = "FlashOverlay"
	flash_overlay.color = Color(1, 0.8, 0.2, 0)
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)

func start_sprint(minutes: int):
	total_seconds = minutes * 60.0
	remaining_seconds = total_seconds
	is_active = true
	is_flashing = false
	visible = true
	progress_bar.color = Color(0.2, 0.8, 0.4, 0.9)
	print("[Sprint] Started: " + str(minutes) + " minutes")

func stop_sprint():
	is_active = false
	is_flashing = false
	visible = false

func _process(delta):
	if not is_active and not is_flashing:
		return
	
	if is_active:
		remaining_seconds -= delta
		
		# Update progress bar width
		var progress = 1.0 - (remaining_seconds / total_seconds) if total_seconds > 0 else 0.0
		progress_bar.anchor_right = clampf(1.0 - progress, 0, 1)
		
		# Color shift: green → yellow → red
		if remaining_seconds < total_seconds * 0.2:
			progress_bar.color = Color(1, 0.3, 0.2, 0.9)
		elif remaining_seconds < total_seconds * 0.5:
			progress_bar.color = Color(1, 0.8, 0.2, 0.9)
		
		# Update label
		var mins = int(remaining_seconds) / 60
		var secs = int(remaining_seconds) % 60
		time_label.text = "🏃 Sprint: %02d:%02d" % [mins, secs]
		
		if remaining_seconds <= 0:
			_sprint_complete()
	
	if is_flashing:
		flash_timer -= delta
		var alpha = sin(flash_timer * 8) * 0.3
		flash_overlay.color.a = max(0, alpha)
		if flash_timer <= 0:
			is_flashing = false
			flash_overlay.color.a = 0
			visible = false

func _sprint_complete():
	is_active = false
	is_flashing = true
	flash_timer = flash_duration
	time_label.text = "✅ Sprint Complete!"
	
	# Play sprint alarm sound
	var sound = get_node_or_null("/root/Main/SprintAlarmSound")
	if sound and sound.stream:
		sound.play()
	
	print("[Sprint] Complete!")

func get_remaining() -> float:
	return remaining_seconds if is_active else 0.0

func get_progress() -> float:
	if total_seconds <= 0:
		return 0.0
	return 1.0 - (remaining_seconds / total_seconds)
