## Day/Night cycle — shifts DirectionalLight color temperature over time.
## Warm morning → neutral day → warm evening → dim night. Visual only.
## Also adjusts a skylight mesh color to simulate window brightness.
extends Node

@export var cycle_duration: float = 300.0  # full day in seconds (5 min default)
@export var time_scale: float = 1.0

var current_time: float = 0.0  # 0.0 = midnight, 0.5 = noon

# Color presets for time of day
var color_dawn := Color(1.0, 0.7, 0.4)       # warm orange
var color_morning := Color(1.0, 0.9, 0.75)    # warm white
var color_noon := Color(1.0, 1.0, 0.95)       # neutral white
var color_evening := Color(1.0, 0.75, 0.5)    # warm orange
var color_night := Color(0.3, 0.3, 0.5)       # dim blue

var energy_dawn := 0.6
var energy_morning := 0.8
var energy_noon := 1.0
var energy_evening := 0.6
var energy_night := 0.15

func _ready():
	# Start at morning (0.25 = 6 AM)
	current_time = 0.35

func _process(delta):
	current_time += (delta * time_scale) / cycle_duration
	if current_time >= 1.0:
		current_time -= 1.0
	
	var light = get_node_or_null("/root/Main/DirectionalLight3D")
	if light:
		var color = _get_color_for_time(current_time)
		var energy = _get_energy_for_time(current_time)
		light.light_color = color
		light.light_energy = energy
	
	# Update skylight/window effect on ceiling
	_update_skylight()

func _get_color_for_time(t: float) -> Color:
	# 0.0 = midnight, 0.25 = dawn, 0.35 = morning, 0.5 = noon, 0.7 = evening, 0.85 = night
	if t < 0.2:
		return color_night
	elif t < 0.3:
		return color_night.lerp(color_dawn, (t - 0.2) / 0.1)
	elif t < 0.4:
		return color_dawn.lerp(color_morning, (t - 0.3) / 0.1)
	elif t < 0.6:
		return color_morning.lerp(color_noon, (t - 0.4) / 0.2)
	elif t < 0.7:
		return color_noon.lerp(color_evening, (t - 0.6) / 0.1)
	elif t < 0.8:
		return color_evening.lerp(color_night, (t - 0.7) / 0.1)
	else:
		return color_night

func _get_energy_for_time(t: float) -> float:
	if t < 0.2:
		return energy_night
	elif t < 0.3:
		return lerp(energy_night, energy_dawn, (t - 0.2) / 0.1)
	elif t < 0.4:
		return lerp(energy_dawn, energy_morning, (t - 0.3) / 0.1)
	elif t < 0.6:
		return lerp(energy_morning, energy_noon, (t - 0.4) / 0.2)
	elif t < 0.7:
		return lerp(energy_noon, energy_evening, (t - 0.6) / 0.1)
	elif t < 0.8:
		return lerp(energy_evening, energy_night, (t - 0.7) / 0.1)
	else:
		return energy_night

func _update_skylight():
	var skylight = get_node_or_null("/root/Main/Skylight")
	if not skylight:
		return
	
	var brightness = _get_energy_for_time(current_time)
	var sky_color = _get_color_for_time(current_time)
	
	if skylight is CSGBox3D:
		var mat = skylight.material
		if mat and mat is StandardMaterial3D:
			mat.emission = sky_color
			mat.emission_energy_multiplier = brightness * 0.5

func get_time_of_day_name() -> String:
	if current_time < 0.2:
		return "Night"
	elif current_time < 0.3:
		return "Dawn"
	elif current_time < 0.4:
		return "Morning"
	elif current_time < 0.6:
		return "Noon"
	elif current_time < 0.7:
		return "Evening"
	elif current_time < 0.8:
		return "Dusk"
	else:
		return "Night"
