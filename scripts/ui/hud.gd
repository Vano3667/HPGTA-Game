extends Control
## HUD strip, banners and every menu panel, in English or Russian (see core/i18n.gd).
## Panels keep their buttons large and low on the screen so the game stays playable with one thumb.

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


## A title with a subtitle, or (with an empty subtitle) a smaller wrapped tip.
func show_banner(text: String, sub: String) -> void:
    banner = text
    banner_sub = sub
    banner_t = 3.0 if sub != "" else 4.0


func _text(pos: Vector2, text: String, font_size: int, col: Color) -> void:
    draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, col)


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
    var ch: Dictionary = world.chapter
    var duel: bool = ch.get("duel", false)
    draw_rect(Rect2(x0, 0.0, STRIP, vs.y), Color("111619"))
    draw_line(Vector2(x0, 0.0), Vector2(x0, vs.y), Color("4d5148"), 2.0)

    var y: float = top + STRIP + 18.0
    _text(Vector2(x0 + 5.0, y), I18n.t("ui_lv") % int(p.level), 12, C_GOLD)
    y += 10.0
    var bar_h: float = 130.0
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

    var clock: String = I18n.t("ui_boss")
    if not duel and not world.director.boss_spawned:
        var remain: float = maxf(0.0, Chapters.SURVIVE_TIME - float(world.time))
        clock = "%d:%02d" % [int(remain / 60.0), int(remain) % 60]
    _text(Vector2(x0 + 5.0, y), clock, 12, C_TEXT)
    y += 16.0
    _text(Vector2(x0 + 5.0, y), "x%d" % int(world.kills), 10, C_DIM)
    y += 14.0
    _text(Vector2(x0 + 5.0, y), I18n.t("ui_g") % int(world.run_gold), 10, C_GOLD)
    y += 20.0
    for id in p.weapons.keys():
        _text(Vector2(x0 + 4.0, y), "%s %d" % [_abbr("sp_" + str(id)), int(p.weapons[id])], 10, C_CYAN)
        y += 13.0
    for id in p.passives.keys():
        _text(Vector2(x0 + 4.0, y), "%s %d" % [_abbr("pa_" + str(id)), int(p.passives[id])], 10, C_GOLD)
        y += 13.0
    for id in p.fusions.keys():
        _text(Vector2(x0 + 4.0, y), "+" + _abbr("fu_" + str(id)), 10, C_TEXT)
        y += 13.0
    # One gold pip per active synergy.
    var pips: int = world.syn.size()
    for i in pips:
        draw_rect(Rect2(x0 + 5.0 + (i % 6) * 6.5, y + 2.0 + int(i / 6.0) * 7.0, 4.5, 4.5), C_GOLD)

    var name: String = I18n.t("ch_" + str(ch.id))
    var head: String = "%d/%d %s" % [int(world.chapter_index) + 1, Chapters.LIST.size(), name]
    if str(world.mode) == "endless":
        head = "%s  %s" % [I18n.t("ui_loop") % (int(world.tier) + 1), name]
    _text(Vector2(8.0, top + 16.0), head, 12, C_GOLD)
    if world.boss != null:
        var bw: float = x0 - 16.0
        var k: float = clampf(float(world.boss.hp) / float(world.boss.max_hp), 0.0, 1.0)
        draw_rect(Rect2(8.0, top + 24.0, bw, 8.0), Color("2a1416"))
        draw_rect(Rect2(8.0, top + 24.0, bw * k, 8.0), Color("e0503c"))
        draw_rect(Rect2(8.0, top + 24.0, bw, 8.0), Color("c9a24c"), false, 1.0)
        _text(Vector2(8.0, top + 46.0), I18n.t("bo_" + str(world.boss.type)), 12, C_TEXT)

    if banner_t > 0.0 and overlay == null:
        var alpha: float = clampf(banner_t, 0.0, 1.0)
        if banner_sub == "":
            draw_multiline_string(_font, Vector2(14.0, vs.y * 0.3), banner, HORIZONTAL_ALIGNMENT_CENTER, x0 - 28.0, 15, -1, Color(C_TEXT, alpha))
        else:
            draw_string(_font, Vector2(0.0, vs.y * 0.3), banner, HORIZONTAL_ALIGNMENT_CENTER, x0, 24, Color(C_GOLD, alpha))
            draw_string(_font, Vector2(0.0, vs.y * 0.3 + 22.0), banner_sub, HORIZONTAL_ALIGNMENT_CENTER, x0, 13, Color(C_TEXT, alpha))


# ---------------------------------------------------------------- panel building

func close_panel() -> void:
    if overlay != null:
        overlay.queue_free()
        overlay = null


