extends SceneTree
## Build step: cuts the master art in assets/visual-kit into small runtime textures in art/gen/
## (ignored by git, rebuilt in CI before every import). The masters are never modified.
## Usage: godot --headless --path . -s res://tools/build_sprites.gd
##
## Output, as scripts/core/sprites.gd expects it:
##   hero_<id>.png   4 columns (down, left, right, up) x 2 rows (idle, step)
##   mob_<spr>.png   one frame per enemy sprite
##   boss_<spr>.png  one frame per story boss
##   map_<name>.png  painted arena floor
## Anything that cannot be sliced safely is skipped with a warning; the game then draws it in code.

const SRC := "res://assets/visual-kit/"
const OUT := "res://art/gen/"
const CELL := 256

const HEROES := {
    "harry": "hero-wizard-pseudo3d-atlas.png",
    "hermione": "hermione-pseudo3d-8pose-atlas.png",
    "ron": "ron-pseudo3d-8pose-atlas.png",
}
# Sprite names in reading order, as listed in assets/visual-kit/VISUAL_BIBLE.md.
const MOBS := {
    "enemies-core-pseudo3d-atlas.png": ["cauldron", "sprite", "mimic", "caster", "armor", "book", "portrait", "spider", "wraith", "plant"],
    "enemies-expansion-pseudo3d-atlas.png": ["centaur", "ball", "drowned", "automaton", "serpent", "frostwitch", "carriage", "gargoyle", "guard", "owl"],
}
# Story bosses: [single pose, 8-pose atlas].
const BOSSES := {
    "quirrell": ["boss-01-quirrell-dual-face.png", "boss-01-quirrell-8pose-atlas.png"],
    "basilisk": ["boss-02-cockatrice-basilisk.png", "boss-02-cockatrice-basilisk-8pose-atlas.png"],
    "dementor": ["boss-03-dementor.png", "boss-03-dementor-8pose-atlas.png"],
    "nagini": ["boss-04-nagini.png", "boss-04-nagini-8pose-atlas.png"],
    "voldemort": ["boss-05-voldemort.png", "boss-05-voldemort-8pose-atlas.png"],
}
const MAPS := [
    "01-diagon-alley", "02-academy-courtyard", "03-forbidden-forest", "04-storm-pitch", "05-mysteries-archive",
    "06-frost-village", "07-serpent-vault", "08-midnight-crossroads", "09-storm-prison", "10-astronomy-tower",
    "boss-01-mirror-chamber", "boss-02-underground-dungeon", "boss-03-lakeside-forest-clearing",
    "boss-04-ruined-classroom", "boss-05-broken-bridge",
]

var made := 0
var skipped := 0


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(_abs(OUT))
    for id in HEROES:
        _hero(str(id), str(HEROES[id]))
    for file in MOBS:
        _mobs(str(file), MOBS[file])
    for id in BOSSES:
        _boss(str(id), str(BOSSES[id][0]), str(BOSSES[id][1]))
    for m in MAPS:
        _map(str(m))
    print("[sprites] done: %d written, %d skipped" % [made, skipped])
    quit(0)


func _abs(path: String) -> String:
    return ProjectSettings.globalize_path(path)


func _load(file: String) -> Image:
    var img := Image.new()
    if img.load(_abs(SRC + "sprites/" + file)) != OK:
        print("[sprites] WARNING %s: cannot load" % file)
        return null
    img.convert(Image.FORMAT_RGBA8)
    return img


func _save(img: Image, name: String) -> void:
    if img.save_png(_abs(OUT + name + ".png")) != OK:
        print("[sprites] WARNING %s: cannot save" % name)
        skipped += 1
        return
    made += 1
    print("[sprites] %s.png %dx%d" % [name, img.get_width(), img.get_height()])


# ---------------------------------------------------------------- cell detection

# Runs of rows/columns that contain opaque pixels: [[start, end], ...].
func _runs(counts: PackedInt32Array, span: int) -> Array:
    var n: int = counts.size()
    var thr: int = maxi(2, int(span * 0.004))
    var gap_min: int = maxi(2, int(n * 0.012))
    var len_min: int = maxi(4, int(n * 0.03))
    var out: Array = []
    var start: int = -1
    var last: int = -1
    for i in n:
        if counts[i] > thr:
            if start < 0:
                start = i
            elif i - last > gap_min:
                if last - start >= len_min:
                    out.append([start, last])
                start = i
            last = i
    if start >= 0 and last - start >= len_min:
        out.append([start, last])
    return out


