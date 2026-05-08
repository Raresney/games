extends Control

var selected: int = 0

@onready var car_name: Label = $VBox/CarName
@onready var car_desc: Label = $VBox/CarDesc
@onready var car_preview: ColorRect = $VBox/Preview
@onready var counter: Label = $VBox/Counter

func _ready() -> void:
	selected = GameData.selected_car
	_update()

func _update() -> void:
	var data: Dictionary = GameData.cars[selected]
	car_name.text = data["name"]
	car_desc.text = data["description"]
	car_preview.color = data["color"]
	counter.text = str(selected + 1) + " / " + str(GameData.cars.size())
	GameData.selected_car = selected

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_play_pressed()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_on_prev_pressed()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_on_next_pressed()

func _on_prev_pressed() -> void:
	selected = (selected - 1 + GameData.cars.size()) % GameData.cars.size()
	_update()

func _on_next_pressed() -> void:
	selected = (selected + 1) % GameData.cars.size()
	_update()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
