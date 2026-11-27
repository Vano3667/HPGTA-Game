extends RefCounted
## The look of the interface: fonts, colours, button and frame styles and small drawn ornaments.
## The fonts are optional files in res://art/gen/ (the CI workflow downloads them). Without them
## the engine's default font is used and everything else stays the same.

const DIR := "res://art/gen/"
const GOLD := Color("f0d278")
const GOLD_DIM := Color("8f7334")
const TEXT := Color("e6dcc0")
const CYAN := Color("67dcf4")
const INK := Color("0b0e12")
const PANEL := Color("12171d")
const BUTTON := Color("1c232b")
# Accent colour of an upgrade card by its kind; anything else (spells) is cyan.
const KINDS := {
    "fusion": Color("ff9a3c"), "evolve": Color("d58cff"), "evolution": Color("d58cff"), "evo": Color("d58cff"),
    "passive": Color("f0d278"), "heal": Color("7fe39a"),
}

static var title: Font = null
static var body: Font = null
static var bold: Font = null
## How many of the three font files were found.
static var found := 0
static var _loaded := false
static var _theme: Theme = null


static func load_fonts() -> void:
    if _loaded:
        return
    _loaded = true
    var base: Font = ThemeDB.fallback_font
    body = _font("font_body", base)
    bold = _font("font_bold", body)
    title = _font("font_title", bold)


static func _font(name: String, fallback: Font) -> Font:
    var path: String = DIR + name + ".ttf"
    if not ResourceLoader.exists(path):
        return fallback
    var f := load(path) as FontFile
    if f == null:
        return fallback
    # Glyphs the file lacks come from the engine font.
    var extra: Array[Font] = [ThemeDB.fallback_font]
    f.fallbacks = extra
    found += 1
    return f


static func theme() -> Theme:
    if _theme != null:
        return _theme
    load_fonts()
    var t := Theme.new()
    t.default_font = body
    t.default_font_size = 16
    t.set_font("font", "Button", bold)
    t.set_font_size("font_size", "Button", 17)
    t.set_color("font_color", "Button", TEXT)
    t.set_color("font_hover_color", "Button", GOLD)
    t.set_color("font_pressed_color", "Button", Color("fff3c4"))
    t.set_color("font_focus_color", "Button", TEXT)
    t.set_color("font_outline_color", "Button", Color(0.0, 0.0, 0.0, 0.8))
    t.set_constant("outline_size", "Button", 3)
    t.set_stylebox("normal", "Button", box(BUTTON, GOLD_DIM, 2, 9))
    t.set_stylebox("hover", "Button", box(BUTTON.lightened(0.08), GOLD, 2, 9))
    t.set_stylebox("pressed", "Button", box(Color("3b2f17"), GOLD, 2, 9))
    t.set_stylebox("disabled", "Button", box(INK, Color("3b3b36"), 2, 9))
    t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
    t.set_color("font_outline_color", "Label", Color(0.0, 0.0, 0.0, 0.85))
    t.set_constant("outline_size", "Label", 2)
    _theme = t
    return t


static func box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.set_border_width_all(width)
    s.set_corner_radius_all(radius)
    s.set_content_margin_all(8.0)
    s.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
    s.shadow_size = 4
    s.shadow_offset = Vector2(0.0, 2.0)
    return s


## The frame around a menu.
static func panel_box(alpha: float = 0.95) -> StyleBoxFlat:
    var s: StyleBoxFlat = box(Color(PANEL, alpha), GOLD_DIM, 2, 14)
    s.set_content_margin_all(16.0)
    s.shadow_size = 12
    s.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
    return s


## An upgrade card: tinted with its accent colour, with a thick bar on the left.
## state: 0 normal, 1 hover, 2 pressed.
static func card_box(col: Color, state: int) -> StyleBoxFlat:
    var bg: Color = BUTTON.lerp(col, 0.07 + 0.07 * state)
    var s: StyleBoxFlat = box(bg, col if state > 0 else col.darkened(0.25), 2, 11)
    s.border_width_left = 7
    return s


