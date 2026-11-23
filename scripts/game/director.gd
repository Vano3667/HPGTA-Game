extends RefCounted
## Pacing: escalating waves, elites, chapter hazards, boss duels and boss behaviour.
## The world has no borders, so everything here is placed relative to the hero.

const Chapters = preload("res://scripts/data/chapters.gd")
const I18n = preload("res://scripts/core/i18n.gd")

var w
var spawn_t := 0.5
var elite_t := 35.0
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
    elite_t = 35.0
    hazard_t = 6.0
    boss_spawned = false
    boss_dead = false
    clear_t = 0.0
    pat_i = 0
    _cleanup = false
    _done = false


func hp_mult(k: float) -> float:
    var tier: int = w.tier
    return (1.0 + 0.35 * tier) * (1.0 + 0.6 * k)


func step(delta: float) -> void:
    var ch: Dictionary = w.chapter
    if boss_dead:
        _after_boss(delta)
        return
    if ch.get("duel", false):
        _duel(delta, ch)
        return
    var k: float = clampf(w.time / Chapters.SURVIVE_TIME, 0.0, 1.0)
    var tier: int = w.tier
    var mult: float = hp_mult(k)
    spawn_t -= delta
    if spawn_t <= 0.0:
        if boss_spawned:
            spawn_t = 1.8
            _spawn_batch(ch, 2, mult)
        else:
            # Gentle opening that ramps to a dense swarm by the end of the chapter.
            spawn_t = lerpf(1.6, 0.42, k)
            _spawn_batch(ch, 1 + int(k * 4.0) + int(tier * 0.35), mult)
    if not boss_spawned:
        elite_t -= delta
        if elite_t <= 0.0:
            elite_t = 35.0
            w.spawn_enemy(_pick(ch), edge_pos(), true, mult)
        if w.time >= Chapters.SURVIVE_TIME:
            # The crowd is dispelled either way, so the duel stays readable.
            boss_spawned = true
            _wipe(true)
            if str(ch.boss) == "":
                # No guardian here: the way to the story boss opens.
                w.hazards = []
                w.portal()
                boss_dead = true
                clear_t = 2.5
                return
            w.spawn_boss(ch.boss)
            spawn_t = 4.0
    if ch.has("hazard"):
        _hazards(delta, ch.hazard)


# A boss stage: no waves, the story boss walks in at once and only a trickle of minions joins.
func _duel(delta: float, ch: Dictionary) -> void:
    if not boss_spawned:
        if w.time >= 2.5:
            boss_spawned = true
            w.spawn_boss(ch.boss)
            spawn_t = 5.0
    else:
        spawn_t -= delta
        if spawn_t <= 0.0:
            spawn_t = 3.2
            if w.enemies.size() < 12:
                _spawn_batch(ch, 1, hp_mult(0.5))
    _tick_hazards(delta)


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
            e.dead = true
            w.add_fx({"kind": "ring", "pos": e.pos, "r0": 2.0, "r1": e.r * 2.0, "col": Color("f0d278"), "life": 0.3})
            if drop_xp:
                w._drop_gem(e.pos, int(e.xp))


# After the boss falls: wipe remaining threats, let the player vacuum XP, then end the stage.
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
        w.spawn_enemy(_pick(ch), edge_pos(), false, mult)


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


## A point just outside the visible screen around the hero: where enemies enter, and where the
## ones that were left far behind come back in.
func edge_pos() -> Vector2:
    var pp: Vector2 = w.player.pos
    var vs: Vector2 = w.view_world
    var rng: RandomNumberGenerator = w.rng
    var half: Vector2 = vs * 0.5 + Vector2(40.0, 30.0)
    var side: int = rng.randi() % 4
    if side == 0:
        return pp + Vector2(rng.randf_range(-half.x, half.x), -half.y)
    if side == 1:
        return pp + Vector2(rng.randf_range(-half.x, half.x), half.y)
    if side == 2:
        return pp + Vector2(-half.x, rng.randf_range(-half.y, half.y))
    return pp + Vector2(half.x, rng.randf_range(-half.y, half.y))


