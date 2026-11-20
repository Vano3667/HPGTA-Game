extends RefCounted
## The automatic arsenal. Every spell picks its own target and fires on its own timer;
## the player never aims or presses a cast button.

const Spells = preload("res://scripts/data/spells.gd")

var w
var cd := {}
var orbit := 0.0
var orbit_hit := {}
var familiar := Vector2.ZERO
var rings: Array = []
var stag = null


func _init(world) -> void:
    w = world


func reset() -> void:
    cd = {}
    orbit_hit = {}
    rings = []
    stag = null
    if not w.player.is_empty():
        familiar = w.player.pos


func lv(id: String) -> int:
    return int(w.player.weapons.get(id, 0))


func _can_cast(id: String) -> bool:
    return lv(id) > 0 and float(cd.get(id, 0.0)) <= 0.0


func step(delta: float) -> void:
    var p: Dictionary = w.player
    var haste: float = Spells.cooldown_mult(p)
    for id in p.weapons.keys():
        cd[id] = float(cd.get(id, 0.4)) - delta
    _wand(p, haste)
    _stupefy(p, haste)
    _protego(p, delta)
    _patronus(p, haste, delta)
    _incendio(p, haste, delta)
    _glacius(p, haste)
    _expelliarmus(p, haste)
    _lumos(p, haste, delta)


func _wand(p: Dictionary, haste: float) -> void:
    if not _can_cast("wand"):
        return
    var tgt = w.nearest_enemy(p.pos, 300.0)
    if tgt == null:
        cd["wand"] = 0.12
        return
    var n: int = lv("wand")
    cd["wand"] = (0.72 - 0.05 * n) * haste
    var dir: Vector2 = (tgt.pos - p.pos).normalized()
    p.aim = dir
    var count: int = 1
    if n >= 3:
        count = 2
    if n >= 5:
        count = 3
    var chain: int = 3 if p.evolved.has("chain") else 0
    for i in count:
        var d: Vector2 = dir.rotated((i - (count - 1) * 0.5) * 0.16)
        w.fire_shot({"kind": "wand", "pos": p.pos + d * 9.0, "vel": d * 340.0, "dmg": 9.0 + 3.0 * n, "r": 4.0, "life": 1.0, "pierce": int(n * 0.5), "chain": chain})
    w.sound.emit("wand")


func _stupefy(p: Dictionary, haste: float) -> void:
    if not _can_cast("stupefy"):
        return
    var tgt = w.toughest_enemy(p.pos, 300.0)
    if tgt == null:
        cd["stupefy"] = 0.2
        return
    var n: int = lv("stupefy")
    cd["stupefy"] = (3.2 - 0.25 * n) * haste
    var dir: Vector2 = (tgt.pos - p.pos).normalized()
    var count: int = 1
    if n >= 3:
        count = 3
    if n >= 5:
        count = 5
    for i in count:
        var d: Vector2 = dir.rotated((i - (count - 1) * 0.5) * 0.22)
        w.fire_shot({"kind": "stupefy", "pos": p.pos + d * 9.0, "vel": d * 260.0, "dmg": 20.0 + 8.0 * n, "r": 5.0, "life": 1.3, "stun": 0.9 + 0.15 * n})
    w.sound.emit("stupefy")


func rune_count() -> int:
    var n: int = lv("protego")
    if n <= 0:
        return 0
    if w.player.evolved.has("maxima"):
        return 6
    if n >= 4:
        return 3
    if n >= 2:
        return 2
    return 1


func rune_radius() -> float:
    if w.player.evolved.has("maxima"):
        return 46.0
    return 31.0


func rune_pos(i: int, count: int) -> Vector2:
    var pp: Vector2 = w.player.pos
    return pp + Vector2.from_angle(orbit + TAU * i / float(count)) * rune_radius()


## True when a shield rune is close enough to stop a hostile curse at this point.
func blocks(pos: Vector2) -> bool:
    var count: int = rune_count()
    for i in count:
        if rune_pos(i, count).distance_to(pos) < 9.0:
            return true
    return false


