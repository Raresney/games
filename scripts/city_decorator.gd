extends Node3D

# Daytime building palette
const BUILDING_DARKS: Array = [
	Color(0.72, 0.55, 0.4),
	Color(0.55, 0.62, 0.7),
	Color(0.85, 0.78, 0.65),
	Color(0.45, 0.5, 0.55),
	Color(0.65, 0.45, 0.4),
]

const NEON_COLORS: Array = [
	Color(1.0, 0.85, 0.4),
	Color(0.9, 0.85, 0.7),
	Color(0.75, 0.85, 1.0),
	Color(1.0, 0.95, 0.7),
]

func _ready() -> void:
	_decorate_buildings()
	_spawn_extra_buildings()
	_spawn_trees()
	_add_streetlamps()
	_add_road_markings()
	_spawn_traffic_cones()
	_spawn_ramps()
	_spawn_gas_stations()

func _decorate_buildings() -> void:
	var buildings := get_node_or_null("../Buildings")
	if buildings == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for child in buildings.get_children():
		if not (child is CSGBox3D):
			continue
		var box: CSGBox3D = child
		var col: Color = BUILDING_DARKS[rng.randi() % BUILDING_DARKS.size()]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = 0.05
		mat.roughness = 0.6
		box.material = mat
		_add_window_grid(box, rng)

func _add_window_grid(box: CSGBox3D, rng: RandomNumberGenerator) -> void:
	var sz: Vector3 = box.size
	var rows: int = max(int(sz.y / 3.5), 2)
	for r in rows:
		# Some rows lit, some dark
		if rng.randf() > 0.65:
			continue
		var col: Color = NEON_COLORS[rng.randi() % NEON_COLORS.size()]
		var win_mat := StandardMaterial3D.new()
		win_mat.albedo_color = col * 0.35
		win_mat.emission_enabled = true
		win_mat.emission = col
		win_mat.emission_energy_multiplier = 0.7
		var y: float = -sz.y * 0.5 + (r + 0.5) * (sz.y / float(rows))
		var fm := BoxMesh.new()
		fm.size = Vector3(sz.x * 0.85, 0.55, 0.04)
		var f := MeshInstance3D.new()
		f.mesh = fm
		f.position = Vector3(0, y, sz.z * 0.5 + 0.03)
		f.material_override = win_mat
		box.add_child(f)
		var b := MeshInstance3D.new()
		b.mesh = fm
		b.position = Vector3(0, y, -sz.z * 0.5 - 0.03)
		b.material_override = win_mat
		box.add_child(b)
		var lm := BoxMesh.new()
		lm.size = Vector3(0.04, 0.55, sz.z * 0.85)
		var l := MeshInstance3D.new()
		l.mesh = lm
		l.position = Vector3(-sz.x * 0.5 - 0.03, y, 0)
		l.material_override = win_mat
		box.add_child(l)
		var rg := MeshInstance3D.new()
		rg.mesh = lm
		rg.position = Vector3(sz.x * 0.5 + 0.03, y, 0)
		rg.material_override = win_mat
		box.add_child(rg)

func _add_neon_outline(box: CSGBox3D, rng: RandomNumberGenerator) -> void:
	# Bright neon edge along the top of the building
	var sz: Vector3 = box.size
	var col: Color = NEON_COLORS[rng.randi() % NEON_COLORS.size()]
	var em := StandardMaterial3D.new()
	em.albedo_color = col
	em.emission_enabled = true
	em.emission = col
	em.emission_energy_multiplier = 1.5
	var y_top: float = sz.y * 0.5 + 0.05
	# top X bars
	var bx := BoxMesh.new()
	bx.size = Vector3(sz.x + 0.2, 0.12, 0.12)
	for z_off in [sz.z * 0.5, -sz.z * 0.5]:
		var m := MeshInstance3D.new()
		m.mesh = bx
		m.position = Vector3(0, y_top, z_off)
		m.material_override = em
		box.add_child(m)
	var bz := BoxMesh.new()
	bz.size = Vector3(0.12, 0.12, sz.z + 0.2)
	for x_off in [sz.x * 0.5, -sz.x * 0.5]:
		var m := MeshInstance3D.new()
		m.mesh = bz
		m.position = Vector3(x_off, y_top, 0)
		m.material_override = em
		box.add_child(m)

func _add_neon_strips(box: CSGBox3D, rng: RandomNumberGenerator) -> void:
	# Vertical neon accent strips on building corners
	var sz: Vector3 = box.size
	if rng.randf() > 0.6:
		return
	var col: Color = NEON_COLORS[rng.randi() % NEON_COLORS.size()]
	var em := StandardMaterial3D.new()
	em.albedo_color = col
	em.emission_enabled = true
	em.emission = col
	em.emission_energy_multiplier = 1.5
	var sm := BoxMesh.new()
	sm.size = Vector3(0.18, sz.y * 0.85, 0.18)
	for x_off in [sz.x * 0.5 + 0.05, -sz.x * 0.5 - 0.05]:
		for z_off in [sz.z * 0.5 + 0.05, -sz.z * 0.5 - 0.05]:
			var m := MeshInstance3D.new()
			m.mesh = sm
			m.position = Vector3(x_off, 0, z_off)
			m.material_override = em
			box.add_child(m)

