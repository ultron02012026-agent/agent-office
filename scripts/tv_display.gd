## tv_display.gd — Manages TV/monitor screens in agent offices
## Loads images from URLs and displays them on screen surfaces.
## Agents use [TV_SHOW:url] tags. Ultron has 3 monitors: [SCREEN1:url] [SCREEN2:url] [SCREEN3:url]
extends Node

# Room name → TV node path mapping (other agents have wall TVs)
var room_tvs := {
	"Spinfluencer": ["Room2_TV_Main"],
	"Dexer": ["Room3_TV_Main"],
	"DJ Sam": ["Room4_TV_Main"],
}

# Ultron front desk monitors (screen glow nodes, not the bezels)
var ultron_screens := {
	1: "Ultron_FD_Screen1",
	2: "Ultron_FD_Screen2",
	3: "Ultron_FD_Screen3",
}

var _default_screen_mat: StandardMaterial3D

func _ready():
	_default_screen_mat = StandardMaterial3D.new()
	_default_screen_mat.albedo_color = Color(0.15, 0.15, 0.18, 1)
	_default_screen_mat.emission_enabled = true
	_default_screen_mat.emission = Color(0.1, 0.15, 0.25, 1)
	_default_screen_mat.emission_energy_multiplier = 0.5

func show_image_on_tv(room_name: String, url: String):
	# For non-Ultron rooms, show on their wall TV
	if room_tvs.has(room_name):
		_fetch_and_display(room_tvs[room_name][0], url, room_name)
		return
	# For Ultron, default TV_SHOW goes to center monitor (screen 2)
	if room_name == "Ultron":
		show_on_screen(2, url)
		return
	push_warning("tv_display: no TV for room '%s'" % room_name)

func show_on_screen(screen_num: int, url: String):
	if not ultron_screens.has(screen_num):
		push_warning("tv_display: no screen %d" % screen_num)
		return
	_fetch_and_display(ultron_screens[screen_num], url, "Ultron_Screen%d" % screen_num)

func clear_tv(room_name: String):
	if room_tvs.has(room_name):
		_reset_screen(room_tvs[room_name][0])
	elif room_name == "Ultron":
		# Clear all 3 monitors
		for screen_path in ultron_screens.values():
			_reset_screen(screen_path)

func clear_screen(screen_num: int):
	if ultron_screens.has(screen_num):
		_reset_screen(ultron_screens[screen_num])

func _reset_screen(node_path: String):
	var node = get_node_or_null("/root/Main/" + node_path)
	if node:
		node.material = _default_screen_mat.duplicate()

func _fetch_and_display(node_path: String, url: String, label: String):
	var node = get_node_or_null("/root/Main/" + node_path)
	if not node:
		push_warning("tv_display: node '%s' not found" % node_path)
		return
	var http = HTTPRequest.new()
	http.set_meta("node_path", node_path)
	http.set_meta("label", label)
	add_child(http)
	http.request_completed.connect(_on_image_loaded.bind(http))
	var err = http.request(url)
	if err != OK:
		push_warning("tv_display: request failed for '%s'" % url)
		http.queue_free()

func _on_image_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	var node_path = http.get_meta("node_path")
	var label = http.get_meta("label")
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("tv_display: download failed for '%s' (code %d)" % [label, response_code])
		return
	
	var node = get_node_or_null("/root/Main/" + node_path)
	if not node:
		return
	
	var img = Image.new()
	var err = img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		err = img.load_webp_from_buffer(body)
	if err != OK:
		push_warning("tv_display: could not decode image for '%s'" % label)
		return
	
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.8
	node.material = mat
