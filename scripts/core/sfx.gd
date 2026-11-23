extends Node
## Procedural sound effects, so the game ships without audio files. Every sound is built from soft
## bell and pluck tones tuned to one scale (A minor pentatonic, which sits inside the keys of all
## three music loops), so effects that overlap sound like notes of one instrument, not like noise.
## Crystals climb the scale while you keep collecting; the wand cycles through a four-note figure.
## Streams are synthesised on a worker thread (in headless runs: at once, so CI executes the code).

const RATE := 22050
# MIDI notes: A5 C6 D6 E6 G6 A6 C7 D7, and E5 G5 A5 G5.
const GEM := [81, 84, 86, 88, 91, 93, 96, 98]
const WAND := [76, 79, 81, 79]
# Long sounds get their own players so quick ones cannot cut them off.
const LONG := ["level", "boss_down", "patronus"]

var enabled := true
var _players: Array = []
var _long: Array = []
var _streams := {}
var _last := {}
var _next := 0
var _next_long := 0
var _gem_i := 0
var _gem_at := 0
var _wand_i := 0
var _thread: Thread = null
var _mutex := Mutex.new()
var _buf := PackedFloat32Array()


func _ready() -> void:
    for i in 6:
        var p := AudioStreamPlayer.new()
        p.volume_db = -9.0
        add_child(p)
        _players.append(p)
    for i in 2:
        var q := AudioStreamPlayer.new()
        q.volume_db = -7.0
        add_child(q)
        _long.append(q)
    if DisplayServer.get_name() == "headless":
        _build()
    else:
        _thread = Thread.new()
        _thread.start(_build)


func _exit_tree() -> void:
    if _thread != null and _thread.is_started():
        _thread.wait_to_finish()


func play(id: String) -> void:
    if not enabled or id == "":
        return
    var now: int = Time.get_ticks_msec()
    if now - int(_last.get(id, -1000)) < 70:
        return
    _last[id] = now
    var key: String = id
    if id == "gem":
        # A pause resets the run; otherwise each crystal sounds one step higher.
        if now - _gem_at > 1100:
            _gem_i = 0
        _gem_at = now
        key = "gem%d" % _gem_i
        _gem_i = (_gem_i + 1) % GEM.size()
    elif id == "wand":
        key = "wand%d" % _wand_i
        _wand_i = (_wand_i + 1) % WAND.size()
    _mutex.lock()
    var stream = _streams.get(key)
    _mutex.unlock()
    if stream == null:
        return
    var p: AudioStreamPlayer = null
    if id in LONG:
        p = _long[_next_long]
        _next_long = (_next_long + 1) % _long.size()
    else:
        p = _players[_next]
        _next = (_next + 1) % _players.size()
    p.stream = stream
    p.play()


# ---------------------------------------------------------------- the sounds

