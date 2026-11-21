extends SceneTree
## Slices the master art in assets/visual-kit into small runtime sheets under res://art/gen/.
## Run it before importing the project (CI does this on every build):
##   godot --headless --path . -s res://tools/build_sprites.gd
## Masters are never modified. A sheet is skipped - and the game draws that actor in code - when
## the master has no usable transparency or does not split into the expected cells.
## Layout facts below were measured with tools/asset_probe.gd.

const SRC := "res://assets/visual-kit/"
const OUT := "res://art/gen/"
const HERO_CELL := 144
const MOB_CELL := 128
const BOSS_CELL := 288

# "cols": which source column holds each runtime direction [down, left, right, up].
# "back_fix": a corrected back-facing pose that replaces the sheet's own back frames when usable.
const HEROES := {
    "harry": {"file": "hero-wizard-pseudo3d-atlas.png", "cols": [0, 3, 1, 2], "back_fix": "hero-wizard-forward-wand-standing.png"},
    "hermione": {"file": "hermione-pseudo3d-8pose-atlas.png", "cols": [2, 3, 1, 0]},
    "ron": {"file": "ron-pseudo3d-8pose-atlas.png", "cols": [2, 3, 1, 0]},
}
const BOSSES := {
    "quirrell": "boss-01-quirrell-dual-face.png", "basilisk": "boss-02-cockatrice-basilisk.png",
    "dementor": "boss-03-dementor.png", "nagini": "boss-04-nagini.png", "voldemort": "boss-05-voldemort.png",
}
# Enemy boards: 5 columns x 2 rows, read left to right, top to bottom.
const MOBS := {
    "enemies-core-pseudo3d-atlas.png": ["cauldron", "sprite", "mimic", "caster", "armor", "book", "portrait", "spider", "wraith", "plant"],
    "enemies-expansion-pseudo3d-atlas.png": ["centaur", "ball", "drowned", "automaton", "serpent", "frostwitch", "carriage", "gargoyle", "guard", "owl"],
}

var _wrote := 0


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for id in HEROES:
        _hero(str(id), HEROES[id])
    for id in BOSSES:
        _single("boss_" + str(id), str(BOSSES[id]), BOSS_CELL)
    for file in MOBS:
        _mobs(str(file), MOBS[file])
    _maps()
    print("[sprites] done, %d files written" % _wrote)
    quit(0)


func _save(img: Image, name: String) -> void:
    if img.save_png(ProjectSettings.globalize_path(OUT + name + ".png")) == OK:
        _wrote += 1
        print("[sprites] wrote %s.png %dx%d" % [name, img.get_width(), img.get_height()])
    else:
        print("[sprites] could not write %s.png" % name)


# Loads a master and makes its transparency clean: faint pixels become fully clear. Masters that
# have no clear pixels at all but a fully opaque subject on a half-opaque backdrop are keyed.
func _load(file: String) -> Image:
    var img := Image.new()
    if img.load(ProjectSettings.globalize_path(SRC + "sprites/" + file)) != OK:
        print("[sprites] skip %s: cannot load" % file)
        return null
    img.convert(Image.FORMAT_RGBA8)
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var size: int = data.size()
    var total: int = w * h
    var clear: int = 0
    var solid: int = 0
    var i: int = 3
    while i < size:
        var a: int = data[i]
        if a <= 40:
            clear += 1
        elif a >= 250:
            solid += 1
        i += 4
    var cut: int = 40
    if clear * 100 < total * 3:
        if solid * 100 < total * 8 or solid * 100 > total * 75:
            print("[sprites] skip %s: no usable transparency (clear %d%%, solid %d%%)" % [file, int(clear * 100.0 / total), int(solid * 100.0 / total)])
            return null
        cut = 249
        print("[sprites] %s: no clear pixels, keeping only the fully opaque %d%%" % [file, int(solid * 100.0 / total)])
    i = 3
    while i < size:
        if data[i] <= cut:
            data[i] = 0
        elif cut > 40:
            data[i] = 255
        i += 4
    var out: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
    out.fix_alpha_edges()
    return out


