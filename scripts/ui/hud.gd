extends Control
## HUD strip, banners, tutorial hints and every menu panel, in English or Russian (core/i18n.gd).
## Fonts, frames, button styles and ornaments come from ui/style.gd.

signal start_requested(kind)
signal upgrade_chosen(choice)
signal continue_requested
signal settings_changed
signal pause_requested
signal resume_requested
signal menu_requested

const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")
const I18n2 = preload("res://scripts/core/i18n2.gd")
const Art = preload("res://scripts/game/art.gd")
const Style = preload("res://scripts/ui/style.gd")

const STRIP := 48.0
const C_GOLD := Color("f0d278")
const C_TEXT := Color("e6dcc0")
const C_DIM := Color("a9b0a7")
const C_CYAN := Color("67dcf4")

var world
var save
var overlay: Control = null
var pause_btn: Button = null
var banner := ""
var banner_sub := ""
var banner_t := 0.0
var _font: Font = null
var _title_font: Font = null
# Parts of the open panel: its frame, the animated backdrop, the frame that fades in and the
# short tap guard of the level-up screen.
var _frame: Control = null
var _fx: Control = null
var _pop: Control = null
var _guard: Control = null
var _fx_t := 0.0


func setup(p_world, p_save) -> void:
    world = p_world
    save = p_save


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = Style.theme()
    _font = Style.bold
    _title_font = Style.title
    pause_btn = Button.new()
    pause_btn.text = "II"
    pause_btn.focus_mode = Control.FOCUS_NONE
    pause_btn.visible = false
    pause_btn.pressed.connect(func(): pause_requested.emit())
    add_child(pause_btn)
    _layout()
    get_viewport().size_changed.connect(_layout)


func _process(delta: float) -> void:
    banner_t = maxf(0.0, banner_t - delta)
    var in_run: bool = world != null and world.in_run
    pause_btn.visible = in_run and overlay == null
    if _fx != null and is_instance_valid(_fx):
        _fx_t += delta
        _fx.queue_redraw()
        if _pop != null and is_instance_valid(_pop):
            _pop.modulate.a = clampf(_fx_t / 0.22, 0.0, 1.0)
        # The thumb is usually on the screen when a level arrives: ignore taps for a moment.
        if _guard != null and is_instance_valid(_guard) and _fx_t > 0.4:
            _guard.queue_free()
            _guard = null
    queue_redraw()


func _layout() -> void:
    var vs: Vector2 = get_viewport_rect().size
    var ins: Vector2 = _insets()
    pause_btn.position = Vector2(vs.x - STRIP + 3.0, ins.x + 3.0)
    pause_btn.size = Vector2(STRIP - 6.0, STRIP - 6.0)


# Safe-area insets in viewport units: x = top (cutout/status bar), y = bottom (gesture bar).
func _insets() -> Vector2:
    if not OS.has_feature("mobile"):
        return Vector2.ZERO
    var win := Vector2(DisplayServer.window_get_size())
    var safe := Rect2(DisplayServer.get_display_safe_area())
    var vs: Vector2 = get_viewport_rect().size
    if win.y <= 0.0:
        return Vector2.ZERO
    var k: float = vs.y / win.y
    var top: float = clampf(safe.position.y * k, 0.0, vs.y * 0.12)
    var bottom: float = clampf((win.y - safe.end.y) * k, 0.0, vs.y * 0.12)
    return Vector2(top, bottom)


func show_banner(text: String, sub: String) -> void:
    banner = text
    banner_sub = sub
    banner_t = 3.0


func _text(pos: Vector2, text: String, font_size: int, col: Color) -> void:
    draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, col)


# Text with a dark outline, for anything drawn over the playfield.
func _out(pos: Vector2, text: String, width: float, font_size: int, col: Color, font: Font, centered: bool) -> void:
    var dark := Color(0.0, 0.0, 0.0, 0.8 * col.a)
    if centered:
        draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, dark)
        draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, col)
    else:
        draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 4, dark)
        draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, col)


func _abbr(key: String) -> String:
    return I18n.t(key).substr(0, 3).to_upper()


