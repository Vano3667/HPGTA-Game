extends RefCounted
## Runtime access to the painted art that tools/build_sprites.gd slices from assets/visual-kit.
## Every call returns null / false when a sheet is missing or painted graphics are switched off,
## and the caller falls back to code-drawn art.

const DIR := "res://art/gen/"

static var enabled := true
static var cache := {}


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


## Hero sheet: 4 columns (down, left, right, up) x 2 rows (idle, step). "height" is in world units.
static func actor(ci: CanvasItem, name: String, feet: Vector2, facing: Vector2, moving: bool, height: float, mod: Color, t: float) -> bool:
    var tx: Texture2D = tex(name)
    if tx == null:
        return false
    var cw: float = tx.get_width() / 4.0
    var ch: float = tx.get_height() / 2.0
    var col: int = 0
    if absf(facing.x) > absf(facing.y):
        col = 2 if facing.x > 0.0 else 1
    elif facing.y < 0.0:
        col = 3
    var row: int = 0
    var bob: float = 0.0
    if moving:
        row = int(t * 7.0) % 2
        bob = absf(sin(t * 11.0)) * 1.2
    var size := Vector2(height * cw / ch, height)
    ci.draw_texture_rect_region(tx, Rect2(feet - Vector2(size.x * 0.5, size.y * 0.97 + bob), size), Rect2(col * cw, row * ch, cw, ch), mod)
    return true


## One-frame sprite (enemies and story bosses), feet at the bottom centre.
static func single(ci: CanvasItem, name: String, feet: Vector2, height: float, flip: bool, mod: Color) -> bool:
    var tx: Texture2D = tex(name)
    if tx == null:
        return false
    var size := Vector2(height * tx.get_width() / float(tx.get_height()), height)
    var rect := Rect2(feet - Vector2(size.x * 0.5, size.y * 0.97), size)
    if flip:
        rect.position.x += size.x
        rect.size.x = -size.x
    ci.draw_texture_rect(tx, rect, false, mod)
    return true
