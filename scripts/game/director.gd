extends RefCounted
## Pacing: escalating waves, elites, the chapter hazard and boss behaviour.

const Chapters = preload("res://scripts/data/chapters.gd")

var w
var spawn_t := 0.5
var elite_t := 40.0
var hazard_t := 6.0
var boss_spawned := false
var boss_dead := false
var clear_t := 0.0
var pat_i := 0
var _cleanup := false
var _done := false


func _init(world) -> void:
    w = world


func reset() -> void:
    spawn_t = 0.5
    elite_t = 40.0
    hazard_t = 6.0
    boss_spawned = false
    boss_dead = false
    clear_t = 0.0
    pat_i = 0
    _cleanup = false
    _done = false


func step(delta: float) -> void:
    var ch: Dictionary = w.chapter
    if boss_dead:
        _after_boss(delta)
        return
    var k: float = clampf(w.time / Chapters.SURVIVE_TIME, 0.0, 1.0)
    var index: int = w.chapter_index
    var mult: float = (1.0 + 0.7 * index) * (1.0 + 0.6 * k)
    spawn_t -= delta
    if spawn_t <= 0.0:
        if boss_spawned:
            spawn_t = 1.8
            _spawn_batch(ch, 2, mult)
        else:
            # Gentle opening that ramps to a dense swarm by the end of the chapter.
            spawn_t = lerpf(1.5, 0.4, k)
            _spawn_batch(ch, 1 + int(k * 5.0) + index, mult)
    if not boss_spawned:
        elite_t -= delta
        if elite_t <= 0.0:
            elite_t = 40.0
            w.spawn_enemy(_pick(ch), _edge_pos(), true, mult)
        if w.time >= Chapters.SURVIVE_TIME:
            # The boss arrives with a shockwave that dispels the crowd, so the duel stays readable
            # and automatic spells can actually reach the boss.
            boss_spawned = true
            _wipe(true)
            w.spawn_boss(ch.boss)
            spawn_t = 4.0
    _hazards(delta, ch.hazard)


func on_boss_dead() -> void:
    boss_dead = true
    clear_t = 2.5
    _cleanup = true


# Remove every regular enemy and hostile curse. Optionally leave their XP behind.
func _wipe(drop_xp: bool) -> void:
    w.bolts = []
    w.pending = []
    for e in w.enemies:
        if e.hp > 0.0 and not e.boss:
            e.hp = 0.0
            w.add_fx({"kind": "ring", "pos": e.pos, "r0": 2.0, "r1": e.r * 2.0, "col": Color("f0d278"), "life": 0.3})
            if drop_xp:
                w._drop_gem(e.pos, int(e.xp))


# After the boss falls: wipe remaining threats, let the player vacuum XP, then end the chapter.
func _after_boss(delta: float) -> void:
    if _cleanup:
        _cleanup = false
        w.hazards = []
        _wipe(false)
    clear_t -= delta
    if clear_t <= 0.0 and not _done:
        _done = true
        w.finish_chapter()


func _spawn_batch(ch: Dictionary, count: int, mult: float) -> void:
    for i in count:
        if w.enemies.size() + w.pending.size() >= w.MAX_ENEMIES:
            return
        w.spawn_enemy(_pick(ch), _edge_pos(), false, mult)


func _pick(ch: Dictionary) -> String:
    var total: float = 0.0
    var avail: Array = []
    for row in ch.enemies:
        if w.time >= row[1]:
            avail.append(row)
            total += row[2]
    var roll: float = w.rng.randf() * total
    for row in avail:
        roll -= row[2]
        if roll <= 0.0:
            return row[0]
    return ch.enemies[0][0]


# Enemies enter from just outside the visible screen around the player.
func _edge_pos() -> Vector2:
    var pp: Vector2 = w.player.pos
    var a: Vector2 = Chapters.ARENA
    var vs: Vector2 = w.view_size
    var rng: RandomNumberGenerator = w.rng
    var half: Vector2 = vs * 0.5 + Vector2(30.0, 30.0)
    var pos: Vector2 = pp
    for attempt in 5:
        var side: int = rng.randi() % 4
        if side == 0:
            pos = pp + Vector2(rng.randf_range(-half.x, half.x), -half.y)
        elif side == 1:
            pos = pp + Vector2(rng.randf_range(-half.x, half.x), half.y)
        elif side == 2:
            pos = pp + Vector2(-half.x, rng.randf_range(-half.y, half.y))
        else:
            pos = pp + Vector2(half.x, rng.randf_range(-half.y, half.y))
        pos.x = clampf(pos.x, 20.0, a.x - 20.0)
        pos.y = clampf(pos.y, 20.0, a.y - 20.0)
        if absf(pos.x - pp.x) > half.x - 40.0 or absf(pos.y - pp.y) > half.y - 40.0:
            break
    return pos


