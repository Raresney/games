extends Node

var selected_car: int = 0

var cars: Array = [
	{
		"name": "Lamborghini Huracán",
		"color": Color(1.0, 0.75, 0.0, 1),
		"engine_force": 350.0,
		"top_speed": 72.0,
		"max_steer": 0.40,
		"description": "Top Speed: 260 km/h\n0-100 km/h in 3.2s\nEngine: V10 5.2L"
	},
	{
		"name": "Ferrari SF90",
		"color": Color(0.9, 0.05, 0.05, 1),
		"engine_force": 320.0,
		"top_speed": 68.0,
		"max_steer": 0.43,
		"description": "Top Speed: 250 km/h\n0-100 km/h in 3.5s\nEngine: V8 Hybrid"
	},
	{
		"name": "Bugatti Chiron",
		"color": Color(0.05, 0.1, 0.75, 1),
		"engine_force": 420.0,
		"top_speed": 110.0,
		"max_steer": 0.37,
		"description": "Top Speed: 420 km/h\n0-100 km/h in 2.4s\nEngine: W16 8.0L"
	}
]