# Right-edge status strip: level, HP, XP, clock, galleons and the current build.
func _draw() -> void:
    if world == null or not world.in_run or world.player.is_empty():
        return
    var vs: Vector2 = get_viewport_rect().size
    var top: float = _insets().x
    var x0: float = vs.x - STRIP
    var p: Dictionary = world.player
    var endless: bool = str(world.mode) == "endless"
    draw_rect(Rect2(x0, 0.0, STRIP, vs.y), Color("0f1318"))
    draw_line(Vector2(x0, 0.0), Vector2(x0, vs.y), Color("8f7334"), 2.0)
    draw_line(Vector2(x0 + 3.5, 0.0), Vector2(x0 + 3.5, vs.y), Color(0.56, 0.45, 0.2, 0.35), 1.0)

    var y: float = top + STRIP + 18.0
    _text(Vector2(x0 + 6.0, y), I18n.t("ui_lv") % int(p.level), 12, C_GOLD)
    y += 10.0
    var bar_h: float = 150.0
    var hp_k: float = clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
    draw_rect(Rect2(x0 + 8.0, y, 14.0, bar_h), Color("3a1c1c"))
    draw_rect(Rect2(x0 + 8.0, y + bar_h * (1.0 - hp_k), 14.0, bar_h * hp_k), Color("d74839"))
    draw_rect(Rect2(x0 + 8.0, y + bar_h * (1.0 - hp_k), 4.0, bar_h * hp_k), Color("f0806a"))
    draw_rect(Rect2(x0 + 8.0, y, 14.0, bar_h), Color("8f7334"), false, 1.0)
    var xp_k: float = clampf(float(p.xp) / float(p.xp_next), 0.0, 1.0)
    draw_rect(Rect2(x0 + 28.0, y, 14.0, bar_h), Color("243b46"))
    draw_rect(Rect2(x0 + 28.0, y + bar_h * (1.0 - xp_k), 14.0, bar_h * xp_k), Color("42b9d2"))
    draw_rect(Rect2(x0 + 28.0, y + bar_h * (1.0 - xp_k), 4.0, bar_h * xp_k), Color("9be6f5"))
    draw_rect(Rect2(x0 + 28.0, y, 14.0, bar_h), Color("8f7334"), false, 1.0)
    y += bar_h + 14.0
    _text(Vector2(x0 + 8.0, y), "HP", 10, Color("cf625b"))
    _text(Vector2(x0 + 28.0, y), "XP", 10, C_CYAN)
    y += 22.0

    var remain: float = maxf(0.0, Chapters.SURVIVE_TIME - float(world.time))
    var clock: String = "%d:%02d" % [int(remain / 60.0), int(remain) % 60]
    if world.director.boss_spawned or world.chapter.get("duel", false):
        clock = I18n.t("ui_boss")
    _text(Vector2(x0 + 6.0, y), clock, 12, C_TEXT)
    y += 16.0
    _text(Vector2(x0 + 6.0, y), "x%d" % int(world.kills), 10, C_DIM)
    y += 14.0
    _text(Vector2(x0 + 6.0, y), I18n.t("ui_g") % int(world.run_gold), 10, C_GOLD)
    y += 20.0
    # The build, with how many of its slots are used.
    var spells: Dictionary = p.weapons
    var charms: Dictionary = p.passives
    _text(Vector2(x0 + 6.0, y), "%d/%d" % [spells.size(), Spells.WEAPON_SLOTS], 9, C_DIM)
    y += 12.0
    for id in spells.keys():
        _text(Vector2(x0 + 6.0, y), "%s %d" % [_abbr("sp_" + str(id)), int(spells[id])], 10, C_CYAN)
        y += 13.0
    for id in p.fusions.keys():
        _text(Vector2(x0 + 6.0, y), "+" + _abbr("fu_" + str(id)), 10, Color("ffb04a"))
        y += 13.0
    y += 3.0
    _text(Vector2(x0 + 6.0, y), "%d/%d" % [charms.size(), Spells.PASSIVE_SLOTS], 9, C_DIM)
    y += 12.0
    for id in charms.keys():
        _text(Vector2(x0 + 6.0, y), "%s %d" % [_abbr("pa_" + str(id)), int(charms[id])], 10, C_GOLD)
        y += 13.0
    # One gold pip per active synergy.
    var pips: int = world.syn.size()
    for i in pips:
        Style.diamond(self, Vector2(x0 + 9.0 + (i % 5) * 7.5, y + 5.0 + int(i / 5.0) * 8.0), 3.0, C_GOLD)

    var place: String = I18n.t("ch_" + str(world.chapter.id))
    if endless:
        place = I18n.t("ui_loop") % (int(world.tier) + 1) + "  " + place
    else:
        place = "%d/%d %s" % [int(world.chapter_index) + 1, Chapters.LIST.size(), place]
    _out(Vector2(8.0, top + 17.0), place, -1.0, 13, C_GOLD, _font, false)
    if world.boss != null:
        var bw: float = x0 - 28.0
        var by: float = top + 27.0
        var k: float = clampf(float(world.boss.hp) / float(world.boss.max_hp), 0.0, 1.0)
        draw_rect(Rect2(14.0, by, bw, 9.0), Color("1c0d0f"))
        draw_rect(Rect2(14.0, by, bw * k, 9.0), Color("e0503c"))
        draw_rect(Rect2(14.0, by, bw * k, 3.0), Color("ff8a6a"))
        draw_rect(Rect2(14.0, by, bw, 9.0), Color("c9a24c"), false, 1.5)
        Style.diamond(self, Vector2(14.0, by + 4.5), 6.0, C_GOLD)
        Style.diamond(self, Vector2(14.0 + bw, by + 4.5), 6.0, C_GOLD)
        _out(Vector2(14.0, by + 28.0), I18n.t("bo_" + str(world.boss.type)), -1.0, 15, C_TEXT, _title_font, false)

    if overlay != null:
        return
    # First run: four short hints, one after another.
    if not endless and int(world.chapter_index) == 0 and not bool(save.data.get("tutorial", false)):
        var tip: int = int(float(world.time) / 6.0)
        if tip < 4:
            var ty: float = vs.y * 0.6
            var mid := Vector2(x0 * 0.5, 0.0)
            draw_rect(Rect2(0.0, ty - 21.0, x0, 32.0), Color(0.0, 0.0, 0.0, 0.55))
            for edge in [ty - 21.0, ty + 11.0]:
                var ey: float = edge
                Style.fade_line(self, Vector2(0.0, ey), mid + Vector2(0.0, ey), 1.4, C_GOLD)
                Style.fade_line(self, Vector2(x0, ey), mid + Vector2(0.0, ey), 1.4, C_GOLD)
            draw_string(_font, Vector2(0.0, ty), I18n.t("tut_%d" % (tip + 1)), HORIZONTAL_ALIGNMENT_CENTER, x0, 14, C_TEXT)
    if banner_t > 0.0:
        var alpha: float = clampf(banner_t, 0.0, 1.0)
        var ny: float = vs.y * 0.3
        _out(Vector2(0.0, ny), banner, x0, 28, Color(C_GOLD, alpha), _title_font, true)
        Style.divider(self, Vector2(x0 * 0.5, ny + 13.0), 120.0, Color(C_GOLD, alpha))
        _out(Vector2(0.0, ny + 36.0), banner_sub, x0, 14, Color(C_TEXT, alpha), _font, true)