func _add_streetlamps() -> void:
	var positions: Array = []
	for z in range(-150, 151, 25):
		positions.append(Vector3(8.5, 0, z))
		positions.append(Vector3(-8.5, 0, z))
	for x in range(-150, 151, 25):
		if abs(x) < 12:
			continue
		positions.append(Vector3(x, 0, 8.5))
		positions.append(Vector3(x, 0, -8.5))
	for p in positions:
		_make_lamp(p)

func _make_lamp(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.08
	pm.bottom_radius = 0.1
	pm.height = 5.0
	pole.mesh = pm
	pole.position = Vector3(0, 2.5, 0)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.1, 0.1, 0.13)
	pole_mat.metallic = 0.7
	pole_mat.roughness = 0.3
	pole.material_override = pole_mat
	root.add_child(pole)
	# Neon ring at top
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.22
	bm.height = 0.44
	bulb.mesh = bm
	bulb.position = Vector3(0, 5.0, 0)
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(0.95, 0.6, 0.1)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.55, 0.1)
	bulb_mat.emission_energy_multiplier = 2.5
	bulb.material_override = bulb_mat
	root.add_child(bulb)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 4.9, 0)
	light.light_color = Color(1.0, 0.55, 0.15)
	light.light_energy = 1.5
	light.omni_range = 12.0
	root.add_child(light)

func _spawn_extra_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var spawned: int = 0
	for _i in 180:
		var x: float = rng.randf_range(-650, 650)
		var z: float = rng.randf_range(-650, 650)
		# Keep clear of roads
		if abs(x) < 14 or abs(z) < 14 or (abs(x - 80) < 12) or (abs(x + 80) < 12) or (abs(z - 80) < 12) or (abs(z + 80) < 12):
			continue
		# Avoid existing buildings cluster center
		if abs(x) < 130 and abs(z) < 130 and rng.randf() < 0.5:
			continue
		var w: float = rng.randf_range(12, 26)
		var h: float = rng.randf_range(15, 55)
		var d: float = rng.randf_range(12, 26)
		var box := CSGBox3D.new()
		box.size = Vector3(w, h, d)
		box.position = Vector3(x, h * 0.5, z)
		box.use_collision = true
		var col: Color = BUILDING_DARKS[rng.randi() % BUILDING_DARKS.size()]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = 0.05
		mat.roughness = 0.7
		box.material = mat
		add_child(box)
		_add_window_grid(box, rng)
		spawned += 1

func _spawn_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.32, 0.2, 0.1)
	trunk_mat.roughness = 0.9
	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.18, 0.42, 0.15)
	leaves_mat.roughness = 0.85
	for _i in 200:
		var x: float = rng.randf_range(-680, 680)
		var z: float = rng.randf_range(-680, 680)
		if abs(x) < 10 or abs(z) < 10 or (abs(x - 80) < 10) or (abs(x + 80) < 10) or (abs(z - 80) < 10) or (abs(z + 80) < 10):
			continue
		var root := Node3D.new()
		root.position = Vector3(x, 0, z)
		add_child(root)
		# Trunk
		var trunk := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.18
		tm.bottom_radius = 0.25
		tm.height = 2.5
		trunk.mesh = tm
		trunk.position = Vector3(0, 1.25, 0)
		trunk.material_override = trunk_mat
		root.add_child(trunk)
		# Leaves (sphere)
		var leaves := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = rng.randf_range(1.3, 2.0)
		lm.height = lm.radius * 2.0
		leaves.mesh = lm
		leaves.position = Vector3(0, 3.0, 0)
		leaves.material_override = leaves_mat
		root.add_child(leaves)

func _spawn_traffic_cones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(1.0, 0.45, 0.05)
	cone_mat.emission_enabled = true
	cone_mat.emission = Color(1.0, 0.4, 0.1)
	cone_mat.emission_energy_multiplier = 0.4
	for _i in 40:
		var x: float = rng.randf_range(-150, 150)
		var z: float = rng.randf_range(-150, 150)
		# Only place near roads, not on them
		var on_x_road: bool = abs(x) < 7.5 or abs(x - 80) < 7.5 or abs(x + 80) < 7.5
		var on_z_road: bool = abs(z) < 7.5 or abs(z - 80) < 7.5 or abs(z + 80) < 7.5
		if on_x_road or on_z_road:
			continue
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.25
		cm.height = 0.6
		cone.mesh = cm
		cone.position = Vector3(x, 0.3, z)
		cone.material_override = cone_mat
		add_child(cone)

