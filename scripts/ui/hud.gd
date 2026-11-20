extends Control
## HUD strip, banners and every menu panel. Panels keep their buttons large and low on the
## screen so the whole game stays playable with one thumb.

signal start_requested(resume)
signal upgrade_chosen(choice)
signal continue_requested
signal settings_changed
signal pause_requested
signal resume_requested
signal menu_requested

const Chapters = preload("res://scripts/data/chapters.gd")
const Spells = preload("res://scripts/data/spells.gd")

const STRIP := 48.0
const C_GOLD := Color("f0d278")
const C_TEXT := Color("dad1b0")
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


func setup(p_world, p_save) -> void:
    world = p_world
    save = p_save


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _font = ThemeDB.fallback_font
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


# Right-edge status strip in the spirit of the reference boards: level, HP, XP, clock, spells.
func _draw() -> void:
    if world == null or not world.in_run or world.player.is_empty():
        return
    var vs: Vector2 = get_viewport_rect().size
    var top: float = _insets().x
    var x0: float = vs.x - STRIP
    var p: Dictionary = world.player
    draw_rect(Rect2(x0, 0.0, STRIP, vs.y), Color("111619"))
    draw_line(Vector2(x0, 0.0), Vector2(x0, vs.y), Color("4d5148"), 2.0)

    var y: float = top + STRIP + 18.0
    _text(Vector2(x0 + 6.0, y), "LV %d" % int(p.level), 12, C_GOLD)
    y += 10.0
    var bar_h: float = 150.0
    var hp_k: float = clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
    draw_rect(Rect2(x0 + 7.0, y, 14.0, bar_h), Color("3a1c1c"))
    draw_rect(Rect2(x0 + 7.0, y + bar_h * (1.0 - hp_k), 14.0, bar_h * hp_k), Color("d74839"))
    draw_rect(Rect2(x0 + 7.0, y, 14.0, bar_h), Color("83949a"), false, 1.0)
    var xp_k: float = clampf(float(p.xp) / float(p.xp_next), 0.0, 1.0)
    draw_rect(Rect2(x0 + 27.0, y, 14.0, bar_h), Color("243b46"))
    draw_rect(Rect2(x0 + 27.0, y + bar_h * (1.0 - xp_k), 14.0, bar_h * xp_k), Color("42b9d2"))
    draw_rect(Rect2(x0 + 27.0, y, 14.0, bar_h), Color("83949a"), false, 1.0)
    y += bar_h + 14.0
    _text(Vector2(x0 + 7.0, y), "HP", 10, Color("cf625b"))
    _text(Vector2(x0 + 27.0, y), "XP", 10, C_CYAN)
    y += 22.0

    var remain: float = maxf(0.0, Chapters.SURVIVE_TIME - float(world.time))
    var clock: String = "%d:%02d" % [int(remain / 60.0), int(remain) % 60]
    if world.director.boss_spawned:
        clock = "BOSS"
    _text(Vector2(x0 + 5.0, y), clock, 12, C_TEXT)
    y += 16.0
    _text(Vector2(x0 + 5.0, y), "K %d" % int(world.kills), 10, C_DIM)
    y += 20.0
    for id in p.weapons.keys():
        var w_name: String = str(Spells.WEAPONS[id].name).substr(0, 3).to_upper()
        _text(Vector2(x0 + 5.0, y), "%s %d" % [w_name, int(p.weapons[id])], 10, C_CYAN)
        y += 13.0
    for id in p.passives.keys():
        var p_name: String = str(Spells.PASSIVES[id].name).substr(0, 3).to_upper()
        _text(Vector2(x0 + 5.0, y), "%s %d" % [p_name, int(p.passives[id])], 10, C_GOLD)
        y += 13.0

    _text(Vector2(8.0, top + 16.0), "%d/5 %s" % [int(world.chapter_index) + 1, str(world.chapter.name)], 12, C_GOLD)
    if world.boss != null:
        var bw: float = x0 - 16.0
        var k: float = clampf(float(world.boss.hp) / float(world.boss.max_hp), 0.0, 1.0)
        draw_rect(Rect2(8.0, top + 24.0, bw, 8.0), Color("2a1416"))
        draw_rect(Rect2(8.0, top + 24.0, bw * k, 8.0), Color("e0503c"))
        draw_rect(Rect2(8.0, top + 24.0, bw, 8.0), Color("c9a24c"), false, 1.0)
        _text(Vector2(8.0, top + 46.0), str(world.boss.name), 12, C_TEXT)

    if banner_t > 0.0 and overlay == null:
        var alpha: float = clampf(banner_t, 0.0, 1.0)
        draw_string(_font, Vector2(0.0, vs.y * 0.3), banner, HORIZONTAL_ALIGNMENT_CENTER, x0, 24, Color(C_GOLD, alpha))
        draw_string(_font, Vector2(0.0, vs.y * 0.3 + 22.0), banner_sub, HORIZONTAL_ALIGNMENT_CENTER, x0, 13, Color(C_TEXT, alpha))


# ---------------------------------------------------------------- panel building

func close_panel() -> void:
    if overlay != null:
        overlay.queue_free()
        overlay = null


func _panel(title: String, sub: String, low: bool) -> VBoxContainer:
    close_panel()
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.03, 0.04, 0.84)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay = bg
    var box := VBoxContainer.new()
    bg.add_child(box)
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
    box.alignment = BoxContainer.ALIGNMENT_END if low else BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 10)
    box.add_child(_label(title, 26, C_GOLD))
    if sub != "":
        box.add_child(_label(sub, 14, C_DIM))
    return box


