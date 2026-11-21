extends RefCounted
## The automatic arsenal. Spells and fusions are data (spells.gd); this file implements the
## archetypes: bolt, nova, zone, strike, beam plus the three special ones (orbit, stag, familiar).
## Every spell picks its own target and fires on its own timer.

const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")

var w
var cd := {}
var orbit := 0.0
var orbit_hit := {}
var familiar := Vector2.ZERO
var casts: Array = []
var stag = null


func _init(world) -> void:
    w = world


func reset() -> void:
    cd = {}
    orbit_hit = {}
    casts = []
    stag = null
    if not w.player.is_empty():
        familiar = w.player.pos


func lv(id: String) -> int:
    return int(w.player.weapons.get(id, 0))


func step(delta: float) -> void:
    var p: Dictionary = w.player
    var haste: float = Spells.cooldown_mult(p)
    orbit += delta * 3.4
    _resolve_casts(delta)
    _stag(delta)
    for id in p.weapons.keys():
        _tick(str(id), Spells.WEAPONS[id], int(p.weapons[id]), p, haste, delta)
    for id in p.fusions.keys():
        _tick(str(id), Spells.FUSIONS[id], Spells.fusion_level(p, str(id)), p, haste, delta)


func _tick(id: String, def: Dictionary, level: int, p: Dictionary, haste: float, delta: float) -> void:
    var kind: String = def.kind
    if kind == "orbit":
        _protego(p, level, delta)
        return
    if kind == "familiar":
        var pp: Vector2 = p.pos
        var home: Vector2 = pp + Vector2.from_angle(w.run_time * 1.3) * 26.0
        familiar = familiar.lerp(home, minf(1.0, delta * 6.0))
    var left: float = float(cd.get(id, 0.5)) - delta
    if left > 0.0:
        cd[id] = left
    elif _cast(id, def, level, p):
        cd[id] = Spells.cooldown(def, level) * haste
    else:
        cd[id] = 0.2


func _target(def: Dictionary, origin: Vector2):
    var mode: String = def.get("tgt", "near")
    var reach: float = float(def.get("rng", 300.0))
    # During a boss fight most casts go for the boss, so the swarm cannot shield it forever.
    if w.boss != null and mode != "rand" and w.rng.randf() < 0.6:
        var bp: Vector2 = w.boss.pos
        if origin.distance_to(bp) <= reach:
            return w.boss
    if mode == "tough":
        return w.toughest_enemy(origin, reach)
    if mode == "rand":
        return w.random_enemy(origin, reach)
    if mode == "ranged":
        var caster = w.nearest_enemy(origin, reach, "ranged")
        if caster != null:
            return caster
    return w.nearest_enemy(origin, reach)


func _zone(def: Dictionary, level: int, pos: Vector2) -> Dictionary:
    return {
        "pos": pos, "r": Spells.radius(def, level), "life": float(def.life) * (1.0 + 0.08 * (level - 1)),
        "dmg": Spells.dmg(def, level), "el": def.el, "st": def.get("st", ""), "sd": float(def.get("sd", 0.0)),
        "pull": float(def.get("pull", 0.0)), "col": def.col,
    }


