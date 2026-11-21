extends RefCounted
## Builds the ten chapter arenas: solid props (with a pseudo-3D height), ground decor, light
## sources and the tiled ground texture. Layouts are seeded, so a chapter always looks the same.
## The centre of every arena is left open for the player.

const Chapters = preload("res://scripts/data/chapters.gd")


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


static func _label(w, pos: Vector2, text: String, col: Color) -> void:
    w.decor.append({"kind": "label", "pos": pos, "text": text, "col": col})


static func build(w) -> void:
    w.obstacles = []
    w.props = []
    w.decor = []
    w.lights = []
    var ch: Dictionary = w.chapter
    var index: int = w.chapter_index
    var a: Vector2 = Chapters.ARENA
    var c: Vector2 = a * 0.5
    var lr := RandomNumberGenerator.new()
    lr.seed = 4200 + index
    var prop: Color = ch.prop
    var prop2: Color = ch.prop2
    var edge: Color = ch.edge
    var accent: Color = ch.accent
    match ch.layout:
        "street":
            _rect(w, Rect2(c.x - 210.0, 0.0, 420.0, a.y), Color("353a38"))
            _rect(w, Rect2(c.x - 214.0, 0.0, 6.0, a.y), Color("8a7960"))
            _rect(w, Rect2(c.x + 208.0, 0.0, 6.0, a.y), Color("8a7960"))
            var y: float = 50.0
            var n: int = 0
            while y < a.y - 280.0:
                var h: float = lr.randf_range(170.0, 250.0)
                var wl: float = lr.randf_range(200.0, 300.0)
                var wr: float = lr.randf_range(200.0, 300.0)
                _box(w, Rect2(40.0, y, wl, h), lr.randf_range(0.2, 0.32), prop.lerp(Color("4a5a52"), lr.randf() * 0.6), prop2)
                _box(w, Rect2(a.x - 40.0 - wr, y, wr, h), lr.randf_range(0.2, 0.32), prop.lerp(Color("5a4a5a"), lr.randf() * 0.6), prop2)
                if n == 2:
                    _label(w, Vector2(52.0, y + h + 18.0), "OLLIVANDERS", Color("f4d787"))
                if n == 3:
                    _label(w, Vector2(a.x - 28.0 - wr, y + h + 18.0), "GRINGOTTS", Color("efd17a"))
                _lamp(w, Vector2(c.x - 196.0, y + h * 0.5), accent)
                _lamp(w, Vector2(c.x + 196.0, y + h), accent)
                y += h + lr.randf_range(70.0, 110.0)
                n += 1
            for i in 16:
                var crate := Vector2(lr.randf_range(c.x - 190.0, c.x + 150.0), lr.randf_range(80.0, a.y - 120.0))
                if crate.distance_to(c) < 130.0:
                    continue
                _box(w, Rect2(crate, Vector2(lr.randf_range(24.0, 38.0), lr.randf_range(24.0, 38.0))), 0.07, Color("6a4a34"), Color("8a6444"))
            for i in 14:
                # puddles catch the lamp light
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
            _label(w, Vector2(c.x - 60.0, c.y - 160.0), "THE THREE BROOMSTICKS", Color("6a4a3a"))
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
            _label(w, Vector2(c.x - 40.0, c.y - 676.0), "GREAT HALL", Color("f0d278"))
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
                # glowing mushroom rings
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
            _label(w, Vector2(c.x - 86.0, 60.0), "SALAZAR SLYTHERIN", Color("6aff9a"))
        "vaults":
            for sy in [-1.0, 1.0]:
                _rect(w, Rect2(0.0, c.y + sy * 420.0 - 3.0, a.x, 2.0), edge)
                _rect(w, Rect2(0.0, c.y + sy * 420.0 + 9.0, a.x, 2.0), edge)
            for i in 5:
                for sx in [-1.0, 1.0]:
                    var door := Rect2(c.x + sx * 560.0 - 70.0, 110.0 + i * 360.0, 140.0, 200.0)
                    _box(w, door, 0.3, prop2, Color("4a4a52"))
                    _ring(w, door.get_center() - Vector2(sx * 96.0, 0.0), 22.0, edge)
                    _lamp(w, door.get_center() - Vector2(sx * 110.0, -70.0), accent, 80.0)
            for i in 22:
                var pile := Vector2(lr.randf_range(240.0, a.x - 240.0), lr.randf_range(90.0, a.y - 90.0))
                if pile.distance_to(c) < 140.0:
                    continue
                _box(w, Rect2(pile, Vector2(lr.randf_range(22.0, 40.0), lr.randf_range(18.0, 30.0))), 0.06, Color("c9a23c"), Color("f0d060"))
                _light(w, pile + Vector2(14.0, 10.0), Color("ffd860"), 40.0)
            _label(w, Vector2(c.x - 40.0, 50.0), "VAULT 713", Color("ffd860"))
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
            _label(w, Vector2(c.x - 30.0, c.y - 716.0), "AZKABAN", Color("a8d8ff"))
        "manor":
            _box(w, Rect2(c.x - 360.0, 60.0, 720.0, 170.0), 0.36, Color("3a3642"), Color("26222c"))
            _rect(w, Rect2(c.x - 40.0, 230.0, 80.0, a.y - 290.0), Color(0.3, 0.28, 0.34, 0.7))
            _ring(w, c, 90.0, edge)
            _ring(w, c, 40.0, accent)
            for i in 9:
                var hy: float = 330.0 + i * 170.0
                if absf(hy - c.y) < 130.0:
                    continue
                var shift: float = 60.0 if i % 2 == 0 else -60.0
                for sx in [-1.0, 1.0]:
                    _box(w, Rect2(c.x + sx * 330.0 - 150.0 + shift, hy, 300.0, 40.0), 0.12, prop, prop2)
                _lamp(w, Vector2(c.x - 70.0 if i % 2 == 0 else c.x + 70.0, hy + 20.0), accent, 70.0)
            _label(w, Vector2(c.x - 50.0, 250.0), "MALFOY MANOR", Color("8a7aa0"))
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
            for i in 3:
                var fire_x: float = c.x - 400.0 + i * 400.0
                _rect(w, Rect2(fire_x - 42.0, 14.0, 84.0, 60.0), Color("121619"))
                _light(w, Vector2(fire_x, 50.0), accent, 90.0)
                _rect(w, Rect2(fire_x - 42.0, a.y - 74.0, 84.0, 60.0), Color("121619"))
                _light(w, Vector2(fire_x, a.y - 44.0), accent, 90.0)
            _label(w, Vector2(c.x - 78.0, c.y - 344.0), "HALL OF PROPHECY", Color("bfc8d4"))


# A 64 px noisy tile gives the textured ground; it is repeated across the arena.
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
