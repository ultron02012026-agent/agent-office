## EnvironmentManager — hot-swap skybox, ground, ambient, fog, tonemap presets.
extends Node

var presets := {
	"grasslands_sunset": {
		"hdri": "res://assets/environment/grasslands_sunset_2k.hdr",
		"ground_color": Color(0.2, 0.45, 0.12, 1),
		"ground_metallic": 0.0,
		"ground_roughness": 0.95,
		"ambient_color": Color(0.7, 0.75, 0.85, 1),
		"ambient_energy": 0.8,
		"tonemap_mode": 3,
		"tonemap_white": 6.0,
	},
	"neon_city": {
		"hdri": "res://assets/environment/skybox.hdr",
		"ground_color": Color(0.08, 0.08, 0.1, 1),
		"ground_metallic": 0.3,
		"ground_roughness": 0.4,
		"ambient_color": Color(0.4, 0.4, 0.6, 1),
		"ambient_energy": 0.5,
		"tonemap_mode": 3,
		"tonemap_white": 4.0,
	},
}

var current_preset: String = "grasslands_sunset"

func switch_env(preset_name: String) -> bool:
	if not presets.has(preset_name):
		print("[EnvironmentManager] Unknown preset: ", preset_name)
		return false

	var p = presets[preset_name]
	current_preset = preset_name
	print("[EnvironmentManager] Switching to: ", preset_name)

	# Skybox
	var world_env = get_node_or_null("/root/Main/WorldEnvironment")
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		var tex = load(p["hdri"])
		if tex and env.sky and env.sky.sky_material:
			env.sky.sky_material.panorama = tex

		# Ambient
		env.ambient_light_color = p["ambient_color"]
		env.ambient_light_energy = p["ambient_energy"]

		# Tonemap
		env.tonemap_mode = p["tonemap_mode"]
		env.tonemap_white = p["tonemap_white"]

		# Fog (optional)
		if p.has("fog_enabled"):
			env.fog_enabled = p["fog_enabled"]
		if p.has("fog_density"):
			env.fog_density = p["fog_density"]
		if p.has("fog_color"):
			env.fog_light_color = p["fog_color"]

	# Ground material
	var ground = get_node_or_null("/root/Main/OutdoorGround")
	if ground and ground.material:
		var mat: StandardMaterial3D = ground.material
		mat.albedo_color = p["ground_color"]
		mat.metallic = p["ground_metallic"]
		mat.roughness = p["ground_roughness"]

	return true

func get_preset_names() -> Array:
	return presets.keys()