# Returns false when there is nothing worth casting at (the spell retries shortly).
func _cast(id: String, def: Dictionary, level: int, p: Dictionary) -> bool:
    var pp: Vector2 = p.pos
    var kind: String = def.kind
    var dmg: float = Spells.dmg(def, level)
    var col: Color = def.col
    if kind == "nova":
        var r: float = Spells.radius(def, level)
        if def.has("heal"):
            if p.hp >= p.max_hp:
                return false
        elif def.has("dispel"):
            if w.bolts.is_empty() and w.enemies_in(pp, r).is_empty():
                return false
        elif w.enemies_in(pp, r * 1.15).is_empty():
            return false
        casts.append({"t": 0.4, "m": 0.4, "id": id, "def": def, "lv": level, "pos": pp, "follow": true, "r": r})
        return true
    if kind == "zone" and def.get("tgt", "near") == "self":
        w.add_zone(_zone(def, level, pp))
        return true
    var origin: Vector2 = pp
    if kind == "familiar":
        origin = familiar
    var tgt = _target(def, origin)
    if kind == "stag" and w.boss != null:
        tgt = w.boss
    if tgt == null:
        return false
    var tp: Vector2 = tgt.pos
    var dir: Vector2 = (tp - origin).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.UP
    if kind == "bolt" or kind == "familiar":
        if id == "wand":
            p.aim = dir
        var n: int = Spells.count(def, level)
        var spread: float = float(def.get("spread", 0.16))
        var pierce: int = int(def.get("pierce", 0))
        var chain: int = 0
        if id == "wand":
            pierce = int(level * 0.5)
            if p.evolved.has("chain"):
                chain = 3
        for i in n:
            var d: Vector2 = dir.rotated((i - (n - 1) * 0.5) * spread)
            if def.has("curve"):
                d = dir.rotated(0.9 if w.rng.randf() < 0.5 else -0.9)
            w.fire_shot({
                "id": id, "el": def.el, "col": col, "pos": origin + d * 9.0, "vel": d * float(def.sp), "dmg": dmg,
                "r": float(def.get("sr", 4.0)), "life": float(def.get("life", 1.1)), "pierce": pierce, "chain": chain,
                "turn": float(def.get("turn", 0.0)), "boom": float(def.get("boom", 0.0)), "st": def.get("st", ""),
                "sd": float(def.get("sd", 0.0)), "kb": float(def.get("kb", 40.0)), "elite": float(def.get("elite", 1.0)),
            })
    elif kind == "zone":
        w.add_zone(_zone(def, level, tp))
    elif kind == "strike":
        var count: int = Spells.count(def, level)
        var delay: float = float(def.get("delay", 0.4))
        for i in count:
            var at: Vector2 = tp
            if i > 0:
                var other = w.random_enemy(pp, float(def.get("rng", 300.0)))
                if other != null:
                    at = other.pos
            casts.append({"t": delay + 0.06 * i, "m": delay + 0.06 * i, "id": id, "def": def, "lv": level, "pos": at, "follow": false, "r": Spells.radius(def, level)})
    elif kind == "beam":
        var length: float = float(def.rng)
        var width: float = float(def.get("w", 10.0))
        var seen := {}
        var steps: int = int(length / 14.0)
        for i in steps:
            var sp: Vector2 = pp + dir * (14.0 * (i + 1))
            for e in w.enemies_in(sp, width):
                if seen.has(e.id):
                    continue
                seen[e.id] = true
                w.hit(e, dmg, dir * float(def.get("kb", 0.0)), def.el, def.get("st", ""), float(def.get("sd", 0.0)))
            if i % 2 == 0:
                w.spawn_part(sp, dir * 60.0 + Vector2(0.0, -12.0), 0.35, col, 1.8, true)
        w.add_fx({"kind": "line", "a": pp, "b": pp + dir * length, "col": col, "life": 0.22, "width": width * 0.5})
    elif kind == "stag":
        stag = {"pos": pp, "dir": dir, "left": 380.0 + 25.0 * level, "width": 22.0 + 4.0 * level, "dmg": dmg, "hit": {}, "sd": float(def.sd)}
    w.sound.emit(def.get("snd", ""))
    return true


# Novas and strikes land after a short friendly telegraph.
func _resolve_casts(delta: float) -> void:
    var keep: Array = []
    for c in casts:
        c.t -= delta
        if c.follow:
            c.pos = w.player.pos
        if c.t > 0.0:
            keep.append(c)
            continue
        var def: Dictionary = c.def
        var pos: Vector2 = c.pos
        var r: float = c.r
        var col: Color = def.col
        var dmg: float = Spells.dmg(def, c.lv)
        if def.has("heal"):
            w.heal(float(def.heal) * (1.0 + 0.3 * (c.lv - 1)))
            w.burst(pos, col, 8, 50.0)
        else:
            w.blast(pos, r, dmg, float(def.get("kb", 0.0)), def.el, def.get("st", ""), float(def.get("sd", 0.0)), def.has("bane"))
            w.add_fx({"kind": "ring", "pos": pos, "r0": r * 0.3, "r1": r, "col": col, "life": 0.35, "width": 4.0})
            w.burst(pos, col, 10, 110.0)
        if def.has("also"):
            var extra: Dictionary = def.also
            for e in w.enemies_in(pos, r):
                for st in extra:
                    w.apply_status(e, str(st), float(extra[st]))
        if def.has("mend"):
            w.heal(float(def.mend))
        if def.has("dispel"):
            w.dispel(pos, r)
        if def.el == "lightning":
            w.add_fx({"kind": "line", "a": pos + Vector2(-14.0, -150.0), "b": pos, "col": col, "life": 0.18, "width": 3.0})
        if def.kind == "strike":
            w.shake = maxf(w.shake, 0.35)
        if def.has("scorch") or (c.id == "incendio" and w.player.evolved.has("inferno")):
            w.add_zone({"pos": pos, "r": r * 0.9, "life": 2.6, "dmg": dmg * 0.3, "el": "fire", "st": "burn", "sd": 2.0, "pull": 0.0, "col": col})
        w.sound.emit(def.get("snd", ""))
    casts = keep


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


func _protego(p: Dictionary, level: int, delta: float) -> void:
    var count: int = rune_count()
    for id in orbit_hit.keys():
        orbit_hit[id] -= delta
        if orbit_hit[id] <= 0.0:
            orbit_hit.erase(id)
    var pp: Vector2 = p.pos
    var dmg: float = Spells.dmg(Spells.WEAPONS["protego"], level)
    for i in count:
        var rp: Vector2 = rune_pos(i, count)
        for e in w.enemies_in(rp, 7.0):
            if orbit_hit.has(e.id):
                continue
            orbit_hit[e.id] = 0.45
            var away: Vector2 = e.pos - pp
            w.hit(e, dmg, away.normalized() * 130.0, "light", "", 0.0)


