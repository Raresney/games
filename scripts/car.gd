extends VehicleBody3D

var engine_force_max: float = 2500.0
var max_brake: float = 35.0
var max_steer_angle: float = 0.45
var top_speed: float = 90.0

var speed_kmh: float = 0.0

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 800.0) * 8.0
	top_speed = data.get("top_speed", 70.0) * 1.5
	max_steer_angle = data.get("max_steer", 0.45)
	var car_color: Color = data.get("color", Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = car_color
	mat.metallic = 0.95
	mat.roughness = 0.12
	mat.metallic_specular = 1.0
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.6
	mat.clearcoat_roughness = 0.05
	for n in ["CarBody", "LowerBody", "CarRoof", "Hood", "Trunk", "Spoiler", "SpoilerL", "SpoilerR", "MirrorL", "MirrorR"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()

	# steering — speed-sensitive
	var steer_input: float = Input.get_axis("steer_right", "steer_left")
	var sf: float = clamp(1.0 - speed / (top_speed * 1.2), 0.35, 1.0)
	steering = move_toward(steering, steer_input * max_steer_angle * sf, delta * 4.5)

	# engine + brakes
	if throttle > 0.0:
		engine_force = -throttle * engine_force_max
		brake = 0.0
	elif throttle < 0.0:
		# if moving forward, throttle down brakes hard; if stopped/reversing, push back
		var fwd_dot: float = transform.basis.z.dot(linear_velocity)
		if fwd_dot > 1.0:
			engine_force = 0.0
			brake = max_brake * abs(throttle)
		else:
			engine_force = -throttle * engine_force_max * 0.4
			brake = 0.0
	else:
		engine_force = 0.0
		brake = 1.5

	if Input.is_action_pressed("handbrake"):
		brake = max_brake * 1.5
		engine_force = 0.0

	# Anti-roll: counter excessive lateral tilt
	var roll: float = transform.basis.x.dot(Vector3.UP)
	apply_torque(-transform.basis.z * roll * mass * 12.0)
	# Downforce — keeps car planted at speed
	var down_force: float = speed * speed * 0.04
	apply_central_force(Vector3.DOWN * down_force)