# ---------------------------------------------------------------- panel building

func close_panel() -> void:
    _frame = null
    _fx = null
    _pop = null
    _guard = null
    if overlay != null:
        overlay.queue_free()
        overlay = null


# A dimmed screen with one framed column of content. "low" keeps the frame near the thumb.
func _panel(title: String, sub: String, low: bool, dim: float = 0.86, title_size: int = 28) -> VBoxContainer:
    close_panel()
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.03, 0.05, dim)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay = bg
    var ins: Vector2 = _insets()
    var outer := VBoxContainer.new()
    bg.add_child(outer)
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
    outer.alignment = BoxContainer.ALIGNMENT_END if low else BoxContainer.ALIGNMENT_CENTER
    outer.add_theme_constant_override("separation", 0)
    _gap(outer, ins.x)
    var frame := PanelContainer.new()
    frame.add_theme_stylebox_override("panel", Style.panel_box())
    frame.draw.connect(func(): Style.corners(frame, Rect2(Vector2.ZERO, frame.size), Style.GOLD))
    outer.add_child(frame)
    _gap(outer, ins.y + (10.0 if low else 0.0))
    _frame = frame
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 9)
    frame.add_child(box)
    box.add_child(_title(title, title_size))
    box.add_child(_rule())
    if sub != "":
        box.add_child(_label(sub, 14, C_DIM))
    return box


# A scrolling list that fills the rest of a panel (for long screens).
func _scroll(box: VBoxContainer) -> VBoxContainer:
    var frame := box.get_parent() as Control
    if frame != null:
        frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    box.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 4)
    scroll.add_child(list)
    return list


func _gap(list: Control, h: float = 8.0) -> void:
    var gap := Control.new()
    gap.custom_minimum_size = Vector2(0.0, h)
    gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    list.add_child(gap)


