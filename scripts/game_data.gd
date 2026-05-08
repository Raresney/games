extends Node

var selected_car: int = 0

var cars: Array = [
	{
		"name": "Lamborghini Huracán",
		"color": Color(1.0, 0.78, 0.0, 1),
		"accent": Color(0.05, 0.05, 0.05, 1),
		"engine_force": 1100.0,
		"top_speed": 105.0,
		"max_steer": 0.42,
		"description": "Top Speed: 325 km/h\n0-100 km/h in 2.9s\nEngine: V10 5.2L 640HP",
		# Shape: low, wide, angular
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
		"top_speed": 100.0,
		"max_steer": 0.44,
		"description": "Top Speed: 340 km/h\n0-100 km/h in 2.5s\nEngine: V8 Hybrid 1000HP",
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
		"top_speed": 145.0,
		"max_steer": 0.36,
		"description": "Top Speed: 420 km/h\n0-100 km/h in 2.4s\nEngine: W16 8.0L 1500HP",
		"body_scale": Vector3(1.10, 1.0, 1.15),
		"roof_scale": Vector3(1.0, 1.0, 1.05),
		"hood_low": false,
		"big_spoiler": false,
		"side_skirts": false,
		"twin_exhaust": false,
		"quad_exhaust": true,
	}
]
