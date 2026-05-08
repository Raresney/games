extends VehicleBody3D

var engine_force_max: float = 800.0
var max_brake: float = 30.0
var max_steer_angle: float = 0.5
var top_speed: float = 70.0

var speed_kmh: float = 0.0

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 800.0) * 2.5
	top_speed = data.get("top_speed", 70.0)
	max_steer_angle = data.get("max_steer", 0.5)
	var car_color: Color = data.get("color", Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = car_color
	mat.metallic = 0.9
	mat.roughness = 0.1
	for n in ["CarBody", "CarRoof", "Hood", "Trunk", "Spoiler"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()
	if throttle > 0.0:
		engine_force = throttle * engine_force_max
		brake = 0.0
	elif throttle < 0.0:
		engine_force = throttle * engine_force_max * 0.4
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 2.0
	if Input.is_action_pressed("handbrake"):
		brake = max_brake
		engine_force = 0.0
	var steer_input: float = Input.get_axis("steer_right", "steer_left")
	steering = move_toward(steering, steer_input * max_steer_angle, delta * 4.0)
