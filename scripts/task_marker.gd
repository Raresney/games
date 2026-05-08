extends Area3D

@export var marker_index: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		var tm := get_parent()
		if tm.has_method("on_marker_reached"):
			tm.on_marker_reached(marker_index)
