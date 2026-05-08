extends VehicleBody3D

var engine_force_max: float = 300.0
var max_brake: float = 50.0
var max_steer_angle: float = 0.45
var top_speed: float = 65.0

var speed_kmh: float = 0.0

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 300.0)
	top_speed = data.get("top_speed", 65.0)
	max_steer_angle = data.get("max_steer", 0.45)
	var car_color: Color = data.get("color", Color.WHITE)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = car_color
	mat.metallic = 0.85
	mat.roughness = 0.15
	mat.metallic_specular = 1.0

	if has_node("CarBody"):
		$CarBody.set_surface_override_material(0, mat)
	if has_node("CarRoof"):
		$CarRoof.set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6

	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()

	if throttle > 0.0:
		var force_factor: float = clamp(1.0 - speed / top_speed, 0.01, 1.0)
		engine_force = throttle * engine_force_max * force_factor
		brake = 0.0
	elif throttle < 0.0:
		engine_force = throttle * engine_force_max * 0.3
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 3.0

	if Input.is_action_pressed("handbrake"):
		brake = max_brake
		engine_force = 0.0

	var steer_input: float = Input.get_axis("steer_right", "steer_left")
	var speed_factor: float = clamp(1.0 - speed / top_speed * 0.55, 0.3, 1.0)
	steering = move_toward(steering, steer_input * max_steer_angle * speed_factor, delta * 5.0)

	var down_force: float = speed * 0.5
	apply_central_force(Vector3.DOWN * down_force)