# ---------------------------------------------------------------- hazards
# A hazard is a set of rectangles and circles. It warns first ("warn"), then is live for "life".

func _new_hazard(warn: float, life: float, dmg: float) -> Dictionary:
    return {"rects": [], "circles": [], "vel": Vector2.ZERO, "warn": warn, "warn_max": warn, "life": life, "dmg": dmg, "slow": false}


func _hazards(delta: float, hz: Dictionary) -> void:
    hazard_t -= delta
    if hazard_t <= 0.0:
        hazard_t = hz.every * (0.8 if boss_spawned else 1.0)
        _make_hazard(hz)
    _tick_hazards(delta)


func _tick_hazards(delta: float) -> void:
    var p: Dictionary = w.player
    var keep: Array = []
    for h in w.hazards:
        if h.warn > 0.0:
            h.warn -= delta
            if h.warn <= 0.0:
                w.sound.emit("burst")
                for c in h.circles:
                    if not h.slow:
                        w.burst(c[0], Color("ffb04a"), 10, 120.0)
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
    for c in h.circles:
        var cp: Vector2 = c[0]
        if pos.distance_to(cp) < c[1]:
            return true
    return false


# A straight danger lane through a point, along the dominant axis of dir.
func _lane(at: Vector2, dir: Vector2, half: float) -> Rect2:
    if absf(dir.x) > absf(dir.y):
        return Rect2(at.x - 420.0, at.y - half, 840.0, half * 2.0)
    return Rect2(at.x - half, at.y - 520.0, half * 2.0, 1040.0)


# Every hazard warns first and always leaves a way out.
func _make_hazard(hz: Dictionary) -> void:
    var pp: Vector2 = w.player.pos
    var rng: RandomNumberGenerator = w.rng
    var n: int = int(hz.get("n", 1))
    var h: Dictionary = _new_hazard(float(hz.warn), float(hz.life), float(hz.damage))
    match hz.kind:
        "lane":
            # A lamp flash / venom jet: one lane through the player's position.
            var half: float = float(hz.get("w", 44.0)) * 0.5
            var jitter := Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(-40.0, 40.0))
            h.rects = [_lane(pp + jitter, Vector2.RIGHT if rng.randf() < 0.5 else Vector2.DOWN, half)]
        "glyph":
            # Floor glyphs lock patches of ground for a few seconds.
            var rects: Array = []
            for i in n:
                var off := Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-70.0, 70.0))
                rects.append(Rect2(pp + off - Vector2(60.0, 40.0), Vector2(120.0, 80.0)))
            h.rects = rects
        "fog":
            # Fog, roots or snowdrifts slow the hero down.
            var circles: Array = []
            for i in n:
                circles.append([pp + Vector2(rng.randf_range(-80.0, 80.0), rng.randf_range(-80.0, 80.0)), float(hz.get("r", 80.0))])
            h.circles = circles
            h.slow = true
        "sweep":
            # Flight lanes / carriages sweep across, one behind another, each with a readable gap.
            var sgn: float = 1.0 if rng.randf() < 0.5 else -1.0
            var strips: Array = []
            var top: float = pp.y - 480.0
            var bottom: float = pp.y + 480.0
            for i in n:
                var x: float = pp.x - sgn * (240.0 + i * 170.0) - 22.0
                var gap_y: float = pp.y + rng.randf_range(-140.0, 140.0)
                strips.append(Rect2(x, top, 44.0, gap_y - 55.0 - top))
                strips.append(Rect2(x, gap_y + 55.0, 44.0, bottom - gap_y - 55.0))
            h.rects = strips
            h.vel = Vector2(150.0 * sgn, 0.0)
        "orb":
            # A prophecy orb glows, then bursts in a cross of lines.
            var c := Vector2(pp.x + rng.randf_range(-50.0, 50.0), pp.y + rng.randf_range(-50.0, 50.0))
            h.rects = [Rect2(c.x - 300.0, c.y - 15.0, 600.0, 30.0), Rect2(c.x - 15.0, c.y - 300.0, 30.0, 600.0)]
        "bolts":
            # Lightning strikes several marked spots at once.
            var spots: Array = []
            for i in n:
                spots.append([pp + Vector2(rng.randf_range(-110.0, 110.0), rng.randf_range(-130.0, 130.0)), float(hz.get("r", 44.0))])
            h.circles = spots
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
        if dist > 96.0:
            e.pos += dir * e.speed * (0.5 if e.s.has("chill") else 1.0) * delta
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
        w.add_fx({"kind": "text", "pos": e.pos + Vector2(-24.0, -40.0), "text": I18n.t("ui_phase") % (phase + 1), "col": Color("f0d278"), "life": 1.4})
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
    var tell: float = e.tell
    var origin: Vector2 = e.pos
    if e.pat == "slam":
        var h: Dictionary = _new_hazard(tell, 0.3, e.dmg * 1.4)
        h.circles = [[target, 64.0]]
        w.add_hazard(h)
    elif e.pat == "gaze":
        # A deadly stare / killing curse: a wide lane straight through the hero.
        var gaze: Dictionary = _new_hazard(tell + 0.25, 0.5, e.dmg * 1.3)
        gaze.rects = [_lane(target, dir, 28.0)]
        w.add_hazard(gaze)
    elif e.pat == "web":
        # Webs / freezing mist: slowing pools around the player.
        var web: Dictionary = _new_hazard(tell, 5.0, 0.0)
        var pools: Array = []
        for i in 3:
            var off: Vector2 = Vector2.from_angle(w.rng.randf() * TAU) * w.rng.randf_range(30.0, 110.0)
            pools.append([target + off, 52.0])
        web.circles = pools
        web.slow = true
        w.add_hazard(web)
    elif e.pat == "breath":
        # Fiendfyre: a row of blasts marching from the boss through the player.
        var fire: Dictionary = _new_hazard(tell, 0.5, e.dmg * 1.2)
        var row: Array = []
        for i in 5:
            row.append([origin + dir * (60.0 + 62.0 * i), 36.0])
        fire.circles = row
        w.add_hazard(fire)


