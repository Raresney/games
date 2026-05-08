extends AudioStreamPlayer3D

var _phase: float = 0.0
var _phase2: float = 0.0
var _phase3: float = 0.0
var _playback: AudioStreamGeneratorPlayback = null
var car: VehicleBody3D = null
const SR: float = 22050.0

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SR
	gen.buffer_length = 0.1
	stream = gen
	unit_size = 8.0
	max_db = 4.0
	play()
	_playback = get_stream_playback()
	car = get_parent() as VehicleBody3D

func _process(_delta: float) -> void:
	if _playback == null or car == null:
		return
	var speed: float = car.linear_velocity.length()
	var throttle: float = Input.get_axis("brake", "accelerate")
	var rpm: float = clamp(speed / 35.0, 0.05, 1.0)
	# V8/V10 firing fundamental
	var f1: float = 45.0 + rpm * 180.0
	var f2: float = f1 * 2.0
	var f3: float = f1 * 3.0
	var load: float = 0.4 + max(throttle, 0.0) * 0.5 + rpm * 0.4
	var frames: int = _playback.get_frames_available()
	for i in frames:
		_phase += f1 / SR
		_phase2 += f2 / SR
		_phase3 += f3 / SR
		if _phase > 1.0: _phase -= 1.0
		if _phase2 > 1.0: _phase2 -= 1.0
		if _phase3 > 1.0: _phase3 -= 1.0
		var s1: float = sin(_phase * TAU)
		var s2: float = sin(_phase2 * TAU) * 0.55
		var s3: float = sin(_phase3 * TAU) * 0.3
		# pulse/firing shape — sharper at high load
		var pulse: float = pow(max(s1, 0.0), 1.5 + (1.0 - load) * 2.0)
		var rumble: float = (randf() - 0.5) * 0.18 * load
		var sample: float = (pulse * 0.7 + s2 * 0.3 + s3 * 0.2 + rumble) * (0.25 + load * 0.45)
		_playback.push_frame(Vector2(sample, sample))
