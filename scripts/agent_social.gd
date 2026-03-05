## Agent-to-Agent visits — periodically an agent avatar "visits" another agent's room.
## Every ~90 seconds, clones an avatar that walks to another room's doorway, stays 10s, returns.
## Pure visual — shows agents are alive and collaborating.
extends Node

const VISIT_INTERVAL := 90.0  # seconds between visits
const VISIT_STAY_DURATION := 10.0  # how long visitor stays
const MOVE_SPEED := 3.0  # units per second

var visit_timer: float = 0.0
var is_visiting: bool = false
var visit_phase: String = "idle"  # idle, moving_to, staying, returning
var visit_stay_timer: float = 0.0

var visitor_mesh: MeshInstance3D = null
var visitor_start_pos: Vector3
var visitor_target_pos: Vector3

# Agent room positions (doorway positions in hallway)
var agent_positions := {
	"Ultron": Vector3(-2, 0.7, -8),
	"Spinfluencer": Vector3(-2, 0.7, 0),
	"Dexer": Vector3(2, 0.7, -8),
	"Architect": Vector3(2, 0.7, 0),
}

# Agent home positions (inside room, at desk)
var agent_home := {
	"Ultron": Vector3(-7, 0.7, -10.2),
	"Spinfluencer": Vector3(-7, 0.7, -2.2),
	"Dexer": Vector3(7, 0.7, -10.2),
	"Architect": Vector3(7, 0.7, -2.2),
}

var agent_names := ["Ultron", "Spinfluencer", "Dexer", "Architect"]
var current_visitor: String = ""
var current_target: String = ""

func _ready():
	# Randomize initial timer so visits don't happen immediately
	visit_timer = randf_range(30.0, VISIT_INTERVAL)

func _process(delta):
	match visit_phase:
		"idle":
			visit_timer -= delta
			if visit_timer <= 0:
				_start_visit()
		"moving_to":
			_move_visitor(delta, visitor_target_pos, "staying")
		"staying":
			visit_stay_timer -= delta
			if visit_stay_timer <= 0:
				visit_phase = "returning"
		"returning":
			_move_visitor(delta, visitor_start_pos, "cleanup")
		"cleanup":
			_end_visit()

func _start_visit():
	# Pick random visitor and target (different agents)
	current_visitor = agent_names[randi() % agent_names.size()]
	var possible_targets = agent_names.filter(func(n): return n != current_visitor)
	current_target = possible_targets[randi() % possible_targets.size()]
	
	visitor_start_pos = agent_home[current_visitor]
	visitor_target_pos = agent_positions[current_target]
	
	# Create visitor mesh (small capsule clone)
	visitor_mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.8
	visitor_mesh.mesh = capsule
	
	# Copy color from original avatar
	var original = get_node_or_null("/root/Main/" + current_visitor + "_Avatar")
	if original:
		var mat = original.get_surface_override_material(0)
		if mat:
			var clone_mat = mat.duplicate()
			clone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			clone_mat.albedo_color.a = 0.7
			visitor_mesh.set_surface_override_material(0, clone_mat)
	
	visitor_mesh.global_position = visitor_start_pos
	var main = get_node_or_null("/root/Main")
	if main:
		main.add_child(visitor_mesh)
	
	visit_phase = "moving_to"
	visit_stay_timer = VISIT_STAY_DURATION
	is_visiting = true

func _move_visitor(delta: float, target: Vector3, next_phase: String):
	if not visitor_mesh or not is_instance_valid(visitor_mesh):
		_end_visit()
		return
	
	var current_pos = visitor_mesh.global_position
	var direction = (target - current_pos)
	var distance = direction.length()
	
	if distance < 0.3:
		visitor_mesh.global_position = target
		visit_phase = next_phase
		return
	
	visitor_mesh.global_position += direction.normalized() * MOVE_SPEED * delta
	
	# Bob while moving
	visitor_mesh.position.y = visitor_start_pos.y + sin(Time.get_ticks_msec() * 0.005) * 0.05

func _end_visit():
	if visitor_mesh and is_instance_valid(visitor_mesh):
		visitor_mesh.queue_free()
	visitor_mesh = null
	is_visiting = false
	current_visitor = ""
	current_target = ""
	visit_phase = "idle"
	visit_timer = VISIT_INTERVAL + randf_range(-15, 15)

func get_visit_status() -> Dictionary:
	return {
		"is_visiting": is_visiting,
		"visitor": current_visitor,
		"target": current_target,
		"phase": visit_phase
	}