func _fan(e: Dictionary, dir: Vector2, col: Color) -> void:
    for i in 7:
        var d: Vector2 = dir.rotated((i - 3) * 0.16)
        w.fire_bolt(e.pos + d * e.r, d * 112.0, e.dmg, col)


func _boss_fire(e: Dictionary) -> void:
    e.state = ""
    e.cd = e.rest
    var col: Color = e.bolt
    var fd: Vector2 = e.dir
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
            _fan(e, fd, col)
        "twin":
            # Two faces, two fans: one forward, one straight behind.
            _fan(e, fd, col)
            _fan(e, -fd, col)
        "charge":
            e.state = "dash"
            e.state_t = 0.55
        "blink":
            # Apparate to the far side of the player, then strike again quickly.
            var pp: Vector2 = w.player.pos
            var away: Vector2 = pp - e.pos
            w.burst(e.pos, col, 14, 120.0)
            e.pos = w.push_out(pp + away.normalized() * 110.0, e.r)
            w.burst(e.pos, col, 14, 120.0)
            e.cd = 0.5
        "summon":
            var list: Array = w.chapter.enemies
            for i in 6:
                var type: String = list[i % list.size()][0]
                var at: Vector2 = e.pos + Vector2.from_angle(TAU * i / 6.0) * (e.r + 26.0)
                w.spawn_enemy(type, at, false, hp_mult(1.0))
        "core":
            # The boss overreaches: it is marked, held in place and takes extra damage.
            e.s["mark"] = 4.0
            e.hold = 2.5
            w.add_fx({"kind": "text", "pos": e.pos + Vector2(-52.0, -44.0), "text": I18n.t("ui_core"), "col": Color("f0d278"), "life": 1.6})
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