# Opaque pixels per row / per column inside a rectangle.
func _rows(data: PackedByteArray, w: int, r: Rect2i) -> PackedInt32Array:
    var out := PackedInt32Array()
    out.resize(r.size.y)
    for y in r.size.y:
        var o: int = ((r.position.y + y) * w + r.position.x) * 4 + 3
        var c: int = 0
        for x in r.size.x:
            if data[o + x * 4] > 0:
                c += 1
        out[y] = c
    return out


func _cols(data: PackedByteArray, w: int, r: Rect2i) -> PackedInt32Array:
    var out := PackedInt32Array()
    out.resize(r.size.x)
    for y in r.size.y:
        var o: int = ((r.position.y + y) * w + r.position.x) * 4 + 3
        for x in r.size.x:
            if data[o + x * 4] > 0:
                out[x] += 1
    return out


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


# The smallest rectangle inside r that still holds every opaque pixel (ignoring single specks).
func _tight(data: PackedByteArray, w: int, r: Rect2i) -> Rect2i:
    var rc: PackedInt32Array = _rows(data, w, r)
    var cc: PackedInt32Array = _cols(data, w, r)
    var y0: int = 0
    var y1: int = rc.size() - 1
    var x0: int = 0
    var x1: int = cc.size() - 1
    while y0 < y1 and rc[y0] <= 1:
        y0 += 1
    while y1 > y0 and rc[y1] <= 1:
        y1 -= 1
    while x0 < x1 and cc[x0] <= 1:
        x0 += 1
    while x1 > x0 and cc[x1] <= 1:
        x1 -= 1
    return Rect2i(r.position.x + x0, r.position.y + y0, x1 - x0 + 1, y1 - y0 + 1)


# Finds the cells of a rows x cols board from its transparency. Returns [] when it does not fit.
func _grid(img: Image, rows: int, cols: int, file: String) -> Array:
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var rc: PackedInt32Array = _rows(data, w, Rect2i(0, 0, w, h))
    var bands: Array = _runs(rc, w)
    if bands.size() == 1 and rows == 2:
        # The two rows touch: cut at the emptiest line near the middle.
        var b: Array = bands[0]
        var mid: int = int((int(b[0]) + int(b[1])) * 0.5)
        var span: int = int((int(b[1]) - int(b[0])) / 6.0)
        var best: int = mid
        for y in range(mid - span, mid + span):
            if rc[y] < rc[best]:
                best = y
        bands = [[b[0], best - 1], [best, b[1]]]
    if bands.size() != rows:
        print("[sprites] skip %s: expected %d rows, found %d" % [file, rows, bands.size()])
        return []
    var out: Array = []
    var ref: Array = []
    for bi in rows:
        var y0: int = bands[bi][0]
        var y1: int = bands[bi][1]
        var band := Rect2i(0, y0, w, y1 - y0 + 1)
        var cells: Array = _runs(_cols(data, w, band), band.size.y)
        if cells.size() != cols:
            if ref.size() != cols:
                print("[sprites] skip %s: row %d has %d cells, expected %d" % [file, bi, cells.size(), cols])
                return []
            cells = ref
        elif ref.is_empty():
            ref = cells
        for c in cells:
            out.append(_tight(data, w, Rect2i(int(c[0]), y0, int(c[1]) - int(c[0]) + 1, band.size.y)))
    return out


# One runtime cell: the cropped pose scaled by "scale" (or less, to fit), feet at the bottom centre.
func _frame(img: Image, r: Rect2i, cw: int, ch: int, scale: float) -> Image:
    var sub: Image = img.get_region(r)
    var k: float = minf(scale, minf((cw - 4.0) / r.size.x, (ch - 6.0) / r.size.y))
    var nw: int = maxi(1, int(r.size.x * k))
    var nh: int = maxi(1, int(r.size.y * k))
    sub.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
    var cell: Image = Image.create(cw, ch, false, Image.FORMAT_RGBA8)
    cell.blit_rect(sub, Rect2i(0, 0, nw, nh), Vector2i(int((cw - nw) * 0.5), ch - 3 - nh))
    return cell