func _pad(height: float) -> Control:
    var pad := Control.new()
    pad.custom_minimum_size = Vector2(0.0, height)
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return pad


func _panel(title: String, sub: String, low: bool) -> VBoxContainer:
    close_panel()
    var bg := ColorRect.new()
    bg.color = Color(0.02, 0.03, 0.04, 0.86)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay = bg
    var box := VBoxContainer.new()
    bg.add_child(box)
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
    box.alignment = BoxContainer.ALIGNMENT_END if low else BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 8)
    box.add_child(_pad(_insets().x))
    box.add_child(_label(title, 26, C_GOLD))
    if sub != "":
        box.add_child(_label(sub, 14, C_DIM))
    return box


# Bottom padding keeps the last button clear of the gesture bar.
func _finish(box: VBoxContainer) -> void:
    box.add_child(_pad(_insets().y + 12.0))


# A scrolling list that takes the free space of a panel.
func _list(box: VBoxContainer) -> VBoxContainer:
    box.alignment = BoxContainer.ALIGNMENT_BEGIN
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    box.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 4)
    scroll.add_child(list)
    return list


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
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    b.clip_text = true
    b.pressed.connect(cb)
    return b


func _pair(a: Control, b: Control) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(a)
    row.add_child(b)
    return row


# A button made of wrapped text lines: [[text, font size, colour], ...].
func _row(lines: Array, cb: Callable, min_h: float) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0.0, min_h)
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    var v := VBoxContainer.new()
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(v)
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 1)
    for item in lines:
        var line: Array = item
        var col: Color = line[2]
        v.add_child(_label(str(line[0]), int(line[1]), col))
    b.pressed.connect(cb)
    return b


func _card(c: Dictionary) -> Button:
    return _row([[c.tag, 11, C_CYAN], [c.title, 18, C_GOLD], [c.text, 11, C_TEXT]], func(): upgrade_chosen.emit(c), 138.0)


# ---------------------------------------------------------------- main screens

func show_menu() -> void:
    var box: VBoxContainer = _panel("HEX DISTRICT", I18n.t("ui_sub"), false)
    var d: Dictionary = save.data
    box.add_child(_label(I18n.t("ui_stats") % [int(d.runs), int(d.wins), int(d.best_chapter), Chapters.LIST.size(), int(d.best_kills)], 12, C_DIM))
    box.add_child(_label(I18n.t("ui_gold") % int(d.gold), 15, C_GOLD))
    var cp: Dictionary = d.get("checkpoint", {})
    if not cp.is_empty():
        var idx: int = clampi(int(cp.get("chapter", 0)), 0, Chapters.LIST.size() - 1)
        box.add_child(_button(I18n.t("ui_continue") % I18n.t("ch_" + str(Chapters.LIST[idx].id)), func(): start_requested.emit("resume"), 52.0))
    box.add_child(_button(I18n.t("ui_new"), func(): start_requested.emit("story"), 52.0))
    box.add_child(_button(I18n.t("ui_endless") % int(d.best_endless), func(): start_requested.emit("endless"), 52.0))
    box.add_child(_pair(_button(I18n.t("ui_hero") % I18n.t("he_" + str(d.hero)), show_heroes, 48.0), _button(I18n.t("ui_shop"), show_shop, 48.0)))
    box.add_child(_pair(_button(I18n.t("ui_combos"), func(): show_combos(show_menu), 48.0), _button(I18n.t("ui_bestiary"), show_bestiary, 48.0)))
    box.add_child(_pair(_button(I18n.t("ui_help"), show_help, 48.0), _button(I18n.t("ui_settings"), func(): show_settings(show_menu), 48.0)))
    box.add_child(_label(I18n.t("ui_hint"), 12, C_TEXT))
    box.add_child(_label(I18n.t("ui_legal"), 10, C_DIM))
    _finish(box)


func show_levelup(choices: Array, level: int) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_level") % level, I18n.t("ui_choose"), true)
    for c in choices:
        box.add_child(_card(c))
    _finish(box)


func show_pause() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_paused"), "", true)
    box.add_child(_button(I18n.t("ui_resume"), func(): resume_requested.emit()))
    box.add_child(_button(I18n.t("ui_combos"), func(): show_combos(show_pause)))
    box.add_child(_button(I18n.t("ui_settings"), func(): show_settings(show_pause)))
    box.add_child(_button(I18n.t("ui_quit"), func(): menu_requested.emit()))
    _finish(box)


