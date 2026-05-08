extends Node3D

const CAR_SCENE := preload("res://scenes/car.tscn")

var car_instance: Node = null

func _ready() -> void:
	var car_data: Dictionary = GameData.cars[GameData.selected_car]

	car_instance = CAR_SCENE.instantiate()
	add_child(car_instance)
	car_instance.global_position = $CarSpawn.global_position
	car_instance.setup_from_data(car_data)

	var hud: Node = $HUD
	var task_manager: Node = $TaskManager
	hud.car = car_instance
	hud.task_manager = task_manager

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
