extends RefCounted
## Pseudo-3D top-down sprites. The high-resolution master atlas is in assets/visual-kit/sprites/;
## gameplay keeps procedural silhouettes for tiny Android-scale rendering and low memory use.

const CLOAK := Color("20252a")
const SCARF := Color("9b2935")
const GOLD := Color("c4a149")
const HAIR := Color("141719")
const GLASS := Color("ced2c5")
const SCAR := Color("eadb9a")
const WAND := Color("b58c51")
const SPELL := Color("67dcf4")
const SHADOW := Color(0.0, 0.0, 0.0, 0.32)
const AMBER := Color(1.0, 0.72, 0.12, 0.9)


## Harry from above: dark cloak, red/gold scarf, black hair, round glasses, scar, wand pointing at the auto-target.
static func harry(ci: CanvasItem, pos: Vector2, facing: Vector2, aim: Vector2, t: float, ghost: bool) -> void:
    ci.draw_set_transform(pos + Vector2(1.5, 5.5), 0.0, Vector2(1.55, 0.68))
    ci.draw_circle(Vector2.ZERO, 6.0, SHADOW)
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    var f: Vector2 = Vector2.DOWN
    if facing.length() > 0.1:
        f = facing.normalized()
    var s: Vector2 = Vector2(-f.y, f.x)
    var a: float = 0.45 if ghost else 1.0
    var back: Vector2 = pos - f * 8.0
    var cloak := PackedVector2Array([pos + s * 5.0 + f * 2.0, pos - s * 5.0 + f * 2.0, back - s * 8.0, back + s * 8.0])
    ci.draw_colored_polygon(cloak, Color(CLOAK.darkened(0.45), a))
    cloak.append(cloak[0])
    ci.draw_polyline(cloak, Color("0d1013", a), 2.0)
    var inner := PackedVector2Array([pos + s * 3.8 + f * 1.5, pos - s * 3.8 + f * 1.5, back - s * 5.8, back + s * 5.8])
    ci.draw_colored_polygon(inner, Color(CLOAK, a))
    ci.draw_line(back + s * 4.0, pos + f * 1.6 + s * 2.0, Color("59606a", a), 1.0)
    ci.draw_line(pos - s * 6.0 - f * 1.0, pos + s * 6.0 - f * 1.0, Color(SCARF, a), 3.0)
    ci.draw_line(pos - s * 2.0 - f * 1.0, pos + s * 2.0 - f * 1.0, Color(GOLD, a), 3.0)
    var head: Vector2 = pos + f * 2.0
    ci.draw_circle(head, 5.4, Color("0b0e10", a))
    ci.draw_circle(head + f * 0.45, 4.4, Color("d4b18d", a))
    ci.draw_circle(head - f * 1.2, 4.6, Color(HAIR, a))
    ci.draw_circle(head + f * 3.0 + s * 2.2, 1.5, Color(GLASS, a))
    ci.draw_circle(head + f * 3.0 - s * 2.2, 1.5, Color(GLASS, a))
    ci.draw_line(head + f * 1.5 + s * 1.2, head - f * 0.5 + s * 0.2, Color(SCAR, a), 1.0)
    var d: Vector2 = f
    if aim.length() > 0.1:
        d = aim.normalized()
    var hand: Vector2 = pos + s * 5.0
    ci.draw_line(hand, hand + d * 9.0, Color(WAND, a), 2.0)
    ci.draw_line(hand + Vector2(0.6, 0.6), hand + d * 9.0 + Vector2(0.6, 0.6), Color("4f3420", a), 1.0)
    ci.draw_circle(hand + d * 9.0, 2.0 + 0.5 * sin(t * 10.0), SPELL)