# Sprite cells of an atlas: one Array of Rect2i per row of sprites.
func _grid(img: Image) -> Array:
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var rows := PackedInt32Array()
    rows.resize(h)
    for y in h:
        var o: int = y * w * 4 + 3
        var c: int = 0
        for x in w:
            if data[o + x * 4] > 40:
                c += 1
        rows[y] = c
    var out: Array = []
    for band in _runs(rows, w):
        var y0: int = band[0]
        var y1: int = band[1]
        var cols := PackedInt32Array()
        cols.resize(w)
        for y in range(y0, y1 + 1):
            var o2: int = y * w * 4 + 3
            for x in w:
                if data[o2 + x * 4] > 40:
                    cols[x] += 1
        var row: Array = []
        for cell in _runs(cols, y1 - y0 + 1):
            row.append(Rect2i(int(cell[0]), y0, int(cell[1]) - int(cell[0]) + 1, y1 - y0 + 1))
        out.append(row)
    return out


func _shape(grid: Array) -> String:
    var parts := PackedStringArray()
    for row in grid:
        parts.append(str(row.size()))
    return "rows of [" + ", ".join(parts) + "]"


func _clear_pct(img: Image) -> float:
    var data: PackedByteArray = img.get_data()
    var clear: int = 0
    for i in range(3, data.size(), 4):
        if data[i] <= 40:
            clear += 1
    return 100.0 * clear / float(img.get_width() * img.get_height())


func _skin(c: Color) -> bool:
    return c.r > 0.62 and c.g > 0.42 and c.b > 0.28 and c.r > c.g * 1.08 and c.g > c.b * 1.05 and c.b > c.r * 0.45


# x = share of skin-coloured pixels in the top 40% of a cell (percent),
# y = where they sit relative to the silhouette (-1 left .. 1 right).
func _face(img: Image, rect: Rect2i) -> Vector2:
    var cw: float = float(rect.size.x)
    var ch: float = float(rect.size.y)
    var op: int = 0
    var skin: int = 0
    var sx: float = 0.0
    var ox: float = 0.0
    for gy in 20:
        for gx in 40:
            var c: Color = img.get_pixel(rect.position.x + int(cw * (gx + 0.5) / 40.0), rect.position.y + int(ch * 0.4 * (gy + 0.5) / 20.0))
            if c.a < 0.3:
                continue
            op += 1
            ox += gx
            if _skin(c):
                skin += 1
                sx += gx
    if op == 0 or skin == 0:
        return Vector2.ZERO
    return Vector2(100.0 * skin / float(op), (sx / float(skin) - ox / float(op)) / 20.0)


# Which of the four cells of a row faces where. Returns cell indices for [down, left, right, up]:
# side views show the face off-centre, the front view shows the most skin, the back view the least.
func _directions(img: Image, cells: Array) -> Array:
    var skin := PackedFloat32Array()
    var score := PackedFloat32Array()
    for item in cells:
        var rect: Rect2i = item
        var st: Vector2 = _face(img, rect)
        skin.append(st.x)
        score.append(st.x * st.y)
    var right: int = 0
    var left: int = 0
    for i in 4:
        if score[i] > score[right]:
            right = i
        if score[i] < score[left]:
            left = i
    if right == left:
        # No readable faces: assume the documented order (down, right, up, left).
        return [0, 3, 1, 2]
    var rest: Array = []
    for i in 4:
        if i != right and i != left:
            rest.append(i)
    var down: int = rest[0]
    var up: int = rest[1]
    if skin[up] > skin[down]:
        down = rest[1]
        up = rest[0]
    return [down, left, right, up]


# Horizontal centre of the feet (lowest 12% of the visible pixels) of a cell image.
func _feet_x(part: Image) -> float:
    var used: Rect2i = part.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return part.get_width() * 0.5
    var y0: int = used.end.y - maxi(2, int(used.size.y * 0.12))
    var sum: float = 0.0
    var n: int = 0
    for y in range(y0, used.end.y, 2):
        for x in range(used.position.x, used.end.x, 2):
            if part.get_pixel(x, y).a > 0.3:
                sum += x
                n += 1
    if n == 0:
        return used.position.x + used.size.x * 0.5
    return sum / float(n)


# ---------------------------------------------------------------- heroes

func _hero(id: String, file: String) -> void:
    var img: Image = _load(file)
    if img == null:
        skipped += 1
        return
    var grid: Array = _grid(img)
    if grid.size() != 2 or grid[0].size() != 4 or grid[1].size() != 4:
        print("[sprites] WARNING hero %s: expected 2 rows of 4 poses, found %s - skipped" % [id, _shape(grid)])
        skipped += 1
        return
    var sheet: Image = Image.create(CELL * 4, CELL * 2, false, Image.FORMAT_RGBA8)
    for r in 2:
        var cells: Array = grid[r]
        var order: Array = _directions(img, cells)
        print("[sprites] hero %s row %d: down=c%d left=c%d right=c%d up=c%d" % [id, r, int(order[0]), int(order[1]), int(order[2]), int(order[3])])
        for c in 4:
            var rect: Rect2i = cells[int(order[c])]
            _place(sheet, img.get_region(rect), Vector2i(c * CELL, r * CELL), true)
    if id == "harry":
        _fix_back(sheet)
    _save(sheet, "hero_" + id)


