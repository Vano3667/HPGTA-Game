extends RefCounted
## Endless stage generator. The world has no borders: the ground is cut into square chunks and a
## chunk gets its obstacles, lights and ground decor when the hero comes near. A chunk is built
## from a seed, so a place looks the same when the hero walks back to it during a stage; every
## new stage draws a new seed.
## With a painted floor (art/gen/map_*.png) the obstacles are the painted sprites of that map
## (art/gen/prop_<map>_*.png). A painted floor without such sprites stays empty. Without a
## painted floor (art missing, or "Graphics: simple") the obstacles are code-drawn blocks,
## trees and hoops in the chapter's colours.

const Sprites = preload("res://scripts/core/sprites.gd")

## World width of a painted obstacle, by the size class in its file name (the hero is about 20 wide).
const PROP_SIZE := {"s": 24.0, "m": 52.0, "l": 100.0, "xl": 180.0}
const PROP_TYPES := ["wall", "low", "pit", "deco"]
## Side of a chunk in world units, and how many chunks are kept around the hero in each direction.
const CHUNK := 400.0
const KEEP := 2
## Obstacles stay this far from the chunk border and from each other, so there is always a way through.
const MARGIN := 28.0
const GAP := 52.0
## Painted obstacles known for a map even when the folder cannot be listed (exported builds).
## File names are <type>-<size>-<name>: wall and low are solid, pit is a solid hole drawn flat
## on the floor, deco is not solid.
const KNOWN := {
    "01-diagon-alley": ["wall-xl-shop-row", "wall-l-book-shop", "wall-l-potion-shop", "wall-m-market-stall", "wall-s-lamp-post", "low-s-barrels", "low-s-crates", "low-m-cart", "pit-m-sinkhole"],
}

static var _files := {}
static var _scanned := false


## The painted obstacles available for a map: [{id, type, cls, tex, dim}, ...], in a stable order.
static func palette(map: String) -> Array:
    var out: Array = []
    if map == "" or not Sprites.enabled:
        return out
    if not _scanned:
        _scanned = true
        var dir := DirAccess.open(Sprites.DIR)
        if dir != null:
            for n in dir.get_files():
                var f: String = str(n)
                if f.ends_with(".import"):
                    f = f.substr(0, f.length() - 7)
                if f.begins_with("prop_") and f.ends_with(".png"):
                    _files[f.substr(5, f.length() - 9)] = true
    var ids := {}
    for id in KNOWN.get(map, []):
        ids[str(id)] = true
    var prefix: String = map + "_"
    for key in _files:
        var name: String = str(key)
        if name.begins_with(prefix):
            ids[name.substr(prefix.length())] = true
    var names: Array = ids.keys()
    names.sort()
    for n in names:
        var id: String = str(n)
        var parts: PackedStringArray = id.split("-")
        if parts.size() < 3 or not (parts[0] in PROP_TYPES) or not PROP_SIZE.has(parts[1]):
            continue
        var tx: Texture2D = Sprites.tex("prop_%s_%s" % [map, id])
        if tx == null:
            continue
        var width: float = PROP_SIZE[parts[1]]
        out.append({"id": id, "type": parts[0], "cls": parts[1], "tex": tx, "dim": Vector2(width, width * tx.get_height() / float(tx.get_width()))})
    return out


## Start a stage: forget the old chunks and build the ones around the hero.
static func begin(w) -> void:
    w.chunks = {}
    w.obstacles = []
    w.props = []
    w.decor = []
    w.lights = []
    w.palette = []
    if w.floor_tex != null:
        w.palette = palette(str(w.chapter.get("map", "")))
    w.chunk_at = Vector2i(1 << 20, 0)
    update(w)


## Call every step. Does nothing until the hero crosses into another chunk; then it builds the
## missing chunks around the hero, drops the far ones and refreshes the world's lists.
static func update(w) -> void:
    var pp: Vector2 = w.player.pos
    var here := Vector2i(floori(pp.x / CHUNK), floori(pp.y / CHUNK))
    if here == w.chunk_at:
        return
    w.chunk_at = here
    var chunks: Dictionary = w.chunks
    for key in chunks.keys():
        var k: Vector2i = key
        if absi(k.x - here.x) > KEEP + 1 or absi(k.y - here.y) > KEEP + 1:
            chunks.erase(key)
    for cx in range(here.x - KEEP, here.x + KEEP + 1):
        for cy in range(here.y - KEEP, here.y + KEEP + 1):
            var at := Vector2i(cx, cy)
            if not chunks.has(at):
                chunks[at] = _chunk(w, cx, cy)
    var props: Array = []
    var obstacles: Array = []
    var lights: Array = []
    var decor: Array = []
    for key in chunks:
        var c: Dictionary = chunks[key]
        props.append_array(c.props)
        obstacles.append_array(c.obstacles)
        lights.append_array(c.lights)
        decor.append_array(c.decor)
    w.props = props
    w.obstacles = obstacles
    w.lights = lights
    w.decor = decor
    w._index_obstacles()


