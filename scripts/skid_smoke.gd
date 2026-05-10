extends GPUParticles3D

var car: VehicleBody3D = null
var wheel: VehicleWheel3D = null

func _ready() -> void:
	one_shot = false
	emitting = false
	amount = 60
	lifetime = 1.4
	preprocess = 0.0
	explosiveness = 0.0
	randomness = 0.6
	# Process material
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 50.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0.8, 0)
	pm.linear_accel_min = -1.5
	pm.linear_accel_max = -0.6
	pm.scale_min = 0.7
	pm.scale_max = 1.4
	pm.scale_curve = _build_scale_curve()
	pm.color = Color(0.92, 0.92, 0.94, 0.85)
	pm.color_ramp = _build_color_ramp()
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	process_material = pm
	# Mesh — flat quad would be best but use sphere for now
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	sm.radial_segments = 6
	sm.rings = 4
	draw_pass_1 = sm
	# Find car (parent VehicleBody3D)
	var p: Node = get_parent()
	while p != null and not (p is VehicleBody3D):
		p = p.get_parent()
	if p:
		car = p
	var w: Node = get_parent()
	if w is VehicleWheel3D:
		wheel = w

func _build_scale_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.3))
	c.add_point(Vector2(0.3, 1.0))
	c.add_point(Vector2(1.0, 2.2))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct

func _build_color_ramp() -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.95, 0.97, 0.0))   # invisible at birth
	g.set_color(1, Color(0.55, 0.55, 0.6, 0.0))    # fades to invisible at death
	g.add_point(0.1, Color(0.96, 0.96, 0.98, 0.85))
	g.add_point(0.6, Color(0.7, 0.7, 0.75, 0.5))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt

func _process(_delta: float) -> void:
	if car == null:
		return
	var speed: float = car.linear_velocity.length()
	var handbrake: bool = Input.is_action_pressed("handbrake")
	var hard_steer: bool = abs(car.steering) > 0.25 and speed > 8.0
	var grounded: bool = wheel.is_in_contact() if wheel else true
	emitting = grounded and (handbrake or hard_steer or car.is_drifting) and speed > 3.0