# Scales a pose to the cell height and stands it on the bottom centre of its cell.
func _place(sheet: Image, part: Image, at: Vector2i, by_feet: bool) -> void:
    var k: float = (CELL - 8.0) / float(part.get_height())
    var w: int = maxi(1, int(part.get_width() * k))
    var h: int = maxi(1, int(part.get_height() * k))
    var anchor: float = part.get_width() * 0.5
    if by_feet:
        anchor = _feet_x(part)
    part.resize(w, h, Image.INTERPOLATE_LANCZOS)
    var x: int = clampi(int(CELL * 0.5 - anchor * k), 0, maxi(0, CELL - w))
    sheet.blit_rect(part, Rect2i(0, 0, mini(w, CELL), h), at + Vector2i(x, CELL - 4 - h))


# In the atlas the back view holds the wand towards the camera. The corrected standing pose
# (hero-wizard-forward-wand-standing.png) replaces the idle back view when its background can be removed.
func _fix_back(sheet: Image) -> void:
    var file: String = "hero-wizard-forward-wand-standing.png"
    var img: Image = _load(file)
    if img == null:
        return
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var solid: int = 0
    for i in range(3, data.size(), 4):
        if data[i] > 215:
            solid += 1
    var pct: float = 100.0 * solid / float(w * h)
    if pct < 4.0 or pct > 60.0:
        print("[sprites] WARNING back pose NOT fixed: %s has no removable background (%.1f%% of its pixels are solid)" % [file, pct])
        return
    for i in range(3, data.size(), 4):
        if data[i] <= 215:
            data[i] = 0
    var keyed: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
    var used: Rect2i = keyed.get_used_rect()
    var ratio: float = used.size.x / float(maxi(1, used.size.y))
    if used.size.y < h * 0.3 or ratio < 0.2 or ratio > 0.85:
        print("[sprites] WARNING back pose NOT fixed: %s does not key to a standing figure (box %dx%d)" % [file, used.size.x, used.size.y])
        return
    sheet.fill_rect(Rect2i(3 * CELL, 0, CELL, CELL), Color(0.0, 0.0, 0.0, 0.0))
    _place(sheet, keyed.get_region(used), Vector2i(3 * CELL, 0), false)
    print("[sprites] back pose fixed: idle back view of Harry taken from %s (%.1f%% solid, box %dx%d)" % [file, pct, used.size.x, used.size.y])


# ---------------------------------------------------------------- enemies and bosses

func _single(img: Image, rect: Rect2i, name: String, height: int) -> void:
    var part: Image = img.get_region(rect)
    var used: Rect2i = part.get_used_rect()
    if used.size.x < 4 or used.size.y < 4:
        print("[sprites] WARNING %s: empty cell - skipped" % name)
        skipped += 1
        return
    part = part.get_region(used)
    var k: float = minf(1.0, height / float(used.size.y))
    part.resize(maxi(1, int(used.size.x * k)), maxi(1, int(used.size.y * k)), Image.INTERPOLATE_LANCZOS)
    _save(part, name)


func _mobs(file: String, names: Array) -> void:
    var img: Image = _load(file)
    if img == null:
        skipped += names.size()
        return
    var grid: Array = _grid(img)
    var cells: Array = []
    for row in grid:
        cells.append_array(row)
    if cells.size() != names.size():
        print("[sprites] WARNING %s: expected %d sprites, found %s - skipped" % [file, names.size(), _shape(grid)])
        skipped += names.size()
        return
    for i in names.size():
        var rect: Rect2i = cells[i]
        _single(img, rect, "mob_" + str(names[i]), 160)


func _boss(id: String, single: String, atlas: String) -> void:
    var img: Image = _load(single)
    if img != null:
        var pct: float = _clear_pct(img)
        if pct > 3.0 and pct < 99.0:
            _single(img, Rect2i(0, 0, img.get_width(), img.get_height()), "boss_" + id, 320)
            return
        print("[sprites] boss %s: %s has no transparent background (%.1f%% clear), using the atlas" % [id, single, pct])
    img = _load(atlas)
    if img == null:
        skipped += 1
        return
    var grid: Array = _grid(img)
    if grid.is_empty() or grid[0].is_empty():
        print("[sprites] WARNING boss %s: no sprite cells found in %s - skipped" % [id, atlas])
        skipped += 1
        return
    var rect: Rect2i = grid[0][0]
    _single(img, rect, "boss_" + id, 320)


# ---------------------------------------------------------------- maps

func _map(name: String) -> void:
    var src: String = _abs(SRC + "locations/" + name + ".png")
    var dst: String = _abs(OUT + "map_" + name + ".png")
    if DirAccess.copy_absolute(src, dst) != OK:
        print("[sprites] WARNING map %s: cannot copy" % name)
        skipped += 1
        return
    made += 1
    print("[sprites] map_%s.png" % name)
