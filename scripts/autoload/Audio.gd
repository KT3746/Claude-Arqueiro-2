extends Node
## Efeitos sonoros do jogo — todos sintetizados em código na hora que o jogo
## abre (nenhum arquivo de áudio externo). Um pool de AudioStreamPlayer toca
## os sons sem cortar uns aos outros.

const MIX_RATE := 22050
const POOL_SIZE := 10

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_sounds()

func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not _streams.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	p.stream = _streams[sound_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale * randf_range(0.96, 1.04)
	p.play()

func _build_sounds() -> void:
	_streams["draw"] = _make_draw()
	_streams["release"] = _make_release()
	_streams["impact_wood"] = _make_impact(480.0, 0.11, 0.35)
	_streams["impact_flesh"] = _make_impact(180.0, 0.14, 0.3)
	_streams["bullseye"] = _make_bullseye()
	_streams["enemy_death"] = _make_enemy_death()
	_streams["click"] = _make_click()
	_streams["footstep"] = _make_impact(90.0, 0.07, 0.6)
	_streams["wave_start"] = _make_wave_start()
	_streams["damage"] = _make_impact(140.0, 0.18, 0.45)

# ---------------------------------------------------------------------------
# Geração de formas de onda simples — sem depender de nenhum asset de áudio.
# ---------------------------------------------------------------------------

func _lowpass(samples: PackedFloat32Array, alpha: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(samples.size())
	var prev: float = 0.0
	for i in range(samples.size()):
		prev += alpha * (samples[i] - prev)
		out[i] = prev
	return out

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: float = clamp(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	stream.data = bytes
	return stream

func _make_draw() -> AudioStreamWAV:
	var dur: float = 0.32
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		raw[i] = randf_range(-1.0, 1.0) * t * 0.5
	return _make_stream(_lowpass(raw, 0.15))

func _make_release() -> AudioStreamWAV:
	var dur: float = 0.35
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	var freq: float = 180.0
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var decay: float = exp(-t * 14.0)
		var tone: float = sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 2.01 * t) * 0.25 + sin(TAU * freq * 3.0 * t) * 0.15
		var transient: float = randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.6
		raw[i] = (tone * decay + transient) * 0.8
	return _make_stream(raw)

func _make_impact(base_freq: float, dur: float, noise_amt: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var decay: float = exp(-t / (dur * 0.28))
		var thump: float = sin(TAU * base_freq * t) * decay
		var noise: float = randf_range(-1.0, 1.0) * decay * noise_amt
		raw[i] = thump * 0.7 + noise
	return _make_stream(_lowpass(raw, 0.5))

func _make_bullseye() -> AudioStreamWAV:
	var dur: float = 0.4
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	var f1: float = 880.0
	var f2: float = 1108.0
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var decay: float = exp(-t * 7.0)
		raw[i] = (sin(TAU * f1 * t) * 0.5 + sin(TAU * f2 * t) * 0.35) * decay
	return _make_stream(raw)

func _make_enemy_death() -> AudioStreamWAV:
	var dur: float = 0.5
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var prog: float = float(i) / n
		var freq: float = lerp(500.0, 90.0, prog)
		var decay: float = exp(-prog * 3.5)
		var tone: float = sin(TAU * freq * t) * 0.4
		var noise: float = randf_range(-1.0, 1.0) * 0.3 * decay
		raw[i] = tone * decay + noise
	return _make_stream(_lowpass(raw, 0.35))

func _make_click() -> AudioStreamWAV:
	var dur: float = 0.04
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		raw[i] = randf_range(-1.0, 1.0) * (1.0 - t) * 0.5
	return _make_stream(raw)

func _make_wave_start() -> AudioStreamWAV:
	var dur: float = 0.6
	var n: int = int(MIX_RATE * dur)
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var prog: float = float(i) / n
		var freq: float = lerp(220.0, 330.0, clamp(prog * 2.0, 0.0, 1.0))
		var env: float = sin(PI * prog)
		raw[i] = sin(TAU * freq * t) * env * 0.6 + sin(TAU * freq * 0.5 * t) * env * 0.2
	return _make_stream(raw)