func _stag(delta: float) -> void:
    if stag == null:
        return
    var sd: Vector2 = stag.dir
    var side: Vector2 = Vector2(-sd.y, sd.x)
    stag.pos += sd * 430.0 * delta
    stag.left -= 430.0 * delta
    var sp: Vector2 = stag.pos
    w.spawn_part(sp - sd * 10.0, side * w.rng.randf_range(-30.0, 30.0), 0.5, Color("bfe9ff"), 2.0, true)
    for e in w.enemies_in(sp, stag.width):
        if stag.hit.has(e.id):
            continue
        stag.hit[e.id] = true
        var rel: Vector2 = e.pos - sp
        var sgn: float = 1.0 if side.dot(rel) >= 0.0 else -1.0
        w.hit(e, stag.dmg, side * sgn * 160.0, "light", "mark", stag.sd)
        if e.hp <= 0.0:
            continue
        if e.boss:
            if e.patronus_weak:
                # The counter-window: the stag staggers dark bosses and opens them up.
                e.hold = maxf(e.hold, 1.8)
                w.add_fx({"kind": "text", "pos": e.pos + Vector2(-34.0, -34.0), "text": I18n.t("ui_stagger"), "col": Color("bfe9ff"), "life": 1.2})
        else:
            w.apply_status(e, "stun", 0.5)
    if stag.left <= 0.0:
        stag = null


## Friendly visuals stay cyan / gold / blue-white so they never read as threats.
func draw(ci: CanvasItem) -> void:
    var count: int = rune_count()
    for i in count:
        var rp: Vector2 = rune_pos(i, count) + Vector2(0.0, -5.0)
        ci.draw_circle(rp, 4.0, Color("67dcf4"))
        ci.draw_arc(rp, 6.0, orbit * 2.0, orbit * 2.0 + 4.0, 8, Color("f0d278"), 1.5)
    for c in casts:
        var col: Color = c.def.col
        var k: float = 1.0 - clampf(c.t / maxf(c.m, 0.01), 0.0, 1.0)
        var cp: Vector2 = c.pos
        ci.draw_arc(cp, c.r, 0.0, TAU, 28, Color(col, 0.3 + 0.4 * k), 1.2)
        ci.draw_arc(cp, maxf(2.0, c.r * k), 0.0, TAU, 24, Color(col, 0.85), 1.6)
    if lv("lumos") > 0:
        var fp: Vector2 = familiar + Vector2(0.0, -10.0)
        ci.draw_circle(familiar + Vector2(0.0, 3.0), 3.0, Color(0.0, 0.0, 0.0, 0.25))
        ci.draw_circle(fp, 2.6, Color("fff3c0"))
    if stag != null:
        var sp: Vector2 = stag.pos + Vector2(0.0, -4.0)
        var sd: Vector2 = stag.dir
        var ss: Vector2 = Vector2(-sd.y, sd.x)
        var white := Color(1.0, 1.0, 1.0)
        ci.draw_line(sp - sd * 12.0, sp - sd * 40.0, Color(0.6, 0.9, 1.0, 0.5), 4.0)
        ci.draw_circle(sp - sd * 8.0, 7.0, Color(0.85, 0.97, 1.0, 0.9))
        ci.draw_circle(sp + sd * 2.0, 6.0, Color(0.9, 0.98, 1.0, 0.95))
        ci.draw_circle(sp + sd * 9.0, 4.0, white)
        ci.draw_line(sp + sd * 10.0, sp + sd * 16.0 + ss * 6.0, white, 1.5)
        ci.draw_line(sp + sd * 10.0, sp + sd * 16.0 - ss * 6.0, white, 1.5)


## Additive glow for the same things (drawn on the world's glow layer).
func glow(ci: CanvasItem, tex: Texture2D) -> void:
    var count: int = rune_count()
    for i in count:
        var rp: Vector2 = rune_pos(i, count) + Vector2(0.0, -5.0)
        ci.draw_texture_rect(tex, Rect2(rp - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), false, Color(0.4, 0.86, 0.96, 0.6))
    if lv("lumos") > 0:
        var fp: Vector2 = familiar + Vector2(0.0, -10.0)
        ci.draw_texture_rect(tex, Rect2(fp - Vector2(26.0, 26.0), Vector2(52.0, 52.0)), false, Color(1.0, 0.95, 0.7, 0.5))
    if stag != null:
        var sp: Vector2 = stag.pos
        var r: float = stag.width * 1.8
        ci.draw_texture_rect(tex, Rect2(sp - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, Color(0.6, 0.9, 1.0, 0.7))