func show_chapter_clear(index: int) -> void:
    var next: Dictionary = Chapters.LIST[mini(index + 1, Chapters.LIST.size() - 1)]
    var box: VBoxContainer = _panel(I18n.t("ui_cleared"), I18n.t("ui_cleared_sub"), true)
    if next.get("duel", false):
        box.add_child(_label(I18n.t("ui_next_boss") % I18n.t("bo_" + str(next.boss)), 18, C_TEXT))
        box.add_child(_label(I18n.t("ch_" + str(next.id)), 13, C_DIM))
    else:
        box.add_child(_label(I18n.t("ui_next") % I18n.t("ch_" + str(next.id)), 18, C_TEXT))
        box.add_child(_label(I18n.t("cs_" + str(next.id)), 13, C_DIM))
    box.add_child(_label(I18n.t("ui_sum3") % int(world.run_gold), 13, C_GOLD))
    box.add_child(_label(I18n.t("ui_saved"), 12, C_DIM))
    box.add_child(_button(I18n.t("ui_go"), func(): continue_requested.emit()))
    _finish(box)


func show_summary(victory: bool) -> void:
    var title: String = I18n.t("ui_win") if victory else I18n.t("ui_lose")
    var sub: String = I18n.t("ui_win_sub") if victory else I18n.t("ui_lose_sub")
    var box: VBoxContainer = _panel(title, sub, true)
    var secs: int = int(world.run_time)
    var mode: String = str(world.mode)
    var stage: int = int(world.chapter_index) + 1
    if mode == "endless":
        stage = int(world.tier) + 1
    box.add_child(_label(I18n.t("ui_sum1") % [stage, I18n.t("ch_" + str(world.chapter.id))], 16, C_TEXT))
    box.add_child(_label(I18n.t("ui_sum2") % [int(secs / 60.0), secs % 60, int(world.player.level), int(world.kills)], 14, C_TEXT))
    box.add_child(_label(I18n.t("ui_sum3") % int(world.run_gold), 14, C_GOLD))
    box.add_child(_button(I18n.t("ui_restart"), func(): start_requested.emit(mode)))
    box.add_child(_button(I18n.t("ui_shop"), show_shop))
    box.add_child(_button(I18n.t("ui_menu"), func(): menu_requested.emit()))
    _finish(box)


# ---------------------------------------------------------------- meta: heroes and upgrades

func show_heroes() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_hero") % I18n.t("he_" + str(save.data.hero)), I18n.t("ui_hero_sub"), false)
    box.add_child(_label(I18n.t("ui_gold") % int(save.data.gold), 15, C_GOLD))
    var owned: Array = save.data.get("heroes", ["harry"])
    for id in Spells.HEROES:
        box.add_child(_hero_row(str(id), owned))
    box.add_child(_button(I18n.t("ui_back"), show_menu, 56.0))
    _finish(box)


func _hero_row(id: String, owned: Array) -> Button:
    var state: String = I18n.t("ui_select")
    var col: Color = C_CYAN
    if str(save.data.hero) == id:
        state = I18n.t("ui_selected")
        col = C_GOLD
    elif not (id in owned):
        state = I18n.t("ui_buy") % int(Spells.HEROES[id].cost)
    var cb: Callable = func() -> void:
        if Spells.hero_pick(save.data, id):
            save.save_data()
        show_heroes()
    return _row([[I18n.t("he_" + id), 18, C_GOLD], [I18n.t("hd_" + id), 11, C_TEXT], [state, 12, col]], cb, 104.0)


func show_shop() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_shop"), I18n.t("ui_shop_sub"), false)
    box.add_child(_label(I18n.t("ui_gold") % int(save.data.gold), 15, C_GOLD))
    var list: VBoxContainer = _list(box)
    for id in Spells.META:
        list.add_child(_meta_row(str(id)))
    box.add_child(_button(I18n.t("ui_back"), show_menu, 56.0))
    _finish(box)


func _meta_row(id: String) -> Button:
    var meta: Dictionary = save.data.get("meta", {})
    var lv: int = int(meta.get(id, 0))
    var cap: int = int(Spells.META[id][0])
    var state: String = I18n.t("ui_max")
    var col: Color = C_DIM
    if lv < cap:
        var cost: int = Spells.meta_cost(id, lv)
        state = I18n.t("ui_buy") % cost
        if int(save.data.gold) >= cost:
            col = C_CYAN
    var cb: Callable = func() -> void:
        if Spells.meta_buy(save.data, id):
            save.save_data()
        show_shop()
    return _row([["%s  %d/%d" % [I18n.t("me_" + id), lv, cap], 15, C_GOLD], [I18n.t("md_" + id), 11, C_TEXT], [state, 12, col]], cb, 66.0)


# ---------------------------------------------------------------- reference screens

func _entry(list: VBoxContainer, title: String, state: String, on: bool, req: String, desc: String) -> void:
    var head: String = title
    if state != "":
        head += "  -  " + state
    list.add_child(_label(head, 15, C_GOLD if on else C_TEXT))
    if req != "":
        list.add_child(_label(req, 11, C_CYAN))
    list.add_child(_label(desc, 12, C_DIM))
    list.add_child(_pad(6.0))


