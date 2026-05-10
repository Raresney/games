extends Control

@onready var grid: GridContainer = $Scroll/Grid
@onready var money_label: Label = $MoneyLabel
@onready var car_label: Label = $CarLabel
var selected_car: int = 0

func _ready() -> void:
	selected_car = GameData.selected_car
	$BackBtn.pressed.connect(_back)
	$CarRow/PrevCar.pressed.connect(_prev_car)
	$CarRow/NextCar.pressed.connect(_next_car)
	_refresh()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _prev_car() -> void:
	selected_car = (selected_car - 1 + GameData.cars.size()) % GameData.cars.size()
	GameData.selected_car = selected_car
	_refresh()

func _next_car() -> void:
	selected_car = (selected_car + 1) % GameData.cars.size()
	GameData.selected_car = selected_car
	_refresh()

func _refresh() -> void:
	money_label.text = "💰  $" + str(GameData.money)
	car_label.text = GameData.cars[selected_car]["name"]
	for c in grid.get_children():
		c.queue_free()
	for i in GameData.COLOR_SHOP.size():
		var entry: Dictionary = GameData.COLOR_SHOP[i]
		var card := _make_card(i, entry)
		grid.add_child(card)

func _make_card(idx: int, entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 1)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.2, 0.85, 1.0, 0.5)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(220, 200)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)

	var swatch := ColorRect.new()
	swatch.color = entry["color"]
	swatch.custom_minimum_size = Vector2(0, 90)
	v.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text = entry["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	v.add_child(name_lbl)

	var unlocked: bool = GameData.is_color_unlocked(selected_car, idx)
	var equipped: bool = GameData.custom_colors[selected_car] == idx or (idx == 0 and GameData.custom_colors[selected_car] == -1)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 36)
	if equipped:
		btn.text = "✔  EQUIPPED"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
	elif unlocked:
		btn.text = "EQUIP"
		btn.pressed.connect(func(): _equip(idx))
	else:
		btn.text = "BUY  $" + str(entry["price"])
		if GameData.money < entry["price"]:
			btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		btn.pressed.connect(func(): _buy(idx))
	v.add_child(btn)
	return card

func _buy(idx: int) -> void:
	if GameData.unlock_color(selected_car, idx):
		_equip(idx)

func _equip(idx: int) -> void:
	GameData.custom_colors[selected_car] = idx
	GameData.save_data()
	_refresh()