func _label(text: String, font_size: int, col: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", col)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l


# A heading in the display font with a heavy outline and a drop shadow.
func _title(text: String, font_size: int) -> Label:
    var l: Label = _label(text, font_size, C_GOLD)
    l.add_theme_font_override("font", Style.title)
    l.add_theme_constant_override("outline_size", 5)
    l.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
    l.add_theme_constant_override("shadow_offset_x", 0)
    l.add_theme_constant_override("shadow_offset_y", 3)
    return l


# The ornament under a heading.
func _rule() -> Control:
    var c := Control.new()
    c.custom_minimum_size = Vector2(0.0, 12.0)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    c.draw.connect(func(): Style.divider(c, c.size * 0.5, minf(150.0, c.size.x * 0.42), Style.GOLD))
    return c


func _button(text: String, cb: Callable, min_h: float = 64.0) -> Button:
    var b := Button.new()
    b.text = text
    b.clip_text = true
    b.custom_minimum_size = Vector2(0.0, min_h)
    b.focus_mode = Control.FOCUS_NONE
    if min_h < 50.0:
        b.add_theme_font_size_override("font_size", 15)
    b.pressed.connect(cb)
    return b


# The main action of a screen: brighter frame and larger text.
func _primary(b: Button) -> Button:
    b.add_theme_stylebox_override("normal", Style.box(Color("2b2413"), Style.GOLD, 2, 10))
    b.add_theme_stylebox_override("hover", Style.box(Color("3a3018"), Color("fff3c4"), 2, 10))
    b.add_theme_stylebox_override("pressed", Style.box(Color("4a3c1c"), Color("fff3c4"), 2, 10))
    b.add_theme_color_override("font_color", Style.GOLD)
    b.add_theme_font_size_override("font_size", 19)
    return b


# A big three-line button: small tag, title, description, tinted with an accent colour.
func _card(tag: String, title: String, text: String, cb: Callable, min_h: float = 136.0, col: Color = C_CYAN) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0.0, min_h)
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_stylebox_override("normal", Style.card_box(col, 0))
    b.add_theme_stylebox_override("hover", Style.card_box(col, 1))
    b.add_theme_stylebox_override("pressed", Style.card_box(col, 2))
    b.draw.connect(func(): Style.card_deco(b, col))
    var v := VBoxContainer.new()
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(v)
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 3)
    v.add_child(_label(tag, 11, col))
    var name_l: Label = _label(title, 19, C_GOLD)
    name_l.add_theme_font_override("font", Style.title)
    name_l.add_theme_constant_override("outline_size", 4)
    v.add_child(name_l)
    v.add_child(_label(text, 12, C_TEXT))
    b.pressed.connect(cb)
    return b


func _gold_label() -> Label:
    return _label(I18n.t("ui_gold") % int(save.data.get("gold", 0)), 15, C_GOLD)


# True while a run with a hero is going on (the build limits can be shown).
func _has_build() -> bool:
    return world != null and world.in_run and not world.player.is_empty()


# An animated layer behind the frame of the open panel: "menu" (calm) or "level" (a burst).
func _backdrop(kind: String) -> void:
    if overlay == null:
        return
    var fx := Control.new()
    fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var mat := CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    fx.material = mat
    overlay.add_child(fx)
    overlay.move_child(fx, 0)
    fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var anchor: Control = _frame
    fx.draw.connect(func(): _draw_fx(fx, kind, anchor))
    _fx = fx
    _fx_t = 0.0


