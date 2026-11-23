extends RefCounted
## Runtime access to the painted art that tools/build_sprites.gd slices from assets/visual-kit.
## Every call returns null / false when a sheet is missing or painted graphics are switched off,
## and the caller falls back to code-drawn art.

const DIR := "res://art/gen/"
# Facing sectors start at "right" and go clockwise on screen (right, down-right, down, ...).
# Five-direction sheets hold front, front-right, right, back-right, back; the rest is mirrored.
const COL8 := [2, 1, 0, 1, 2, 3, 4, 3]
const FLIP8 := [false, false, false, true, true, true, false, false]
# Old four-direction sheets hold down, left, right, up.
const COL4 := [2, 0, 1, 3]
# Walk cycle over the rows of a five-direction sheet: step A, stand, step B, stand.
const WALK := [1, 0, 2, 0]

static var enabled := true
static var cache := {}
static var _sector_of := {}


static func tex(name: String) -> Texture2D:
    if not enabled or name == "":
        return null
    if cache.has(name):
        return cache[name]
    var path: String = DIR + name + ".png"
    var t: Texture2D = null
    if ResourceLoader.exists(path):
        t = load(path)
    cache[name] = t
    return t


static func forget(prefix: String) -> void:
    for k in cache.keys():
        if str(k).begins_with(prefix):
            cache.erase(k)


# Which of n facing sectors to show. The current one is kept until the direction has clearly left
# it, so a thumb resting on a diagonal does not make the sprite flicker between two poses.
static func _sector(key: String, facing: Vector2, n: int) -> int:
    var cur: int = int(_sector_of.get(key, -1))
    if facing.length_squared() < 0.01:
        return cur if cur >= 0 else (n >> 2)
    var w: float = TAU / n
    var a: float = facing.angle()
    if cur >= 0 and absf(wrapf(a - cur * w, -PI, PI)) < w * 0.72:
        return cur
    cur = posmod(roundi(a / w), n)
    _sector_of[key] = cur
    return cur


# Draws one cell with its bottom centre on "feet". Mirroring happens around the feet, in place.
static func _cell(ci: CanvasItem, tx: Texture2D, src: Rect2, feet: Vector2, size: Vector2, flip: bool, rot: float, squash: float, mod: Color) -> void:
    ci.draw_set_transform(feet, rot, Vector2(-1.0 if flip else 1.0, squash))
    ci.draw_texture_rect_region(tx, Rect2(-size.x * 0.5, -size.y * 0.97, size.x, size.y), src, mod)
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Hero sprite. "name" is hero_<id>; a five-direction sheet hero8_<id> is preferred when it exists.
## "height" is in world units.
static func actor(ci: CanvasItem, name: String, feet: Vector2, facing: Vector2, moving: bool, height: float, mod: Color, t: float) -> bool:
    if name.begins_with("hero_") and _actor8(ci, "hero8_" + name.substr(5), feet, facing, moving, height, mod, t):
        return true
    var tx: Texture2D = tex(name)
    if tx == null:
        return false
    var cw: float = tx.get_width() / 4.0
    var ch: float = tx.get_height() / 2.0
    var col: int = COL4[_sector(name, facing, 4)]
    var row: int = 0
    var bob: float = 0.0
    if moving:
        row = int(t * 7.0) % 2
        bob = absf(sin(t * 11.0)) * 1.2
    _cell(ci, tx, Rect2(col * cw, row * ch, cw, ch), feet - Vector2(0.0, bob), Vector2(height * cw / ch, height), false, 0.0, 1.0, mod)
    return true


# Five-direction sheet: 5 columns, 1 to 3 rows (stand, step A, step B), cells 3:2.
# With a single row the walk is faked with a bob, a lean and a slight squash.
static func _actor8(ci: CanvasItem, name: String, feet: Vector2, facing: Vector2, moving: bool, height: float, mod: Color, t: float) -> bool:
    var tx: Texture2D = tex(name)
    if tx == null:
        return false
    var cw: float = tx.get_width() / 5.0
    var rows: int = maxi(1, roundi(tx.get_height() / (cw / 1.5)))
    var ch: float = tx.get_height() / float(rows)
    var k: int = _sector(name, facing, 8)
    var row: int = 0
    var bob: float = 0.0
    var rot: float = 0.0
    var squash: float = 1.0
    if moving:
        if rows >= 3:
            row = WALK[int(t * 8.0) % 4]
        elif rows == 2:
            row = int(t * 7.0) % 2
        else:
            squash = 1.0 + 0.035 * sin(t * 20.0)
        bob = absf(sin(t * 10.0)) * 1.4
        rot = clampf(facing.x, -1.0, 1.0) * 0.06
    var col: int = COL8[k]
    var flip: bool = FLIP8[k]
    _cell(ci, tx, Rect2(col * cw, row * ch, cw, ch), feet - Vector2(0.0, bob), Vector2(height * cw / ch, height), flip, rot, squash, mod)
    return true


## One-frame sprite (enemies and story bosses), feet at the bottom centre.
static func single(ci: CanvasItem, name: String, feet: Vector2, height: float, flip: bool, mod: Color) -> bool:
    var tx: Texture2D = tex(name)
    if tx == null:
        return false
    var size := Vector2(height * tx.get_width() / float(tx.get_height()), height)
    ci.draw_set_transform(feet, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
    ci.draw_texture_rect(tx, Rect2(-size.x * 0.5, -size.y * 0.97, size.x, size.y), false, mod)
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return true
