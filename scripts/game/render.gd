extends RefCounted
## World rendering in a GTA2-like pseudo-3D style: the camera looks straight down, solid props are
## extruded and their roofs lean away from the screen centre (parallax), sprites are stacked in
## layers above soft shadows, and an additive layer adds lights, spell glow and bright particles.

const Art = preload("res://scripts/game/art.gd")
const Chapters = preload("res://scripts/data/chapters.gd")


## Soft radial gradient texture (used for lights and the vignette).
static func radial(inner: Color, outer: Color, start: float) -> GradientTexture2D:
    var g := Gradient.new()
    g.set_color(0, inner)
    g.set_color(1, outer)
    g.set_offset(0, start)
    var tex := GradientTexture2D.new()
    tex.gradient = g
    tex.width = 64
    tex.height = 64
    tex.fill = GradientTexture2D.FILL_RADIAL
    tex.fill_from = Vector2(0.5, 0.5)
    tex.fill_to = Vector2(1.0, 0.5)
    return tex


## Where a point at height h appears: higher things slide away from the camera centre.
static func lift(p: Vector2, cam: Vector2, h: float) -> Vector2:
    return p + (p - cam) * h


static func _view(w, margin: float) -> Rect2:
    var vw: Vector2 = w.view_world
    var cam: Vector2 = w.cam
    var half: Vector2 = vw * 0.5 + Vector2(margin, margin)
    return Rect2(cam - half, half * 2.0)