# Light behind the heading, slowly turning rays and rising sparks. A new level adds a flash,
# three expanding rings and a burst of sparks. Everything is drawn additively.
func _draw_fx(ci: Control, kind: String, anchor: Control) -> void:
    var vs: Vector2 = ci.size
    var t: float = _fx_t
    var level: bool = kind == "level"
    var c := Vector2(vs.x * 0.5, vs.y * 0.28)
    if anchor != null and is_instance_valid(anchor):
        var r: Rect2 = anchor.get_global_rect()
        c = Vector2(r.position.x + r.size.x * 0.5, r.position.y + 44.0)
    var gold := Color(1.0, 0.76, 0.3)
    var pale := Color(0.55, 0.9, 1.0)
    var none := PackedVector2Array()
    if level:
        if t < 0.3 and bool(save.data.get("flash", true)):
            ci.draw_rect(Rect2(Vector2.ZERO, vs), Color(gold, 0.3 * (1.0 - t / 0.3)))
    else:
        var hi := Color(0.05, 0.08, 0.2, 1.0)
        var lo := Color(0.0, 0.0, 0.0, 1.0)
        ci.draw_primitive(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0.0), vs, Vector2(0.0, vs.y)]), PackedColorArray([hi, hi, lo, lo]), none)
    var rise: float = 1.0 - pow(1.0 - minf(1.0, t / 0.5), 3.0)
    var tex: Texture2D = null
    if world != null:
        tex = world.light_tex
    if tex != null:
        var gr: float = (230.0 if level else 250.0) * (0.6 + 0.4 * rise)
        ci.draw_texture_rect(tex, Rect2(c - Vector2(gr, gr * 0.62), Vector2(gr * 2.0, gr * 1.24)), false, Color(gold, (0.5 if level else 0.25) * rise))
    var reach: float = (340.0 if level else 300.0) * rise
    if reach > 6.0:
        for i in 14:
            var a: float = TAU * i / 14.0 + t * (0.22 if level else 0.06)
            var half: float = 0.075 if i % 2 == 0 else 0.04
            var l: float = reach * (1.0 if i % 2 == 0 else 0.72)
            var core := Color(gold, (0.2 if level else 0.07) * (0.75 + 0.25 * sin(t * 2.0 + i)))
            var edge := Color(gold, 0.0)
            ci.draw_primitive(PackedVector2Array([c, c + Vector2.from_angle(a - half) * l, c + Vector2.from_angle(a + half) * l]), PackedColorArray([core, edge, edge]), none)
    if level:
        for j in 3:
            var k: float = (t - j * 0.16) / 0.9
            if k > 0.0 and k < 1.0:
                ci.draw_arc(c, 24.0 + 380.0 * k, 0.0, TAU, 56, Color(gold, 0.55 * (1.0 - k)), 1.0 + 3.0 * (1.0 - k))
        var bk: float = t / 1.1
        if bk < 1.0:
            var out_k: float = 1.0 - pow(1.0 - bk, 2.0)
            for i in 22:
                var d: Vector2 = Vector2.from_angle(TAU * Style.rnd(i, 7.0))
                var at: Vector2 = c + d * (30.0 + (170.0 + 190.0 * Style.rnd(i, 8.0)) * out_k)
                Style.star(ci, at, (3.0 + 5.0 * Style.rnd(i, 9.0)) * (1.0 - bk * 0.6), Color(gold if i % 3 > 0 else pale, 0.9 * (1.0 - bk)))
    var count: int = 38 if level else 30
    var span: float = vs.y + 40.0
    for i in count:
        var speed: float = 16.0 + 44.0 * Style.rnd(i, 1.0)
        var x: float = vs.x * Style.rnd(i, 2.0) + sin(t * (0.5 + Style.rnd(i, 3.0)) + i) * 14.0
        var y: float = vs.y + 20.0 - fposmod(t * speed + span * Style.rnd(i, 4.0), span)
        var tw: float = 0.5 + 0.5 * sin(t * (2.0 + 3.0 * Style.rnd(i, 5.0)) + i * 1.7)
        var rad: float = (2.0 + 4.0 * Style.rnd(i, 6.0)) * (0.5 + 0.5 * tw)
        Style.star(ci, Vector2(x, y), rad, Color(gold if i % 4 > 0 else pale, (0.2 + 0.5 * tw) * minf(1.0, t / 0.4)))


# ---------------------------------------------------------------- screens

func show_menu() -> void:
    var box: VBoxContainer = _panel("HEX DISTRICT", I18n.t("ui_sub"), false, 0.92, 38)
    _frame.add_theme_stylebox_override("panel", Style.panel_box(0.6))
    _backdrop("menu")
    var d: Dictionary = save.data
    box.add_child(_label(I18n.t("ui_stats") % [int(d.runs), int(d.wins), int(d.best_chapter), Chapters.LIST.size(), int(d.best_kills)], 12, C_DIM))
    box.add_child(_gold_label())
    var cp: Dictionary = d.get("checkpoint", {})
    if not cp.is_empty():
        var idx: int = clampi(int(cp.get("chapter", 0)), 0, Chapters.LIST.size() - 1)
        box.add_child(_primary(_button(I18n.t("ui_continue") % I18n.t("ch_" + str(Chapters.LIST[idx].id)), func(): start_requested.emit("resume"), 58.0)))
    box.add_child(_primary(_button(I18n.t("ui_new"), func(): start_requested.emit("story"), 58.0)))
    box.add_child(_button(I18n.t("ui_endless") % int(d.best_endless), func(): start_requested.emit("endless"), 54.0))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    box.add_child(grid)
    var items: Array = [
        [I18n.t("ui_hero") % I18n.t("he_" + str(d.hero)), func(): show_heroes(show_menu)],
        [I18n.t("ui_shop"), func(): show_shop(show_menu)],
        [I18n.t("ui_combos"), func(): show_combos(show_menu)],
        [I18n.t("ui_bestiary"), func(): show_bestiary(show_menu)],
        [I18n.t("ui_help"), func(): show_help(show_menu)],
        [I18n.t("ui_settings"), func(): show_settings(show_menu)],
    ]
    for item in items:
        var b: Button = _button(str(item[0]), item[1], 46.0)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        grid.add_child(b)
    box.add_child(_rule())
    box.add_child(_label(I18n.t("ui_hint"), 12, C_TEXT))
    box.add_child(_label(I18n.t("ui_legal"), 10, C_DIM))


