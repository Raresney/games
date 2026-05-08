extends VehicleBody3D

var engine_force_max: float = 5000.0
var max_brake: float = 40.0
var max_steer_angle: float = 0.45
var top_speed: float = 130.0
var speed_kmh: float = 0.0

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 1000.0) * 15.0
	top_speed = data.get("top_speed", 100.0) * 1.6
	max_steer_angle = data.get("max_steer", 0.45)
	var car_color: Color = data.get("color", Color.WHITE)
	var accent_color: Color = data.get("accent", Color(0.05, 0.05, 0.05, 1))
	# Body PBR paint with clearcoat
	var paint := StandardMaterial3D.new()
	paint.albedo_color = car_color
	paint.metallic = 0.95
	paint.roughness = 0.10
	paint.metallic_specular = 1.0
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.8
	paint.clearcoat_roughness = 0.04
	# Carbon/black accent
	var accent := StandardMaterial3D.new()
	accent.albedo_color = accent_color
	accent.metallic = 0.6
	accent.roughness = 0.35
	for n in ["CarBody", "Nose", "Tail", "Hood", "MirrorL", "MirrorR", "CabinFront", "CabinRear", "LowerBody"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, paint)
	for n in ["CarRoof", "Spoiler", "SpoilerL", "SpoilerR", "SideSkirtL", "SideSkirtR"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, accent)
	# Apply shape parameters via scale on whole car
	if data.has("body_scale"):
		var bs: Vector3 = data["body_scale"]
		# Apply only on visual length to avoid breaking wheels
		for n in ["CarBody", "Nose", "Tail", "Hood", "LowerBody", "CabinFront", "CabinRear", "CarRoof", "Glass"]:
			if has_node(n):
				get_node(n).scale = Vector3(bs.x, bs.y, 1.0)
	# Spoiler visibility
	var big: bool = data.get("big_spoiler", false)
	if has_node("Spoiler"): $Spoiler.visible = big
	if has_node("SpoilerL"): $SpoilerL.visible = big
	if has_node("SpoilerR"): $SpoilerR.visible = big
	# Side skirts
	var skirts: bool = data.get("side_skirts", true)
	if has_node("SideSkirtL"): $SideSkirtL.visible = skirts
	if has_node("SideSkirtR"): $SideSkirtR.visible = skirts
	# Exhaust pipes (twin = inner only, quad = all 4)
	var twin: bool = data.get("twin_exhaust", false)
	var quad: bool = data.get("quad_exhaust", false)
	if has_node("ExhaustL1"): $ExhaustL1.visible = twin or quad
	if has_node("ExhaustR1"): $ExhaustR1.visible = twin or quad
	if has_node("ExhaustL2"): $ExhaustL2.visible = quad
	if has_node("ExhaustR2"): $ExhaustR2.visible = quad

func _physics_process(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()

	var steer_input: float = Input.get_axis("steer_right", "steer_left")
	var sf: float = clamp(1.0 - speed / (top_speed * 1.4), 0.3, 1.0)
	steering = move_toward(steering, steer_input * max_steer_angle * sf, delta * 5.0)

	if throttle > 0.0:
		engine_force = -throttle * engine_force_max
		brake = 0.0
	elif throttle < 0.0:
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

	# Anti-roll
	var roll: float = transform.basis.x.dot(Vector3.UP)
	apply_torque(-transform.basis.z * roll * mass * 12.0)
	# Speed-scaled downforce
	var down_force: float = speed * speed * 0.05
	apply_central_force(Vector3.DOWN * down_force)
