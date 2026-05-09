extends Node3D

# Spawns simple NPC vehicles that drive along the road grid
const NPC_COUNT: int = 12
const ROAD_LANES: Array = [0, 80, -80]  # X positions for NS roads, Z for EW roads
const SPEED_MIN: float = 8.0
const SPEED_MAX: float = 16.0

var npcs: Array = []

class NPC:
	var node: Node3D
	var velocity: Vector3
	var target_z: float = 0.0
	var target_x: float = 0.0
	var axis: String = "z"  # "z" for NS road, "x" for EW road

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 333
	for i in NPC_COUNT:
		_spawn_npc(rng)

func _spawn_npc(rng: RandomNumberGenerator) -> void:
	var npc := NPC.new()
	var col: Color = Color.from_hsv(rng.randf(), 0.6, 0.7)
	# Build a simple car body
	var node := Node3D.new()
	add_child(node)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.7, 1.2, 4.0)
	body.mesh = bm
	body.position = Vector3(0, 0.6, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.6
	mat.roughness = 0.3
	body.material_override = mat
	node.add_child(body)
	# Tail lights
	var tail := MeshInstance3D.new()
	var tlm := BoxMesh.new()
	tlm.size = Vector3(1.5, 0.12, 0.05)
	tail.mesh = tlm
	tail.position = Vector3(0, 0.7, 2.0)
	var tail_mat := StandardMaterial3D.new()
	tail_mat.albedo_color = Color(1, 0.1, 0.1, 1)
	tail_mat.emission_enabled = true
	tail_mat.emission = Color(1, 0.1, 0.1, 1)
	tail_mat.emission_energy_multiplier = 1.0
	tail.material_override = tail_mat
	node.add_child(tail)
	# Random spawn on a road
	if rng.randf() > 0.5:
		# NS road
		var x: float = ROAD_LANES[rng.randi() % 3] + (3.5 if rng.randf() > 0.5 else -3.5)
		var z: float = rng.randf_range(-200, 200)
		node.position = Vector3(x, 0.0, z)
		npc.axis = "z"
		var dir: float = 1.0 if x > ROAD_LANES[0] else -1.0  # opposite lanes go opposite ways
		if rng.randf() > 0.5:
			dir = -dir
		var speed: float = rng.randf_range(SPEED_MIN, SPEED_MAX)
		npc.velocity = Vector3(0, 0, dir * speed)
		if dir < 0:
			node.rotation.y = PI
	else:
		# EW road
		var z: float = ROAD_LANES[rng.randi() % 3] + (3.5 if rng.randf() > 0.5 else -3.5)
		var x: float = rng.randf_range(-200, 200)
		node.position = Vector3(x, 0.0, z)
		npc.axis = "x"
		var dir: float = 1.0
		if rng.randf() > 0.5:
			dir = -1.0
		var speed: float = rng.randf_range(SPEED_MIN, SPEED_MAX)
		npc.velocity = Vector3(dir * speed, 0, 0)
		node.rotation.y = PI / 2.0 if dir > 0 else -PI / 2.0
	npc.node = node
	npcs.append(npc)

func _process(delta: float) -> void:
	for npc in npcs:
		npc.node.position += npc.velocity * delta
		# Wrap around if out of bounds
		if npc.node.position.x > 280:
			npc.node.position.x = -280
		elif npc.node.position.x < -280:
			npc.node.position.x = 280
		if npc.node.position.z > 280:
			npc.node.position.z = -280
		elif npc.node.position.z < -280:
			npc.node.position.z = 280