## The upgrade choice sits in the middle of the screen, over a burst of light. Under the heading
## it says how many spell and talisman slots the build has and how many are used.
func show_levelup(choices: Array, level: int) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_level") % level, I18n.t("ui_choose"), false, 0.6, 34)
    _frame.add_theme_stylebox_override("panel", Style.panel_box(0.8))
    _frame.modulate.a = 0.0
    _pop = _frame
    _backdrop("level")
    if _has_build():
        var p: Dictionary = world.player
        var spells: Dictionary = p.weapons
        box.add_child(_label(Spells.limits(p), 12, C_CYAN))
        if spells.size() >= Spells.WEAPON_SLOTS:
            box.add_child(_label(I18n2.t("x_full"), 11, C_DIM))
    for item in choices:
        var c: Dictionary = item
        var col: Color = Style.kind_color(str(c.get("kind", "")))
        box.add_child(_card(str(c.tag), str(c.title), str(c.text), func(): upgrade_chosen.emit(c), 136.0, col))
    var guard := Control.new()
    guard.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.add_child(guard)
    guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _guard = guard


func show_pause() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_paused"), "", true)
    if _has_build():
        box.add_child(_label(Spells.limits(world.player), 12, C_CYAN))
    box.add_child(_primary(_button(I18n.t("ui_resume"), func(): resume_requested.emit())))
    box.add_child(_button(I18n.t("ui_combos"), func(): show_combos(show_pause)))
    box.add_child(_button(I18n.t("ui_settings"), func(): show_settings(show_pause)))
    box.add_child(_button(I18n.t("ui_quit"), func(): menu_requested.emit()))


func show_chapter_clear(index: int) -> void:
    var next: Dictionary = Chapters.LIST[mini(index + 1, Chapters.LIST.size() - 1)]
    var box: VBoxContainer = _panel(I18n.t("ui_cleared"), I18n.t("ui_cleared_sub"), true)
    if next.get("duel", false):
        box.add_child(_label(I18n.t("ui_next_boss") % I18n.t("bo_" + str(next.boss)), 18, Color("ff9a7a")))
        box.add_child(_label(I18n.t("ch_" + str(next.id)), 13, C_DIM))
    else:
        box.add_child(_label(I18n.t("ui_next") % I18n.t("ch_" + str(next.id)), 18, C_TEXT))
        box.add_child(_label(I18n.t("cs_" + str(next.id)), 13, C_DIM))
    box.add_child(_label(I18n.t("ui_sum3") % int(world.run_gold), 13, C_GOLD))
    box.add_child(_label(I18n.t("ui_saved"), 12, C_DIM))
    box.add_child(_primary(_button(I18n.t("ui_go"), func(): continue_requested.emit())))


func show_summary(victory: bool) -> void:
    var title: String = I18n.t("ui_win") if victory else I18n.t("ui_lose")
    var sub: String = I18n.t("ui_win_sub") if victory else I18n.t("ui_lose_sub")
    var box: VBoxContainer = _panel(title, sub, true)
    var secs: int = int(world.run_time)
    var mode: String = str(world.mode)
    var stage: int = int(world.tier) + 1 if mode == "endless" else int(world.chapter_index) + 1
    box.add_child(_label(I18n.t("ui_sum1") % [stage, I18n.t("ch_" + str(world.chapter.id))], 16, C_TEXT))
    box.add_child(_label(I18n.t("ui_sum2") % [int(secs / 60.0), secs % 60, int(world.player.level), int(world.kills)], 14, C_TEXT))
    box.add_child(_label(I18n.t("ui_sum3") % int(world.run_gold), 14, C_GOLD))
    box.add_child(_primary(_button(I18n.t("ui_restart"), func(): start_requested.emit(mode))))
    box.add_child(_button(I18n.t("ui_shop"), func(): show_shop(show_menu), 52.0))
    box.add_child(_button(I18n.t("ui_menu"), func(): menu_requested.emit(), 52.0))


