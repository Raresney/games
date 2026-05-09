extends GPUParticles3D

@export var car_path: NodePath
var car: VehicleBody3D = null
var wheel: VehicleWheel3D = null

func _ready() -> void:
	one_shot = false
	emitting = false
	amount = 24
	lifetime = 0.7
	# Build a process material at runtime
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	pm.color = Color(0.85, 0.85, 0.9, 0.7)
	process_material = pm
	# Sphere mesh for puffs
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	draw_pass_1 = sm
	# Find car (parent VehicleBody3D)
	var p: Node = get_parent()
	while p != null and not (p is VehicleBody3D):
		p = p.get_parent()
	if p:
		car = p
	# Wheel parent
	var w: Node = get_parent()
	if w is VehicleWheel3D:
		wheel = w

func _process(_delta: float) -> void:
	if car == null:
		return
	var speed: float = car.linear_velocity.length()
	var handbrake: bool = Input.is_action_pressed("handbrake")
	var hard_steer: bool = abs(car.steering) > 0.25 and speed > 8.0
	var grounded: bool = wheel.is_in_contact() if wheel else true
	emitting = grounded and (handbrake or hard_steer) and speed > 3.0