static func _chunk(w, cx: int, cy: int) -> Dictionary:
    var out := {"props": [], "obstacles": [], "lights": [], "decor": []}
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(Vector3i(cx, cy, int(w.map_seed)))
    var origin := Vector2(cx, cy) * CHUNK
    var ch: Dictionary = w.chapter
    var accent: Color = ch.accent
    var safe: Vector2 = w.spawn_pos
    var pal: Array = w.palette
    if not pal.is_empty():
        _painted(out, rng, origin, pal, safe, accent)
    elif w.floor_tex == null:
        _drawn(out, rng, origin, ch, safe)
    # Soft pools of light, so no stretch of ground is flat.
    for i in 1 + rng.randi() % 2:
        out.lights.append({"pos": origin + Vector2(rng.randf(), rng.randf()) * CHUNK, "h": 0.0, "r": rng.randf_range(60.0, 100.0), "col": accent})
    return out


# True when rect keeps clear of the hero's starting spot and of everything already placed.
static func _fits(rect: Rect2, taken: Array, safe: Vector2, gap: float) -> bool:
    if rect.grow(64.0).has_point(safe):
        return false
    var grown: Rect2 = rect.grow(gap)
    for item in taken:
        var other: Rect2 = item
        if grown.intersects(other):
            return false
    return true


# A free spot for something of size "dim" inside the chunk, or a rectangle of zero size.
static func _spot(rng: RandomNumberGenerator, origin: Vector2, dim: Vector2, taken: Array, safe: Vector2) -> Rect2:
    var room: Vector2 = Vector2(CHUNK, CHUNK) - dim - Vector2(MARGIN, MARGIN) * 2.0
    if room.x < 0.0 or room.y < 0.0:
        return Rect2()
    for attempt in 6:
        var rect := Rect2(origin + Vector2(MARGIN, MARGIN) + Vector2(rng.randf() * room.x, rng.randf() * room.y), dim)
        if _fits(rect, taken, safe, GAP):
            taken.append(rect)
            return rect
    return Rect2()


# ---------------------------------------------------------------- painted obstacles

# One painted obstacle. "rect" is where the sprite is drawn; "hit" is the solid part; "base" is its
# lower edge, used to decide whether the hero is in front of the obstacle or behind it.
static func _sprite(out: Dictionary, entry: Dictionary, box: Rect2, accent: Color) -> void:
    var type: String = entry.type
    var pos: Vector2 = box.position
    var dim: Vector2 = box.size
    var hit: Rect2 = box
    var solid: bool = true
    var flat: bool = false
    if type == "wall":
        if dim.x <= 30.0 and dim.y > dim.x * 1.5:
            # A post: only its base is solid, the rest can be walked behind.
            var b: float = dim.x * 0.7
            hit = Rect2(pos.x + (dim.x - b) * 0.5, pos.y + dim.y - b, b, b)
        else:
            hit = Rect2(pos.x + dim.x * 0.05, pos.y + dim.y * 0.2, dim.x * 0.9, dim.y * 0.78)
    elif type == "low":
        hit = Rect2(pos.x + dim.x * 0.1, pos.y + dim.y * 0.3, dim.x * 0.8, dim.y * 0.62)
    elif type == "pit":
        flat = true
        hit = box.grow(-minf(dim.x, dim.y) * 0.16)
    else:
        flat = true
        solid = false
    out.props.append({"kind": "sprite", "rect": box, "c": box.get_center(), "h": 0.0, "tex": entry.tex, "flat": flat, "hit": hit, "base": hit.end.y})
    if solid:
        out.obstacles.append(hit)
    if str(entry.id).contains("lamp"):
        out.lights.append({"pos": Vector2(box.get_center().x, pos.y + dim.x * 0.5), "h": 0.0, "r": 78.0, "col": accent})


static func _put(out: Dictionary, rng: RandomNumberGenerator, origin: Vector2, group: Array, taken: Array, safe: Vector2, accent: Color) -> void:
    if group.is_empty():
        return
    var entry: Dictionary = group[rng.randi() % group.size()]
    var dim: Vector2 = entry.dim
    var box: Rect2 = _spot(rng, origin, dim, taken, safe)
    if box.size.x > 0.0:
        _sprite(out, entry, box, accent)


