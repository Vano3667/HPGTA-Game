extends RefCounted
## Code-drawn pseudo-3D sprites. Every actor is a small stack: an elliptical shadow on the ground,
## a shaded body lifted above it, and details on top. Flying things hover higher and bob.
## Silhouettes and palette follow refs/character_harry_topdown.svg and refs/enemies_topdown.svg.

const CLOAK := Color("262c33")
const SCARF := Color("b02a38")
const GOLD := Color("d4ae4c")
const HAIR := Color("141719")
const SKIN := Color("e8ba8f")
const GLASS := Color("dfe4d8")
const SCAR := Color("eadb9a")
const WAND := Color("b58c51")
const SPELL := Color("67dcf4")
const SHADOW := Color(0.0, 0.0, 0.0, 0.36)
const AMBER := Color(1.0, 0.72, 0.12, 0.9)


static func shadow(ci: CanvasItem, pos: Vector2, r: float) -> void:
    ci.draw_set_transform(pos, 0.0, Vector2(1.0, 0.5))
    ci.draw_circle(Vector2.ZERO, r, SHADOW)
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A lit sphere: dark rim, body colour, highlight towards the top-left light.
static func ball(ci: CanvasItem, pos: Vector2, r: float, col: Color) -> void:
    ci.draw_circle(pos, r, col.darkened(0.42))
    ci.draw_circle(pos + Vector2(-r * 0.1, -r * 0.14), r * 0.84, col)
    ci.draw_circle(pos + Vector2(-r * 0.3, -r * 0.36), r * 0.3, col.lightened(0.32))


## A small 3D block: lit top face with a darker front face below it.
static func slab(ci: CanvasItem, pos: Vector2, half: Vector2, depth: float, col: Color, edge: Color) -> void:
    ci.draw_rect(Rect2(pos + Vector2(-half.x, half.y), Vector2(half.x * 2.0, depth)), col.darkened(0.48))
    ci.draw_rect(Rect2(pos - half, half * 2.0), col)
    ci.draw_rect(Rect2(pos - half, Vector2(half.x * 2.0, half.y * 0.7)), col.lightened(0.12))
    ci.draw_rect(Rect2(pos - half, half * 2.0), edge, false, 0.8)


## Harry: cloak skirt on the ground, shoulders and scarf above it, head on top, wand at the auto-target.
static func harry(ci: CanvasItem, pos: Vector2, facing: Vector2, aim: Vector2, t: float, ghost: bool, moving: bool) -> void:
    shadow(ci, pos + Vector2(0.0, 3.0), 8.5)
    var f: Vector2 = Vector2.DOWN
    if facing.length() > 0.1:
        f = facing.normalized()
    var s: Vector2 = Vector2(-f.y, f.x)
    var a: float = 0.45 if ghost else 1.0
    var bob: float = 0.0
    if moving:
        bob = sin(t * 14.0) * 0.8
    var sway: float = sin(t * 9.0) * (2.0 if moving else 0.6)
    var back: Vector2 = pos - f * 10.0 + s * sway
    var cloak := PackedVector2Array([pos + s * 6.0 + f * 2.0, pos - s * 6.0 + f * 2.0, back - s * 8.5, back + s * 8.5])
    ci.draw_colored_polygon(cloak, Color(CLOAK.darkened(0.3), a))
    cloak.append(cloak[0])
    ci.draw_polyline(cloak, Color(SCARF.darkened(0.2), a), 0.8)
    var torso: Vector2 = pos + Vector2(0.0, -4.0 - bob)
    ci.draw_circle(torso, 6.4, Color(CLOAK.darkened(0.25), a))
    ci.draw_circle(torso + Vector2(-0.6, -0.9), 5.4, Color(CLOAK.lightened(0.08), a))
    ci.draw_line(torso - s * 5.6, torso + s * 5.6, Color(SCARF, a), 2.6)
    ci.draw_line(torso - s * 1.8, torso + s * 1.8, Color(GOLD, a), 2.6)
    ci.draw_line(torso - f * 2.0, torso - f * 9.0 - s * sway, Color(SCARF, a), 2.0)
    ci.draw_line(torso - f * 6.0 - s * sway * 0.6, torso - f * 9.0 - s * sway, Color(GOLD, a), 2.0)
    var d: Vector2 = f
    if aim.length() > 0.1:
        d = aim.normalized()
    var hand: Vector2 = torso + s * 5.6
    ci.draw_line(hand, hand + d * 10.0, Color(WAND, a), 1.6)
    ci.draw_circle(hand + d * 10.0, 1.8 + 0.5 * sin(t * 10.0), SPELL)
    var head: Vector2 = pos + Vector2(0.0, -9.5 - bob) + f * 1.5
    ci.draw_circle(head, 5.3, Color(HAIR.lightened(0.05), a))
    ci.draw_circle(head + f * 1.9, 3.5, Color(SKIN, a))
    ci.draw_circle(head - f * 1.0 + Vector2(-0.5, -0.6), 4.5, Color(HAIR, a))
    ci.draw_circle(head - f * 1.6 + Vector2(-1.2, -1.4), 1.6, Color(HAIR.lightened(0.22), a))
    ci.draw_arc(head + f * 3.2 + s * 1.8, 1.3, 0.0, TAU, 8, Color(GLASS, a), 0.7)
    ci.draw_arc(head + f * 3.2 - s * 1.8, 1.3, 0.0, TAU, 8, Color(GLASS, a), 0.7)
    ci.draw_line(head + f * 2.0 + s * 1.3, head + f * 0.6 + s * 0.4, Color(SCAR, a), 0.8)