func _protego(p: Dictionary, delta: float) -> void:
    var count: int = rune_count()
    if count <= 0:
        return
    orbit += delta * 3.4
    for id in orbit_hit.keys():
        orbit_hit[id] -= delta
        if orbit_hit[id] <= 0.0:
            orbit_hit.erase(id)
    var n: int = lv("protego")
    var pp: Vector2 = p.pos
    for i in count:
        var rp: Vector2 = rune_pos(i, count)
        for e in w.enemies_in(rp, 7.0):
            if orbit_hit.has(e.id):
                continue
            orbit_hit[e.id] = 0.45
            var away: Vector2 = e.pos - pp
            w.hurt(e, 5.0 + 3.0 * n, away.normalized() * 130.0)


func _patronus(p: Dictionary, haste: float, delta: float) -> void:
    if stag != null:
        var sd: Vector2 = stag.dir
        var side: Vector2 = Vector2(-sd.y, sd.x)
        stag.pos += sd * 430.0 * delta
        stag.left -= 430.0 * delta
        var sp: Vector2 = stag.pos
        for e in w.enemies_in(sp, stag.width):
            if stag.hit.has(e.id):
                continue
            stag.hit[e.id] = true
            var rel: Vector2 = e.pos - sp
            var sgn: float = 1.0 if side.dot(rel) >= 0.0 else -1.0
            w.hurt(e, stag.dmg, side * sgn * 160.0)
            if e.boss:
                if e.patronus_weak and e.hp > 0.0:
                    # The counter-window: the stag staggers Aragog and opens him up.
                    e.stun = 1.8
                    e.weak = 4.5
                    w.add_fx({"kind": "text", "pos": e.pos + Vector2(-34.0, -34.0), "text": "STAGGERED!", "col": Color("bfe9ff"), "life": 1.2})
            else:
                e.stun = maxf(e.stun, 0.5)
        if stag.left <= 0.0:
            stag = null
        return
    if not _can_cast("patronus"):
        return
    var tgt = w.boss
    if tgt == null:
        tgt = w.nearest_enemy(p.pos, 340.0)
    if tgt == null:
        cd["patronus"] = 0.3
        return
    var n: int = lv("patronus")
    cd["patronus"] = (10.0 - 0.9 * n) * haste
    var dir: Vector2 = (tgt.pos - p.pos).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.UP
    stag = {"pos": p.pos, "dir": dir, "left": 380.0 + 25.0 * n, "width": 22.0 + 4.0 * n, "dmg": 35.0 + 15.0 * n, "hit": {}}
    w.sound.emit("patronus")


func _incendio(p: Dictionary, haste: float, delta: float) -> void:
    var pp: Vector2 = p.pos
    var keep: Array = []
    for ring in rings:
        ring.t -= delta
        if ring.t > 0.0:
            keep.append(ring)
            continue
        for e in w.enemies_in(pp, ring.r):
            var away: Vector2 = e.pos - pp
            w.hurt(e, ring.dmg, away.normalized() * 110.0)
        w.add_fx({"kind": "ring", "pos": pp, "r0": ring.r * 0.4, "r1": ring.r, "col": Color("ff9a3c"), "life": 0.35, "width": 5.0})
        if p.evolved.has("inferno"):
            w.add_zone({"kind": "fire", "pos": pp, "r": ring.r * 0.9, "life": 2.6, "dmg": ring.dmg * 0.3, "slow": false})
        w.sound.emit("fire")
    rings = keep
    if not _can_cast("incendio"):
        return
    var n: int = lv("incendio")
    var radius: float = 50.0 + 10.0 * n
    if w.enemies_in(pp, radius * 1.25).is_empty():
        cd["incendio"] = 0.25
        return
    cd["incendio"] = (5.2 - 0.4 * n) * haste
    rings.append({"t": 0.45, "r": radius, "dmg": 16.0 + 8.0 * n})


func _glacius(p: Dictionary, haste: float) -> void:
    if not _can_cast("glacius"):
        return
    var tgt = w.nearest_enemy(p.pos, 240.0)
    if tgt == null:
        cd["glacius"] = 0.3
        return
    var n: int = lv("glacius")
    cd["glacius"] = (6.5 - 0.4 * n) * haste
    w.add_zone({"kind": "ice", "pos": tgt.pos, "r": 46.0 + 8.0 * n, "life": 3.0 + 0.3 * n, "dmg": 2.0 + 2.0 * n, "slow": true})
    w.sound.emit("ice")