func _spawn_ramps() -> void:
	# Drivable ramps placed off-road to launch the car
	var ramp_positions: Array = [
		Vector3(40, 0, 40), Vector3(-40, 0, 40),
		Vector3(40, 0, -40), Vector3(-40, 0, -40),
		Vector3(120, 0, 0), Vector3(-120, 0, 0),
		Vector3(0, 0, 120), Vector3(0, 0, -120),
	]
	for pos in ramp_positions:
		var ramp := CSGBox3D.new()
		ramp.size = Vector3(8, 1.6, 6)
		ramp.position = pos + Vector3(0, 0.8, 0)
		# Tilt forward (rotate around X)
		ramp.rotation_degrees = Vector3(-15, randf() * 360.0, 0)
		ramp.use_collision = true
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.4, 0.05, 1)
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.4, 0.05, 1)
		mat.emission_energy_multiplier = 0.2
		ramp.material = mat
		add_child(ramp)

func _spawn_gas_stations() -> void:
	# Cosmetic gas stations at major intersections
	var stations: Array = [
		Vector3(40, 0, 40), Vector3(-40, 0, -40), Vector3(120, 0, 90), Vector3(-120, 0, -90)
	]
	for pos in stations:
		_make_gas_station(pos)

func _make_gas_station(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	# Canopy roof
	var canopy := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(12, 0.4, 8)
	canopy.mesh = cm
	canopy.position = Vector3(0, 5.0, 0)
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.95, 0.95, 0.95)
	canopy.material_override = canopy_mat
	root.add_child(canopy)
	# Pillars
	for x_off in [-5.0, 5.0]:
		for z_off in [-3.5, 3.5]:
			var pillar := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.3, 5.0, 0.3)
			pillar.mesh = pm
			pillar.position = Vector3(x_off, 2.5, z_off)
			var pill_mat := StandardMaterial3D.new()
			pill_mat.albedo_color = Color(0.6, 0.6, 0.65)
			pill_mat.metallic = 0.5
			pillar.material_override = pill_mat
			root.add_child(pillar)
	# Pumps (2)
	for x_off in [-2.0, 2.0]:
		var pump := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.6, 1.6, 0.5)
		pump.mesh = pm
		pump.position = Vector3(x_off, 0.8, 0)
		var pump_mat := StandardMaterial3D.new()
		pump_mat.albedo_color = Color(0.95, 0.15, 0.1)
		pump.material_override = pump_mat
		root.add_child(pump)
	# Sign light
	var sign_light := OmniLight3D.new()
	sign_light.position = Vector3(0, 5.5, 0)
	sign_light.light_color = Color(1, 0.95, 0.6)
	sign_light.light_energy = 1.5
	sign_light.omni_range = 16.0
	root.add_child(sign_light)

func _add_road_markings() -> void:
	# Glowing center dashes — neon yellow/cyan
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 0.85, 0.2)
	line_mat.emission_enabled = true
	line_mat.emission = Color(1.0, 0.85, 0.2)
	line_mat.emission_energy_multiplier = 0.8
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.3, 0.02, 2.5)
	for road_x in [0, 80, -80]:
		for z in range(-280, 281, 8):
			if abs(z) < 12:
				continue
			var dash := MeshInstance3D.new()
			dash.mesh = dash_mesh
			dash.position = Vector3(road_x, 0.04, z)
			dash.material_override = line_mat
			add_child(dash)
	var dash_mesh_h := BoxMesh.new()
	dash_mesh_h.size = Vector3(2.5, 0.02, 0.3)
	for road_z in [0, 80, -80]:
		for x in range(-280, 281, 8):
			if abs(x) < 12:
				continue
			var dash := MeshInstance3D.new()
			dash.mesh = dash_mesh_h
			dash.position = Vector3(x, 0.04, road_z)
			dash.material_override = line_mat
			add_child(dash)
	# Road edge cyan strips
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.0, 0.9, 1.0)
	edge_mat.emission_enabled = true
	edge_mat.emission = Color(0.0, 0.9, 1.0)
	edge_mat.emission_energy_multiplier = 0.7
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.1, 0.02, 600.0)
	for road_x in [0, 80, -80]:
		for offset in [6.8, -6.8]:
			var e := MeshInstance3D.new()
			e.mesh = edge_mesh
			e.position = Vector3(road_x + offset, 0.05, 0)
			e.material_override = edge_mat
			add_child(e)
	var edge_mesh_h := BoxMesh.new()
	edge_mesh_h.size = Vector3(600.0, 0.02, 0.1)
	for road_z in [0, 80, -80]:
		for offset in [6.8, -6.8]:
			var e := MeshInstance3D.new()
			e.mesh = edge_mesh_h
			e.position = Vector3(0, 0.05, road_z + offset)
			e.material_override = edge_mat
			add_child(e)