static func kind_color(kind: String) -> Color:
    return KINDS.get(kind, CYAN)


## A repeatable pseudo-random number in 0..1 for particle number i.
static func rnd(i: int, salt: float) -> float:
    return fposmod(sin(i * 12.9898 + salt * 78.233) * 43758.5453, 1.0)


static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
    var pts := PackedVector2Array([c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(0.0, r), c + Vector2(-r, 0.0)])
    ci.draw_primitive(pts, PackedColorArray([col, col, col, col]), PackedVector2Array())


## A four-point sparkle: bright in the middle, fading to its tips.
static func star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
    var w: float = r * 0.28
    var tip := Color(col, 0.0)
    var cols := PackedColorArray([col, tip, col, tip])
    var none := PackedVector2Array()
    ci.draw_primitive(PackedVector2Array([c + Vector2(-w, 0.0), c + Vector2(0.0, -r), c + Vector2(w, 0.0), c + Vector2(0.0, r)]), cols, none)
    ci.draw_primitive(PackedVector2Array([c + Vector2(0.0, -w), c + Vector2(r, 0.0), c + Vector2(0.0, w), c + Vector2(-r, 0.0)]), cols, none)


## A thin horizontal line that is clear at "a" and solid at "b".
static func fade_line(ci: CanvasItem, a: Vector2, b: Vector2, h: float, col: Color) -> void:
    var clear := Color(col, 0.0)
    var n := Vector2(0.0, h * 0.5)
    ci.draw_primitive(PackedVector2Array([a - n, b - n, b + n, a + n]), PackedColorArray([clear, col, col, clear]), PackedVector2Array())


## Ornament under a title: two fading lines with diamonds between them.
static func divider(ci: CanvasItem, c: Vector2, half: float, col: Color) -> void:
    fade_line(ci, c + Vector2(-half, 0.0), c + Vector2(-11.0, 0.0), 1.6, col)
    fade_line(ci, c + Vector2(half, 0.0), c + Vector2(11.0, 0.0), 1.6, col)
    diamond(ci, c, 5.0, col)
    diamond(ci, c, 2.2, Color(INK, col.a))
    diamond(ci, c + Vector2(-16.0, 0.0), 2.0, col)
    diamond(ci, c + Vector2(16.0, 0.0), 2.0, col)


## Corner brackets with a diamond, drawn inside a frame.
static func corners(ci: CanvasItem, r: Rect2, col: Color) -> void:
    var l: float = 18.0
    for sx in [0, 1]:
        for sy in [0, 1]:
            var p := Vector2(r.end.x if sx == 1 else r.position.x, r.end.y if sy == 1 else r.position.y)
            var dx: float = -1.0 if sx == 1 else 1.0
            var dy: float = -1.0 if sy == 1 else 1.0
            var o: Vector2 = p + Vector2(dx * 7.0, dy * 7.0)
            ci.draw_line(o, o + Vector2(dx * l, 0.0), col, 1.5)
            ci.draw_line(o, o + Vector2(0.0, dy * l), col, 1.5)
            diamond(ci, o, 3.5, col)


## Small ornaments on an upgrade card.
static func card_deco(ci: Control, col: Color) -> void:
    var s: Vector2 = ci.size
    var c := Color(col, 0.9)
    diamond(ci, Vector2(s.x - 14.0, 14.0), 4.0, c)
    diamond(ci, Vector2(s.x - 14.0, s.y - 14.0), 4.0, c)
    fade_line(ci, Vector2(s.x * 0.25, 7.0), Vector2(s.x - 24.0, 7.0), 1.2, Color(col, 0.5))
    fade_line(ci, Vector2(s.x * 0.25, s.y - 7.0), Vector2(s.x - 24.0, s.y - 7.0), 1.2, Color(col, 0.5))
