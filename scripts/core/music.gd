extends Node
## Procedural soundtrack. Three short original loops (menu, battle, boss) are synthesised on a
## worker thread at startup, so the game ships without any audio files.

const RATE := 16000

# chords: [root midi note, third in semitones]. lead: semitones above the chord root + 12, -1 = rest.
const SONGS := {
    "menu": {"bpm": 76.0, "steps": 6, "chords": [[52, 3], [52, 3], [48, 4], [48, 4], [45, 3], [45, 3], [47, 4], [47, 4]],
        "arp": [0, 2, 1, 2, 3, 2], "bass": [0], "amp": 0.22,
        "lead": [[7, -1, -1, 3, -1, 7], [12, -1, -1, -1, 10, 7], [4, -1, -1, 7, -1, 12], [11, -1, -1, -1, -1, -1], [3, -1, -1, 7, -1, 12], [10, -1, 7, -1, 3, -1], [4, -1, -1, 7, -1, 10], [7, -1, -1, -1, -1, -1]]},
    "battle": {"bpm": 132.0, "steps": 8, "chords": [[50, 3], [50, 3], [46, 4], [46, 4], [53, 4], [53, 4], [48, 4], [45, 4]],
        "arp": [0, 1, 2, 3, 2, 1, 2, 3], "bass": [0, 2, 4, 6], "amp": 0.2,
        "lead": [[7, -1, 7, 10, -1, 7, -1, 3], [5, -1, 3, -1, 0, -1, -1, -1], [7, -1, 7, 11, -1, 7, -1, 4], [12, -1, 11, -1, 7, -1, -1, -1], [7, -1, 4, 7, -1, 12, -1, 11], [9, -1, 7, -1, 4, -1, -1, -1], [4, -1, 7, -1, 12, -1, 11, -1], [7, -1, 4, -1, 7, 8, 10, 11]]},
    "boss": {"bpm": 150.0, "steps": 8, "chords": [[40, 3], [40, 3], [41, 4], [40, 3], [43, 3], [43, 3], [42, 3], [47, 4]],
        "arp": [0, 0, 2, 0, 1, 0, 2, 3], "bass": [0, 1, 2, 3, 4, 5, 6, 7], "amp": 0.2,
        "lead": [[12, -1, -1, 15, -1, -1, 19, -1], [18, -1, 15, -1, 12, -1, -1, -1], [11, -1, -1, 16, -1, -1, 19, -1], [15, -1, 12, -1, 7, -1, -1, -1], [12, -1, -1, 15, -1, -1, 19, -1], [22, -1, 19, -1, 15, -1, -1, -1], [12, -1, 15, -1, 18, -1, 15, -1], [16, -1, -1, -1, 11, -1, 9, 11]]},
}

var enabled := true
var _player: AudioStreamPlayer
var _tracks := {}
var _want := ""
var _now := ""
var _thread: Thread = null
var _mutex := Mutex.new()
var _buf := PackedFloat32Array()


func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.volume_db = -15.0
    add_child(_player)
    if DisplayServer.get_name() == "headless":
        return
    _thread = Thread.new()
    _thread.start(_build)


func _exit_tree() -> void:
    if _thread != null and _thread.is_started():
        _thread.wait_to_finish()


func play(id: String) -> void:
    _want = id


func _process(_delta: float) -> void:
    var target: String = _want if enabled else ""
    if target == _now:
        return
    if target == "":
        _player.stop()
        _now = ""
        return
    _mutex.lock()
    var stream = _tracks.get(target)
    _mutex.unlock()
    if stream == null:
        return
    _player.stream = stream
    _player.play()
    _now = target


func _build() -> void:
    for id in ["menu", "battle", "boss"]:
        var stream: AudioStreamWAV = render(SONGS[id])
        _mutex.lock()
        _tracks[id] = stream
        _mutex.unlock()


func _freq(note: int) -> float:
    return 440.0 * pow(2.0, (note - 69) / 12.0)


## Renders one loop. Notes that ring past the end wrap around, so the loop point is seamless.
func render(song: Dictionary) -> AudioStreamWAV:
    var steps: int = song.steps
    var step_s: float = 30.0 / float(song.bpm)
    var chords: Array = song.chords
    var total: int = int(chords.size() * steps * step_s * RATE)
    _buf = PackedFloat32Array()
    _buf.resize(total)
    var amp: float = song.amp
    for bar in chords.size():
        var root: int = chords[bar][0]
        var tones: Array = [root + 12, root + 12 + int(chords[bar][1]), root + 19, root + 24]
        var lead: Array = song.lead[bar]
        for s in steps:
            var at: int = int((bar * steps + s) * step_s * RATE)
            _note(at, _freq(tones[int(song.arp[s % song.arp.size()])]), step_s * 2.2, amp * 0.55, 0)
            if s in song.bass:
                _note(at, _freq(root), step_s * 1.9, amp * 1.2, 1)
            var deg: int = lead[s]
            if deg >= 0:
                _note(at, _freq(root + 12 + deg), step_s * 2.6, amp * 0.8, 2)
    var bytes := PackedByteArray()
    bytes.resize(total * 2)
    for i in total:
        var v: float = _buf[i]
        bytes.encode_s16(i * 2, int(v / (1.0 + absf(v)) * 30000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = bytes
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = total
    return stream


# kind 0 = bell (arpeggio), 1 = soft bass, 2 = lead with a slow vibrato.
func _note(at: int, freq: float, dur: float, amp: float, kind: int) -> void:
    var n: int = int(dur * RATE)
    var size: int = _buf.size()
    var w: float = TAU * freq / RATE
    for i in n:
        var k: float = float(i) / float(n)
        var s: float = 0.0
        if kind == 0:
            s = (sin(w * i) + 0.4 * sin(2.0 * w * i) + 0.15 * sin(3.0 * w * i)) * exp(-5.0 * k)
        elif kind == 1:
            s = (sin(w * i) + 0.3 * sin(2.0 * w * i)) * minf(1.0, i / 200.0) * (1.0 - k)
        else:
            s = sin(w * i + 0.5 * sin(0.0022 * i)) * minf(1.0, i / 400.0) * (1.0 - k) * (1.0 - k)
        _buf[(at + i) % size] += s * amp
