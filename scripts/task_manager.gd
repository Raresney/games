extends Node3D

signal task_completed(index: int)
signal all_tasks_done

var current_task: int = 0
var score: int = 0

var tasks: Array = [
	{"text": "Drive to the Gas Station",   "marker": "Marker1", "reward": 500},
	{"text": "Reach the City Hall",         "marker": "Marker2", "reward": 750},
	{"text": "Go to the Police Station",    "marker": "Marker3", "reward": 1000},
	{"text": "Deliver to the Hospital",     "marker": "Marker4", "reward": 800},
	{"text": "Return to Start — Finish!",   "marker": "Marker5", "reward": 2000},
]

func _ready() -> void:
	_activate_marker(0)

func _activate_marker(index: int) -> void:
	for i in tasks.size():
		var mname: String = tasks[i]["marker"]
		if has_node(mname):
			get_node(mname).visible = (i == index)

func on_marker_reached(index: int) -> void:
	if index != current_task:
		return
	score += tasks[current_task]["reward"]
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
		return tasks[current_task]["text"]
	return "All tasks complete! Score: $" + str(score)
