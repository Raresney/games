extends Control

var selected: int = 0

@onready var car_name: Label = $LeftPanel/V/CarName
@onready var car_desc: Label = $LeftPanel/V/CarDesc
@onready var car_preview: ColorRect = $LeftPanel/V/Preview
@onready var counter: Label = $LeftPanel/V/Counter
@onready var money_label: Label = $MoneyLabel
@onready var prev_btn: Button = $LeftPanel/V/NavRow/PrevBtn
@onready var next_btn: Button = $LeftPanel/V/NavRow/NextBtn
@onready var play_btn: Button = $LeftPanel/V/PlayBtn
@onready var grid: GridContainer = $RightPanel/V/Scroll/Grid

func _ready() -> void:
	selected = GameData.selected_car
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	_update()

func _update() -> void:
	var data: Dictionary = GameData.cars[selected]
	car_name.text = data["name"]
	car_desc.text = data["description"]
	car_preview.color = GameData.get_active_color(selected)
	counter.text = str(selected + 1) + " / " + str(GameData.cars.size())
	GameData.selected_car = selected
	money_label.text = "💰  $" + str(GameData.money)
	_rebuild_color_grid()

func _rebuild_color_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in GameData.COLOR_SHOP.size():
		var entry: Dictionary = GameData.COLOR_SHOP[i]
		grid.add_child(_make_color_card(i, entry))

func _make_color_card(idx: int, entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 1)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.18, 0.45, 0.7, 0.6)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(220, 90)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)

	var swatch := ColorRect.new()
	swatch.color = entry["color"]
	swatch.custom_minimum_size = Vector2(0, 32)
	v.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text = entry["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	v.add_child(name_lbl)

	var unlocked: bool = GameData.is_color_unlocked(selected, idx)
	var equipped: bool = (GameData.custom_colors[selected] == idx) or (idx == 0 and GameData.custom_colors[selected] == -1)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 26)
	btn.add_theme_font_size_override("font_size", 12)
	if equipped:
		btn.text = "✔ EQUIPPED"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
	elif unlocked:
		btn.text = "EQUIP"
		btn.pressed.connect(func(): _equip(idx))
	else:
		btn.text = "$" + str(entry["price"])
		if GameData.money < entry["price"]:
			btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		btn.pressed.connect(func(): _buy(idx))
	v.add_child(btn)
	return card

func _buy(idx: int) -> void:
	if GameData.unlock_color(selected, idx):
		_equip(idx)

func _equip(idx: int) -> void:
	GameData.custom_colors[selected] = idx
	GameData.save_data()
	_update()

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