static func enemy(ci: CanvasItem, e: Dictionary, t: float, hc: bool) -> void:
    var ground: Vector2 = e.pos
    var r: float = e.r
    var col: Color = e.col
    var col2: Color = e.col2
    var st: Dictionary = e.s
    if st.has("petrify"):
        col = col.lerp(Color("9aa0a4"), 0.7)
    elif st.has("chill"):
        col = col.lerp(Color("9ad0ff"), 0.35)
    if e.flash > 0.0:
        col = Color(1.0, 1.0, 1.0)
    var face: Vector2 = e.face
    var side: Vector2 = Vector2(-face.y, face.x)
    var wob: float = sin(t * 9.0 + e.id)
    var up: float = r * 0.35
    if e.fly:
        up = r * 1.1 + sin(t * 4.0 + e.id) * 1.5
    if st.has("levitate"):
        up += 9.0 + sin(t * 6.0 + e.id) * 2.0
    shadow(ci, ground + Vector2(0.0, r * 0.3), r * (0.75 if e.fly else 1.0))
    var pos: Vector2 = ground + Vector2(0.0, -up)
    match e.look:
        "blob":
            ball(ci, pos, r, col)
            ci.draw_arc(pos + Vector2(0.0, -r * 0.2), r * 0.8, 0.0, TAU, 12, col.lightened(0.3), 1.0)
            ci.draw_circle(pos + Vector2(0.0, -r * 0.25), r * 0.42 + wob * 0.5, col2)
        "pixie":
            ci.draw_circle(pos + Vector2(-r, -1.0 + wob * 1.5), r * 0.7, Color(col2, 0.6))
            ci.draw_circle(pos + Vector2(r, -1.0 - wob * 1.5), r * 0.7, Color(col2, 0.6))
            ball(ci, pos, r * 0.62, col)
        "box":
            slab(ci, pos, Vector2(r, r * 0.75), r * 0.6, col, col2)
            ci.draw_line(pos - Vector2(r * 0.5, 0.0), pos + Vector2(r * 0.5, 0.0), col2, 0.8)
        "armor":
            slab(ci, pos + Vector2(0.0, r * 0.2), Vector2(r * 0.8, r * 0.6), r * 0.7, col, Color("a99563"))
            slab(ci, pos + Vector2(0.0, -r * 0.7), Vector2(r * 0.55, r * 0.38), r * 0.3, col.lightened(0.15), Color("a99563"))
            ci.draw_circle(pos + Vector2(0.0, r * 0.2), r * 0.24, col2)
        "wizard":
            ball(ci, pos + Vector2(0.0, r * 0.25), r * 0.95, col)
            ball(ci, pos + Vector2(0.0, -r * 0.6), r * 0.55, col.lightened(0.08))
            ci.draw_circle(pos + Vector2(0.0, -r * 0.6) + face * r * 0.22, r * 0.34, Color("c8c0b4"))
            ci.draw_line(pos + side * r * 0.7, pos + side * r * 0.7 + face * (r * 0.6 + 6.0), Color("d6c89d"), 1.2)
            ci.draw_circle(pos + side * r * 0.7 + face * (r * 0.6 + 6.0), 1.6, col2)
        "spider":
            for i in 4:
                var ang: float = -1.1 + i * 0.72 + wob * 0.12
                var leg: Vector2 = Vector2(cos(ang), sin(ang)) * r * 1.9
                ci.draw_line(pos, ground + leg, col2, 1.4)
                ci.draw_line(pos, ground + Vector2(-leg.x, leg.y), col2, 1.4)
            ball(ci, pos, r * 0.82, col)
            ball(ci, pos + face * r * 0.75, r * 0.48, col.lightened(0.1))
            ci.draw_circle(pos + face * r * 0.95 + side * 1.4, 0.9, Color("ff5548"))
            ci.draw_circle(pos + face * r * 0.95 - side * 1.4, 0.9, Color("ff5548"))
        "dementor":
            ci.draw_circle(pos - face * r * 1.7 - Vector2(wob, -r * 0.5), r * 0.45, Color(col, 0.7))
            ci.draw_circle(pos - face * r * 0.9 + Vector2(wob, r * 0.25), r * 0.72, Color(col, 0.85))
            ball(ci, pos, r, col.lightened(0.04))
            ci.draw_arc(pos, r, 0.0, TAU, 14, Color("56687a"), 1.0)
            ci.draw_circle(pos + face * r * 0.3, r * 0.3, Color("05070a"))
        "plant":
            ball(ci, pos + Vector2(-r * 0.5, r * 0.3), r * 0.6, col)
            ball(ci, pos + Vector2(r * 0.5, r * 0.3), r * 0.6, col)
            ball(ci, pos + Vector2(0.0, -r * 0.3), r * 0.72, col.lightened(0.1))
            ci.draw_circle(pos + Vector2(0.0, -r * 0.4), r * 0.24 + wob * 0.4, col2)
        "beast":
            ball(ci, pos - face * r * 0.5, r * 0.9, col)
            ball(ci, pos + face * r * 0.55 + Vector2(0.0, -r * 0.2), r * 0.66, col.lightened(0.1))
            ci.draw_arc(pos - face * r * 0.5, r * 0.9, 0.0, TAU, 10, col2, 0.8)
            ci.draw_circle(pos + face * r * 1.0 + side * 1.6 + Vector2(0.0, -r * 0.2), 1.0, Color("ff5a4a"))
            ci.draw_circle(pos + face * r * 1.0 - side * 1.6 + Vector2(0.0, -r * 0.2), 1.0, Color("ff5a4a"))
        "ball":
            ball(ci, pos, r, col)
            ci.draw_arc(pos, r, 0.0, TAU, 10, col2, 1.0)
        "inferi":
            ci.draw_line(pos + Vector2(-r, wob), pos + Vector2(r, -wob), col2, 1.6)
            slab(ci, pos + Vector2(0.0, r * 0.1), Vector2(r * 0.5, r * 0.6), r * 0.5, col, col2)
            ball(ci, pos - Vector2(0.0, r * 0.8), r * 0.46, col.lightened(0.15))
        "echo":
            ci.draw_arc(pos, r, t * 3.0, t * 3.0 + 4.5, 10, col2, 1.4)
            ci.draw_arc(pos, r * 0.55, -t * 4.0, -t * 4.0 + 4.0, 8, col, 1.4)
            ci.draw_circle(pos, r * 0.25, Color(col2, 0.8))
        "snake":
            for j in 5:
                var i: int = 4 - j
                var seg: Vector2 = pos - face * r * 0.85 * i + side * sin(t * 8.0 + e.id + i * 1.1) * r * 0.45 * minf(1.0, i)
                ball(ci, seg, r * (1.0 - 0.13 * i), col if i > 0 else col.lightened(0.1))
            ci.draw_circle(pos + face * r * 0.5 + side * r * 0.4, 1.0, col2)
            ci.draw_circle(pos + face * r * 0.5 - side * r * 0.4, 1.0, col2)
        "snitch":
            ci.draw_line(pos, pos + Vector2(-r * 2.2, -r * 0.6 + wob * 3.0), col2, 1.6)
            ci.draw_line(pos, pos + Vector2(r * 2.2, -r * 0.6 - wob * 3.0), col2, 1.6)
            ci.draw_arc(pos, r * 1.6, t * 6.0, t * 6.0 + 5.0, 16, Color(col2, 0.6), 1.2)
            ball(ci, pos, r * 0.7, col)
        "hex":
            ball(ci, pos, r, col)
            ci.draw_arc(pos, r, t * 1.5, t * 1.5 + 4.0, 20, Color("47ed5b"), 2.4)
            ci.draw_arc(pos, r * 0.7, -t * 2.0, -t * 2.0 + 4.0, 16, Color("b7e5ff"), 1.6)
            var core: Color = Color("f0d278") if st.has("mark") else col2
            ci.draw_circle(pos, r * 0.3, core)
        _:
            ball(ci, pos, r, col)

    # Telegraphs sit on the ground: a shape plus motion before every dangerous move.
    var state: String = e.state
    if state == "wind":
        var cd: Vector2 = e.dir
        ci.draw_line(ground, ground + cd * 140.0, AMBER, 3.0 if hc else 1.6)
        ci.draw_arc(ground, r + 3.0, 0.0, TAU, 10, AMBER, 1.2)
    elif state == "aim":
        ci.draw_arc(pos, r + 3.0 + wob, 0.0, TAU, 10, AMBER, 2.0 if hc else 1.2)
    elif state == "tell" and e.boss:
        boss_tell(ci, e, hc)

    # Status markers.
    if st.has("burn"):
        ci.draw_circle(pos + Vector2(wob, -r - 1.0), 1.8, Color("ff8a2a"))
    if st.has("wet"):
        ci.draw_arc(pos, r + 1.5, 0.3, 2.8, 8, Color("4aa8ff"), 1.0)
    if st.has("mark"):
        ci.draw_arc(pos, r + 3.0, t * 3.0, t * 3.0 + 1.6, 6, Color("fff0a0"), 1.0)
    if st.has("root"):
        ci.draw_arc(ground, r, 0.0, TAU, 10, Color("b08a5a"), 1.4)
    if st.has("fear"):
        ci.draw_circle(pos + Vector2(0.0, -r - 4.0), 1.5, Color("ffa0e0"))
    if e.hold > 0.0:
        ci.draw_arc(pos - Vector2(0.0, r + 3.0), 3.0, t * 8.0, t * 8.0 + 4.0, 6, Color("f0d278"), 1.2)
    if e.elite:
        ci.draw_arc(ground, r + 2.0, 0.0, TAU, 14, Color("f0d278"), 0.9)
    if e.boss:
        ci.draw_arc(ground, r + 4.0, 0.0, TAU, 20, Color("e0503c"), 1.2)