static func enemy(ci: CanvasItem, e: Dictionary, t: float, hc: bool) -> void:
    var pos: Vector2 = e.pos
    var r: float = e.r
    var col: Color = e.col
    var col2: Color = e.col2
    if e.flash > 0.0:
        col = Color(1.0, 1.0, 1.0)
    var face: Vector2 = e.face
    var wob: float = sin(t * 9.0 + e.id)
    ci.draw_circle(pos + Vector2(1.0, r * 0.45), r, SHADOW)
    match e.look:
        "blob":
            ci.draw_circle(pos, r, col)
            ci.draw_arc(pos, r, 0.0, TAU, 12, col.lightened(0.25), 1.5)
            ci.draw_circle(pos, r * 0.5 + wob * 0.6, col2)
        "pixie":
            ci.draw_circle(pos + Vector2(-r, -1.0 + wob * 1.5), r * 0.7, Color(col2, 0.7))
            ci.draw_circle(pos + Vector2(r, -1.0 - wob * 1.5), r * 0.7, Color(col2, 0.7))
            ci.draw_circle(pos, r * 0.6, col)
        "box":
            var b := Rect2(pos - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6))
            ci.draw_rect(b, col)
            ci.draw_rect(b, col2, false, 1.5)
            ci.draw_line(pos - Vector2(r * 0.5, 0.0), pos + Vector2(r * 0.5, 0.0), col2, 1.0)
        "armor":
            ci.draw_rect(Rect2(pos - Vector2(r * 0.9, r * 0.35) + Vector2(1.5, 2.0), Vector2(r * 1.8, r * 1.65)), Color("111619"))
            ci.draw_rect(Rect2(pos - Vector2(r * 0.8, r * 0.5), Vector2(r * 1.6, r * 1.4)), col)
            ci.draw_rect(Rect2(pos - Vector2(r * 0.6, r), Vector2(r * 1.2, r * 0.7)), col.lightened(0.18))
            ci.draw_rect(Rect2(pos - Vector2(r * 0.8, r), Vector2(r * 1.6, r * 1.9)), Color("a99563"), false, 1.0)
            ci.draw_circle(pos + Vector2(0.0, r * 0.2), r * 0.25, col2)
        "wizard":
            ci.draw_circle(pos + Vector2(1.5, 2.5), r * 0.95, Color("12161b"))
            ci.draw_rect(Rect2(pos - Vector2(r * 0.9, r * 0.4), Vector2(r * 1.8, r * 1.3)), col)
            ci.draw_rect(Rect2(pos - Vector2(r * 0.72, r * 0.28), Vector2(r * 0.5, r * 0.86)), col.lightened(0.16))
            ci.draw_rect(Rect2(pos - Vector2(r * 0.5, r), Vector2(r, r * 0.8)), Color("b0a99d"))
            ci.draw_line(pos + Vector2(-r * 0.3, -r * 0.65), pos + Vector2(r * 0.3, -r * 0.65), Color("1f2427"), 1.0)
            ci.draw_line(pos + face * r * 0.6, pos + face * (r + 6.0), Color("d6c89d"), 1.5)
            ci.draw_circle(pos + face * (r + 6.0), 1.8, col2)
        "spider":
            for i in 3:
                var ang: float = -0.8 + i * 0.8 + wob * 0.12
                var leg: Vector2 = Vector2(cos(ang), sin(ang)) * r * 1.9
                ci.draw_line(pos, pos + leg, col2, 2.0)
                ci.draw_line(pos, pos + Vector2(-leg.x, leg.y), col2, 2.0)
            ci.draw_circle(pos, r * 0.8, col)
            ci.draw_circle(pos + face * r * 0.7, r * 0.5, col.lightened(0.12))
            ci.draw_circle(pos + face * r * 0.9 + Vector2(-1.5, 0.0), 1.0, Color("ff5548"))
            ci.draw_circle(pos + face * r * 0.9 + Vector2(1.5, 0.0), 1.0, Color("ff5548"))
        "dementor":
            ci.draw_circle(pos, r, col)
            ci.draw_circle(pos - face * r * 0.9 + Vector2(wob, 0.0), r * 0.7, col)
            ci.draw_circle(pos - face * r * 1.7 - Vector2(wob, 0.0), r * 0.45, col)
            ci.draw_arc(pos, r, 0.0, TAU, 12, Color("475665"), 1.5)
            ci.draw_line(pos + Vector2(-2.5, -1.0), pos + Vector2(2.5, -1.0), col2, 1.0)
        "plant":
            ci.draw_circle(pos + Vector2(-r * 0.5, r * 0.3), r * 0.6, col)
            ci.draw_circle(pos + Vector2(r * 0.5, r * 0.3), r * 0.6, col)
            ci.draw_circle(pos + Vector2(0.0, -r * 0.3), r * 0.7, col.lightened(0.1))
            ci.draw_circle(pos + Vector2(0.0, -r * 0.3), r * 0.25 + wob * 0.4, col2)
        "beast":
            ci.draw_circle(pos - face * r * 0.5, r * 0.9, col)
            ci.draw_circle(pos + face * r * 0.5, r * 0.7, col.lightened(0.1))
            ci.draw_arc(pos - face * r * 0.5, r * 0.9, 0.0, TAU, 10, col2, 1.0)
            ci.draw_circle(pos + face * r * 0.9, 1.4, Color("dc504e"))
        "ball":
            ci.draw_circle(pos, r, col)
            ci.draw_arc(pos, r, 0.0, TAU, 10, col2, 1.5)
            ci.draw_circle(pos + Vector2(-r * 0.3, -r * 0.3), r * 0.25, col2)
        "inferi":
            ci.draw_line(pos + Vector2(-r, wob), pos + Vector2(r, -wob), col2, 2.0)
            ci.draw_rect(Rect2(pos - Vector2(r * 0.5, r * 0.6), Vector2(r, r * 1.4)), col)
            ci.draw_circle(pos - Vector2(0.0, r * 0.7), r * 0.45, col.lightened(0.15))
        "golem":
            ci.draw_circle(pos + Vector2(1.5, 3.0), r * 0.95, Color("11171b"))
            ci.draw_circle(pos, r, col)
            ci.draw_circle(pos - Vector2(r * 0.22, r * 0.28), r * 0.62, col.lightened(0.16))
            ci.draw_line(pos - Vector2(r * 0.55, 0.0), pos + Vector2(r * 0.55, 0.0), Color("dffaff"), 1.5)
            ci.draw_circle(pos + face * r * 0.42, r * 0.2, col2)
        "serpent":
            var tail: Vector2 = pos - face * r * 0.7
            ci.draw_circle(tail + Vector2(1.0, 2.0), r * 0.78, Color("111619"))
            ci.draw_circle(tail, r * 0.78, col.darkened(0.12))
            ci.draw_circle(pos + face * r * 0.55, r * 0.64, col)
            ci.draw_arc(tail, r * 0.58, 0.0, TAU, 10, col2, 1.0)
            ci.draw_circle(pos + face * r * 0.9, r * 0.14, col2)
        "wisp":
            ci.draw_circle(pos + Vector2(0.0, 2.0), r * 1.1, Color(col, 0.15))
            ci.draw_arc(pos, r, t * 4.0, t * 4.0 + 4.8, 12, col2, 2.0)
            ci.draw_circle(pos, r * 0.42, col)
            ci.draw_circle(pos - Vector2(r * 0.16, r * 0.18), r * 0.18, col2)
        "coach":
            var cb := Rect2(pos - Vector2(r, r * 0.65), Vector2(r * 2.0, r * 1.3))
            ci.draw_rect(cb.position + Vector2(2.0, 3.0), cb.size, Color("101217"))
            ci.draw_rect(cb, col)
            ci.draw_rect(cb.grow(-r * 0.22), col.lightened(0.1))
            ci.draw_circle(pos + Vector2(-r * 0.62, r * 0.72), r * 0.28, col2)
            ci.draw_circle(pos + Vector2(r * 0.62, r * 0.72), r * 0.28, col2)
        "owl":
            ci.draw_circle(pos + Vector2(0.0, 2.0), r, Color("11151b"))
            ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-r * 1.2, 0.0), pos, pos + Vector2(-r * 0.25, r * 0.75)]), col)
            ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(r * 1.2, 0.0), pos, pos + Vector2(r * 0.25, r * 0.75)]), col)
            ci.draw_circle(pos, r * 0.56, col.lightened(0.12))
            ci.draw_circle(pos - Vector2(r * 0.2, r * 0.12), r * 0.14, col2)
            ci.draw_circle(pos + Vector2(r * 0.2, -r * 0.12), r * 0.14, col2)
        "gargoyle":
            ci.draw_circle(pos + Vector2(1.5, 2.8), r, Color("11151b"))
            ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-r * 1.15, -r * 0.45), pos + Vector2(-r * 0.3, r * 0.82), pos]), col.darkened(0.08))
            ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(r * 1.15, -r * 0.45), pos + Vector2(r * 0.3, r * 0.82), pos]), col.darkened(0.08))
            ci.draw_circle(pos, r * 0.68, col)
            ci.draw_arc(pos, r * 0.52, 3.5, 5.9, 8, col.lightened(0.2), 1.0)
            ci.draw_circle(pos + face * r * 0.42, r * 0.2, col2)
        "echo":
            ci.draw_arc(pos, r, t * 3.0, t * 3.0 + 4.5, 10, col2, 1.5)
            ci.draw_arc(pos, r * 0.55, -t * 4.0, -t * 4.0 + 4.0, 8, col, 1.5)
        "snitch":
            ci.draw_line(pos, pos + Vector2(-r * 2.2, -r * 0.6 + wob * 3.0), col2, 2.0)
            ci.draw_line(pos, pos + Vector2(r * 2.2, -r * 0.6 - wob * 3.0), col2, 2.0)
            ci.draw_arc(pos, r * 1.6, t * 6.0, t * 6.0 + 5.0, 16, Color(col2, 0.6), 1.5)
            ci.draw_circle(pos, r * 0.7, col)
            ci.draw_circle(pos + Vector2(-r * 0.2, -r * 0.2), r * 0.2, col2)
        "hex":
            ci.draw_circle(pos, r, col)
            ci.draw_arc(pos, r, t * 1.5, t * 1.5 + 4.0, 20, Color("47ed5b"), 3.0)
            ci.draw_arc(pos, r * 0.7, -t * 2.0, -t * 2.0 + 4.0, 16, Color("b7e5ff"), 2.0)
            var core: Color = Color("f0d278") if e.weak > 0.0 else col2
            ci.draw_circle(pos, r * 0.3, core)
        _:
            ci.draw_circle(pos, r, col)

    # Shared rim and top-left highlight make every low-resolution silhouette read as a tiny
    # pseudo-3D object rather than a flat token.
    ci.draw_arc(pos - Vector2(r * 0.1, r * 0.12), r * 0.82, 3.55, 5.55, 9, Color(col2, 0.4), 1.0)

    # Telegraphs: a shape plus motion before every dangerous move.
    var state: String = e.state
    if state == "wind":
        var cd: Vector2 = e.dir
        ci.draw_line(pos, pos + cd * 150.0, AMBER, 4.0 if hc else 2.0)
        ci.draw_arc(pos, r + 3.0, 0.0, TAU, 10, AMBER, 1.5)
    elif state == "aim":
        ci.draw_arc(pos, r + 3.0 + wob, 0.0, TAU, 10, AMBER, 2.5 if hc else 1.5)
    elif state == "tell" and e.boss:
        boss_tell(ci, e, hc)
    if e.stun > 0.0:
        ci.draw_arc(pos - Vector2(0.0, r + 3.0), 3.0, t * 8.0, t * 8.0 + 4.0, 6, Color("f0d278"), 1.5)
    if e.elite:
        ci.draw_arc(pos, r + 2.0, 0.0, TAU, 14, Color("f0d278"), 1.0)
    if e.boss:
        ci.draw_arc(pos, r + 4.0, 0.0, TAU, 20, Color("e0503c"), 1.5)


