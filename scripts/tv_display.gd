## tv_display.gd — Manages TV/monitor screens in agent offices
## Loads images from URLs and displays them on screen surfaces.
## All agents use [TV_SHOW:url] tags. Ultron has one big monitor.
extends Node

# Room name → TV node path mapping (other agents have wall TVs)
var room_tvs := {
	"Spinfluencer": ["Room2_TV_Main"],
	"Dexer": ["Room3_TV_Main"],
	"DJ Sam": ["Room4_TV_Main"],
}

# Ultron front desk — single big monitor
var ultron_screen := "Ultron_FD_Screen2"
# Legacy compat (all map to the same screen)
var ultron_screens := {
	1: "Ultron_FD_Screen2",
	2: "Ultron_FD_Screen2",
	3: "Ultron_FD_Screen2",
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
	# For Ultron, show on the single monitor
	if room_name == "Ultron":
		_fetch_and_display(ultron_screen, url, "Ultron_Screen")
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
		_reset_screen(ultron_screen)

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
	http.max_redirects = 8
	add_child(http)
	http.request_completed.connect(_on_image_loaded.bind(http))
	var headers = ["User-Agent: AgentOffice/1.0"]
	var err = http.request(url, headers)
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
	
	# Detect format from response headers or body magic bytes
	var img = Image.new()
	var err = OK
	# Check JPEG magic bytes (FF D8 FF)
	if body.size() >= 3 and body[0] == 0xFF and body[1] == 0xD8 and body[2] == 0xFF:
		err = img.load_jpg_from_buffer(body)
	# Check PNG magic bytes (89 50 4E 47)
	elif body.size() >= 4 and body[0] == 0x89 and body[1] == 0x50 and body[2] == 0x4E and body[3] == 0x47:
		err = img.load_png_from_buffer(body)
	# Check WebP magic bytes (52 49 46 46 ... 57 45 42 50)
	elif body.size() >= 12 and body[0] == 0x52 and body[1] == 0x49 and body[8] == 0x57 and body[9] == 0x45:
		err = img.load_webp_from_buffer(body)
	else:
		# Unknown format — try all
		err = img.load_png_from_buffer(body)
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