func _hero(id: String, cfg: Dictionary) -> void:
    var file: String = cfg.file
    var img: Image = _load(file)
    if img == null:
        return
    var cells: Array = _grid(img, 2, 4, file)
    if cells.size() != 8:
        return
    var tallest: int = 1
    for item in cells:
        var r: Rect2i = item
        tallest = maxi(tallest, r.size.y)
    var scale: float = (HERO_CELL - 6.0) / tallest
    var cell_rect := Rect2i(0, 0, HERO_CELL, HERO_CELL)
    var sheet: Image = Image.create(HERO_CELL * 4, HERO_CELL * 2, false, Image.FORMAT_RGBA8)
    var order: Array = cfg.cols
    for row in 2:
        for d in 4:
            var src: Rect2i = cells[row * 4 + int(order[d])]
            sheet.blit_rect(_frame(img, src, HERO_CELL, HERO_CELL, scale), cell_rect, Vector2i(d * HERO_CELL, row * HERO_CELL))
    if cfg.has("back_fix"):
        var fix_file: String = cfg.back_fix
        var fix: Image = _load(fix_file)
        if fix != null:
            var fw: int = fix.get_width()
            var fh: int = fix.get_height()
            var fr: Rect2i = _tight(fix.get_data(), fw, Rect2i(0, 0, fw, fh))
            var aspect: float = fr.size.y / float(maxi(1, fr.size.x))
            var inside: bool = fr.position.x > 2 and fr.position.y > 2 and fr.end.x < fw - 2 and fr.end.y < fh - 2
            if inside and aspect > 1.3 and aspect < 3.4 and fr.size.y > fh * 0.3:
                var back: Rect2i = cells[int(order[3])]
                var pose: Image = _frame(fix, fr, HERO_CELL, HERO_CELL, back.size.y * scale / fr.size.y)
                for row in 2:
                    sheet.blit_rect(pose, cell_rect, Vector2i(3 * HERO_CELL, row * HERO_CELL))
                print("[sprites] hero_%s: back-facing frames replaced with %s (pose %dx%d)" % [id, fix_file, fr.size.x, fr.size.y])
            else:
                print("[sprites] hero_%s: %s does not isolate cleanly (box %s), keeping the sheet's own back pose" % [id, fix_file, str(fr)])
    _save(sheet, "hero_" + id)


func _single(name: String, file: String, cell: int) -> void:
    var img: Image = _load(file)
    if img == null:
        return
    var w: int = img.get_width()
    var r: Rect2i = _tight(img.get_data(), w, Rect2i(0, 0, w, img.get_height()))
    _save(_frame(img, r, cell, cell, 999.0), name)


func _mobs(file: String, names: Array) -> void:
    var img: Image = _load(file)
    if img == null:
        return
    var cells: Array = _grid(img, 2, 5, file)
    if cells.size() != names.size():
        return
    for i in names.size():
        var r: Rect2i = cells[i]
        _save(_frame(img, r, MOB_CELL, MOB_CELL, 999.0), "mob_" + str(names[i]))


# Location paintings become the arena floors as they are (the importer compresses them).
func _maps() -> void:
    var base: String = ProjectSettings.globalize_path(SRC + "locations")
    var files: Array = Array(DirAccess.get_files_at(base))
    files.sort()
    for n in files:
        var file: String = str(n)
        if not file.ends_with(".png"):
            continue
        var img := Image.new()
        if img.load(base + "/" + file) != OK:
            print("[sprites] skip map %s: cannot load" % file)
            continue
        img.convert(Image.FORMAT_RGB8)
        _save(img, "map_" + file.get_basename())
