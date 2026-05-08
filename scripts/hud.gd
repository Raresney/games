extends CanvasLayer

var car: Node = null
var task_manager: Node = null

@onready var speed_label: Label = $SpeedPanel/V/SpeedLabel
@onready var speed_bar: ProgressBar = $SpeedPanel/V/SpeedBar
@onready var task_label: Label = $TaskPanel/V/TaskLabel
@onready var score_label: Label = $TaskPanel/V/ScoreLabel
@onready var car_label: Label = $SpeedPanel/V/CarLabel

func _ready() -> void:
	car_label.text = GameData.cars[GameData.selected_car]["name"]

func _process(_delta: float) -> void:
	if car:
		var s: int = int(car.speed_kmh)
		speed_label.text = str(s)
		speed_bar.value = s
	if task_manager:
		task_label.text = "▶  " + task_manager.get_task_text()
		score_label.text = "Score:  $" + str(task_manager.score)
