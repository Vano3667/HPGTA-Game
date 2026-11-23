extends SceneTree
## Slices the master art in assets/visual-kit into small runtime sheets under res://art/gen/.
## Run it before importing the project (CI does this on every build):
##   godot --headless --path . -s res://tools/build_sprites.gd
## Masters are never modified. A sheet is skipped - and the game draws that actor in code - when
## the master has no usable transparency or does not split into the expected cells.

const SRC := "res://assets/visual-kit/"
const OUT := "res://art/gen/"
const HERO_CELL := 144
const MOB_CELL := 128
const BOSS_CELL := 288
const DIR_COLS := 5
const TOP_SIDE := 360

# Old four-direction hero atlases. "cols": which source column holds [down, left, right, up].
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
# Enemy boards: 5 columns x 2 rows, read left to right, top to bottom. A file named
# sprites/mobs/<name>.png (or "<name> v2.png") replaces the board cell of the same name.
const MOBS := {
    "enemies-core-pseudo3d-atlas.png": ["cauldron", "sprite", "mimic", "caster", "armor", "book", "portrait", "spider", "wraith", "plant"],
    "enemies-expansion-pseudo3d-atlas.png": ["centaur", "ball", "drowned", "automaton", "serpent", "frostwitch", "carriage", "gargoyle", "guard", "owl"],
}
# Five-direction sheets: one master per row, each a single row of five figures that face
# front, front-right, right, back-right, back. The game mirrors the three left directions.
# Row 0 is the standing pose and is required; later rows (steps or an attack) are optional.
# "w" is wide enough for an outstretched wand, so every figure keeps the same scale.
const DIR_SHEETS := {
    "hero8_harry": {"cell": HERO_CELL, "w": 216, "rows": ["hero-wizard-8dir-idle", "hero-wizard-8dir-walk-a", "hero-wizard-8dir-walk-b"]},
    "hero8_hermione": {"cell": HERO_CELL, "w": 216, "rows": ["hermione-8dir-idle", "hermione-8dir-walk-a", "hermione-8dir-walk-b"]},
    "hero8_ron": {"cell": HERO_CELL, "w": 216, "rows": ["ron-8dir-idle", "ron-8dir-walk-a", "ron-8dir-walk-b"]},
    "boss8_quirrell": {"cell": BOSS_CELL, "w": 432, "rows": ["boss-01-quirrell-8dir-idle", "boss-01-quirrell-8dir-cast"]},
    "boss8_basilisk": {"cell": BOSS_CELL, "w": 432, "rows": ["boss-02-cockatrice-basilisk-8dir-idle", "boss-02-cockatrice-basilisk-8dir-gaze"]},
}
# Straight top-down poses heading right; the game rotates them to any angle.
const TOPS := {
    "top_basilisk_move": "boss-02-cockatrice-basilisk-top-move",
    "top_basilisk_lunge": "boss-02-cockatrice-basilisk-top-lunge",
}
# Location props are named <type>-<size>-<name>.png; the size class sets the exported width.
const PROP_TYPES := ["wall", "low", "pit", "deco"]
const PROP_W := {"s": 96, "m": 192, "l": 320, "xl": 560}

var _wrote := 0


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for id in HEROES:
        _hero(str(id), HEROES[id])
    for id in BOSSES:
        _single("boss_" + str(id), str(BOSSES[id]), BOSS_CELL)
    for file in MOBS:
        _mobs(str(file), MOBS[file])
    _mob_files()
    for id in DIR_SHEETS:
        _dir_sheet(str(id), DIR_SHEETS[id])
    for id in TOPS:
        _top(str(id), str(TOPS[id]))
    _props()
    _map_dir("locations")
    _map_dir("floors")
    print("[sprites] done, %d files written" % _wrote)
    quit(0)


func _save(img: Image, name: String) -> void:
    if img.save_png(ProjectSettings.globalize_path(OUT + name + ".png")) == OK:
        _wrote += 1
        print("[sprites] wrote %s.png %dx%d" % [name, img.get_width(), img.get_height()])
    else:
        print("[sprites] could not write %s.png" % name)