# ---------------------------------------------------------------- hazards

func _hazards(delta: float, hz: Dictionary) -> void:
    hazard_t -= delta
    if hazard_t <= 0.0:
        hazard_t = hz.every * (0.8 if boss_spawned else 1.0)
        _make_hazard(hz)
    var p: Dictionary = w.player
    var keep: Array = []
    for h in w.hazards:
        if h.warn > 0.0:
            h.warn -= delta
            if h.warn <= 0.0:
                w.sound.emit("burst")
            keep.append(h)
            continue
        h.life -= delta
        if h.vel != Vector2.ZERO:
            var moved: Array = []
            for item in h.rects:
                var rect: Rect2 = item
                rect.position += h.vel * delta
                moved.append(rect)
            h.rects = moved
        if _inside(h, p.pos, p.r):
            if h.slow:
                p.slow = 0.55
            if h.dmg > 0.0:
                w.damage_player(h.dmg)
        if h.life > 0.0:
            keep.append(h)
    w.hazards = keep


func _inside(h: Dictionary, pos: Vector2, r: float) -> bool:
    for item in h.rects:
        var rect: Rect2 = item
        if rect.grow(r * 0.5).has_point(pos):
            return true
    if h.r > 0.0:
        var c: Vector2 = h.pos
        return pos.distance_to(c) < h.r
    return false


# Every hazard warns first and always leaves a way out.
func _make_hazard(hz: Dictionary) -> void:
    var pp: Vector2 = w.player.pos
    var rng: RandomNumberGenerator = w.rng
    var h: Dictionary = {
        "rects": [], "pos": Vector2.ZERO, "r": 0.0, "vel": Vector2.ZERO,
        "warn": float(hz.warn), "warn_max": float(hz.warn), "life": float(hz.life), "dmg": float(hz.damage), "slow": false,
    }
    match hz.kind:
        "lane":
            # Diagon Alley: a street lamp flashes, then a short burst fills one lane.
            if rng.randf() < 0.5:
                h.rects = [Rect2(pp.x - 320.0, pp.y + rng.randf_range(-70.0, 70.0) - 22.0, 640.0, 44.0)]
            else:
                h.rects = [Rect2(pp.x + rng.randf_range(-70.0, 70.0) - 22.0, pp.y - 440.0, 44.0, 880.0)]
        "glyph":
            # Hogwarts: a staircase glyph locks a patch of floor for a few seconds.
            var off := Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 90.0))
            h.rects = [Rect2(pp + off - Vector2(80.0, 50.0), Vector2(160.0, 100.0))]
        "fog":
            # Forbidden Forest: roots and fog slow Harry down.
            h.pos = pp + Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 90.0))
            h.r = 95.0
            h.slow = true
        "sweep":
            # Quidditch: a flight lane sweeps across the pitch with one readable gap.
            var from_left: bool = rng.randf() < 0.5
            var x: float = pp.x - 300.0
            if not from_left:
                x = pp.x + 250.0
            var gap_y: float = pp.y + rng.randf_range(-160.0, 160.0)
            var top: float = pp.y - 520.0
            var bottom: float = pp.y + 520.0
            h.rects = [Rect2(x, top, 50.0, gap_y - 65.0 - top), Rect2(x, gap_y + 65.0, 50.0, bottom - gap_y - 65.0)]
            h.vel = Vector2(150.0 if from_left else -150.0, 0.0)
            h["path"] = Rect2(pp.x - 300.0, top, 600.0, 1040.0)
        "orb":
            # Ministry: a prophecy orb glows, then bursts in a cross of lines.
            var c := Vector2(pp.x + rng.randf_range(-60.0, 60.0), pp.y + rng.randf_range(-60.0, 60.0))
            h.rects = [Rect2(c.x - 300.0, c.y - 17.0, 600.0, 34.0), Rect2(c.x - 17.0, c.y - 300.0, 34.0, 600.0)]
    w.add_hazard(h)
    w.sound.emit("warn")


# ---------------------------------------------------------------- bosses

