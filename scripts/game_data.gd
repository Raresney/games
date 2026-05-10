extends Node

const SAVE_PATH: String = "user://save.cfg"

var selected_car: int = 0
var money: int = 0
var unlocked_colors: Array = [0, 0, 0]   # default color index for each car
var custom_colors: Array = [-1, -1, -1]  # -1 = default, else index into COLOR_SHOP

const COLOR_SHOP: Array = [
	{"name": "Stock",          "color": Color.WHITE,                  "price": 0},
	{"name": "Crimson Red",    "color": Color(0.85, 0.05, 0.08),      "price": 1500},
	{"name": "Midnight Blue",  "color": Color(0.04, 0.1, 0.45),       "price": 1500},
	{"name": "Forest Green",   "color": Color(0.05, 0.4, 0.18),       "price": 2000},
	{"name": "Pearl White",    "color": Color(0.95, 0.95, 0.98),      "price": 2500},
	{"name": "Carbon Black",   "color": Color(0.04, 0.04, 0.06),      "price": 3000},
	{"name": "Solar Orange",   "color": Color(1.0, 0.45, 0.05),       "price": 3500},
	{"name": "Electric Cyan",  "color": Color(0.0, 0.85, 1.0),        "price": 5000},
	{"name": "Magenta Glow",   "color": Color(1.0, 0.1, 0.85),        "price": 5500},
	{"name": "Chrome Silver",  "color": Color(0.85, 0.86, 0.92),      "price": 7500},
	{"name": "Gold Plate",     "color": Color(1.0, 0.85, 0.2),        "price": 12000},
]

var cars: Array = [
	{
		"name": "Lamborghini Huracán",
		"color": Color(1.0, 0.78, 0.0, 1),
		"accent": Color(0.05, 0.05, 0.05, 1),
		"engine_force": 1100.0,
		"top_speed": 65.0,
		"max_steer": 0.42,
		"description": "Top Speed: 235 km/h\n0-100 km/h in 2.9s\nEngine: V10 5.2L 640HP",
		"body_scale": Vector3(1.06, 0.85, 1.05),
		"roof_scale": Vector3(0.95, 0.85, 1.05),
		"hood_low": true,
		"big_spoiler": false,
		"side_skirts": true,
		"twin_exhaust": false,
		"quad_exhaust": true,
	},
	{
		"name": "Ferrari SF90 Stradale",
		"color": Color(0.88, 0.04, 0.04, 1),
		"accent": Color(0.05, 0.05, 0.05, 1),
		"engine_force": 1050.0,
		"top_speed": 62.0,
		"max_steer": 0.44,
		"description": "Top Speed: 225 km/h\n0-100 km/h in 2.5s\nEngine: V8 Hybrid 1000HP",
		"body_scale": Vector3(1.02, 0.95, 1.08),
		"roof_scale": Vector3(0.93, 0.95, 1.0),
		"hood_low": true,
		"big_spoiler": true,
		"side_skirts": true,
		"twin_exhaust": true,
		"quad_exhaust": false,
	},
	{
		"name": "Bugatti Chiron",
		"color": Color(0.04, 0.12, 0.55, 1),
		"accent": Color(0.55, 0.45, 0.05, 1),
		"engine_force": 1500.0,
		"top_speed": 70.0,
		"max_steer": 0.36,
		"description": "Top Speed: 250 km/h\n0-100 km/h in 2.4s\nEngine: W16 8.0L 1500HP",
		"body_scale": Vector3(1.10, 1.0, 1.15),
		"roof_scale": Vector3(1.0, 1.0, 1.05),
		"hood_low": false,
		"big_spoiler": false,
		"side_skirts": false,
		"twin_exhaust": false,
		"quad_exhaust": true,
	}
]

func _ready() -> void:
	load_data()

func _exit_tree() -> void:
	save_data()

func get_active_color(car_index: int) -> Color:
	var custom_idx: int = custom_colors[car_index]
	if custom_idx >= 0 and custom_idx < COLOR_SHOP.size():
		return COLOR_SHOP[custom_idx]["color"]
	return cars[car_index]["color"]

func is_color_unlocked(car_index: int, color_index: int) -> bool:
	if color_index == 0:
		return true
	var key: String = "%d_%d" % [car_index, color_index]
	return _unlocked.has(key)

func unlock_color(car_index: int, color_index: int) -> bool:
	var price: int = COLOR_SHOP[color_index]["price"]
	if money < price:
		return false
	money -= price
	_unlocked["%d_%d" % [car_index, color_index]] = true
	save_data()
	return true

var _unlocked: Dictionary = {}

func add_money(amount: int) -> void:
	money += amount
	save_data()

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "money", money)
	cfg.set_value("game", "selected_car", selected_car)
	cfg.set_value("game", "custom_colors", custom_colors)
	cfg.set_value("game", "unlocked", _unlocked)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	money = cfg.get_value("game", "money", 0)
	selected_car = cfg.get_value("game", "selected_car", 0)
	custom_colors = cfg.get_value("game", "custom_colors", [-1, -1, -1])
	_unlocked = cfg.get_value("game", "unlocked", {})