# The real file name for a base name, ignoring case and stray spaces ("name .png"). "" if absent.
func _find(dir_rel: String, base: String) -> String:
    var dir: String = ProjectSettings.globalize_path(SRC + dir_rel)
    if not DirAccess.dir_exists_absolute(dir):
        return ""
    var want: String = base.strip_edges().to_lower()
    for n in DirAccess.get_files_at(dir):
        var f: String = str(n)
        if f.get_extension().to_lower() == "png" and f.get_basename().strip_edges().to_lower() == want:
            return f
    return ""


func _load(file: String) -> Image:
    return _load_at("sprites/" + file)


# Loads a master and makes its transparency clean: faint pixels become fully clear. Masters that
# have no clear pixels at all but a fully opaque subject on a half-opaque backdrop are keyed.
func _load_at(rel: String) -> Image:
    var path: String = ProjectSettings.globalize_path(SRC + rel)
    if not FileAccess.file_exists(path):
        print("[sprites] skip %s: no such file" % rel)
        return null
    var img := Image.new()
    if img.load(path) != OK:
        print("[sprites] skip %s: cannot load" % rel)
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
            print("[sprites] skip %s: no usable transparency (clear %d%%, solid %d%%)" % [rel, int(clear * 100.0 / total), int(solid * 100.0 / total)])
            return null
        cut = 249
        print("[sprites] %s: no clear pixels, keeping only the fully opaque %d%%" % [rel, int(solid * 100.0 / total)])
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


# Share of opaque pixels inside a rectangle, in percent.
func _fill(data: PackedByteArray, w: int, r: Rect2i) -> int:
    var sum: int = 0
    for c in _rows(data, w, r):
        sum += c
    return int(sum * 100.0 / maxi(1, r.size.x * r.size.y))


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


# Finds n figures standing in one row. Extra fragments are merged into their nearest neighbour;
# figures that touch are split evenly (and reported, because that cut can clip a wand).
func _strip(img: Image, n: int, file: String) -> Array:
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var bands: Array = _runs(_rows(data, w, Rect2i(0, 0, w, h)), w)
    if bands.is_empty():
        print("[sprites] skip %s: nothing opaque found" % file)
        return []
    var y0: int = bands[0][0]
    var y1: int = bands[bands.size() - 1][1]
    var band := Rect2i(0, y0, w, y1 - y0 + 1)
    var cells: Array = _runs(_cols(data, w, band), band.size.y)
    var found: int = cells.size()
    if found == 0:
        print("[sprites] skip %s: no figures found" % file)
        return []
    while cells.size() > n:
        var best: int = 0
        var gap: int = 1 << 30
        for i in cells.size() - 1:
            var g: int = int(cells[i + 1][0]) - int(cells[i][1])
            if g < gap:
                gap = g
                best = i
        cells[best] = [cells[best][0], cells[best + 1][1]]
        cells.remove_at(best + 1)
    if cells.size() < n:
        var x0: int = cells[0][0]
        var x1: int = cells[cells.size() - 1][1]
        var step: float = (x1 - x0 + 1) / float(n)
        cells = []
        for i in n:
            cells.append([x0 + int(step * i), x0 + int(step * (i + 1)) - 1])
        print("[sprites] %s: WARNING figures touch (%d separate shapes), split into %d equal parts" % [file, found, n])
    elif found != n:
        print("[sprites] %s: %d separate shapes merged into %d figures" % [file, found, n])
    var out: Array = []
    for c in cells:
        out.append(_tight(data, w, Rect2i(int(c[0]), y0, int(c[1]) - int(c[0]) + 1, band.size.y)))
    return out


