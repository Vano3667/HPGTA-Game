extends RefCounted
## Builds a stage arena. With a painted map (art/gen/map_*.png) the image is the floor; painted
## obstacles (art/gen/prop_*.png) are placed on it from the PAINTED table and soft lights are added.
## Without a painted map the arena is procedural: solid props with a pseudo-3D height, ground decor
## and light sources, seeded so a chapter always looks the same.

const Sprites = preload("res://scripts/core/sprites.gd")

## World width of a painted obstacle, by the size class in its file name (the hero is about 20 wide).
const PROP_SIZE := {"s": 24.0, "m": 52.0, "l": 100.0, "xl": 180.0}
## Painted obstacles per map: [file name, x, y]. x is the centre and y the bottom edge of the
## sprite, both as fractions of the arena. File names are <type>-<size>-<name>:
## wall and low are solid, pit is a solid hole drawn flat on the floor, deco is not solid.
## Nobody on the agent side has seen these layouts; they follow rules (open centre, wide lanes,
## buildings along the edges) and are meant to be corrected from the user's feedback.
const PAINTED := {
    "01-diagon-alley": [
        ["wall-xl-shop-row", 0.17, 0.125], ["wall-l-book-shop", 0.10, 0.42], ["wall-l-potion-shop", 0.10, 0.66], ["wall-l-book-shop", 0.10, 0.95],
        ["wall-l-potion-shop", 0.90, 0.20], ["wall-l-book-shop", 0.90, 0.50], ["wall-xl-shop-row", 0.83, 0.75], ["wall-l-potion-shop", 0.90, 0.97],
        ["wall-m-market-stall", 0.30, 0.34], ["wall-m-market-stall", 0.70, 0.60],
        ["wall-s-lamp-post", 0.25, 0.18], ["wall-s-lamp-post", 0.75, 0.30], ["wall-s-lamp-post", 0.25, 0.56], ["wall-s-lamp-post", 0.75, 0.86],
        ["low-s-barrels", 0.27, 0.46], ["low-s-barrels", 0.74, 0.44], ["low-s-barrels", 0.60, 0.13],
        ["low-s-crates", 0.72, 0.52], ["low-s-crates", 0.28, 0.70], ["low-s-crates", 0.42, 0.09],
        ["low-m-cart", 0.36, 0.86], ["low-m-cart", 0.62, 0.24],
        ["pit-m-sinkhole", 0.62, 0.40], ["pit-m-sinkhole", 0.38, 0.66],
    ],
}


# A solid extruded block. h is the pseudo-3D height (parallax factor of the roof).
static func _box(w, rect: Rect2, h: float, col: Color, col2: Color) -> void:
    w.props.append({"kind": "box", "rect": rect, "c": rect.get_center(), "h": h, "col": col, "col2": col2})
    w.obstacles.append(rect)


static func _tree(w, pos: Vector2, s: float, trunk: Color, leaf: Color) -> void:
    var rect := Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s))
    w.props.append({"kind": "tree", "rect": rect, "c": pos, "h": 0.3, "col": trunk, "col2": leaf})
    w.obstacles.append(rect)


static func _hoop(w, pos: Vector2, col: Color) -> void:
    var rect := Rect2(pos - Vector2(5.0, 5.0), Vector2(10.0, 10.0))
    w.props.append({"kind": "hoop", "rect": rect, "c": pos, "h": 0.3, "col": col, "col2": col})
    w.obstacles.append(rect)


# A street lamp / torch: not solid, but it lights the scene.
static func _lamp(w, pos: Vector2, col: Color, r: float = 74.0) -> void:
    w.props.append({"kind": "lamp", "rect": Rect2(pos - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), "c": pos, "h": 0.22, "col": Color("26262a"), "col2": col})
    w.lights.append({"pos": pos, "h": 0.22, "r": r, "col": col})


static func _light(w, pos: Vector2, col: Color, r: float) -> void:
    w.lights.append({"pos": pos, "h": 0.0, "r": r, "col": col})


