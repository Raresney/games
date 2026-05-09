extends VehicleBody3D

signal collision_impact(strength: float)

var engine_force_max: float = 5000.0
var max_brake: float = 38.0
var max_steer_angle: float = 0.5
var top_speed: float = 90.0

# Stats exposed to HUD
var speed_kmh: float = 0.0
var nitro: float = 100.0          # 0-100
var drift_angle: float = 0.0       # angle between velocity and forward
var drift_score: int = 0
var drift_combo: float = 0.0       # current combo bar (drops if not drifting)
var is_drifting: bool = false
var prev_velocity: Vector3 = Vector3.ZERO

func setup_from_data(data: Dictionary) -> void:
	engine_force_max = data.get("engine_force", 1000.0) * 11.0
	top_speed = data.get("top_speed", 100.0) * 1.0
	max_steer_angle = data.get("max_steer", 0.5)
	max_brake = 42.0
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
	for n in ["CarBody", "Nose", "NoseCone", "Tail", "Hood", "MirrorL", "MirrorR", "FenderFL", "FenderFR", "FenderRL", "FenderRR", "CarRoof", "SidePanelL", "SidePanelR"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, paint)
	for n in ["LowerBody", "Splitter", "Diffuser", "IntakeL", "IntakeR", "Spoiler", "SpoilerL", "SpoilerR", "SideSkirtL", "SideSkirtR"]:
		if has_node(n):
			get_node(n).set_surface_override_material(0, accent)
	# Tuned: all cars get spoiler, side skirts, and quad exhaust
	for n in ["Spoiler", "SpoilerL", "SpoilerR", "SideSkirtL", "SideSkirtR", "HoodScoop", "StripeL", "StripeR"]:
		if has_node(n): get_node(n).visible = true
	for n in ["ExhaustL1", "ExhaustR1", "ExhaustL2", "ExhaustR2"]:
		if has_node(n): get_node(n).visible = true
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var impact_speed: float = (linear_velocity - prev_velocity).length()
	if impact_speed > 4.0:
		emit_signal("collision_impact", min(impact_speed * 0.08, 1.0))

func _physics_process(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	var throttle: float = Input.get_axis("brake", "accelerate")
	var speed: float = linear_velocity.length()
	var steer_input: float = Input.get_axis("steer_right", "steer_left")

	# Steering (inverted because car runs in reverse Godot direction)
	var sf: float = clamp(1.0 - speed / 50.0, 0.22, 1.0)
	steering = -steer_input * max_steer_angle * sf

	# Nitro: regenerates over time, consumed when held
	var boost_active: bool = Input.is_action_pressed("nitro") and nitro > 1.0 and throttle > 0.0
	if boost_active:
		nitro = max(0.0, nitro - delta * 30.0)
	else:
		nitro = min(100.0, nitro + delta * 18.0)
	var boost_mult: float = 2.2 if boost_active else 1.0
	var top_speed_now: float = top_speed * boost_mult

	# Engine + brake
	if throttle > 0.0:
		if speed < top_speed_now:
			engine_force = -throttle * engine_force_max * boost_mult
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

	# Drift detection: angle between velocity and forward
	if speed > 6.0:
		var fwd_local: Vector3 = -transform.basis.z
		fwd_local.y = 0
		fwd_local = fwd_local.normalized()
		var vel_flat: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z).normalized()
		drift_angle = abs(fwd_local.angle_to(vel_flat))
		is_drifting = drift_angle > 0.18 and drift_angle < 1.4
		if is_drifting:
			drift_combo = min(drift_combo + delta * (8.0 + speed * 0.4), 100.0)
			drift_score += int(drift_combo * delta * 8.0)
		else:
			drift_combo = max(0.0, drift_combo - delta * 25.0)
	else:
		is_drifting = false
		drift_angle = 0.0
		drift_combo = max(0.0, drift_combo - delta * 40.0)

	# Anti-roll
	var fwd_axis: Vector3 = transform.basis.z
	var roll_vel: float = angular_velocity.dot(fwd_axis)
	angular_velocity -= fwd_axis * roll_vel * 0.5

	# Yaw assist (sign flipped to match steering inversion)
	if abs(steer_input) > 0.05 and speed > 1.0:
		var yaw_axis: Vector3 = transform.basis.y
		var assist: float = steer_input * mass * clamp(speed * 0.4, 1.0, 8.0)
		apply_torque(yaw_axis * assist)

	# Restoring torque if very tilted
	var up_dot: float = transform.basis.y.dot(Vector3.UP)
	if up_dot < 0.85:
		var lean_axis: Vector3 = transform.basis.y.cross(Vector3.UP)
		apply_torque(lean_axis * mass * 18.0)

	# Downforce
	apply_central_force(Vector3.DOWN * speed * speed * 0.06)

	prev_velocity = linear_velocity