# Horizontal centre of whatever touches the ground (the lowest tenth of the figure), in pixels
# from the left edge of r. Anchoring there keeps the body still when the wand arm moves.
func _foot_x(data: PackedByteArray, w: int, r: Rect2i) -> float:
    var rows: int = maxi(3, int(r.size.y * 0.1))
    var lo: int = r.size.x
    var hi: int = -1
    for y in range(r.end.y - rows, r.end.y):
        var o: int = (y * w + r.position.x) * 4 + 3
        for x in r.size.x:
            if data[o + x * 4] > 0:
                lo = mini(lo, x)
                hi = maxi(hi, x)
    if hi < 0:
        return r.size.x * 0.5
    return (lo + hi + 1) * 0.5


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


# Like _frame, but the source column "ax" (the feet) lands on the centre line of the cell.
func _frame_at(img: Image, r: Rect2i, cw: int, ch: int, k: float, ax: float) -> Image:
    var sub: Image = img.get_region(r)
    var nw: int = maxi(1, int(r.size.x * k))
    var nh: int = maxi(1, int(r.size.y * k))
    sub.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
    var cell: Image = Image.create(cw, ch, false, Image.FORMAT_RGBA8)
    var x: int = clampi(int(cw * 0.5 - ax * k), 0, maxi(0, cw - nw))
    cell.blit_rect(sub, Rect2i(0, 0, nw, nh), Vector2i(x, maxi(0, ch - 3 - nh)))
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
    if cfg.has("back_fix") and _find("sprites", str(cfg.back_fix).get_basename()) != "":
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


# One enemy per file under sprites/mobs/. These win over the board cells written just before.
func _mob_files() -> void:
    for board in MOBS:
        for n in MOBS[board]:
            var name: String = str(n)
            var file: String = _find("sprites/mobs", name + " v2")
            if file == "":
                file = _find("sprites/mobs", name)
            if file == "":
                continue
            print("[sprites] mob_%s: using sprites/mobs/%s" % [name, file])
            _single("mob_" + name, "mobs/" + file, MOB_CELL)