func _build() -> void:
    for i in GEM.size():
        _begin(0.17)
        _bell(0.0, float(GEM[i]), 0.17, 0.3, 0.5, 26.0)
        _store("gem%d" % i)
    for i in WAND.size():
        _begin(0.12)
        _bell(0.0, float(WAND[i]), 0.12, 0.2, 0.9, 36.0)
        _bell(0.0, float(WAND[i]) + 12.0, 0.06, 0.07, 0.0, 60.0)
        _store("wand%d" % i)
    # Hurt: a soft low drop with no harsh edge.
    _begin(0.28)
    _drop(0.0, 57.0, 9.0, 0.26, 0.5, 4.0)
    _noise(0.0, 0.07, 0.12, 34.0, 0.4)
    _store("hurt")
    # Warning: two clear pings on one note.
    _begin(0.36)
    _bell(0.0, 76.0, 0.17, 0.34, 1.0, 22.0)
    _bell(0.15, 76.0, 0.21, 0.34, 1.0, 18.0)
    _store("warn")
    # Stupefy and lightning: a firm falling fourth.
    _begin(0.28)
    _bell(0.0, 69.0, 0.2, 0.38, 1.0, 20.0)
    _bell(0.07, 64.0, 0.2, 0.36, 1.0, 17.0)
    _store("stupefy")
    # Fire: a warm low fifth under a soft breath of air.
    _begin(0.44)
    _bell(0.0, 50.0, 0.42, 0.34, 1.0, 9.0)
    _bell(0.0, 57.0, 0.42, 0.22, 0.6, 10.0)
    _noise(0.0, 0.3, 0.16, 10.0, 0.22)
    _store("fire")
    # Ice and water: two glassy high notes.
    _begin(0.36)
    _bell(0.0, 88.0, 0.3, 0.24, 0.3, 14.0)
    _bell(0.06, 93.0, 0.29, 0.22, 0.3, 14.0)
    _bell(0.06, 100.0, 0.2, 0.07, 0.0, 22.0)
    _store("ice")
    # Burst: a round low boom.
    _begin(0.38)
    _drop(0.0, 45.0, 12.0, 0.36, 0.6, 3.5)
    _noise(0.0, 0.2, 0.18, 14.0, 0.3)
    _store("burst")
    # Level-up: a bright rising arpeggio that keeps ringing.
    _begin(1.3)
    var up: Array = [69, 72, 76, 81, 84, 88]
    for i in up.size():
        _bell(0.065 * i, float(up[i]), 0.9, 0.26, 0.5, 4.5)
    _store("level")
    # Patronus: a slower silver shimmer.
    _begin(1.0)
    var silver: Array = [69, 76, 81, 84, 88]
    for i in silver.size():
        _bell(0.08 * i, float(silver[i]), 0.65, 0.22, 0.3, 6.0)
    _store("patronus")
    # Boss down: the scale turns major for a short fanfare and a held chord.
    _begin(1.9)
    var fanfare: Array = [57, 64, 69, 73, 76, 81]
    for i in fanfare.size():
        _bell(0.09 * i, float(fanfare[i]), 1.2, 0.26, 0.7, 3.2)
    for note in [69, 73, 76]:
        _bell(0.62, float(note), 1.25, 0.2, 0.5, 2.6)
    _store("boss_down")


func _begin(seconds: float) -> void:
    _buf = PackedFloat32Array()
    _buf.resize(int(seconds * RATE))


func _freq(note: float) -> float:
    return 440.0 * pow(2.0, (note - 69.0) / 12.0)


# A bell or pluck: a sine with two overtones that die away faster than the fundamental.
# bright 0..1 sets the overtones, decay is how fast the note fades (larger = shorter).
func _bell(at: float, note: float, dur: float, amp: float, bright: float, decay: float) -> void:
    var start: int = int(at * RATE)
    var n: int = mini(int(dur * RATE), _buf.size() - start)
    var w: float = TAU * _freq(note) / RATE
    for i in n:
        var tt: float = float(i) / RATE
        var fade: float = exp(-decay * tt)
        var s: float = sin(w * i) + bright * (0.45 * sin(2.0 * w * i) + 0.2 * sin(3.0 * w * i)) * fade
        _buf[start + i] += s * minf(1.0, i / 50.0) * fade * amp


# A low tone whose pitch falls by "fall" semitones (thuds and booms).
func _drop(at: float, note: float, fall: float, dur: float, amp: float, decay: float) -> void:
    var start: int = int(at * RATE)
    var n: int = mini(int(dur * RATE), _buf.size() - start)
    var phase: float = 0.0
    for i in n:
        var k: float = float(i) / float(maxi(1, n))
        phase += TAU * _freq(note - fall * k) / RATE
        var s: float = sin(phase) + 0.3 * sin(2.0 * phase)
        _buf[start + i] += s * minf(1.0, i / 40.0) * exp(-decay * k) * amp


# Smoothed noise: a breath of air, never a hiss.
func _noise(at: float, dur: float, amp: float, decay: float, smooth: float) -> void:
    var start: int = int(at * RATE)
    var n: int = mini(int(dur * RATE), _buf.size() - start)
    var v: float = 0.0
    for i in n:
        v = lerpf(v, randf_range(-1.0, 1.0), smooth)
        var tt: float = float(i) / RATE
        _buf[start + i] += v * minf(1.0, i / 80.0) * exp(-decay * tt) * amp


# Turns the buffer into a stream: soft clipping and a short fade at the very end.
func _store(id: String) -> void:
    var n: int = _buf.size()
    var bytes := PackedByteArray()
    bytes.resize(n * 2)
    var tail: int = mini(n, 300)
    for i in n:
        var v: float = _buf[i]
        if i >= n - tail:
            v *= float(n - i) / float(tail)
        bytes.encode_s16(i * 2, int(v / (1.0 + absf(v)) * 30000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = bytes
    _mutex.lock()
    _streams[id] = stream
    _mutex.unlock()
