extends Node3D

const CAR_SCENE := preload("res://scenes/car.tscn")
const BASE_FOV: float = 70.0
const MAX_FOV: float = 88.0

var car_instance: VehicleBody3D = null
var camera: Camera3D = null
var cam_pos: Vector3 = Vector3.ZERO
var cam_yaw: float = 0.0
var current_fov: float = BASE_FOV
var shake_t: float = 0.0
var impact_shake: float = 0.0
var prev_speed: float = 0.0

var arrow: MeshInstance3D = null
var task_manager: Node = null

func _ready() -> void:
	var car_data: Dictionary = GameData.cars[GameData.selected_car]
	car_instance = CAR_SCENE.instantiate()
	add_child(car_instance)
	car_instance.global_position = $CarSpawn.global_position
	car_instance.setup_from_data(car_data)
	if car_instance.has_signal("collision_impact"):
		car_instance.collision_impact.connect(_on_collision_impact)

	camera = Camera3D.new()
	camera.fov = BASE_FOV
	camera.near = 0.1
	camera.far = 800.0
	add_child(camera)
	cam_pos = car_instance.global_position + Vector3(0, 3.2, 8.0)
	camera.global_position = cam_pos

	arrow = MeshInstance3D.new()
	var am := PrismMesh.new()
	am.size = Vector3(1.0, 1.2, 1.0)
	arrow.mesh = am
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.0, 1.0, 0.55)
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(0.0, 1.0, 0.55)
	arrow_mat.emission_energy_multiplier = 1.2
	arrow.material_override = arrow_mat
	add_child(arrow)

	var hud: Node = $HUD
	task_manager = $TaskManager
	hud.car = car_instance
	hud.task_manager = task_manager
	if hud.has_method("_on_all_done") and task_manager.has_signal("all_tasks_done"):
		task_manager.all_tasks_done.connect(hud._on_all_done)

func _on_collision_impact(strength: float) -> void:
	impact_shake = max(impact_shake, strength)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	if car_instance == null or camera == null:
		return
	var back_dir: Vector3 = car_instance.global_basis.z
	back_dir.y = 0
	if back_dir.length() < 0.01:
		back_dir = Vector3(0, 0, 1)
	back_dir = back_dir.normalized()
	var offset: Vector3 = back_dir * 7.5 + Vector3(0, 3.2, 0)
	var target_pos: Vector3 = car_instance.global_position + offset
	cam_pos = cam_pos.lerp(target_pos, clamp(delta * 6.5, 0.0, 1.0))
	cam_yaw = atan2(back_dir.x, back_dir.z)

	var spd: float = car_instance.linear_velocity.length()
	prev_speed = spd
	shake_t += delta * (8.0 + spd * 0.4)
	var speed_shake: float = clamp(spd / 80.0, 0.0, 1.0) * 0.04
	# Decay impact shake
	impact_shake = max(0.0, impact_shake - delta * 1.5)
	var total_shake: float = speed_shake + impact_shake * 0.6
	var shake_offset: Vector3 = Vector3(
		sin(shake_t * 1.3) * total_shake,
		sin(shake_t * 1.7) * total_shake * 0.8,
		0.0
	)
	camera.global_position = cam_pos + shake_offset.rotated(Vector3.UP, cam_yaw)

	var look_target: Vector3 = car_instance.global_position + Vector3(0, 1.0, 0)
	camera.look_at(look_target, Vector3.UP)

	# FOV — boost when nitro active for sense of speed
	var nitro_active: bool = Input.is_action_pressed("nitro") and car_instance.nitro > 1.0
	var t: float = clamp(spd / 70.0, 0.0, 1.0)
	var target_fov: float = lerp(BASE_FOV, MAX_FOV, t)
	if nitro_active:
		target_fov += 8.0
	current_fov = lerp(current_fov, target_fov, clamp(delta * 3.0, 0.0, 1.0))
	camera.fov = current_fov

	_update_arrow(delta)

func _update_arrow(_delta: float) -> void:
	if arrow == null or task_manager == null or car_instance == null:
		return
	var idx: int = task_manager.current_task
	var tasks: Array = task_manager.tasks
	if idx >= tasks.size():
		arrow.visible = false
		return
	arrow.visible = true
	var marker_name: String = tasks[idx]["marker"]
	var marker := task_manager.get_node_or_null(marker_name)
	if marker == null:
		return
	var bob: float = sin(Time.get_ticks_msec() * 0.004) * 0.25
	var car_pos: Vector3 = car_instance.global_position
	arrow.global_position = car_pos + Vector3(0, 4.5 + bob, 0)
	var to_marker: Vector3 = marker.global_position - car_pos
	to_marker.y = 0
	if to_marker.length() < 0.1:
		return
	var yaw: float = atan2(to_marker.x, to_marker.z)
	arrow.rotation = Vector3(PI, yaw, 0.0)