# A chunk of a painted map: often one building, then a few medium and small things around it.
static func _painted(out: Dictionary, rng: RandomNumberGenerator, origin: Vector2, pal: Array, safe: Vector2, accent: Color) -> void:
    var big: Array = []
    var mid: Array = []
    var small: Array = []
    for item in pal:
        var entry: Dictionary = item
        var cls: String = entry.cls
        if cls == "xl" or cls == "l":
            big.append(entry)
        elif cls == "m":
            mid.append(entry)
        else:
            small.append(entry)
    var taken: Array = []
    var built: bool = not big.is_empty() and rng.randf() < 0.6
    if built:
        _put(out, rng, origin, big, taken, safe, accent)
    for i in rng.randi_range(1, 2) + (0 if built else 1):
        _put(out, rng, origin, mid, taken, safe, accent)
    for i in rng.randi_range(2, 4):
        _put(out, rng, origin, small, taken, safe, accent)


# ---------------------------------------------------------------- code-drawn obstacles

# kind: "box" (extruded block), "tree" or "hoop". h is the pseudo-3D height.
static func _block(out: Dictionary, rng: RandomNumberGenerator, origin: Vector2, dim: Vector2, h: float, col: Color, col2: Color, taken: Array, safe: Vector2, kind: String) -> void:
    var rect: Rect2 = _spot(rng, origin, dim, taken, safe)
    if rect.size.x <= 0.0:
        return
    out.props.append({"kind": kind, "rect": rect, "c": rect.get_center(), "h": h, "col": col, "col2": col2})
    out.obstacles.append(rect)


static func _drawn(out: Dictionary, rng: RandomNumberGenerator, origin: Vector2, ch: Dictionary, safe: Vector2) -> void:
    var layout: String = ch.layout
    var prop: Color = ch.prop
    var prop2: Color = ch.prop2
    var edge: Color = ch.edge
    var accent: Color = ch.accent
    var taken: Array = []
    if layout == "forest":
        for i in rng.randi_range(5, 8):
            var s: float = rng.randf_range(16.0, 26.0)
            _block(out, rng, origin, Vector2(s, s), 0.3, prop, prop2.lerp(Color("1a3a2a"), rng.randf()), taken, safe, "tree")
        var shroom: Vector2 = origin + Vector2(rng.randf(), rng.randf()) * CHUNK
        out.decor.append({"kind": "ring", "pos": shroom, "r": 7.0, "col": accent})
        out.lights.append({"pos": shroom, "h": 0.0, "r": 46.0, "col": accent})
        return
    if layout == "pitch":
        for i in rng.randi_range(1, 2):
            _block(out, rng, origin, Vector2(10.0, 10.0), 0.3, accent, accent, taken, safe, "hoop")
        if rng.randf() < 0.5:
            _block(out, rng, origin, Vector2(70.0, rng.randf_range(120.0, 200.0)), 0.2, prop, prop2, taken, safe, "box")
    elif layout in ["duel", "chamber", "tower", "ministry", "fortress"]:
        for i in rng.randi_range(2, 4):
            var side: float = rng.randf_range(40.0, 64.0)
            _block(out, rng, origin, Vector2(side, side), rng.randf_range(0.3, 0.42), prop, prop2, taken, safe, "box")
    else:
        if rng.randf() < 0.7:
            var house := Vector2(rng.randf_range(110.0, 190.0), rng.randf_range(90.0, 150.0))
            _block(out, rng, origin, house, rng.randf_range(0.2, 0.32), prop.lerp(Color("5a4a5a"), rng.randf() * 0.5), prop2, taken, safe, "box")
        for i in rng.randi_range(2, 3):
            var crate := Vector2(rng.randf_range(24.0, 38.0), rng.randf_range(24.0, 38.0))
            _block(out, rng, origin, crate, 0.07, Color("6a4a34"), Color("8a6444"), taken, safe, "box")
    # A street lamp or torch: not solid, but it lights the scene.
    var lamp: Vector2 = origin + Vector2(rng.randf_range(MARGIN, CHUNK - MARGIN), rng.randf_range(MARGIN, CHUNK - MARGIN))
    if _fits(Rect2(lamp - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), taken, safe, 8.0):
        out.props.append({"kind": "lamp", "rect": Rect2(lamp - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), "c": lamp, "h": 0.22, "col": Color("26262a"), "col2": accent})
        out.lights.append({"pos": lamp, "h": 0.22, "r": 74.0, "col": accent})
    for i in 2:
        out.decor.append({"kind": "ring", "pos": origin + Vector2(rng.randf(), rng.randf()) * CHUNK, "r": rng.randf_range(10.0, 26.0), "col": Color(edge, 0.28)})


# A 64 px noisy tile gives the textured ground of code-drawn stages; the world repeats it endlessly.
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