func boss_step(e: Dictionary, delta: float) -> void:
    var p: Vector2 = w.player.pos
    var to: Vector2 = p - e.pos
    var dist: float = to.length()
    var dir: Vector2 = to / maxf(dist, 0.001)
    e.face = dir
    if e.state == "tell":
        e.state_t -= delta
        if e.state_t <= 0.0:
            _boss_fire(e)
    elif e.state == "dash":
        e.pos += e.dir * 320.0 * delta
        e.state_t -= delta
        if e.state_t <= 0.0:
            e.state = ""
            e.cd = e.rest
    else:
        if dist > 110.0:
            e.pos += dir * e.speed * delta
        e.cd -= delta
        if e.cd <= 0.0:
            _boss_tell(e, dir, p)


# Start the wind-up for the next pattern. Everything a boss does is announced first.
func _boss_tell(e: Dictionary, dir: Vector2, target: Vector2) -> void:
    var frac: float = e.hp / e.max_hp
    var phase: int = 0
    if frac <= 0.33:
        phase = 2
    elif frac <= 0.66:
        phase = 1
    if phase != e.phase:
        e.phase = phase
        w.add_fx({"kind": "text", "pos": e.pos + Vector2(-24.0, -40.0), "text": "PHASE %d" % (phase + 1), "col": Color("f0d278"), "life": 1.4})
    var pats: Array = e.patterns[phase]
    e.pat = pats[pat_i % pats.size()]
    pat_i += 1
    e.state = "tell"
    e.state_t = e.tell
    e.dir = dir
    e.gap = w.rng.randf() * TAU
    e.mark = target
    e.repeat = 0
    w.sound.emit("warn")
    if e.pat == "slam":
        w.add_hazard({"rects": [], "pos": target, "r": 78.0, "vel": Vector2.ZERO, "warn": float(e.tell), "warn_max": float(e.tell), "life": 0.3, "dmg": e.dmg * 1.4, "slow": false})
    elif e.pat == "web":
        for i in 3:
            var off: Vector2 = Vector2.from_angle(w.rng.randf() * TAU) * w.rng.randf_range(40.0, 130.0)
            w.add_hazard({"rects": [], "pos": target + off, "r": 60.0, "vel": Vector2.ZERO, "warn": float(e.tell), "warn_max": float(e.tell), "life": 5.0, "dmg": 0.0, "slow": true})


func _boss_fire(e: Dictionary) -> void:
    e.state = ""
    e.cd = e.rest
    var col: Color = e.bolt
    match e.pat:
        "ring":
            _ring(e, 20, 4, 88.0, col)
        "spin":
            # Three rings in a row; the gap rotates a little each time.
            _ring(e, 18, 4, 96.0, col)
            if e.repeat < 2:
                e.repeat += 1
                e.gap += 0.7
                e.state = "tell"
                e.state_t = 0.55
        "fan":
            var fd: Vector2 = e.dir
            for i in 7:
                var d: Vector2 = fd.rotated((i - 3) * 0.16)
                w.fire_bolt(e.pos + d * e.r, d * 112.0, e.dmg, col)
        "charge":
            e.state = "dash"
            e.state_t = 0.55
        "summon":
            var list: Array = w.chapter.enemies
            var index: int = w.chapter_index
            for i in 6:
                var type: String = list[i % list.size()][0]
                var at: Vector2 = e.pos + Vector2.from_angle(TAU * i / 6.0) * (e.r + 26.0)
                w.spawn_enemy(type, at, false, 1.0 + 0.7 * index)
        "core":
            # Final phase of the Hex Disturbance: the seal core is exposed and takes extra damage.
            e.weak = 4.0
            e.stun = 2.5
            w.add_fx({"kind": "text", "pos": e.pos + Vector2(-52.0, -44.0), "text": "SEAL CORE EXPOSED", "col": Color("f0d278"), "life": 1.6})
            _ring(e, 20, 5, 80.0, col)


# A ring of curses with a safe gap centred on e.gap (the pale line in the telegraph).
func _ring(e: Dictionary, n: int, gap_n: int, speed: float, col: Color) -> void:
    var half: float = PI * gap_n / float(n)
    var origin: Vector2 = e.pos
    var base: float = e.gap
    var r: float = e.r
    for i in n:
        var off: float = TAU * (i + 0.5) / float(n)
        if off < half or off > TAU - half:
            continue
        var d: Vector2 = Vector2.from_angle(base + off)
        w.fire_bolt(origin + d * r, d * speed, e.dmg, col)