func _expelliarmus(p: Dictionary, haste: float) -> void:
    if not _can_cast("expelliarmus"):
        return
    var tgt = w.nearest_enemy(p.pos, 320.0, "ranged")
    if tgt == null:
        tgt = w.nearest_enemy(p.pos, 320.0)
    if tgt == null:
        cd["expelliarmus"] = 0.3
        return
    var n: int = lv("expelliarmus")
    cd["expelliarmus"] = (2.6 - 0.2 * n) * haste
    var dir: Vector2 = (tgt.pos - p.pos).normalized()
    var curve: float = 0.9 if w.rng.randf() < 0.5 else -0.9
    var d: Vector2 = dir.rotated(curve)
    w.fire_shot({"kind": "expelliarmus", "pos": p.pos + d * 9.0, "vel": d * 230.0, "dmg": 12.0 + 5.0 * n, "r": 5.0, "life": 1.8, "turn": 5.0, "disarm": 2.5 + 0.4 * n})


func _lumos(p: Dictionary, haste: float, delta: float) -> void:
    var n: int = lv("lumos")
    if n <= 0:
        return
    var pp: Vector2 = p.pos
    var home: Vector2 = pp + Vector2.from_angle(w.run_time * 1.3) * 26.0
    familiar = familiar.lerp(home, minf(1.0, delta * 6.0))
    if float(cd.get("lumos", 0.0)) > 0.0:
        return
    var tgt = w.nearest_enemy(familiar, 220.0)
    if tgt == null:
        cd["lumos"] = 0.15
        return
    cd["lumos"] = (1.0 - 0.1 * n) * haste
    var to: Vector2 = tgt.pos - familiar
    w.fire_shot({"kind": "lumos", "pos": familiar, "vel": to.normalized() * 300.0, "dmg": 4.0 + 2.0 * n, "r": 3.0, "life": 0.9})


## Friendly visuals stay cyan / gold / blue-white so they never read as threats.
func draw(ci: CanvasItem) -> void:
    var pp: Vector2 = w.player.pos
    var count: int = rune_count()
    for i in count:
        var rp: Vector2 = rune_pos(i, count)
        ci.draw_circle(rp, 4.0, Color("67dcf4"))
        ci.draw_arc(rp, 6.0, orbit * 2.0, orbit * 2.0 + 4.0, 8, Color("f0d278"), 1.5)
    for ring in rings:
        var k: float = 1.0 - clampf(ring.t / 0.45, 0.0, 1.0)
        ci.draw_arc(pp, ring.r, 0.0, TAU, 28, Color(1.0, 0.82, 0.35, 0.35 + 0.4 * k), 1.5)
        ci.draw_arc(pp, maxf(2.0, ring.r * k), 0.0, TAU, 24, Color(1.0, 0.6, 0.2, 0.8), 2.0)
    if lv("lumos") > 0:
        ci.draw_circle(familiar, 5.0, Color(1.0, 0.95, 0.7, 0.3))
        ci.draw_circle(familiar, 2.5, Color("fff3c0"))
    if stag != null:
        var sp: Vector2 = stag.pos
        var sd: Vector2 = stag.dir
        var ss: Vector2 = Vector2(-sd.y, sd.x)
        var white := Color(1.0, 1.0, 1.0)
        ci.draw_circle(sp, stag.width, Color(0.6, 0.9, 1.0, 0.18))
        ci.draw_line(sp - sd * 12.0, sp - sd * 40.0, Color(0.6, 0.9, 1.0, 0.5), 4.0)
        ci.draw_circle(sp - sd * 8.0, 7.0, Color(0.85, 0.97, 1.0, 0.9))
        ci.draw_circle(sp + sd * 2.0, 6.0, Color(0.9, 0.98, 1.0, 0.95))
        ci.draw_circle(sp + sd * 9.0, 4.0, white)
        ci.draw_line(sp + sd * 10.0, sp + sd * 16.0 + ss * 6.0, white, 1.5)
        ci.draw_line(sp + sd * 10.0, sp + sd * 16.0 - ss * 6.0, white, 1.5)