static func boss_tell(ci: CanvasItem, e: Dictionary, hc: bool) -> void:
    var pos: Vector2 = e.pos
    var w: float = 4.0 if hc else 2.0
    var k: float = 1.0 - clampf(e.state_t / maxf(e.tell, 0.01), 0.0, 1.0)
    match e.pat:
        "ring", "spin", "core":
            # Amber arc = incoming ring. The pale line marks the safe gap.
            var g: float = e.gap
            ci.draw_arc(pos, 40.0 + 30.0 * k, g + 0.63, g + TAU - 0.63, 28, AMBER, w)
            ci.draw_line(pos, pos + Vector2.from_angle(g) * 150.0, Color(0.6, 1.0, 1.0, 0.9), w)
        "fan":
            var fd: Vector2 = e.dir
            ci.draw_line(pos, pos + fd.rotated(-0.5) * 170.0, AMBER, w)
            ci.draw_line(pos, pos + fd.rotated(0.5) * 170.0, AMBER, w)
            ci.draw_arc(pos, maxf(4.0, 170.0 * k), fd.angle() - 0.5, fd.angle() + 0.5, 10, AMBER, w)
        "charge":
            var cd: Vector2 = e.dir
            ci.draw_line(pos, pos + cd * 190.0, AMBER, w * 2.0)
        "summon":
            ci.draw_arc(pos, e.r + 6.0 + 20.0 * k, 0.0, TAU, 16, Color(0.8, 0.5, 1.0, 0.9), w)
