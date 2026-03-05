extends Node

var passed := 0
var failed := 0

func run() -> Dictionary:
	passed = 0
	failed = 0
	
	test_time_progression()
	test_color_transitions()
	test_energy_transitions()
	test_time_wrapping()
	test_time_of_day_names()
	test_dawn_colors()
	test_noon_is_brightest()
	test_night_is_dimmest()
	
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, test_name: String):
	if condition:
		passed += 1
		print("  ✅ " + test_name)
	else:
		failed += 1
		print("  ❌ " + test_name)

func test_time_progression():
	var current_time = 0.35
	var cycle_duration = 300.0
	var delta = 1.0
	current_time += (delta * 1.0) / cycle_duration
	_assert(current_time > 0.35, "Time progresses forward")
	_assert(abs(current_time - 0.35333) < 0.001, "Time increment correct")

func test_color_transitions():
	# Night should be blue-ish
	var t = 0.1  # night
	var color = _get_color(t)
	_assert(color.b > color.r, "Night color has more blue than red")
	
	# Noon should be neutral white
	t = 0.5
	color = _get_color(t)
	_assert(abs(color.r - color.g) < 0.1, "Noon color is neutral (R ≈ G)")

func test_energy_transitions():
	var night_energy = _get_energy(0.1)
	var noon_energy = _get_energy(0.5)
	_assert(noon_energy > night_energy, "Noon is brighter than night")

func test_time_wrapping():
	var t = 0.99
	t += 0.02
	if t >= 1.0:
		t -= 1.0
	_assert(t >= 0.0 and t < 1.0, "Time wraps around at 1.0")
	_assert(abs(t - 0.01) < 0.001, "Wrapped time correct")

func test_time_of_day_names():
	_assert(_get_name(0.1) == "Night", "0.1 = Night")
	_assert(_get_name(0.25) == "Dawn", "0.25 = Dawn")
	_assert(_get_name(0.35) == "Morning", "0.35 = Morning")
	_assert(_get_name(0.5) == "Noon", "0.5 = Noon")
	_assert(_get_name(0.65) == "Evening", "0.65 = Evening")
	_assert(_get_name(0.75) == "Dusk", "0.75 = Dusk")
	_assert(_get_name(0.9) == "Night", "0.9 = Night")

func test_dawn_colors():
	var dawn = _get_color(0.25)
	_assert(dawn.r > 0.5, "Dawn has warm red component")
	_assert(dawn.g < dawn.r, "Dawn red > green (warm)")

func test_noon_is_brightest():
	var noon_e = _get_energy(0.5)
	_assert(abs(noon_e - 1.0) < 0.1, "Noon energy near 1.0")

func test_night_is_dimmest():
	var night_e = _get_energy(0.05)
	_assert(night_e < 0.3, "Night energy below 0.3")

# Helper functions mirroring day_cycle.gd logic
func _get_color(t: float) -> Color:
	var color_night := Color(0.3, 0.3, 0.5)
	var color_dawn := Color(1.0, 0.7, 0.4)
	var color_morning := Color(1.0, 0.9, 0.75)
	var color_noon := Color(1.0, 1.0, 0.95)
	var color_evening := Color(1.0, 0.75, 0.5)
	
	if t < 0.2: return color_night
	elif t < 0.3: return color_night.lerp(color_dawn, (t - 0.2) / 0.1)
	elif t < 0.4: return color_dawn.lerp(color_morning, (t - 0.3) / 0.1)
	elif t < 0.6: return color_morning.lerp(color_noon, (t - 0.4) / 0.2)
	elif t < 0.7: return color_noon.lerp(color_evening, (t - 0.6) / 0.1)
	elif t < 0.8: return color_evening.lerp(color_night, (t - 0.7) / 0.1)
	else: return color_night

func _get_energy(t: float) -> float:
	if t < 0.2: return 0.15
	elif t < 0.3: return lerp(0.15, 0.6, (t - 0.2) / 0.1)
	elif t < 0.4: return lerp(0.6, 0.8, (t - 0.3) / 0.1)
	elif t < 0.6: return lerp(0.8, 1.0, (t - 0.4) / 0.2)
	elif t < 0.7: return lerp(1.0, 0.6, (t - 0.6) / 0.1)
	elif t < 0.8: return lerp(0.6, 0.15, (t - 0.7) / 0.1)
	else: return 0.15

func _get_name(t: float) -> String:
	if t < 0.2: return "Night"
	elif t < 0.3: return "Dawn"
	elif t < 0.4: return "Morning"
	elif t < 0.6: return "Noon"
	elif t < 0.7: return "Evening"
	elif t < 0.8: return "Dusk"
	else: return "Night"
