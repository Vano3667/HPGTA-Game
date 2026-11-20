extends Node
## Tiny procedural sound effects (decaying square/noise blips) so the prototype needs no audio files.

const RATE := 22050

var enabled := true
var _players: Array = []
var _streams := {}
var _last := {}
var _next := 0


func _ready() -> void:
    for i in 6:
        var p := AudioStreamPlayer.new()
        p.volume_db = -14.0
        add_child(p)
        _players.append(p)
    _streams["wand"] = _tone(920.0, 0.05, -0.4)
    _streams["stupefy"] = _tone(420.0, 0.12, -0.6)
    _streams["patronus"] = _tone(520.0, 0.35, 0.9)
    _streams["fire"] = _tone(160.0, 0.22, -0.5, 0.7)
    _streams["ice"] = _tone(1300.0, 0.14, -0.3, 0.3)
    _streams["hurt"] = _tone(140.0, 0.18, -0.5, 0.5)
    _streams["gem"] = _tone(1500.0, 0.03, 0.3)
    _streams["level"] = _tone(660.0, 0.3, 1.0)
    _streams["warn"] = _tone(300.0, 0.16, 0.0)
    _streams["burst"] = _tone(110.0, 0.2, -0.3, 0.8)
    _streams["boss_down"] = _tone(240.0, 0.6, 1.5)


func _tone(freq: float, dur: float, slide: float, noise: float = 0.0) -> AudioStreamWAV:
    var n: int = int(RATE * dur)
    var bytes := PackedByteArray()
    bytes.resize(n * 2)
    var phase: float = 0.0
    for i in n:
        var k: float = float(i) / float(n)
        phase += TAU * freq * (1.0 + slide * k) / float(RATE)
        var s: float = (1.0 if sin(phase) > 0.0 else -1.0) * (1.0 - k)
        if noise > 0.0:
            s = lerpf(s, randf_range(-1.0, 1.0) * (1.0 - k), noise)
        bytes.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 11000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = bytes
    return stream


func play(id: String) -> void:
    if not enabled or not _streams.has(id) or _players.is_empty():
        return
    var now: int = Time.get_ticks_msec()
    if now - int(_last.get(id, -1000)) < 70:
        return
    _last[id] = now
    var p: AudioStreamPlayer = _players[_next]
    _next = (_next + 1) % _players.size()
    p.stream = _streams[id]
    p.play()
