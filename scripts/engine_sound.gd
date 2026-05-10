extends AudioStreamPlayer3D

var _phase: float = 0.0
var _phase2: float = 0.0
var _phase3: float = 0.0
var _playback: AudioStreamGeneratorPlayback = null
var car: VehicleBody3D = null
const SR: float = 22050.0

var prev_throttle: float = 0.0
var pop_timer: float = 0.0   # how long to keep firing pops
var pop_cooldown: float = 0.0

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SR
	gen.buffer_length = 0.1
	stream = gen
	unit_size = 18.0
	max_db = 12.0
	max_distance = 80.0
	play()
	_playback = get_stream_playback()
	car = get_parent() as VehicleBody3D

func _process(delta: float) -> void:
	if _playback == null or car == null:
		return
	var speed: float = car.linear_velocity.length()
	var throttle: float = Input.get_axis("brake", "accelerate")
	var rpm: float = clamp(speed / 35.0, 0.05, 1.0)
	# Detect throttle release at speed → trigger backfire pops
	if prev_throttle > 0.5 and throttle <= 0.0 and speed > 8.0 and pop_cooldown <= 0.0:
		pop_timer = 0.45  # pop sequence duration
		pop_cooldown = 1.0
	prev_throttle = throttle
	pop_cooldown = max(0.0, pop_cooldown - delta)
	pop_timer = max(0.0, pop_timer - delta)

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
		var pulse: float = pow(max(s1, 0.0), 1.5 + (1.0 - load) * 2.0)
		var rumble: float = (randf() - 0.5) * 0.18 * load
		var sample: float = (pulse * 0.7 + s2 * 0.3 + s3 * 0.2 + rumble) * (0.25 + load * 0.45)
		# Backfire pop bursts — random sharp loud noise during pop window
		if pop_timer > 0.0:
			# Sharp distinct pop hits (~10-12 per second), HARD CLIPPED for crack
			if randf() < 0.005:
				var pop: float = (randf() - 0.5) * 4.0
				sample += clamp(pop, -1.0, 1.0)
			# Sustained crackle (machine-gun style)
			sample += clamp((randf() - 0.5) * 1.4 * (pop_timer / 0.45), -1.0, 1.0)
			# Low boom thump under the crackle
			sample += sin(_phase * TAU * 0.35) * 0.4 * (pop_timer / 0.45)
		_playback.push_frame(Vector2(sample, sample))
