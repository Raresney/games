extends VehicleBody3D

var engine_force_max: float = 5000.0
var max_brake: float = 38.0
var max_steer_angle: float = 0.5
var top_speed: float = 90.0
var speed_kmh: float = 0.0

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 1000.0) * 12.0
	top_speed = data.get("top_speed", 100.0) * 1.5
	max_steer_angle = data.get("max_steer", 0.5)
	var car_color: Color = data.get("color", Color.WHITE)
	var accent_color: Color = data.get("accent", Color(0.05, 0.05, 0.05, 1))
	var paint := StandardMaterial3D.new()
	paint.albedo_color = car_color
	paint.metallic = 0.92
	paint.roughness = 0.12
	paint.metallic_specular = 1.0
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.7
	paint.clearcoat_roughness = 0.04
	var accent := StandardMaterial3D.new()
	accent.albedo_color = accent_color
	accent.metallic = 0.6
	accent.roughness = 0.35
	for n in ["CarBody", "Nose", "Tail", "Hood", "MirrorL", "MirrorR", "FenderFL", "FenderFR", "FenderRL", "FenderRR", "CarRoof"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, paint)
	for n in ["LowerBody", "Splitter", "Diffuser", "IntakeL", "IntakeR", "Spoiler", "SpoilerL", "SpoilerR", "SideSkirtL", "SideSkirtR"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, accent)
	var big: bool = data.get("big_spoiler", false)
	for n in ["Spoiler", "SpoilerL", "SpoilerR"]:
		if has_node(n): get_node(n).visible = big
	var skirts: bool = data.get("side_skirts", true)
	for n in ["SideSkirtL", "SideSkirtR"]:
		if has_node(n): get_node(n).visible = skirts
	var twin: bool = data.get("twin_exhaust", false)
	var quad: bool = data.get("quad_exhaust", false)
	if has_node("ExhaustL1"): $ExhaustL1.visible = twin or quad
	if has_node("ExhaustR1"): $ExhaustR1.visible = twin or quad
	if has_node("ExhaustL2"): $ExhaustL2.visible = quad
	if has_node("ExhaustR2"): $ExhaustR2.visible = quad

func _physics_process(_delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()
	var steer_input: float = Input.get_axis("steer_right", "steer_left")

	# Steering — direct, MUCH less at speed (prevents flip)
	var sf: float = clamp(1.0 - speed / 50.0, 0.22, 1.0)
	steering = steer_input * max_steer_angle * sf

	# Negated engine_force: W = engine_force NEGATIVE = car moves opposite of Godot default
	if throttle > 0.0:
		if speed < top_speed:
			engine_force = -throttle * engine_force_max
		else:
			engine_force = 0.0
		brake = 0.0
	elif throttle < 0.0:
		var fwd_speed: float = transform.basis.z.dot(linear_velocity)
		if fwd_speed > 2.0:
			engine_force = 0.0
			brake = max_brake * abs(throttle)
		elif speed < top_speed * 0.35:
			engine_force = -throttle * engine_force_max * 0.45
			brake = 0.0
		else:
			engine_force = 0.0
			brake = 0.0
	else:
		engine_force = 0.0
		brake = 2.0

	if Input.is_action_pressed("handbrake"):
		brake = max_brake * 1.5
		engine_force = 0.0

	# Anti-roll: damp angular velocity around local Z (forward) axis only
	var fwd_axis: Vector3 = transform.basis.z
	var roll_vel: float = angular_velocity.dot(fwd_axis)
	angular_velocity -= fwd_axis * roll_vel * 0.5

	# Yaw assist — helps the car turn responsively at speed
	if abs(steer_input) > 0.05 and speed > 1.0:
		var yaw_axis: Vector3 = transform.basis.y
		var assist: float = -steer_input * mass * clamp(speed * 0.4, 1.0, 8.0)
		apply_torque(yaw_axis * assist)

	# Restoring torque if seriously tilted (>30°)
	var up_dot: float = transform.basis.y.dot(Vector3.UP)
	if up_dot < 0.85:
		var lean_axis: Vector3 = transform.basis.y.cross(Vector3.UP)
		apply_torque(lean_axis * mass * 18.0)

	# Downforce
	apply_central_force(Vector3.DOWN * speed * speed * 0.06)
