extends CanvasLayer

var car: Node = null
var task_manager: Node = null

@onready var speed_label: Label = $Panel/VBox/SpeedLabel
@onready var task_label: Label = $Panel/VBox/TaskLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var car_label: Label = $Panel/VBox/CarLabel
@onready var controls_label: Label = $ControlsLabel

func _ready() -> void:
	car_label.text = GameData.cars[GameData.selected_car]["name"]
	controls_label.text = "W/S — Accelerate/Brake    A/D — Steer    SPACE — Handbrake    ESC — Menu"

func _process(_delta: float) -> void:
	if car:
		speed_label.text = str(int(car.speed_kmh)) + " km/h"
	if task_manager:
		task_label.text = "▶  " + task_manager.get_task_text()
		score_label.text = "Score:  $" + str(task_manager.score)
