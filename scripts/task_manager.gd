extends Node3D

signal task_completed(index: int)
signal all_tasks_done

var current_task: int = 0
var score: int = 0
var task_start_time: float = 0.0

var tasks: Array = [
	{"text": "Drive to the Gas Station",       "marker": "Marker1", "reward": 500,  "time_bonus": 25.0},
	{"text": "Speed Run to the City Hall",     "marker": "Marker2", "reward": 750,  "time_bonus": 30.0},
	{"text": "Reach the Police Station fast",  "marker": "Marker3", "reward": 1000, "time_bonus": 35.0},
	{"text": "Deliver to the Hospital",        "marker": "Marker4", "reward": 800,  "time_bonus": 28.0},
	{"text": "Highway Run — North Tower",      "marker": "Marker5", "reward": 1200, "time_bonus": 40.0},
	{"text": "South District Sprint",          "marker": "Marker6", "reward": 1300, "time_bonus": 38.0},
	{"text": "East Industrial Drop-off",       "marker": "Marker7", "reward": 1500, "time_bonus": 42.0},
	{"text": "Final Run — Return to Start!",   "marker": "Marker8", "reward": 2500, "time_bonus": 50.0},
]

func _ready() -> void:
	_activate_marker(0)
	task_start_time = Time.get_ticks_msec() / 1000.0

func _activate_marker(index: int) -> void:
	for i in tasks.size():
		var mname: String = tasks[i]["marker"]
		if has_node(mname):
			get_node(mname).visible = (i == index)
	task_start_time = Time.get_ticks_msec() / 1000.0

func get_remaining_time() -> float:
	if current_task >= tasks.size():
		return 0.0
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - task_start_time
	var limit: float = tasks[current_task]["time_bonus"]
	return max(0.0, limit - elapsed)

func on_marker_reached(index: int) -> void:
	if index != current_task:
		return
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - task_start_time
	var time_limit: float = tasks[current_task]["time_bonus"]
	var bonus: int = 0
	if elapsed < time_limit:
		# proportional bonus, max +100% at 0s, 0 at limit
		var ratio: float = clamp(1.0 - elapsed / time_limit, 0.0, 1.0)
		bonus = int(tasks[current_task]["reward"] * ratio)
	score += tasks[current_task]["reward"] + bonus
	task_completed.emit(current_task)
	current_task += 1
	if current_task >= tasks.size():
		all_tasks_done.emit()
		_hide_all_markers()
	else:
		_activate_marker(current_task)

func _hide_all_markers() -> void:
	for t in tasks:
		var mname: String = t["marker"]
		if has_node(mname):
			get_node(mname).visible = false

func get_task_text() -> String:
	if current_task < tasks.size():
		var rem: float = get_remaining_time()
		return "%s   ⏱ %.1fs" % [tasks[current_task]["text"], rem]
	return "🏆 ALL TASKS COMPLETE — Final Score: $" + str(score)