## Combos codex: fusions, evolutions and synergies, and which of them the current build has.
func show_combos(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_combos"), I18n.t("ui_combo_sub"), false)
    var build: Dictionary = {"weapons": {}, "passives": {}, "evolved": {}, "fusions": {}}
    var live: bool = world != null and world.in_run and not world.player.is_empty()
    if live:
        build = world.player
    var owned_f: Dictionary = build.get("fusions", {})
    var owned_e: Dictionary = build.get("evolved", {})
    var list: VBoxContainer = _list(box)
    list.add_child(_label(I18n.t("ui_sec_fusion"), 13, C_CYAN))
    list.add_child(_pad(4.0))
    for key in Spells.FUSIONS:
        var fid: String = str(key)
        var need: Array = Spells.FUSIONS[fid].need
        var got: bool = owned_f.has(fid)
        var state: String = ""
        if got:
            state = I18n.t("ui_owned")
        elif live and Spells.fusion_ready(build, fid):
            state = I18n.t("ui_ready")
        _entry(list, I18n.t("fu_" + fid), state, got, I18n.t("ui_fuse_req") % [Spells.names(need, " + "), Spells.fusion_min(fid)], I18n.t("fd_" + fid))
    list.add_child(_label(I18n.t("ui_sec_evo"), 13, C_CYAN))
    list.add_child(_pad(4.0))
    for key in Spells.EVOLUTIONS:
        var eid: String = str(key)
        var ev: Dictionary = Spells.EVOLUTIONS[eid]
        var has_e: bool = owned_e.has(eid)
        _entry(list, I18n.t("ev_" + eid), I18n.t("ui_owned") if has_e else "", has_e, I18n.t("ui_evo_req") % [I18n.t("sp_" + str(ev.weapon)), I18n.t("pa_" + str(ev.passive))], I18n.t("ed_" + eid))
    list.add_child(_label(I18n.t("ui_sec_syn"), 13, C_CYAN))
    list.add_child(_pad(4.0))
    for key in Spells.SYNERGIES:
        var sid: String = str(key)
        var on: bool = Spells.is_active(build, sid)
        _entry(list, I18n.t("sy_" + sid), I18n.t("ui_syn_on") if on else I18n.t("ui_syn_off"), on, Spells.requirement(sid), I18n.t("sx_" + sid))
    box.add_child(_button(I18n.t("ui_back"), back, 56.0))
    _finish(box)


func show_bestiary() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_bestiary"), I18n.t("ui_best_sub"), false)
    var seen: Dictionary = save.data.get("seen", {})
    var list: VBoxContainer = _list(box)
    for key in Enemies.TYPES:
        _beast(list, str(key), Enemies.TYPES[key], "en_", seen)
    for key in Enemies.BOSSES:
        _beast(list, str(key), Enemies.BOSSES[key], "bo_", seen)
    box.add_child(_button(I18n.t("ui_back"), show_menu, 56.0))
    _finish(box)


func _beast(list: VBoxContainer, id: String, d: Dictionary, prefix: String, seen: Dictionary) -> void:
    if not seen.has(id):
        list.add_child(_label(I18n.t("ui_unknown"), 12, C_DIM))
        return
    list.add_child(_label(I18n.t(prefix + id), 15, C_GOLD))
    list.add_child(_label(I18n.t("ui_bstat") % [int(d.hp), int(d.dmg), I18n.t("ai_" + str(d.get("ai", "boss")))], 11, C_TEXT))
    list.add_child(_pad(4.0))


func show_help() -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_help"), "", false)
    var list: VBoxContainer = _list(box)
    for i in range(1, 6):
        list.add_child(_label(I18n.t("help_%d" % i), 14, C_TEXT))
        list.add_child(_pad(8.0))
    box.add_child(_button(I18n.t("ui_back"), show_menu, 56.0))
    _finish(box)


func show_settings(back: Callable) -> void:
    var box: VBoxContainer = _panel(I18n.t("ui_settings"), I18n.t("ui_set_sub"), false)
    var list: VBoxContainer = _list(box)
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
    _finish(box)


# One button per option; tapping cycles through the values and saves immediately.
func _option(list: VBoxContainer, back: Callable, label: String, key: String, values: Array, names: Array) -> void:
    var i: int = maxi(0, values.find(save.data[key]))
    var cb: Callable = func() -> void:
        save.data[key] = values[(i + 1) % values.size()]
        save.save_data()
        settings_changed.emit()
        show_settings(back)
    list.add_child(_button(label + ": " + str(names[i]), cb, 44.0))
