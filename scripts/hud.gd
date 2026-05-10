extends CanvasLayer

var car: Node = null
var task_manager: Node = null

@onready var speed_label: Label = $SpeedPanel/V/SpeedLabel
@onready var speed_bar: ProgressBar = $SpeedPanel/V/SpeedBar
@onready var nitro_bar: ProgressBar = $SpeedPanel/V/NitroBar
@onready var gear_label: Label = $SpeedPanel/V/GearLabel
@onready var task_label: Label = $TaskPanel/V/TaskLabel
@onready var score_label: Label = $TaskPanel/V/ScoreLabel
@onready var car_label: Label = $SpeedPanel/V/CarLabel
@onready var drift_score_label: Label = $DriftPanel/V/DriftScore
@onready var drift_combo: ProgressBar = $DriftPanel/V/DriftCombo
@onready var drift_panel: PanelContainer = $DriftPanel
@onready var end_screen: PanelContainer = $EndScreen
@onready var end_score: Label = $EndScreen/V/FinalScore
@onready var end_drift: Label = $EndScreen/V/DriftFinal

func _ready() -> void:
	car_label.text = GameData.cars[GameData.selected_car]["name"]
	end_screen.visible = false
	if task_manager:
		task_manager.all_tasks_done.connect(_on_all_done)

func _process(_delta: float) -> void:
	if car:
		var s: int = int(car.speed_kmh)
		speed_label.text = str(s)
		speed_bar.value = s
		nitro_bar.value = car.nitro
		drift_score_label.text = str(car.drift_score)
		drift_combo.value = car.drift_combo
		# Gear + transmission mode
		var mode_tag: String = "[M]" if car.manual_mode else "[A]"
		var gear_str: String = ""
		if car.current_gear == -1:
			gear_str = "R"
		elif car.current_gear == 0:
			gear_str = "N"
		else:
			gear_str = str(car.current_gear)
		gear_label.text = mode_tag + "  GEAR  " + gear_str
		gear_label.modulate = Color(1.0, 0.5, 0.3) if car.manual_mode else Color(0.2, 1.0, 0.45)
		# Pulse drift panel when actively drifting
		if car.is_drifting:
			drift_panel.modulate = Color(1.0, 0.6, 1.0, 1)
		else:
			drift_panel.modulate = Color(1, 1, 1, 1)
	if task_manager:
		task_label.text = "▶  " + task_manager.get_task_text()
		var rem: float = task_manager.get_remaining_time()
		if rem < 5.0 and rem > 0.0:
			task_label.modulate = Color(1.0, 0.4, 0.4)
		else:
			task_label.modulate = Color(1, 1, 1)
		var total: int = task_manager.score + (car.drift_score if car else 0)
		score_label.text = "Score:  $" + str(total)

func _on_all_done() -> void:
	end_screen.visible = true
	if car:
		end_drift.text = "Drift Score:  " + str(car.drift_score)
	if task_manager:
		end_score.text = "Race Score:  $" + str(task_manager.score)