# Bottom padding keeps the last button clear of the gesture bar.
func _finish(box: VBoxContainer) -> void:
    var pad := Control.new()
    pad.custom_minimum_size = Vector2(0.0, _insets().y + 12.0)
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(pad)


func _label(text: String, font_size: int, col: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", col)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l


func _button(text: String, cb: Callable, min_h: float = 64.0) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0.0, min_h)
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(cb)
    return b


func _card(c: Dictionary) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0.0, 112.0)
    b.focus_mode = Control.FOCUS_NONE
    var v := VBoxContainer.new()
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(v)
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(_label(str(c.tag), 11, C_CYAN))
    v.add_child(_label(str(c.title), 18, C_GOLD))
    v.add_child(_label(str(c.text), 12, C_TEXT))
    b.pressed.connect(func(): upgrade_chosen.emit(c))
    return b


# ---------------------------------------------------------------- screens

func show_menu() -> void:
    var box: VBoxContainer = _panel("HEX DISTRICT", "A Harry Potter fan-game survival roguelite", false)
    var d: Dictionary = save.data
    box.add_child(_label("Runs %d   Wins %d   Best chapter %d/5   Most defeated %d" % [int(d.runs), int(d.wins), int(d.best_chapter), int(d.best_kills)], 12, C_DIM))
    var cp: Dictionary = d.get("checkpoint", {})
    if not cp.is_empty():
        var idx: int = clampi(int(cp.get("chapter", 0)), 0, Chapters.LIST.size() - 1)
        box.add_child(_button("CONTINUE - %s" % str(Chapters.LIST[idx].name), func(): start_requested.emit(true)))
    box.add_child(_button("NEW RUN", func(): start_requested.emit(false)))
    box.add_child(_button("SETTINGS", func(): show_settings(show_menu)))
    box.add_child(_label("Move with one thumb in the lower screen. Every spell casts itself.", 12, C_TEXT))
    box.add_child(_label("Unofficial, non-commercial fan project. Not endorsed by the rights holders.", 10, C_DIM))
    _finish(box)


func show_levelup(choices: Array, level: int) -> void:
    var box: VBoxContainer = _panel("LEVEL %d" % level, "Choose one upgrade", true)
    for c in choices:
        box.add_child(_card(c))
    _finish(box)


func show_pause() -> void:
    var box: VBoxContainer = _panel("PAUSED", "", true)
    box.add_child(_button("RESUME", func(): resume_requested.emit()))
    box.add_child(_button("SETTINGS", func(): show_settings(show_pause)))
    box.add_child(_button("QUIT TO MENU", func(): menu_requested.emit()))
    _finish(box)


func show_chapter_clear(index: int) -> void:
    var next: Dictionary = Chapters.LIST[mini(index + 1, Chapters.LIST.size() - 1)]
    var box: VBoxContainer = _panel("CHAPTER CLEARED", "A fragment of the Hex District Seal is recovered.", true)
    box.add_child(_label("Next: %s" % str(next.name), 18, C_TEXT))
    box.add_child(_label(str(next.subtitle), 13, C_DIM))
    box.add_child(_label("Progress saved. Harry recovers 40% health.", 12, C_DIM))
    box.add_child(_button("CONTINUE", func(): continue_requested.emit()))
    _finish(box)


func show_summary(victory: bool) -> void:
    var title: String = "SEAL RESTORED" if victory else "HARRY HAS FALLEN"
    var sub: String = "The Hex District is quiet again." if victory else "The disturbance spreads. Try another build."
    var box: VBoxContainer = _panel(title, sub, true)
    var secs: int = int(world.run_time)
    box.add_child(_label("Chapter %d/5 - %s" % [int(world.chapter_index) + 1, str(world.chapter.name)], 16, C_TEXT))
    box.add_child(_label("Time %d:%02d   Level %d   Defeated %d" % [int(secs / 60.0), secs % 60, int(world.player.level), int(world.kills)], 14, C_TEXT))
    box.add_child(_button("RESTART", func(): start_requested.emit(false)))
    box.add_child(_button("MENU", func(): menu_requested.emit()))
    _finish(box)


func show_settings(back: Callable) -> void:
    var box: VBoxContainer = _panel("SETTINGS", "One-thumb controls and comfort", false)
    _option(box, back, "Hand side", "right_handed", [true, false], ["RIGHT", "LEFT"])
    _option(box, back, "Stick size", "stick_size", [44.0, 56.0, 70.0], ["SMALL", "MEDIUM", "LARGE"])
    _option(box, back, "Stick opacity", "stick_opacity", [0.3, 0.5, 0.8], ["30%", "50%", "80%"])
    _option(box, back, "Sensitivity", "sensitivity", [0.8, 1.0, 1.3], ["LOW", "NORMAL", "HIGH"])
    _option(box, back, "Screen shake", "shake", [true, false], ["ON", "OFF"])
    _option(box, back, "Vibration", "vibration", [true, false], ["ON", "OFF"])
    _option(box, back, "Damage flash", "flash", [true, false], ["ON", "OFF"])
    _option(box, back, "High-contrast telegraphs", "high_contrast", [false, true], ["OFF", "ON"])
    _option(box, back, "Sound", "sound", [true, false], ["ON", "OFF"])
    box.add_child(_button("BACK", back, 56.0))
    _finish(box)


# One button per option; tapping cycles through the values and saves immediately.
func _option(box: VBoxContainer, back: Callable, label: String, key: String, values: Array, names: Array) -> void:
    var i: int = maxi(0, values.find(save.data[key]))
    var cb: Callable = func() -> void:
        save.data[key] = values[(i + 1) % values.size()]
        save.save_data()
        settings_changed.emit()
        show_settings(back)
    box.add_child(_button("%s: %s" % [label, str(names[i])], cb, 44.0))
