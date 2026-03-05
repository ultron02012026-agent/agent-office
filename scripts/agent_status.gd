## Agent status indicator — colored dot above door label showing connection state.
## green = ready, yellow = thinking, red = disconnected.
## Updates based on ChatUI state.
extends Label3D

@export var agent_name: String = ""

enum Status { DISCONNECTED, READY, THINKING }
var current_status: Status = Status.READY

func _ready():
	font_size = 20
	_update_display()

func _process(_delta):
	var new_status = _get_status()
	if new_status != current_status:
		current_status = new_status
		_update_display()

func _get_status() -> Status:
	var chat_ui = get_node_or_null("/root/Main/ChatUI")
	if not chat_ui:
		return Status.DISCONNECTED
	
	# If we're in this agent's room and thinking, show yellow
	if chat_ui.current_room == agent_name and chat_ui.is_thinking:
		return Status.THINKING
	
	# Check if gateway is configured
	if SettingsManager.gateway_url.is_empty():
		return Status.DISCONNECTED
	
	return Status.READY

func _update_display():
	match current_status:
		Status.READY:
			text = "●"
			modulate = Color(0.2, 1, 0.2, 1)
		Status.THINKING:
			text = "●"
			modulate = Color(1, 0.9, 0.2, 1)
		Status.DISCONNECTED:
			text = "●"
			modulate = Color(1, 0.2, 0.2, 1)
