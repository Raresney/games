extends AudioStreamPlayer3D

var _phase: float = 0.0
var _phase2: float = 0.0
var _phase3: float = 0.0
var _playback: AudioStreamGeneratorPlayback = null
var car: VehicleBody3D = null
const SR: float = 22050.0

var prev_throttle: float = 0.0
var pop_cooldown: float = 0.0

# Per-sample pop scheduling for sharp clicks
const POP_LEN_SAMPLES: int = 800     # 36ms each — short crack
const POP_INTERVAL_SAMPLES: int = 1700  # 77ms between
var current_pop_pos: int = 0   # 0 = not playing; otherwise samples processed in current pop
var pops_remaining: int = 0
var samples_until_next_pop: int = 0

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SR
	gen.buffer_length = 0.05
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

	# Trigger pop sequence on throttle release (only once per release)
	if prev_throttle > 0.5 and throttle <= 0.0 and speed > 8.0 and pop_cooldown <= 0.0:
		pops_remaining = 5 + int(rpm * 3)  # 5-8 pops
		samples_until_next_pop = 0  # first pop starts immediately
		current_pop_pos = 0
		pop_cooldown = 0.8
	prev_throttle = throttle
	pop_cooldown = max(0.0, pop_cooldown - delta)

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

		# Pop generator — sharp transient
		if current_pop_pos > 0 or samples_until_next_pop == 0 and pops_remaining > 0:
			# If just fired
			if current_pop_pos == 0 and pops_remaining > 0 and samples_until_next_pop == 0:
				current_pop_pos = 1
				pops_remaining -= 1
				samples_until_next_pop = POP_INTERVAL_SAMPLES
		if current_pop_pos > 0:
			# Sharp exponential decay envelope
			var t_in_pop: float = float(current_pop_pos) / float(POP_LEN_SAMPLES)
			# Attack first 5% then exponential decay
			var env: float = 0.0
			if t_in_pop < 0.05:
				env = t_in_pop / 0.05
			else:
				env = exp(-(t_in_pop - 0.05) * 10.0)
			# Bright crack: very short noise blasted hard then low thump
			var crack: float = (randf() - 0.5) * 2.6 * env
			var thump: float = sin(t_in_pop * PI) * 1.4 * env
			var pop_sample: float = clamp(crack + thump, -1.0, 1.0)
			# Replace the engine sample during pop (don't add — pop dominates for sharp click)
			sample = sample * 0.3 + pop_sample
			current_pop_pos += 1
			if current_pop_pos > POP_LEN_SAMPLES:
				current_pop_pos = 0
		elif samples_until_next_pop > 0:
			samples_until_next_pop -= 1

		_playback.push_frame(Vector2(clamp(sample, -1.0, 1.0), clamp(sample, -1.0, 1.0)))
