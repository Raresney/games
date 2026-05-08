extends Node3D

const BUILDING_COLORS: Array = [
	Color(0.72, 0.55, 0.4),   # warm tan
	Color(0.55, 0.62, 0.7),   # cool blue-gray
	Color(0.85, 0.78, 0.65),  # cream
	Color(0.45, 0.5, 0.55),   # slate
	Color(0.65, 0.45, 0.4),   # brick
	Color(0.5, 0.55, 0.45),   # olive gray
]

func _ready() -> void:
	_decorate_buildings()
	_add_streetlamps()
	_add_road_markings()

func _decorate_buildings() -> void:
	var buildings := get_node_or_null("../Buildings")
	if buildings == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var idx: int = 0
	for child in buildings.get_children():
		if not (child is CSGBox3D):
			continue
		var box: CSGBox3D = child
		var col: Color = BUILDING_COLORS[idx % BUILDING_COLORS.size()]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.85
		# emissive window grid via detail
		mat.detail_enabled = false
		box.material = mat
		# add window grid panel on each side as emissive box
		_add_windows(box, rng)
		idx += 1

func _add_windows(box: CSGBox3D, rng: RandomNumberGenerator) -> void:
	var sz: Vector3 = box.size
	var win_mat := StandardMaterial3D.new()
	var lit: Color = Color(1.0, 0.85, 0.45) if rng.randf() > 0.4 else Color(0.55, 0.7, 1.0)
	win_mat.albedo_color = lit * 0.3
	win_mat.emission_enabled = true
	win_mat.emission = lit
	win_mat.emission_energy_multiplier = 1.2
	# vertical window strips on front+back (Z) and left+right (X)
	var rows: int = max(int(sz.y / 4.0), 1)
	for r in rows:
		var y: float = -sz.y * 0.5 + (r + 0.5) * (sz.y / float(rows))
		# front strip
		var f := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(sz.x * 0.7, 0.9, 0.05)
		f.mesh = fm
		f.position = Vector3(0, y, sz.z * 0.5 + 0.03)
		f.material_override = win_mat
		box.add_child(f)
		# back strip
		var b := MeshInstance3D.new()
		b.mesh = fm
		b.position = Vector3(0, y, -sz.z * 0.5 - 0.03)
		b.material_override = win_mat
		box.add_child(b)
		# left
		var l := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.05, 0.9, sz.z * 0.7)
		l.mesh = lm
		l.position = Vector3(-sz.x * 0.5 - 0.03, y, 0)
		l.material_override = win_mat
		box.add_child(l)
		# right
		var rg := MeshInstance3D.new()
		rg.mesh = lm
		rg.position = Vector3(sz.x * 0.5 + 0.03, y, 0)
		rg.material_override = win_mat
		box.add_child(rg)

func _add_streetlamps() -> void:
	var positions: Array = []
	for z in range(-280, 281, 40):
		positions.append(Vector3(8.5, 0, z))
		positions.append(Vector3(-8.5, 0, z))
	for x in range(-280, 281, 40):
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
	# pole
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.1
	pm.bottom_radius = 0.12
	pm.height = 5.5
	pole.mesh = pm
	pole.position = Vector3(0, 2.75, 0)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.2, 0.2, 0.22)
	pole_mat.metallic = 0.6
	pole_mat.roughness = 0.4
	pole.material_override = pole_mat
	root.add_child(pole)
	# bulb
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.25
	bm.height = 0.5
	bulb.mesh = bm
	bulb.position = Vector3(0, 5.5, 0)
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1, 0.9, 0.6)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1, 0.85, 0.5)
	bulb_mat.emission_energy_multiplier = 3.0
	bulb.material_override = bulb_mat
	root.add_child(bulb)
	# light
	var light := OmniLight3D.new()
	light.position = Vector3(0, 5.4, 0)
	light.light_color = Color(1, 0.85, 0.5)
	light.light_energy = 2.5
	light.omni_range = 14.0
	root.add_child(light)

func _add_road_markings() -> void:
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1, 0.9, 0.3)
	line_mat.emission_enabled = true
	line_mat.emission = Color(1, 0.9, 0.3)
	line_mat.emission_energy_multiplier = 0.3
	# center dashes along main NS road and others
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.25, 0.02, 2.5)
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
	dash_mesh_h.size = Vector3(2.5, 0.02, 0.25)
	for road_z in [0, 80, -80]:
		for x in range(-280, 281, 8):
			if abs(x) < 12:
				continue
			var dash := MeshInstance3D.new()
			dash.mesh = dash_mesh_h
			dash.position = Vector3(x, 0.04, road_z)
			dash.material_override = line_mat
			add_child(dash)