# One row of five figures, all at one scale, each with its feet on the centre line of its cell.
func _dir_row(file: String, cw: int, ch: int) -> Image:
    var img: Image = _load(file)
    if img == null:
        return null
    var cells: Array = _strip(img, DIR_COLS, file)
    if cells.size() != DIR_COLS:
        return null
    var w: int = img.get_width()
    var data: PackedByteArray = img.get_data()
    var tallest: int = 1
    var half: float = 1.0
    var feet: Array = []
    var note: String = ""
    for item in cells:
        var r: Rect2i = item
        var ax: float = _foot_x(data, w, r)
        feet.append(ax)
        tallest = maxi(tallest, r.size.y)
        half = maxf(half, maxf(ax, r.size.x - ax))
        note += " %dx%d" % [r.size.x, r.size.y]
    var by_height: float = (ch - 6.0) / tallest
    var by_width: float = (cw * 0.5 - 2.0) / half
    var k: float = minf(by_height, by_width)
    if by_width < by_height:
        note += " (too wide for the cell, drawn %d%% smaller)" % int(100.0 - 100.0 * by_width / by_height)
    var row: Image = Image.create(cw * DIR_COLS, ch, false, Image.FORMAT_RGBA8)
    for i in DIR_COLS:
        var r: Rect2i = cells[i]
        row.blit_rect(_frame_at(img, r, cw, ch, k, float(feet[i])), Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
    print("[sprites] %s: image %dx%d, figures%s" % [file, w, img.get_height(), note])
    return row


func _dir_sheet(name: String, cfg: Dictionary) -> void:
    var ch: int = cfg.cell
    var cw: int = cfg.w
    var rows: Array = []
    var used: Array = []
    for b in cfg.rows:
        var base: String = str(b)
        var file: String = _find("sprites", base)
        var row: Image = null
        if file == "":
            print("[sprites] %s: no %s.png" % [name, base])
        else:
            row = _dir_row(file, cw, ch)
        if row == null:
            if rows.is_empty():
                print("[sprites] %s skipped: the standing row is missing or unusable" % name)
                return
            continue
        rows.append(row)
        used.append(base)
    var sheet: Image = Image.create(cw * DIR_COLS, ch * rows.size(), false, Image.FORMAT_RGBA8)
    for i in rows.size():
        var row_img: Image = rows[i]
        sheet.blit_rect(row_img, Rect2i(0, 0, cw * DIR_COLS, ch), Vector2i(0, i * ch))
    _save(sheet, name)
    print("[sprites] %s rows: %s" % [name, str(used)])


# A straight top-down pose, tightly cropped; the game rotates it around its centre.
func _top(name: String, base: String) -> void:
    var file: String = _find("sprites", base)
    if file == "":
        print("[sprites] %s: no %s.png" % [name, base])
        return
    var img: Image = _load(file)
    if img == null:
        return
    var w: int = img.get_width()
    var data: PackedByteArray = img.get_data()
    var r: Rect2i = _tight(data, w, Rect2i(0, 0, w, img.get_height()))
    var sub: Image = img.get_region(r)
    var k: float = minf(1.0, TOP_SIDE / float(maxi(r.size.x, r.size.y)))
    sub.resize(maxi(1, int(r.size.x * k)), maxi(1, int(r.size.y * k)), Image.INTERPOLATE_LANCZOS)
    print("[sprites] %s: source box %dx%d in %dx%d, fill %d%%" % [name, r.size.x, r.size.y, w, img.get_height(), _fill(data, w, r)])
    _save(sub, name)


# Obstacles: props/<location>/<type>-<size>-<name>.png -> prop_<location>_<type>-<size>-<name>.png
func _props() -> void:
    var base: String = ProjectSettings.globalize_path(SRC + "props")
    if not DirAccess.dir_exists_absolute(base):
        return
    var locs: Array = Array(DirAccess.get_directories_at(base))
    locs.sort()
    for l in locs:
        var loc: String = str(l)
        var files: Array = Array(DirAccess.get_files_at(base + "/" + loc))
        files.sort()
        for n in files:
            var file: String = str(n)
            if file.get_extension().to_lower() != "png":
                continue
            var id: String = file.get_basename().strip_edges().to_lower()
            var parts: PackedStringArray = id.split("-")
            if parts.size() < 3 or not (parts[0] in PROP_TYPES) or not PROP_W.has(parts[1]):
                print("[sprites] skip prop %s/%s: the name must be <type>-<size>-<name>.png" % [loc, file])
                continue
            var img: Image = _load_at("props/" + loc + "/" + file)
            if img == null:
                continue
            var w: int = img.get_width()
            var data: PackedByteArray = img.get_data()
            var r: Rect2i = _tight(data, w, Rect2i(0, 0, w, img.get_height()))
            var sub: Image = img.get_region(r)
            var k: float = minf(1.0, float(PROP_W[parts[1]]) / r.size.x)
            sub.resize(maxi(1, int(r.size.x * k)), maxi(1, int(r.size.y * k)), Image.INTERPOLATE_LANCZOS)
            print("[sprites] prop %s/%s: source box %dx%d in %dx%d, fill %d%%" % [loc, id, r.size.x, r.size.y, w, img.get_height(), _fill(data, w, r)])
            _save(sub, "prop_%s_%s" % [loc, id])


# Location paintings become the arena floors as they are (the importer compresses them).
# "floors" is read after "locations", so an empty floor replaces the old painting of that name.
func _map_dir(dir_rel: String) -> void:
    var base: String = ProjectSettings.globalize_path(SRC + dir_rel)
    if not DirAccess.dir_exists_absolute(base):
        return
    var files: Array = Array(DirAccess.get_files_at(base))
    files.sort()
    for n in files:
        var file: String = str(n)
        if file.get_extension().to_lower() != "png":
            continue
        var img := Image.new()
        if img.load(base + "/" + file) != OK:
            print("[sprites] skip map %s/%s: cannot load" % [dir_rel, file])
            continue
        img.convert(Image.FORMAT_RGB8)
        _save(img, "map_" + file.get_basename().strip_edges())