static func _rect(w, rect: Rect2, col: Color) -> void:
    w.decor.append({"kind": "rect", "rect": rect, "col": col})


static func _frame(w, rect: Rect2, col: Color) -> void:
    w.decor.append({"kind": "frame", "rect": rect, "col": col})


static func _ring(w, pos: Vector2, r: float, col: Color) -> void:
    w.decor.append({"kind": "ring", "pos": pos, "r": r, "col": col})


# Places the painted obstacles of a map. Returns how many were placed (0 when the art is missing).
# "rect" is where the sprite is drawn; "hit" is the solid part; "base" is its lower edge, used to
# decide whether the hero is in front of the obstacle or behind it.
static func _painted(w, map: String, accent: Color) -> int:
    if not PAINTED.has(map):
        return 0
    var a: Vector2 = w.arena
    var placed: int = 0
    for item in PAINTED[map]:
        var id: String = item[0]
        var tx: Texture2D = Sprites.tex("prop_%s_%s" % [map, id])
        if tx == null:
            continue
        var parts: PackedStringArray = id.split("-")
        var type: String = parts[0]
        var width: float = float(PROP_SIZE.get(parts[1], 52.0))
        var size := Vector2(width, width * tx.get_height() / float(tx.get_width()))
        var pos := Vector2(float(item[1]) * a.x - size.x * 0.5, float(item[2]) * a.y - size.y)
        pos.x = clampf(pos.x, 2.0, maxf(2.0, a.x - size.x - 2.0))
        pos.y = clampf(pos.y, 2.0, maxf(2.0, a.y - size.y - 2.0))
        var box := Rect2(pos, size)
        var hit: Rect2 = box
        var solid: bool = true
        var flat: bool = false
        if type == "wall":
            if width <= 30.0 and size.y > size.x * 1.5:
                # A post: only its base is solid, the rest can be walked behind.
                var b: float = size.x * 0.7
                hit = Rect2(pos.x + (size.x - b) * 0.5, pos.y + size.y - b, b, b)
            else:
                hit = Rect2(pos.x + size.x * 0.05, pos.y + size.y * 0.2, size.x * 0.9, size.y * 0.78)
        elif type == "low":
            hit = Rect2(pos.x + size.x * 0.1, pos.y + size.y * 0.3, size.x * 0.8, size.y * 0.62)
        elif type == "pit":
            flat = true
            hit = box.grow(-minf(size.x, size.y) * 0.16)
        else:
            flat = true
            solid = false
        w.props.append({"kind": "sprite", "rect": box, "c": box.get_center(), "h": 0.0, "tex": tx, "flat": flat, "hit": hit, "base": hit.end.y})
        if solid:
            w.obstacles.append(hit)
        if id.contains("lamp"):
            _light(w, Vector2(box.get_center().x, pos.y + size.x * 0.5), accent, 78.0)
        placed += 1
    return placed


