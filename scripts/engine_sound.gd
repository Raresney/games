extends AudioStreamPlayer3D

var _phase: float = 0.0
var _playback: AudioStreamGeneratorPlayback = null
@export var car_path: NodePath
var car: VehicleBody3D = null

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.1
	stream = gen
	unit_size = 6.0
	max_db = 6.0
	play()
	_playback = get_stream_playback()
	if car_path:
		car = get_node_or_null(car_path)
	if car == null:
		car = get_parent() as VehicleBody3D

func _process(_delta: float) -> void:
	if _playback == null or car == null:
		return
	var speed: float = car.linear_velocity.length()
	var throttle: float = Input.get_axis("brake", "accelerate")
	var rpm: float = clamp(speed / 30.0, 0.0, 1.0)
	var base_freq: float = 65.0 + rpm * 220.0 + (1.0 if throttle > 0.0 else 0.0) * 30.0
	var sample_rate: float = 22050.0
	var frames: int = _playback.get_frames_available()
	for i in frames:
		_phase += base_freq / sample_rate
		if _phase > 1.0:
			_phase -= 1.0
		# saw + slight noise for engine grit
		var saw: float = (_phase * 2.0 - 1.0) * 0.6
		var sub: float = sin(_phase * TAU * 0.5) * 0.3
		var noise: float = (randf() - 0.5) * 0.15 * (0.4 + rpm)
		var sample: float = (saw + sub + noise) * (0.35 + rpm * 0.55)
		_playback.push_frame(Vector2(sample, sample))