## Pick (or buy) the playable hero.
func show_heroes(back: Callable) -> void:
    var current: String = str(save.data.get("hero", "harry"))
    var box: VBoxContainer = _panel(I18n.t("ui_hero") % I18n.t("he_" + current), I18n.t("ui_hero_sub"), true)
    box.add_child(_gold_label())
    var owned: Array = save.data.get("heroes", ["harry"])
    for key in Spells.HEROES:
        var id: String = str(key)
        var state: String = I18n.t("ui_select")
        var col: Color = C_CYAN
        if id == current:
            state = I18n.t("ui_selected")
            col = C_GOLD
        elif not (id in owned):
            state = I18n.t("ui_buy") % int(Spells.HEROES[id].cost)
            col = C_DIM
        var cb: Callable = func() -> void:
            if Spells.hero_pick(save.data, id):
                save.save_data()
                settings_changed.emit()
            show_heroes(back)
        box.add_child(_card(state, I18n.t("he_" + id), I18n.t("hd_" + id), cb, 112.0, col))
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


## Permanent upgrades bought with galleons.
func show_shop(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_shop"), I18n.t("ui_shop_sub"), false)
    box.add_child(_gold_label())
    var list: VBoxContainer = _scroll(box)
    var meta: Dictionary = save.data.get("meta", {})
    for key in Spells.META:
        var id: String = str(key)
        var lv: int = int(meta.get(id, 0))
        var top: int = int(Spells.META[id][0])
        var price: String = I18n.t("ui_max")
        if lv < top:
            price = I18n.t("ui_buy") % Spells.meta_cost(id, lv)
        var cb: Callable = func() -> void:
            if Spells.meta_buy(save.data, id):
                save.save_data()
            show_shop(back)
        list.add_child(_button("%s  %d/%d   %s" % [I18n.t("me_" + id), lv, top, price], cb, 44.0))
        list.add_child(_label(I18n.t("md_" + id), 11, C_DIM))
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


# A section heading inside a long list.
func _section(list: VBoxContainer, text: String) -> void:
    var l: Label = _label(text, 15, Color("ffb04a"))
    l.add_theme_font_override("font", Style.title)
    list.add_child(l)
    list.add_child(_rule())


## Combo codex: fusions (2-4 spells), evolutions and synergies, with the state of the current build.
func show_combos(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_combos"), I18n.t("ui_combo_sub"), false)
    var build: Dictionary = {"weapons": {}, "passives": {}, "evolved": {}, "fusions": {}}
    if _has_build():
        build = world.player
    box.add_child(_label(Spells.limits(build), 12, C_CYAN))
    var list: VBoxContainer = _scroll(box)
    _section(list, I18n.t("ui_sec_fusion"))
    for key in Spells.FUSIONS:
        var fid: String = str(key)
        var need: Array = Spells.FUSIONS[fid].need
        var title: String = I18n.t("fu_" + fid)
        var col: Color = C_TEXT
        if build.fusions.has(fid):
            title += "  -  " + I18n.t("ui_owned")
            col = C_GOLD
        elif Spells.fusion_ready(build, fid):
            title += "  -  " + I18n.t("ui_ready")
            col = C_GOLD
        list.add_child(_label(title, 15, col))
        list.add_child(_label(I18n.t("ui_fuse_req") % [Spells.names(need, " + "), Spells.fusion_min(fid)], 11, C_CYAN))
        list.add_child(_label(I18n.t("fd_" + fid), 12, C_DIM))
        _gap(list)
    _section(list, I18n2.t("x_sec_evo"))
    for key in Spells.EVOLUTIONS:
        var eid: String = str(key)
        var ev: Dictionary = Spells.EVOLUTIONS[eid]
        var have: bool = build.evolved.has(eid)
        var etitle: String = I18n.t("ev_" + eid)
        if have:
            etitle += "  -  " + I18n.t("ui_owned")
        list.add_child(_label(etitle, 15, C_GOLD if have else C_TEXT))
        list.add_child(_label(I18n.t("ui_evo_req") % [I18n.t("sp_" + str(ev.weapon)), I18n.t("pa_" + str(ev.passive))], 11, C_CYAN))
        list.add_child(_label(I18n.t("ed_" + eid), 12, C_DIM))
        _gap(list)
    _section(list, I18n.t("ui_sec_syn"))
    for key in Spells.SYNERGIES:
        var sid: String = str(key)
        var on: bool = Spells.is_active(build, sid)
        var state: String = I18n.t("ui_syn_on") if on else I18n.t("ui_syn_off")
        list.add_child(_label("%s  -  %s" % [I18n.t("sy_" + sid), state], 15, C_GOLD if on else C_TEXT))
        list.add_child(_label(Spells.requirement(sid), 11, C_CYAN))
        list.add_child(_label(I18n.t("sx_" + sid), 12, C_DIM))
        _gap(list)
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


## Every enemy and boss defeated so far, with its picture and behaviour.
func show_bestiary(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_bestiary"), I18n.t("ui_best_sub"), false)
    var seen: Dictionary = save.data.get("seen", {})
    var list: VBoxContainer = _scroll(box)
    for key in Enemies.TYPES:
        _beast(list, str(key), false, seen.has(key))
    for key in Enemies.BOSSES:
        _beast(list, str(key), true, seen.has(key))
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


func _beast(list: VBoxContainer, key: String, boss: bool, known: bool) -> void:
    if not known:
        list.add_child(_label(I18n.t("ui_unknown"), 12, C_DIM))
        return
    var e: Dictionary = Enemies.make_boss(key, Vector2.ZERO, 0) if boss else Enemies.make(key, Vector2.ZERO, 0, 1.0, false)
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 8)
    var icon := Control.new()
    icon.custom_minimum_size = Vector2(60.0, 60.0)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pic := Node2D.new()
    var k: float = 44.0 / (float(e.r) * 3.5)
    pic.position = Vector2(30.0, 46.0)
    pic.scale = Vector2(k, k)
    pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    pic.draw.connect(func(): Art.enemy(pic, e, 0.0, false))
    icon.add_child(pic)
    row.add_child(icon)
    var col := VBoxContainer.new()
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var name_l: Label = _label(I18n.t(("bo_" if boss else "en_") + key), 15, Color("ff9a7a") if boss else C_GOLD)
    name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var stat_l: Label = _label(I18n.t("ui_bstat") % [int(e.max_hp), int(e.dmg), I18n.t("ai_" + str(e.ai))], 11, C_DIM)
    stat_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    col.add_child(name_l)
    col.add_child(stat_l)
    row.add_child(col)
    list.add_child(row)


func show_help(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_help"), "", false)
    for i in 5:
        box.add_child(_label(I18n.t("help_%d" % (i + 1)), 13, C_TEXT))
    box.add_child(_label(I18n2.t("x_help_limits") % [Spells.WEAPON_SLOTS, Spells.PASSIVE_SLOTS, Spells.MAX_LEVEL, Spells.PASSIVE_MAX], 13, C_TEXT))
    if Style.found > 0:
        var credit: String = "Fonts: Yeseva One, Philosopher (SIL Open Font License)"
        if I18n.lang == "ru":
            credit = "Шрифты: Yeseva One, Philosopher (SIL Open Font License)"
        box.add_child(_label(credit, 10, C_DIM))
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


func show_settings(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_settings"), I18n.t("ui_set_sub"), false)
    var list: VBoxContainer = _scroll(box)
    var on_off: Array = [I18n.t("v_on"), I18n.t("v_off")]
    _option(list, back, I18n.t("o_lang"), "lang", ["en", "ru"], ["English", "Русский"])
    _option(list, back, I18n.t("o_sprites"), "sprites", [true, false], [I18n.t("v_painted"), I18n.t("v_drawn")])
    _option(list, back, I18n.t("o_music"), "music", [true, false], on_off)
    _option(list, back, I18n.t("o_sound"), "sound", [true, false], on_off)
    _option(list, back, I18n.t("o_hand"), "right_handed", [true, false], [I18n.t("v_right"), I18n.t("v_left")])
    _option(list, back, I18n.t("o_size"), "stick_size", [44.0, 56.0, 70.0], [I18n.t("v_small"), I18n.t("v_medium"), I18n.t("v_large")])
    _option(list, back, I18n.t("o_opacity"), "stick_opacity", [0.3, 0.5, 0.8], ["30%", "50%", "80%"])
    _option(list, back, I18n.t("o_sens"), "sensitivity", [0.8, 1.0, 1.3], [I18n.t("v_low"), I18n.t("v_normal"), I18n.t("v_high")])
    _option(list, back, I18n.t("o_shake"), "shake", [true, false], on_off)
    _option(list, back, I18n.t("o_vib"), "vibration", [true, false], on_off)
    _option(list, back, I18n.t("o_flash"), "flash", [true, false], on_off)
    _option(list, back, I18n.t("o_contrast"), "high_contrast", [true, false], on_off)
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))


# One button per option; tapping cycles through the values and saves immediately.
func _option(list: VBoxContainer, back: Callable, label: String, key: String, values: Array, names: Array) -> void:
    var i: int = maxi(0, values.find(save.data[key]))
    var cb: Callable = func() -> void:
        save.data[key] = values[(i + 1) % values.size()]
        save.save_data()
        settings_changed.emit()
        show_settings(back)
    list.add_child(_button(label + ": " + str(names[i]), cb, 42.0))