static func build(w) -> void:
    w.obstacles = []
    w.props = []
    w.decor = []
    w.lights = []
    var ch: Dictionary = w.chapter
    var index: int = w.chapter_index
    var a: Vector2 = w.arena
    var c: Vector2 = a * 0.5
    var lr := RandomNumberGenerator.new()
    lr.seed = 4200 + index
    var prop: Color = ch.prop
    var prop2: Color = ch.prop2
    var edge: Color = ch.edge
    var accent: Color = ch.accent
    if w.floor_tex != null:
        var placed: int = _painted(w, str(ch.get("map", "")), accent)
        for i in (3 if placed > 0 else 7):
            _light(w, Vector2(lr.randf_range(0.15, 0.85) * a.x, lr.randf_range(0.1, 0.9) * a.y), accent, lr.randf_range(60.0, 100.0))
        return
    match ch.layout:
        "street":
            _rect(w, Rect2(c.x - 210.0, 0.0, 420.0, a.y), Color("353a38"))
            _rect(w, Rect2(c.x - 214.0, 0.0, 6.0, a.y), Color("8a7960"))
            _rect(w, Rect2(c.x + 208.0, 0.0, 6.0, a.y), Color("8a7960"))
            var y: float = 50.0
            while y < a.y - 280.0:
                var h: float = lr.randf_range(170.0, 250.0)
                var wl: float = lr.randf_range(200.0, 300.0)
                var wr: float = lr.randf_range(200.0, 300.0)
                _box(w, Rect2(40.0, y, wl, h), lr.randf_range(0.2, 0.32), prop.lerp(Color("4a5a52"), lr.randf() * 0.6), prop2)
                _box(w, Rect2(a.x - 40.0 - wr, y, wr, h), lr.randf_range(0.2, 0.32), prop.lerp(Color("5a4a5a"), lr.randf() * 0.6), prop2)
                _lamp(w, Vector2(c.x - 196.0, y + h * 0.5), accent)
                _lamp(w, Vector2(c.x + 196.0, y + h), accent)
                y += h + lr.randf_range(70.0, 110.0)
            for i in 16:
                var crate := Vector2(lr.randf_range(c.x - 190.0, c.x + 150.0), lr.randf_range(80.0, a.y - 120.0))
                if crate.distance_to(c) < 130.0:
                    continue
                _box(w, Rect2(crate, Vector2(lr.randf_range(24.0, 38.0), lr.randf_range(24.0, 38.0))), 0.07, Color("6a4a34"), Color("8a6444"))
            for i in 14:
                _ring(w, Vector2(lr.randf_range(c.x - 190.0, c.x + 190.0), lr.randf_range(60.0, a.y - 60.0)), lr.randf_range(8.0, 18.0), Color(0.45, 0.6, 0.75, 0.35))
        "village":
            for gx in 4:
                for gy in 6:
                    var cell := Vector2(110.0 + gx * 320.0, 90.0 + gy * 300.0)
                    var house := Rect2(cell + Vector2(lr.randf_range(0.0, 90.0), lr.randf_range(0.0, 80.0)), Vector2(lr.randf_range(120.0, 170.0), lr.randf_range(90.0, 130.0)))
                    if house.grow(110.0).has_point(c) or lr.randf() < 0.25:
                        continue
                    _box(w, house, lr.randf_range(0.2, 0.28), prop.lerp(Color("8a5a4a"), lr.randf() * 0.5), prop2)
                    _lamp(w, house.position + Vector2(-16.0, house.size.y + 14.0), accent, 64.0)
            for i in 26:
                _ring(w, Vector2(lr.randf_range(40.0, a.x - 40.0), lr.randf_range(40.0, a.y - 40.0)), lr.randf_range(10.0, 24.0), Color(1.0, 1.0, 1.0, 0.3))
        "courtyard":
            _rect(w, Rect2(c - Vector2(390.0, 390.0), Vector2(780.0, 780.0)), Color("56594f"))
            _frame(w, Rect2(c - Vector2(390.0, 390.0), Vector2(780.0, 780.0)), edge)
            _ring(w, c, 150.0, edge)
            _ring(w, c, 60.0, accent)
            for sx in [-1.0, 1.0]:
                for sy in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 440.0 - 70.0, c.y + sy * 440.0 - 70.0, 140.0, 140.0), 0.42, prop, prop2)
                    _lamp(w, Vector2(c.x + sx * 340.0, c.y + sy * 340.0), accent, 86.0)
                _box(w, Rect2(c.x + sx * 400.0 - 210.0, c.y - 660.0, 420.0, 40.0), 0.24, prop, prop2)
                _box(w, Rect2(c.x + sx * 400.0 - 210.0, c.y + 620.0, 420.0, 40.0), 0.24, prop, prop2)
            for i in 8:
                var statue: Vector2 = c + Vector2.from_angle(TAU * i / 8.0 + 0.4) * 270.0
                _box(w, Rect2(statue - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), 0.16, Color("8a8d86"), Color("a8aba4"))
        "pitch":
            _frame(w, Rect2(130.0, 170.0, a.x - 260.0, a.y - 340.0), edge)
            _ring(w, c, 120.0, edge)
            _rect(w, Rect2(130.0, c.y - 2.0, a.x - 260.0, 4.0), edge)
            for sy in [-1.0, 1.0]:
                for dx in [-120.0, 0.0, 120.0]:
                    _hoop(w, Vector2(c.x + dx, c.y + sy * 640.0), accent)
            _box(w, Rect2(20.0, 320.0, 70.0, a.y - 640.0), 0.2, prop, prop2)
            _box(w, Rect2(a.x - 90.0, 320.0, 70.0, a.y - 640.0), 0.2, prop, Color("2a4a8a"))
            for i in 6:
                _lamp(w, Vector2(110.0 if i % 2 == 0 else a.x - 110.0, 380.0 + i * 220.0), Color("fff4d0"), 110.0)
        "forest":
            _rect(w, Rect2(c.x - 70.0, 0.0, 140.0, a.y), Color(0.16, 0.13, 0.1, 0.55))
            for i in 46:
                var trunk := Vector2(lr.randf_range(60.0, a.x - 60.0), lr.randf_range(60.0, a.y - 60.0))
                if trunk.distance_to(c) < 150.0:
                    continue
                _tree(w, trunk, lr.randf_range(16.0, 26.0), prop, prop2.lerp(Color("1a3a2a"), lr.randf()))
            for i in 12:
                var shroom := Vector2(lr.randf_range(60.0, a.x - 60.0), lr.randf_range(60.0, a.y - 60.0))
                _ring(w, shroom, 7.0, accent)
                _light(w, shroom, accent, 46.0)
        "chamber":
            _rect(w, Rect2(c.x - 46.0, 0.0, 92.0, c.y - 190.0), Color(0.1, 0.32, 0.3, 0.6))
            _rect(w, Rect2(c.x - 46.0, c.y + 190.0, 92.0, a.y - c.y - 190.0), Color(0.1, 0.32, 0.3, 0.6))
            _ring(w, c, 170.0, edge)
            _ring(w, c, 120.0, Color("2a5a4a"))
            for i in 10:
                var py: float = 110.0 + i * 186.0
                if absf(py - c.y) < 150.0:
                    continue
                for sx in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 170.0 - 20.0, py - 20.0, 40.0, 40.0), 0.42, prop, prop2)
                    _light(w, Vector2(c.x + sx * 120.0, py), accent, 60.0)
            for i in 5:
                for sx in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 420.0 - 32.0, 180.0 + i * 370.0, 64.0, 64.0), 0.3, Color("5a6a64"), Color("3a5a4a"))
        "crossroads":
            _rect(w, Rect2(c.x - 150.0, 0.0, 300.0, a.y), Color("2a2c38"))
            _rect(w, Rect2(0.0, c.y - 150.0, a.x, 300.0), Color("2a2c38"))
            _ring(w, c, 110.0, edge)
            for sx in [-1.0, 1.0]:
                for sy in [-1.0, 1.0]:
                    for gx in 2:
                        for gy in 3:
                            var size := Vector2(lr.randf_range(140.0, 180.0), lr.randf_range(150.0, 210.0))
                            var px: float = c.x + sx * (200.0 + gx * 210.0)
                            var py2: float = c.y + sy * (200.0 + gy * 250.0)
                            if sx < 0.0:
                                px -= size.x
                            if sy < 0.0:
                                py2 -= size.y
                            _box(w, Rect2(px, py2, size.x, size.y), lr.randf_range(0.2, 0.34), prop.lerp(Color("5a4a6a"), lr.randf() * 0.5), prop2)
                    _lamp(w, Vector2(c.x + sx * 170.0, c.y + sy * 170.0), accent, 90.0)
        "fortress":
            _ring(w, c, 220.0, edge)
            for sx in [-1.0, 1.0]:
                _box(w, Rect2(c.x + sx * 520.0 - 30.0, c.y - 620.0, 60.0, 500.0), 0.36, prop, prop2)
                _box(w, Rect2(c.x + sx * 520.0 - 30.0, c.y + 120.0, 60.0, 500.0), 0.36, prop, prop2)
                _box(w, Rect2(c.x + sx * 300.0 - 190.0, c.y - 700.0, 380.0, 50.0), 0.36, prop, prop2)
                _box(w, Rect2(c.x + sx * 300.0 - 190.0, c.y + 650.0, 380.0, 50.0), 0.36, prop, prop2)
                for sy in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 290.0 - 80.0, c.y + sy * 330.0 - 60.0, 160.0, 120.0), 0.26, Color("4a5058"), Color("2e3238"))
                    _lamp(w, Vector2(c.x + sx * 180.0, c.y + sy * 240.0), accent, 70.0)
        "tower":
            _ring(w, c, 430.0, edge)
            _ring(w, c, 300.0, edge)
            _ring(w, c, 120.0, accent)
            for i in 12:
                var pillar: Vector2 = c + Vector2.from_angle(TAU * i / 12.0) * 480.0
                _box(w, Rect2(pillar - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), 0.34, prop, prop2)
                if i % 3 == 0:
                    _lamp(w, c + Vector2.from_angle(TAU * i / 12.0 + 0.26) * 380.0, accent, 90.0)
            for i in 6:
                var scope: Vector2 = c + Vector2.from_angle(TAU * i / 6.0 + 0.3) * 230.0
                _box(w, Rect2(scope - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), 0.12, Color("8a7a4a"), Color("d8c477"))
        "ministry":
            _ring(w, c, 330.0, edge)
            _ring(w, c, 260.0, Color("5b5d57"))
            _ring(w, c, 170.0, edge)
            for sx in [-1.0, 1.0]:
                _box(w, Rect2(c.x + sx * 520.0 - 50.0, c.y - 250.0, 100.0, 500.0), 0.3, prop, prop2)
                for k in 6:
                    _light(w, Vector2(c.x + sx * 520.0, c.y - 210.0 + k * 84.0), Color("7bc9ff"), 44.0)
                for sy in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 300.0 - 110.0, c.y + sy * 560.0 - 28.0, 220.0, 56.0), 0.3, prop, prop2)
                    _light(w, Vector2(c.x + sx * 300.0, c.y + sy * 520.0), Color("7bc9ff"), 60.0)
        _:
            # "duel": a compact boss arena with four pillars.
            _ring(w, c, minf(a.x, a.y) * 0.32, edge)
            _ring(w, c, minf(a.x, a.y) * 0.14, accent)
            for sx in [-1.0, 1.0]:
                for sy in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * a.x * 0.36 - 22.0, c.y + sy * a.y * 0.34 - 22.0, 44.0, 44.0), 0.36, prop, prop2)
                    _lamp(w, Vector2(c.x + sx * a.x * 0.24, c.y + sy * a.y * 0.22), accent, 80.0)


# A 64 px noisy tile gives the textured ground of procedural arenas; it is repeated across the arena.
static func ground(ch: Dictionary, index: int) -> ImageTexture:
    var img: Image = Image.create(64, 64, false, Image.FORMAT_RGB8)
    var g: Color = ch.ground
    var g2: Color = ch.ground2
    var g3: Color = ch.ground3
    var layout: String = ch.layout
    var seams: bool = not (layout in ["forest", "pitch", "village"])
    var tr := RandomNumberGenerator.new()
    tr.seed = 77 + index
    for y in 64:
        for x in 64:
            var col: Color = g
            var roll: float = tr.randf()
            if roll < 0.14:
                col = g2
            elif roll < 0.26:
                col = g3
            if seams:
                var shift: int = 8 if ((y >> 4) & 1) == 1 else 0
                if y % 16 == 0 or (x + shift) % 16 == 0:
                    col = g3.darkened(0.25)
                elif y % 16 == 1 or (x + shift) % 16 == 1:
                    col = col.lightened(0.08)
            img.set_pixel(x, y, col)
    return ImageTexture.create_from_image(img)
