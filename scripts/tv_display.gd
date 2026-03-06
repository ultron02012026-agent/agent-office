## tv_display.gd — Manages TV screens in agent offices
## Loads images from URLs and displays them on TV mesh surfaces.
## Each room's main TV can show images via [TV_SHOW:url] tags from agents.
extends Node

# Room name → TV node path mapping
var room_tvs := {
	"Spinfluencer": "Room2_TV_Main",
	"Dexer": "Room3_TV_Main",
	"DJ Sam": "Room4_TV_Main",
}

# Track active requests per room
var _pending: Dictionary = {}

func show_image_on_tv(room_name: String, url: String):
	if not room_tvs.has(room_name):
		push_warning("tv_display: no TV for room '%s'" % room_name)
		return
	
	var tv_node = get_node_or_null("/root/Main/" + room_tvs[room_name])
	if not tv_node:
		push_warning("tv_display: TV node not found for '%s'" % room_name)
		return
	
	# Create HTTP request to fetch the image
	var http = HTTPRequest.new()
	http.set_meta("room_name", room_name)
	http.set_meta("tv_node_path", room_tvs[room_name])
	add_child(http)
	http.request_completed.connect(_on_image_loaded.bind(http))
	var err = http.request(url)
	if err != OK:
		push_warning("tv_display: failed to request image from '%s'" % url)
		http.queue_free()

func clear_tv(room_name: String):
	if not room_tvs.has(room_name):
		return
	var tv_node = get_node_or_null("/root/Main/" + room_tvs[room_name])
	if not tv_node:
		return
	# Reset to default screen material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.15, 0.25, 1)
	mat.emission_energy_multiplier = 0.5
	tv_node.material = mat

func _on_image_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	var room_name = http.get_meta("room_name")
	var tv_path = http.get_meta("tv_node_path")
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("tv_display: image download failed for '%s' (code %d)" % [room_name, response_code])
		return
	
	var tv_node = get_node_or_null("/root/Main/" + tv_path)
	if not tv_node:
		return
	
	# Try to load the image
	var img = Image.new()
	var err = img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		err = img.load_webp_from_buffer(body)
	if err != OK:
		push_warning("tv_display: could not decode image for '%s'" % room_name)
		return
	
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.8
	tv_node.material = mat