static func boss_tell(ci: CanvasItem, e: Dictionary, hc: bool) -> void:
    var pos: Vector2 = e.pos
    var w: float = 3.0 if hc else 1.6
    var k: float = 1.0 - clampf(e.state_t / maxf(e.tell, 0.01), 0.0, 1.0)
    match e.pat:
        "ring", "spin", "core":
            # Amber arc = incoming ring. The pale line marks the safe gap.
            var g: float = e.gap
            ci.draw_arc(pos, 36.0 + 26.0 * k, g + 0.63, g + TAU - 0.63, 28, AMBER, w)
            ci.draw_line(pos, pos + Vector2.from_angle(g) * 130.0, Color(0.6, 1.0, 1.0, 0.9), w)
        "fan":
            var fd: Vector2 = e.dir
            ci.draw_line(pos, pos + fd.rotated(-0.5) * 150.0, AMBER, w)
            ci.draw_line(pos, pos + fd.rotated(0.5) * 150.0, AMBER, w)
            ci.draw_arc(pos, maxf(4.0, 150.0 * k), fd.angle() - 0.5, fd.angle() + 0.5, 10, AMBER, w)
        "charge":
            var cd: Vector2 = e.dir
            ci.draw_line(pos, pos + cd * 176.0, AMBER, w * 2.0)
        "summon":
            ci.draw_arc(pos, e.r + 6.0 + 20.0 * k, 0.0, TAU, 16, Color(0.8, 0.5, 1.0, 0.9), w)
        "blink":
            ci.draw_arc(pos, maxf(3.0, (e.r + 16.0) * (1.0 - k)), 0.0, TAU, 16, Color(0.7, 1.0, 0.8, 0.9), w)
