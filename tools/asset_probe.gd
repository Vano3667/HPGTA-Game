extends SceneTree
## Build-time helper: prints measurable facts about the master images in assets/visual-kit
## (size, real transparency, sprite cells, rough silhouettes). Nothing is modified.
## Usage: godot --headless --path . -s res://tools/asset_probe.gd

const ROOT := "res://assets/visual-kit/"
const THUMB_W := 12
const THUMB_H := 10


func _init() -> void:
    for sub in ["sprites", "locations"]:
        var base: String = ProjectSettings.globalize_path(ROOT + sub)
        var names: Array = Array(DirAccess.get_files_at(base))
        names.sort()
        for n in names:
            var file: String = str(n)
            if file.ends_with(".png"):
                _probe(base + "/" + file, file, sub == "sprites")
    print("[probe] done")
    quit(0)


func _probe(path: String, file: String, sprite: bool) -> void:
    var img := Image.new()
    if img.load(path) != OK:
        print("[probe] %s: load failed" % file)
        return
    img.convert(Image.FORMAT_RGBA8)
    var w: int = img.get_width()
    var h: int = img.get_height()
    var data: PackedByteArray = img.get_data()
    var rows := PackedInt32Array()
    rows.resize(h)
    var clear: int = 0
    for y in h:
        var o: int = y * w * 4 + 3
        var c: int = 0
        for x in w:
            if data[o + x * 4] > 40:
                c += 1
        rows[y] = c
        clear += w - c
    var pct: float = 100.0 * clear / float(w * h)
    print("[probe] %s %dx%d transparent=%.1f%% corner=%s" % [file, w, h, pct, img.get_pixel(2, 2).to_html()])
    if not sprite:
        _luma_grid(img, w, h)
        return
    if pct < 3.0 or pct > 99.0:
        print("[probe]   no usable alpha channel")
        return
    var bands: Array = _runs(rows, w)
    var bi: int = 0
    for band in bands:
        var y0: int = band[0]
        var y1: int = band[1]
        var cols := PackedInt32Array()
        cols.resize(w)
        for y in range(y0, y1 + 1):
            var o2: int = y * w * 4 + 3
            for x in w:
                if data[o2 + x * 4] > 40:
                    cols[x] += 1
        var cells: Array = _runs(cols, y1 - y0 + 1)
        var info: String = ""
        var thumbs: Array = []
        var ci: int = 0
        for cell in cells:
            var st: Dictionary = _cell(img, cell[0], y0, cell[1], y1)
            info += " c%d x=%d-%d skin=%d dx=%.2f;" % [ci, cell[0], cell[1], int(st.skin), float(st.dx)]
            if thumbs.size() < 8:
                thumbs.append(st.lines)
            ci += 1
        print("[probe]  band %d y=%d-%d cells=%d:%s" % [bi, y0, y1, cells.size(), info])
        for ty in THUMB_H:
            var line: String = ""
            for t in thumbs:
                line += str(t[ty]) + "|"
            print("[probe]   " + line)
        bi += 1


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


func _cell(img: Image, x0: int, y0: int, x1: int, y1: int) -> Dictionary:
    var cw: float = float(x1 - x0 + 1)
    var ch: float = float(y1 - y0 + 1)
    var lines: Array = []
    for ty in THUMB_H:
        var s: String = ""
        for tx in THUMB_W:
            s += _glyph(img, x0 + cw * (tx + 0.5) / THUMB_W, y0 + ch * (ty + 0.5) / THUMB_H, cw / THUMB_W * 0.3, ch / THUMB_H * 0.3)
        lines.append(s)
    # Face detection in the top 40% of the cell: skin share and which side it sits on.
    var op: int = 0
    var skin: int = 0
    var sx: float = 0.0
    var ox: float = 0.0
    for gy in 20:
        for gx in 40:
            var c: Color = img.get_pixel(x0 + int(cw * (gx + 0.5) / 40.0), y0 + int(ch * 0.4 * (gy + 0.5) / 20.0))
            if c.a < 0.3:
                continue
            op += 1
            ox += gx
            if _skin(c):
                skin += 1
                sx += gx
    var pct: float = 0.0
    var dx: float = 0.0
    if op > 0:
        pct = 100.0 * skin / float(op)
    if skin > 0 and op > 0:
        dx = (sx / float(skin) - ox / float(op)) / 20.0
    return {"lines": lines, "skin": pct, "dx": dx}


func _glyph(img: Image, fx: float, fy: float, dx: float, dy: float) -> String:
    var w: int = img.get_width()
    var h: int = img.get_height()
    var sum := Color(0.0, 0.0, 0.0, 0.0)
    var n: int = 0
    for off in [Vector2.ZERO, Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
        var o: Vector2 = off
        var c: Color = img.get_pixel(clampi(int(fx + o.x * dx), 0, w - 1), clampi(int(fy + o.y * dy), 0, h - 1))
        if c.a > 0.3:
            sum += c
            n += 1
    if n < 3:
        return " "
    return _class(sum / float(n))


func _skin(c: Color) -> bool:
    return c.r > 0.62 and c.g > 0.42 and c.b > 0.28 and c.r > c.g * 1.08 and c.g > c.b * 1.05 and c.b > c.r * 0.45


func _class(c: Color) -> String:
    if _skin(c):
        return "s"
    if c.r > 0.45 and c.r > c.g * 1.7 and c.r > c.b * 1.7:
        return "R"
    if c.g > 0.4 and c.g > c.r * 1.3 and c.g > c.b * 1.3:
        return "G"
    var l: float = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
    if l < 0.18:
        return "#"
    if l < 0.4:
        return "x"
    if l < 0.65:
        return "o"
    return "."


# Locations: a coarse brightness map (0 dark .. 9 bright), rows separated by '/'.
func _luma_grid(img: Image, w: int, h: int) -> void:
    var out: String = ""
    var mean := Color(0.0, 0.0, 0.0, 1.0)
    for gy in 18:
        for gx in 12:
            var acc: float = 0.0
            for k in 9:
                var px: int = clampi(int(w * (gx + (k % 3 + 0.5) / 3.0) / 12.0), 0, w - 1)
                var py: int = clampi(int(h * (gy + (int(k / 3.0) + 0.5) / 3.0) / 18.0), 0, h - 1)
                var c: Color = img.get_pixel(px, py)
                acc += 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
                mean += c / 1944.0
            out += str(clampi(int(acc / 9.0 * 10.0), 0, 9))
        out += "/"
    mean.a = 1.0
    print("[probe]   mean=%s luma=%s" % [mean.to_html(false), out])
