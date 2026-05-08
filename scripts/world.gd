extends Node3D

const CAR_SCENE := preload("res://scenes/car.tscn")
const BASE_FOV: float = 70.0
const MAX_FOV: float = 84.0

var car_instance: VehicleBody3D = null
var camera: Camera3D = null
var cam_pos: Vector3 = Vector3.ZERO
var cam_yaw: float = 0.0
var current_fov: float = BASE_FOV

func _ready() -> void:
	var car_data: Dictionary = GameData.cars[GameData.selected_car]
	car_instance = CAR_SCENE.instantiate()
	add_child(car_instance)
	car_instance.global_position = $CarSpawn.global_position
	car_instance.setup_from_data(car_data)

	camera = Camera3D.new()
	camera.fov = BASE_FOV
	camera.near = 0.1
	camera.far = 800.0
	add_child(camera)
	cam_pos = car_instance.global_position + Vector3(0, 3.2, 8.0)
	camera.global_position = cam_pos

	var hud: Node = $HUD
	hud.car = car_instance
	hud.task_manager = $TaskManager

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _physics_process(delta: float) -> void:
	if car_instance == null or camera == null:
		return
	# Smooth follow — only car yaw, ignore body roll/pitch jitter
	var car_yaw: float = car_instance.global_rotation.y
	cam_yaw = lerp_angle(cam_yaw, car_yaw, clamp(delta * 4.0, 0.0, 1.0))
	var offset: Vector3 = Vector3(0, 3.2, 8.0).rotated(Vector3.UP, cam_yaw)
	var target_pos: Vector3 = car_instance.global_position + offset
	cam_pos = cam_pos.lerp(target_pos, clamp(delta * 6.5, 0.0, 1.0))
	camera.global_position = cam_pos
	var look_target: Vector3 = car_instance.global_position + Vector3(0, 1.0, 0)
	camera.look_at(look_target, Vector3.UP)
	# Speed-based FOV — feel of speed
	var spd: float = car_instance.linear_velocity.length()
	var t: float = clamp(spd / 60.0, 0.0, 1.0)
	var target_fov: float = lerp(BASE_FOV, MAX_FOV, t)
	current_fov = lerp(current_fov, target_fov, clamp(delta * 3.0, 0.0, 1.0))
	camera.fov = current_fov
