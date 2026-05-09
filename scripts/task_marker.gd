extends Area3D

@export var marker_index: int = 0
var beacon: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Replace the beacon visual with a glowing tall pillar
	beacon = get_node_or_null("Beacon")
	if beacon and beacon is CSGBox3D:
		var b: CSGBox3D = beacon
		b.size = Vector3(1.2, 14.0, 1.2)
		b.position = Vector3(0, 7.0, 0)
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.78, 0.1)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.78, 0.1)
		glow.emission_energy_multiplier = 1.4
		b.material = glow
		var light := OmniLight3D.new()
		light.position = Vector3(0, 3.0, 0)
		light.light_color = Color(1.0, 0.75, 0.2)
		light.light_energy = 2.0
		light.omni_range = 18.0
		add_child(light)

func _process(delta: float) -> void:
	if beacon:
		beacon.rotate_y(delta * 1.5)

func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		var tm := get_parent()
		if tm.has_method("on_marker_reached"):
			tm.on_marker_reached(marker_index)