static func draw(w) -> void:
    var ch: Dictionary = w.chapter
    var a: Vector2 = Chapters.ARENA
    var cam: Vector2 = w.cam
    var t: float = w.run_time
    var hc: bool = bool(w.settings.get("high_contrast", false))
    var lw: float = 2.4 if hc else 1.2
    var view: Rect2 = _view(w, 70.0)
    var edge: Color = ch.edge
    var font: Font = w.font
    var up := Vector2(0.0, -5.0)

    # --- ground
    w.draw_rect(Rect2(Vector2(-600.0, -600.0), a + Vector2(1200.0, 1200.0)), Color("07090b"))
    if w.ground_tex != null:
        w.draw_texture_rect(w.ground_tex, Rect2(Vector2.ZERO, a), true)
    for d in w.decor:
        match d.kind:
            "rect":
                w.draw_rect(d.rect, d.col)
            "frame":
                w.draw_rect(d.rect, d.col, false, 2.0)
            "ring":
                w.draw_arc(d.pos, d.r, 0.0, TAU, 28, d.col, 2.0)
            "label":
                w.draw_string(font, d.pos, d.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, d.col)
    w.draw_rect(Rect2(Vector2.ZERO, a), edge, false, 3.0)

    # --- drop shadows of the props that are on screen
    var near: Array = []
    for p in w.props:
        var rect: Rect2 = p.rect
        if not view.intersects(rect.grow(90.0)):
            continue
        near.append(p)
        if p.kind == "box":
            w.draw_rect(Rect2(rect.position + Vector2(5.0, 7.0), rect.size), Color(0.0, 0.0, 0.0, 0.3))
        else:
            w.draw_circle(p.c + Vector2(4.0, 5.0), rect.size.x * 0.9, Color(0.0, 0.0, 0.0, 0.26))

    # --- friendly ground effects
    for z in w.zones:
        var zc: Color = z.col
        w.draw_circle(z.pos, z.r, Color(zc, 0.14))
        w.draw_arc(z.pos, z.r, t * 0.8, t * 0.8 + TAU, 24, Color(zc, 0.7), 1.2)
        w.draw_arc(z.pos, z.r * 0.6, -t * 1.4, -t * 1.4 + 4.2, 14, Color(zc, 0.45), 1.0)

    # --- hazards: amber blinking outline while warning, solid red when live. Shape + motion, not colour alone.
    var pulse: float = 0.5 + 0.5 * sin(t * 14.0)
    for h in w.hazards:
        var warn: bool = h.warn > 0.0
        var fill: Color = Color(1.0, 0.72, 0.1, 0.08 + 0.14 * pulse) if warn else Color(1.0, 0.25, 0.12, 0.5)
        var line: Color = Color(1.0, 0.8, 0.2, 0.95) if warn else Color(1.0, 0.95, 0.8, 1.0)
        if h.slow and not warn:
            fill = Color(0.6, 0.72, 0.78, 0.32)
            line = Color(0.8, 0.9, 0.95, 0.8)
        var grow: float = 1.0
        if warn:
            grow = 1.0 - h.warn / h.warn_max
        for r in h.rects:
            w.draw_rect(r, fill)
            w.draw_rect(r, line, false, lw)
        for c in h.circles:
            w.draw_circle(c[0], c[1], fill)
            w.draw_arc(c[0], c[1], 0.0, TAU, 28, line, lw)
            if warn:
                w.draw_arc(c[0], maxf(2.0, c[1] * grow), 0.0, TAU, 24, line, lw)

    # --- pickups
    for g in w.gems:
        var gp: Vector2 = g.pos
        if not view.has_point(gp):
            continue
        var bob: float = sin(t * 5.0 + gp.x) * 1.2
        w.draw_circle(gp + Vector2(0.0, 2.0), 2.0, Color(0.0, 0.0, 0.0, 0.3))
        var gc: Color = Color("f0d278") if g.xp >= 5 else Color("67dcf4")
        var gs: float = 2.6 if g.xp >= 5 else 1.9
        w.draw_rect(Rect2(gp + Vector2(-gs, -gs - 3.0 + bob), Vector2(gs * 2.0, gs * 2.0)), gc)
        w.draw_rect(Rect2(gp + Vector2(-0.8, -3.8 + bob), Vector2(1.6, 1.6)), Color(1.0, 1.0, 1.0))

    # --- actors
    for e in w.enemies:
        if e.hp > 0.0 and view.has_point(e.pos):
            Art.enemy(w, e, t, hc)
    w.arsenal.draw(w)
    # Friendly shots are round with coloured trails; hostile bolts are outlined squares.
    for s in w.shots:
        var sp: Vector2 = s.pos + up
        var sc: Color = s.col
        var sr: float = s.r
        w.draw_line(sp - s.vel.normalized() * (7.0 + sr), sp, Color(sc, 0.8), maxf(1.5, sr * 0.5))
        w.draw_circle(sp, maxf(1.6, sr * 0.45), Color(1.0, 1.0, 1.0))
    for b in w.bolts:
        var bp: Vector2 = b.pos + up
        var bc: Color = b.col
        var box := Rect2(bp - Vector2(2.6, 2.6), Vector2(5.2, 5.2))
        w.draw_line(bp - b.vel.normalized() * 7.0, bp, Color(bc, 0.5), 2.0)
        w.draw_rect(box, bc)
        w.draw_rect(box, Color(1.0, 1.0, 1.0, 0.9), false, 1.6 if hc else 0.8)
    var pl: Dictionary = w.player
    var ghost: bool = pl.iframe > 0.0 and fmod(t * 16.0, 2.0) < 1.0
    var moving: bool = w.move_input.length() > 0.1 and w.active
    Art.harry(w, pl.pos, pl.facing, pl.aim, t, ghost, moving)

    # --- extruded props, far ones first so nearer roofs overlap them
    near.sort_custom(func(p1, p2): return cam.distance_squared_to(p1.c) > cam.distance_squared_to(p2.c))
    for p in near:
        _prop(w, p, cam, edge)

    # --- transient effects and weather above everything
    for f in w.fx:
        var k: float = clampf(f.t / f.life, 0.0, 1.0)
        var fc: Color = f.col
        fc.a = 1.0 - k
        match f.kind:
            "ring":
                w.draw_arc(f.pos, lerpf(f.r0, f.r1, k), 0.0, TAU, 22, fc, float(f.get("width", 1.6)))
            "line":
                w.draw_line(f.a, f.b, fc, float(f.get("width", 1.6)))
            "text":
                w.draw_string(font, f.pos + Vector2(0.0, -16.0 * k), str(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, fc)
    for q in w.parts:
        if q.g:
            continue
        var qc: Color = q.c
        qc.a *= minf(1.0, q.t / q.m * 2.0)
        var qp: Vector2 = q.p
        if q.k == 1:
            w.draw_line(qp, qp - q.v * 0.03, qc, 0.8)
        else:
            w.draw_rect(Rect2(qp, Vector2(q.s, q.s)), qc)

    # --- night: a tinted veil that the additive lights then cut through
    var tint: Color = ch.tint
    w.draw_rect(view, Color(tint, float(ch.dark)))


# One extruded prop. Walls are shaded quads between the footprint and the lifted roof.
static func _prop(w, p: Dictionary, cam: Vector2, edge: Color) -> void:
    var rect: Rect2 = p.rect
    var h: float = p.h
    var col: Color = p.col
    var col2: Color = p.col2
    var c: Vector2 = p.c
    var kind: String = p.kind
    if kind == "box":
        var b0: Vector2 = rect.position
        var b2: Vector2 = rect.end
        var b1 := Vector2(b2.x, b0.y)
        var b3 := Vector2(b0.x, b2.y)
        var t0: Vector2 = lift(b0, cam, h)
        var t1: Vector2 = lift(b1, cam, h)
        var t2: Vector2 = lift(b2, cam, h)
        var t3: Vector2 = lift(b3, cam, h)
        var lo: Color = col.darkened(0.66)
        var hi_a: Color = col.darkened(0.28)
        var hi_b: Color = col.darkened(0.44)
        var no_uv := PackedVector2Array()
        w.draw_primitive(PackedVector2Array([b0, b1, t1, t0]), PackedColorArray([lo, lo, hi_a, hi_a]), no_uv)
        w.draw_primitive(PackedVector2Array([b3, b2, t2, t3]), PackedColorArray([lo, lo, hi_a, hi_a]), no_uv)
        w.draw_primitive(PackedVector2Array([b0, b3, t3, t0]), PackedColorArray([lo, lo, hi_b, hi_b]), no_uv)
        w.draw_primitive(PackedVector2Array([b1, b2, t2, t1]), PackedColorArray([lo, lo, hi_b, hi_b]), no_uv)
        var roof := Rect2(t0, t2 - t0)
        w.draw_rect(roof, col)
        if roof.size.x > 30.0 and roof.size.y > 30.0:
            w.draw_rect(roof.grow(-6.0), col2)
            if roof.size.x > 90.0:
                # ridge line and a chimney that pokes a little higher than the roof
                var mid: float = roof.position.y + roof.size.y * 0.5
                w.draw_line(Vector2(roof.position.x + 8.0, mid), Vector2(roof.end.x - 8.0, mid), col2.lightened(0.12), 1.2)
                var base: Vector2 = rect.position + rect.size * 0.25
                var top: Vector2 = lift(base, cam, h + 0.07)
                var foot: Vector2 = lift(base, cam, h)
                w.draw_line(foot + Vector2(5.0, 5.0), top + Vector2(5.0, 5.0), col.darkened(0.6), 9.0)
                w.draw_rect(Rect2(top, Vector2(10.0, 10.0)), col.darkened(0.25))
                w.draw_rect(Rect2(top + Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color("121416"))
        w.draw_rect(roof, edge, false, 1.2)
    elif kind == "tree":
        var s: float = rect.size.x
        var crown: Vector2 = lift(c, cam, h)
        w.draw_line(c, lift(c, cam, h * 0.7), col, s * 0.55)
        w.draw_circle(crown + Vector2(s * 0.5, s * 0.4), s * 1.5, Color(col2.darkened(0.35), 0.8))
        w.draw_circle(crown, s * 1.9, Color(col2, 0.86))
        w.draw_circle(crown - Vector2(s * 0.5, s * 0.5), s * 1.1, Color(col2.lightened(0.14), 0.86))
    elif kind == "lamp":
        var head: Vector2 = lift(c, cam, h)
        w.draw_line(c, head, col, 1.6)
        w.draw_circle(head, 2.6, col2)
    elif kind == "hoop":
        var ring: Vector2 = lift(c, cam, h)
        w.draw_line(c, ring, col.darkened(0.3), 2.0)
        w.draw_arc(ring, 9.0, 0.0, TAU, 16, col, 2.0)


## Additive pass: lights, spell glow, bright particles.
static func glow(w, ci: CanvasItem) -> void:
    var tex: Texture2D = w.light_tex
    var cam: Vector2 = w.cam
    var t: float = w.run_time
    var view: Rect2 = _view(w, 110.0)
    for l in w.lights:
        var base: Vector2 = l.pos
        if not view.has_point(base):
            continue
        var lp: Vector2 = lift(base, cam, l.h)
        var r: float = l.r * (0.94 + 0.06 * sin(t * 7.0 + base.x))
        var lc: Color = l.col
        ci.draw_texture_rect(tex, Rect2(lp - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(lc, 0.5))
    var pp: Vector2 = w.player.pos
    ci.draw_texture_rect(tex, Rect2(pp - Vector2(70.0, 70.0), Vector2(140.0, 140.0)), false, Color(1.0, 0.9, 0.72, 0.3))
    var up := Vector2(0.0, -5.0)
    for s in w.shots:
        var sp: Vector2 = s.pos + up
        var sr: float = 7.0 + s.r
        var sc: Color = s.col
        ci.draw_texture_rect(tex, Rect2(sp - Vector2(sr, sr), Vector2(sr, sr) * 2.0), false, Color(sc, 0.85))
    for b in w.bolts:
        var bp: Vector2 = b.pos + up
        var bc: Color = b.col
        ci.draw_texture_rect(tex, Rect2(bp - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), false, Color(bc, 0.7))
    for g in w.gems:
        var gp: Vector2 = g.pos
        if view.has_point(gp):
            ci.draw_texture_rect(tex, Rect2(gp - Vector2(6.0, 9.0), Vector2(12.0, 12.0)), false, Color(0.4, 0.86, 0.96, 0.5))
    for z in w.zones:
        var zp: Vector2 = z.pos
        var zr: float = z.r * 1.15
        var zc: Color = z.col
        ci.draw_texture_rect(tex, Rect2(zp - Vector2(zr, zr), Vector2(zr, zr) * 2.0), false, Color(zc, 0.26))
    for e in w.enemies:
        if e.hp <= 0.0:
            continue
        var ep: Vector2 = e.pos
        if e.boss:
            var er: float = e.r * 2.6
            var ec: Color = e.col2
            ci.draw_texture_rect(tex, Rect2(ep - Vector2(er, er), Vector2(er, er) * 2.0), false, Color(ec, 0.34))
        elif e.s.has("burn"):
            var fr: float = e.r * 1.8
            ci.draw_texture_rect(tex, Rect2(ep - Vector2(fr, fr), Vector2(fr, fr) * 2.0), false, Color(1.0, 0.5, 0.15, 0.5))
    w.arsenal.glow(ci, tex)
    for q in w.parts:
        if not q.g:
            continue
        var qc: Color = q.c
        qc.a = minf(1.0, q.t / q.m * 2.0)
        var qp: Vector2 = q.p
        var qs: float = q.s
        ci.draw_rect(Rect2(qp - Vector2(qs, qs) * 0.5, Vector2(qs, qs)), qc)
        ci.draw_texture_rect(tex, Rect2(qp - Vector2(qs, qs) * 2.0, Vector2(qs, qs) * 4.0), false, Color(qc, qc.a * 0.5))


## Top overlay: vignette, lightning and damage flashes.
static func top(w, ci: CanvasItem) -> void:
    var view: Rect2 = _view(w, 40.0)
    var flash_on: bool = bool(w.settings.get("flash", true))
    if w.storm_flash > 0.0 and flash_on:
        ci.draw_rect(view, Color(0.8, 0.88, 1.0, w.storm_flash * 0.16))
    ci.draw_texture_rect(w.vig_tex, view, false)
    if w.flash > 0.0 and flash_on:
        ci.draw_rect(view, Color(1.0, 0.2, 0.15, w.flash * 0.2))
