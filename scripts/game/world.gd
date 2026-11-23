extends Node2D
## One run of Hex District: gameplay state and the simulation step.
## Rendering lives in render.gd, the endless arena generator in arena.gd. The UI listens to
## signals; step() can also be driven headlessly (tests/smoke_test.gd).

signal level_up(choices)
signal chapter_cleared(index)
signal stage_changed(tier)
signal run_ended(victory)
signal boss_arrived(boss_key)
signal player_hurt(amount)
signal sound(id)

const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")
const Sprites = preload("res://scripts/core/sprites.gd")
const Arsenal = preload("res://scripts/game/arsenal.gd")
const Director = preload("res://scripts/game/director.gd")
const Arena = preload("res://scripts/game/arena.gd")
const Render = preload("res://scripts/game/render.gd")

# Hard caps keep busy fights cheap on phones.
const MAX_ENEMIES := 170
const MAX_SHOTS := 200
const MAX_BOLTS := 160
const MAX_GEMS := 240
const MAX_FX := 120
const MAX_PARTS := 300
const CELL := 56.0
const HUD_STRIP := 48.0
## World zoom: everything in the arena is drawn 1.5x larger than in v1.
const ZOOM := 1.5
## An enemy left this far behind the hero re-enters from just outside the screen.
const LEASH := 640.0
## Statuses that stop an enemy from acting.
const HOLD := ["stun", "petrify", "levitate", "root"]
const AMB_RATE := {"rain": 55.0, "storm": 60.0, "snow": 16.0, "leaves": 5.0, "wind": 9.0, "fireflies": 6.0, "drip": 7.0, "dust": 7.0, "embers": 9.0, "sparks": 9.0}

var settings := {}
var rng := RandomNumberGenerator.new()
var in_run := false
var active := false
var invulnerable := false
var move_input := Vector2.ZERO
var view_size := Vector2(480.0, 854.0)
var view_world := Vector2(288.0, 569.0)
var cam := Vector2.ZERO

## "story": 15 stages with checkpoints. "endless": chapters loop forever and keep getting harder.
var mode := "story"
## Difficulty step: the stage index in story mode, the number of stages survived in endless mode.
var tier := 0
## Size of one floor tile in world units (the painted floor image repeats, mirrored, without end).
## The world itself has no borders.
var arena := Vector2(1400.0, 1900.0)
var run_gold := 0
var gold_bank := 0
var seen := {}
var floor_tex: Texture2D = null

var chapter_index := 0
var chapter := {}
var time := 0.0
var run_time := 0.0
var kills := 0
var player := {}
var enemies: Array = []
var pending: Array = []
var shots: Array = []
var bolts: Array = []
var gems: Array = []
var zones: Array = []
var hazards: Array = []
var fx: Array = []
var parts: Array = []
# The four lists below are rebuilt by arena.gd from the chunks around the hero.
var obstacles: Array = []
var props: Array = []
var decor: Array = []
var lights: Array = []
## Generated chunks (Vector2i -> lists), the painted obstacles of this map, the seed of this stage,
## where the hero starts (kept clear of obstacles) and the chunk the hero was in last.
var chunks := {}
var palette: Array = []
var map_seed := 0
var spawn_pos := Vector2.ZERO
var chunk_at := Vector2i(1 << 20, 0)
var grid := {}
var boss = null
var shake := 0.0
var flash := 0.0
var storm_flash := 0.0
var syn: Array = []
var syn_cd := {}
var arsenal
var director
var ground_tex: ImageTexture = null
var light_tex: Texture2D = null
var vig_tex: Texture2D = null
var font: Font = null

var _ogrid := {}
var _next_id := 1
var _dead := false
var _cleared := false
var _amb := 0.0
var _storm_t := 5.0
var _step_t := 0.0
var _main: Node2D = null
var _glow: Node2D = null
var _top: Node2D = null


func _init() -> void:
    rng.randomize()
    arsenal = Arsenal.new(self)
    director = Director.new(self)


func _ready() -> void:
    # The world node itself only draws the crisp tiled ground; everything else is on smooth layers.
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    scale = Vector2(ZOOM, ZOOM)
    font = ThemeDB.fallback_font
    light_tex = Render.radial(Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), 0.0)
    vig_tex = Render.radial(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.62), 0.45)
    _main = _layer(_on_main_draw, null)
    var mat := CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _glow = _layer(_on_glow_draw, mat)
    _top = _layer(_on_top_draw, null)


func _layer(cb: Callable, mat: Material) -> Node2D:
    var n := Node2D.new()
    n.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    n.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
    n.material = mat
    add_child(n)
    n.draw.connect(cb)
    return n


func _process(delta: float) -> void:
    view_size = get_viewport_rect().size
    view_world = Vector2(view_size.x - HUD_STRIP, view_size.y) / ZOOM
    if active:
        step(delta)
    _update_camera()
    queue_redraw()
    _main.queue_redraw()
    _glow.queue_redraw()
    _top.queue_redraw()


# The backdrop and, for code-drawn stages, the tiled ground. Both follow the camera: they cover
# the screen plus a margin and start on a multiple of the tile size, so the pattern stays put.
func _draw() -> void:
    if chapter.is_empty():
        return
    var first := Vector2(floorf((cam.x - view_world.x * 0.5) / 64.0) - 2.0, floorf((cam.y - view_world.y * 0.5) / 64.0) - 2.0)
    var cells := Vector2(ceilf(view_world.x / 64.0) + 5.0, ceilf(view_world.y / 64.0) + 5.0)
    var rect := Rect2(first * 64.0, cells * 64.0)
    draw_rect(rect, Color("07090b"))
    if floor_tex == null and ground_tex != null:
        draw_texture_rect(ground_tex, rect, true)


func _on_main_draw() -> void:
    if chapter.is_empty() or player.is_empty():
        return
    Render.draw(self, _main)


func _on_glow_draw() -> void:
    if chapter.is_empty() or player.is_empty():
        return
    Render.glow(self, _glow)


func _on_top_draw() -> void:
    if chapter.is_empty() or player.is_empty():
        return
    Render.top(self, _top)


# ---------------------------------------------------------------- run control

## p_settings is the save dictionary: it also carries the chosen hero and the meta upgrades.
func start_run(p_settings: Dictionary, checkpoint_data: Dictionary = {}, p_mode: String = "story") -> void:
    settings = p_settings
    mode = p_mode
    tier = 0
    kills = 0
    run_time = 0.0
    run_gold = 0
    gold_bank = 0
    seen = {}
    Sprites.enabled = bool(settings.get("sprites", true))
    player = Spells.new_player(str(settings.get("hero", "harry")), settings.get("meta", {}))
    var index: int = 0
    if mode == "story" and not checkpoint_data.is_empty():
        index = int(checkpoint_data.get("chapter", 0))
        kills = int(checkpoint_data.get("kills", 0))
        run_time = float(checkpoint_data.get("run_time", 0.0))
        var saved: Dictionary = checkpoint_data.get("player", {})
        var copy: Dictionary = saved.duplicate(true)
        for k in copy.keys():
            player[k] = copy[k]
        player.pending = 0
        # Drop anything that no longer exists in this version of the game.
        for id in player.weapons.keys():
            if not Spells.WEAPONS.has(id):
                player.weapons.erase(id)
        for id in player.fusions.keys():
            if not Spells.FUSIONS.has(id):
                player.fusions.erase(id)
        if not Spells.HEROES.has(player.hero):
            player.hero = "harry"
        if player.weapons.is_empty():
            player.weapons["wand"] = 1
    in_run = true
    load_chapter(index)


## Snapshot taken when a stage is cleared; start_run() can resume from it.
func checkpoint(next_index: int) -> Dictionary:
    return {"chapter": next_index, "kills": kills, "run_time": run_time, "player": player.duplicate(true)}


func load_chapter(index: int) -> void:
    chapter_index = clampi(index, 0, Chapters.LIST.size() - 1)
    chapter = Chapters.LIST[chapter_index]
    if mode != "endless":
        tier = chapter_index
    time = 0.0
    enemies = []
    pending = []
    shots = []
    bolts = []
    gems = []
    zones = []
    hazards = []
    fx = []
    parts = []
    grid = {}
    boss = null
    _dead = false
    _cleared = false
    storm_flash = 0.0
    Sprites.forget("map_")
    floor_tex = Sprites.tex("map_" + str(chapter.get("map", "")))
    if floor_tex != null:
        arena = Vector2(floor_tex.get_size()) * Chapters.MAP_SCALE
    else:
        arena = Chapters.ARENA
    # A new stage is a new stretch of open ground: new seed, hero in the middle of a clear spot.
    map_seed = rng.randi() % 1000000
    spawn_pos = Vector2(Arena.CHUNK, Arena.CHUNK) * 0.5
    player.pos = spawn_pos
    player.iframe = 1.5
    player.slow = 1.0
    if run_time > 0.0:
        player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.4)
    cam = player.pos
    Arena.begin(self)
    ground_tex = Arena.ground(chapter, chapter_index)
    refresh_synergies()
    arsenal.reset()
    director.reset()
    active = true
    queue_redraw()


func refresh_synergies() -> void:
    syn = Spells.active(player)


func apply_upgrade(c: Dictionary) -> void:
    Spells.apply(player, c)
    refresh_synergies()
    player.pending = maxi(0, int(player.pending) - 1)
    if player.pending > 0:
        level_up.emit(Spells.choices(player, rng))
    else:
        active = true


func finish_chapter() -> void:
    _cleared = true


## A chapter without a guardian ends with the way to the boss arena opening.
func portal() -> void:
    var pp: Vector2 = player.pos
    add_fx({"kind": "ring", "pos": pp, "r0": 10.0, "r1": 160.0, "col": Color("f0d278"), "life": 0.8, "width": 3.0})
    add_fx({"kind": "text", "pos": pp + Vector2(-40.0, -30.0), "text": I18n.t("ui_portal"), "col": Color("f0d278"), "life": 2.0})
    burst(pp, Color("f0d278"), 24, 150.0)
    sound.emit("levelup")


func add_gold(n: int) -> void:
    var v: int = int(ceil(n * float(player.get("m_gold", 1.0))))
    run_gold += v
    gold_bank += v


## Galleons collected since the last call; the caller banks them into the save.
func take_gold() -> int:
    var v: int = gold_bank
    gold_bank = 0
    return v


func _next_level(i: int) -> int:
    var n: int = Chapters.LIST.size()
    for k in n:
        i = (i + 1) % n
        if not Chapters.LIST[i].get("duel", false):
            return i
    return 0


func step(delta: float) -> void:
    if not active:
        return
    delta = minf(delta, 0.05)
    time += delta
    run_time += delta
    shake = maxf(0.0, shake - delta * 3.0)
    flash = maxf(0.0, flash - delta * 3.0)
    storm_flash = maxf(0.0, storm_flash - delta * 4.0)
    for k in syn_cd.keys():
        syn_cd[k] -= delta
    if not pending.is_empty():
        enemies.append_array(pending)
        pending = []
    _update_player(delta)
    Arena.update(self)
    _rebuild_grid()
    director.step(delta)
    arsenal.step(delta)
    _update_enemies(delta)
    _update_shots(delta)
    _update_bolts(delta)
    _update_zones(delta)
    _update_gems(delta)
    _update_fx(delta)
    _ambient(delta)
    _update_parts(delta)
    _resolve_events()


# Signals are only emitted at the end of a step so handlers can safely restart or reload.
func _resolve_events() -> void:
    if _dead:
        _dead = false
        active = false
        in_run = false
        run_ended.emit(false)
    elif _cleared:
        _cleared = false
        if mode == "endless":
            tier += 1
            load_chapter(_next_level(chapter_index))
            stage_changed.emit(tier)
            return
        active = false
        if chapter_index >= Chapters.LIST.size() - 1:
            in_run = false
            run_ended.emit(true)
        else:
            chapter_cleared.emit(chapter_index)
    elif player.pending > 0:
        active = false
        sound.emit("levelup")
        level_up.emit(Spells.choices(player, rng))


# ---------------------------------------------------------------- queries

func _cell(pos: Vector2) -> Vector2i:
    return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))


func _rebuild_grid() -> void:
    grid.clear()
    for e in enemies:
        if e.hp <= 0.0:
            continue
        var key: Vector2i = _cell(e.pos)
        if grid.has(key):
            grid[key].append(e)
        else:
            grid[key] = [e]


func enemies_in(pos: Vector2, radius: float) -> Array:
    var out: Array = []
    var reach: float = radius + 32.0
    var x0: int = floori((pos.x - reach) / CELL)
    var x1: int = floori((pos.x + reach) / CELL)
    var y0: int = floori((pos.y - reach) / CELL)
    var y1: int = floori((pos.y + reach) / CELL)
    for cx in range(x0, x1 + 1):
        for cy in range(y0, y1 + 1):
            var cell = grid.get(Vector2i(cx, cy))
            if cell == null:
                continue
            for e in cell:
                if e.hp > 0.0 and pos.distance_to(e.pos) <= radius + e.r:
                    out.append(e)
    return out


func nearest_enemy(pos: Vector2, max_dist: float, ai: String = ""):
    var best = null
    var best_d: float = max_dist * max_dist
    for e in enemies:
        if e.hp <= 0.0:
            continue
        if ai != "" and e.ai != ai:
            continue
        var d: float = pos.distance_squared_to(e.pos)
        if d < best_d:
            best_d = d
            best = e
    return best


func toughest_enemy(pos: Vector2, max_dist: float):
    var best = null
    var best_hp: float = 0.0
    var limit: float = max_dist * max_dist
    for e in enemies:
        if e.hp <= best_hp:
            continue
        if pos.distance_squared_to(e.pos) > limit:
            continue
        best_hp = e.hp
        best = e
    return best


func random_enemy(pos: Vector2, max_dist: float):
    var limit: float = max_dist * max_dist
    if not enemies.is_empty():
        for attempt in 8:
            var e = enemies[rng.randi() % enemies.size()]
            if e.hp > 0.0 and pos.distance_squared_to(e.pos) <= limit:
                return e
    return nearest_enemy(pos, max_dist)


# Spatial index of the solid rectangles; arena.gd calls this whenever the chunks change.
func _index_obstacles() -> void:
    _ogrid = {}
    for o in obstacles:
        var rect: Rect2 = o
        var g: Rect2 = rect.grow(34.0)
        for cx in range(floori(g.position.x / CELL), floori(g.end.x / CELL) + 1):
            for cy in range(floori(g.position.y / CELL), floori(g.end.y / CELL) + 1):
                var key := Vector2i(cx, cy)
                if _ogrid.has(key):
                    _ogrid[key].append(rect)
                else:
                    _ogrid[key] = [rect]


## Slide a circle out of the solid props (buildings, trunks, shelves).
func push_out(pos: Vector2, r: float) -> Vector2:
    var cell = _ogrid.get(_cell(pos))
    if cell == null:
        return pos
    for o in cell:
        var rect: Rect2 = o
        var near := Vector2(clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y))
        var d: Vector2 = pos - near
        var l: float = d.length()
        if l >= r:
            continue
        if l > 0.001:
            pos = near + d / l * r
            continue
        var left: float = pos.x - rect.position.x
        var right: float = rect.end.x - pos.x
        var top: float = pos.y - rect.position.y
        var bottom: float = rect.end.y - pos.y
        var m: float = minf(minf(left, right), minf(top, bottom))
        if m == left:
            pos.x = rect.position.x - r
        elif m == right:
            pos.x = rect.end.x + r
        elif m == top:
            pos.y = rect.position.y - r
        else:
            pos.y = rect.end.y + r
    return pos


# ---------------------------------------------------------------- mutators

func spawn_enemy(type: String, pos: Vector2, elite: bool, hp_mult: float = 1.0) -> void:
    if enemies.size() + pending.size() >= MAX_ENEMIES:
        return
    var e: Dictionary = Enemies.make(type, pos, _next_id, hp_mult, elite)
    if mode == "endless":
        e.dmg *= 1.0 + 0.04 * tier
    pending.append(e)
    _next_id += 1


func spawn_boss(key: String) -> void:
    var pp: Vector2 = player.pos
    boss = Enemies.make_boss(key, pp + Vector2(0.0, -200.0), _next_id)
    boss.pos = push_out(boss.pos, boss.r)
    var pos: Vector2 = boss.pos
    if mode == "endless":
        var k: float = 1.0 + 0.8 * floorf(tier / 10.0)
        boss.hp *= k
        boss.max_hp *= k
        boss.dmg *= 1.0 + 0.04 * tier
    _next_id += 1
    pending.append(boss)
    add_fx({"kind": "ring", "pos": pos, "r0": 10.0, "r1": 120.0, "col": Color("f0d278"), "life": 0.8, "width": 3.0})
    burst(pos, Color("f0d278"), 24, 140.0)
    shake = 1.0
    boss_arrived.emit(key)


## Damage an enemy. "el" is the element of the hit; it is what triggers synergies.
func hurt(e: Dictionary, amount: float, knock: Vector2 = Vector2.ZERO, el: String = "") -> void:
    if e.hp <= 0.0:
        return
    var dmg: float = amount * Spells.damage_mult(player)
    var st: Dictionary = e.s
    if st.has("mark"):
        dmg *= 1.25
    var fired: Array = []
    if el != "" and not st.is_empty():
        for sid in syn:
            var rule: Dictionary = Spells.SYNERGIES[sid]
            if st.has(rule.st) and el in rule.el:
                dmg *= float(rule.get("mult", 1.0))
                fired.append(sid)
    e.hp -= dmg
    e.flash = 0.1
    if e.boss:
        e.kb += knock * 0.04
    else:
        e.kb += knock
    for sid in fired:
        _synergy(e, sid, amount)
    if e.hp <= 0.0 and not e.dead:
        _kill(e)


## Damage plus status in one call (the status lands after the hit, so synergies read the old state).
func hit(e: Dictionary, amount: float, knock: Vector2, el: String, st: String, dur: float) -> void:
    hurt(e, amount, knock, el)
    if e.hp > 0.0:
        apply_status(e, st, dur)


func blast(pos: Vector2, r: float, amount: float, kb: float, el: String, st: String, dur: float, bane: bool = false) -> void:
    for e in enemies_in(pos, r):
        var away: Vector2 = e.pos - pos
        var dmg: float = amount
        if bane and e.dark:
            dmg *= 2.0
        hit(e, dmg, away.normalized() * kb, el, st, dur)


func apply_status(e: Dictionary, st: String, dur: float) -> void:
    if st == "" or dur <= 0.0 or e.hp <= 0.0:
        return
    var hold: bool = st in HOLD
    if e.boss:
        # Bosses shrug off crowd control: no fear, lift or pull, and short holds.
        if st == "fear" or st == "levitate" or st == "grouped":
            return
        if hold:
            dur *= 0.3
    e.s[st] = maxf(float(e.s.get(st, 0.0)), dur)
    if hold:
        e.hold = maxf(e.hold, dur)


func _synergy(e: Dictionary, sid: String, amount: float) -> void:
    var rule: Dictionary = Spells.SYNERGIES[sid]
    var pos: Vector2 = e.pos
    if rule.get("eat", false):
        e.s.erase(rule.st)
    if rule.has("boom"):
        for o in enemies_in(pos, rule.r):
            var away: Vector2 = o.pos - pos
            hurt(o, rule.boom, away.normalized() * 70.0)
        add_fx({"kind": "ring", "pos": pos, "r0": 6.0, "r1": rule.r, "col": Color("e8f4ff"), "life": 0.3, "width": 3.0})
        burst(pos, Color("e8f4ff"), 8, 90.0)
    if rule.has("chain"):
        var n: int = 0
        for o in enemies_in(pos, 100.0):
            if o.id == e.id:
                continue
            hurt(o, amount * 0.7)
            add_fx({"kind": "line", "a": pos, "b": o.pos, "col": Color("fff27a"), "life": 0.16})
            n += 1
            if n >= rule.chain:
                break
    if rule.has("apply"):
        apply_status(e, rule.apply, rule.dur)
    if rule.has("spread"):
        for o in enemies_in(pos, rule.r):
            apply_status(o, rule.spread, rule.dur)
    if rule.has("heal") and float(syn_cd.get(sid, 0.0)) <= 0.0:
        syn_cd[sid] = 0.5
        heal(rule.heal)
    var key: String = sid + "_t"
    if float(syn_cd.get(key, 0.0)) <= 0.0:
        syn_cd[key] = 1.6
        add_fx({"kind": "text", "pos": pos + Vector2(-22.0, -14.0), "text": I18n.t("sy_" + sid), "col": Color("ffe9a0"), "life": 0.9})


func _kill(e: Dictionary) -> void:
    e.dead = true
    kills += 1
    seen[e.type] = true
    var xp: int = int(e.xp)
    if e.s.has("fear") and syn.has("stagefright"):
        xp *= 2
    add_fx({"kind": "ring", "pos": e.pos, "r0": e.r * 0.5, "r1": e.r * 2.2, "col": e.col2, "life": 0.25})
    burst(e.pos, e.col2, 6, 80.0)
    if e.boss:
        boss = null
        director.on_boss_dead()
        sound.emit("boss_down")
        shake = 1.4
        burst(e.pos, Color("f0d278"), 40, 180.0)
        add_gold(20 + 4 * tier)
        for i in 12:
            _drop_gem(e.pos + Vector2.from_angle(TAU * i / 12.0) * 30.0, 10)
    else:
        var coins: int = 0
        if e.elite:
            coins = 4
        elif rng.randf() < 0.07:
            coins = 1
        _drop_gem(e.pos, xp, coins)


func _drop_gem(pos: Vector2, xp: int, gold: int = 0) -> void:
    if gems.size() >= MAX_GEMS:
        var g: Dictionary = gems[rng.randi() % gems.size()]
        g.xp += xp
        g.gold += gold
        return
    gems.append({"pos": pos, "xp": xp, "gold": gold})


func heal(amount: float) -> void:
    if player.hp >= player.max_hp:
        return
    player.hp = minf(player.max_hp, player.hp + amount)
    var pp: Vector2 = player.pos
    spawn_part(pp + Vector2(rng.randf_range(-6.0, 6.0), 0.0), Vector2(0.0, -30.0), 0.6, Color("9dffb0"), 2.0, true)


## Remove hostile curses inside a circle (Finite Incantatem).
func dispel(pos: Vector2, r: float) -> void:
    var keep: Array = []
    for b in bolts:
        if pos.distance_to(b.pos) <= r:
            burst(b.pos, Color("e8e8ff"), 2, 40.0)
        else:
            keep.append(b)
    bolts = keep


func damage_player(amount: float) -> void:
    if invulnerable or not active or _dead or player.iframe > 0.0:
        return
    var pp: Vector2 = player.pos
    if rng.randf() < float(player.get("dodge", 0.0)):
        player.iframe = 0.35
        add_fx({"kind": "text", "pos": pp + Vector2(-20.0, -24.0), "text": I18n.t("ui_dodge"), "col": Color("bfe9ff"), "life": 0.7})
        return
    var dmg: float = amount * Spells.armor_mult(player)
    player.hp -= dmg
    player.iframe = 0.6
    shake = 1.0
    flash = 1.0
    burst(pp, Color("ff5a4a"), 8, 90.0)
    player_hurt.emit(dmg)
    sound.emit("hurt")
    if player.hp > 0.0:
        return
    if int(player.get("revives", 0)) > 0:
        # Phoenix Tear: one second chance per run.
        player.revives = int(player.revives) - 1
        player.hp = player.max_hp * 0.5
        player.iframe = 2.5
        blast(pp, 140.0, 40.0, 260.0, "light", "stun", 1.5)
        add_fx({"kind": "ring", "pos": pp, "r0": 10.0, "r1": 140.0, "col": Color("ffd27a"), "life": 0.6, "width": 4.0})
        add_fx({"kind": "text", "pos": pp + Vector2(-36.0, -30.0), "text": I18n.t("ui_revive"), "col": Color("ffd27a"), "life": 1.6})
        sound.emit("levelup")
    else:
        player.hp = 0.0
        _dead = true


func fire_shot(s: Dictionary) -> void:
    if shots.size() >= MAX_SHOTS:
        return
    s["hit"] = {}
    shots.append(s)


func fire_bolt(pos: Vector2, vel: Vector2, dmg: float, col: Color) -> void:
    if bolts.size() >= MAX_BOLTS:
        return
    bolts.append({"pos": pos, "vel": vel, "dmg": dmg, "col": col, "life": 6.0})


func add_zone(z: Dictionary) -> void:
    z["tick_t"] = 0.0
    zones.append(z)


func add_hazard(h: Dictionary) -> void:
    hazards.append(h)


func add_fx(f: Dictionary) -> void:
    if fx.size() >= MAX_FX:
        return
    f["t"] = 0.0
    fx.append(f)


## One particle. kind 0 = square mote, 1 = streak along its velocity. glow = drawn on the additive layer.
func spawn_part(pos: Vector2, vel: Vector2, life: float, col: Color, size: float, glow: bool, kind: int = 0, grav: float = 0.0) -> void:
    if parts.size() >= MAX_PARTS:
        return
    parts.append({"p": pos, "v": vel, "t": life, "m": life, "c": col, "s": size, "g": glow, "k": kind, "a": grav})


func burst(pos: Vector2, col: Color, n: int, speed: float = 70.0) -> void:
    for i in n:
        var d: Vector2 = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(speed * 0.3, speed)
        spawn_part(pos, d, rng.randf_range(0.25, 0.6), col, rng.randf_range(1.0, 2.2), true)


func _gain_xp(amount: int) -> void:
    player.xp += amount * float(player.get("m_xp", 1.0))
    while player.xp >= player.xp_next:
        player.xp -= player.xp_next
        player.level += 1
        player.xp_next = 5 + player.level * 4
        player.pending += 1
    sound.emit("gem")


# ---------------------------------------------------------------- simulation

# The hero walks anywhere: only obstacles stop him, there is no edge of the map.
func _update_player(delta: float) -> void:
    var slow: float = player.slow
    player.slow = 1.0
    var mv: Vector2 = move_input
    if mv.length() > 1.0:
        mv = mv.normalized()
    var pos: Vector2 = player.pos + mv * Spells.move_speed(player) * slow * delta
    player.pos = push_out(pos, player.r)
    if mv.length() > 0.1:
        player.facing = mv.normalized()
        _step_t -= delta
        if _step_t <= 0.0:
            # Footstep dust / splashes.
            _step_t = 0.14
            var g2: Color = chapter.ground2
            spawn_part(pos + Vector2(0.0, 4.0), -mv * 14.0, 0.4, Color(g2, 0.7), 2.0, false)
    player.iframe = maxf(0.0, player.iframe - delta)


func _update_enemies(delta: float) -> void:
    var pp: Vector2 = player.pos
    var alive: Array = []
    for e in enemies:
        if e.hp <= 0.0:
            continue
        e.t += delta
        e.flash = maxf(0.0, e.flash - delta)
        var st: Dictionary = e.s
        if not st.is_empty():
            for k in st.keys():
                st[k] -= delta
                if st[k] <= 0.0:
                    st.erase(k)
            if st.has("burn"):
                e.burn_t -= delta
                if e.burn_t <= 0.0:
                    e.burn_t = 0.5
                    spawn_part(e.pos, Vector2(rng.randf_range(-8.0, 8.0), -28.0), 0.5, Color("ff8a2a"), 1.6, true)
                    hurt(e, 3.0 + tier * 0.7)
                    if e.hp <= 0.0:
                        continue
        e.hold = maxf(0.0, e.hold - delta)
        var feared: bool = st.has("fear")
        if e.hold > 0.0:
            pass
        elif e.boss:
            director.boss_step(e, delta)
        elif feared:
            var flee: Vector2 = e.pos - pp
            e.pos += flee.normalized() * e.speed * 0.9 * delta
        else:
            _ai(e, delta, pp)
        var pos: Vector2 = e.pos + e.kb * delta
        e.kb = e.kb * maxf(0.0, 1.0 - 8.0 * delta)
        if not e.boss:
            # Cheap crowd separation: only against a few neighbours in the same grid cell.
            var cell = grid.get(_cell(pos))
            if cell != null:
                var n: int = 0
                for o in cell:
                    if o.id == e.id:
                        continue
                    var d: Vector2 = pos - o.pos
                    var l: float = d.length()
                    var min_d: float = e.r + o.r
                    if l < min_d and l > 0.01:
                        pos += d / l * (min_d - l) * 0.5
                    n += 1
                    if n >= 6:
                        break
        var want: Vector2 = pos
        pos = push_out(pos, e.r)
        if e.hold <= 0.0 and not pos.is_equal_approx(want):
            # Blocked by an obstacle: step sideways along it. Every enemy keeps to its own side,
            # so a crowd flows around a building on both sides.
            var to_hero: Vector2 = (pp - pos).normalized()
            var turn: float = 1.0 if int(e.id) % 2 == 0 else -1.0
            pos = push_out(pos + Vector2(-to_hero.y, to_hero.x) * turn * e.speed * 0.8 * delta, e.r)
        if pos.distance_squared_to(pp) > LEASH * LEASH:
            # Left far behind in the open world: come back in from just outside the screen.
            pos = push_out(director.edge_pos(), e.r)
            e.kb = Vector2.ZERO
        e.pos = pos
        if e.hold <= 0.0 and not feared and pos.distance_to(pp) < e.r + player.r:
            damage_player(e.dmg)
        alive.append(e)
    enemies = alive


func _ai(e: Dictionary, delta: float, pp: Vector2) -> void:
    var to: Vector2 = pp - e.pos
    var dist: float = to.length()
    var dir: Vector2 = to / maxf(dist, 0.001)
    var spd: float = e.speed * (0.5 if e.s.has("chill") else 1.0)
    e.face = dir
    match e.ai:
        "chase":
            e.pos += dir * spd * delta
        "weave":
            var side: Vector2 = Vector2(-dir.y, dir.x) * sin(e.t * 5.0 + e.id) * 0.8
            e.pos += (dir + side).normalized() * spd * delta
        "ranged":
            if e.state == "aim":
                # Short visible wind-up before the curse leaves the wand.
                e.state_t -= delta
                if e.state_t <= 0.0:
                    e.state = ""
                    fire_bolt(e.pos + dir * e.r, dir * 96.0, e.dmg, e.bolt)
            else:
                if dist > 118.0:
                    e.pos += dir * spd * delta
                elif dist < 80.0:
                    e.pos -= dir * spd * 0.6 * delta
                e.cd -= delta
                if e.cd <= 0.0 and not e.s.has("disarm") and dist < 215.0:
                    e.cd = e.shot_cd
                    e.state = "aim"
                    e.state_t = 0.5
        "charge":
            if e.state == "wind":
                e.state_t -= delta
                if e.state_t <= 0.0:
                    e.state = "dash"
                    e.state_t = 0.5
            elif e.state == "dash":
                e.pos += e.dir * spd * 3.6 * delta
                e.state_t -= delta
                if e.state_t <= 0.0:
                    e.state = ""
                    e.cd = 2.4
            else:
                e.pos += dir * spd * delta
                e.cd -= delta
                if e.cd <= 0.0 and dist < 150.0:
                    e.state = "wind"
                    e.state_t = 0.7
                    e.dir = dir


func _update_shots(delta: float) -> void:
    var keep: Array = []
    for s in shots:
        s.life -= delta
        if s.turn > 0.0:
            var tgt = nearest_enemy(s.pos, 260.0)
            if tgt != null:
                var want: Vector2 = tgt.pos - s.pos
                var ang: float = lerp_angle(s.vel.angle(), want.angle(), minf(1.0, s.turn * delta))
                s.vel = Vector2.from_angle(ang) * s.vel.length()
        s.pos += s.vel * delta
        if rng.randf() < 0.35:
            spawn_part(s.pos, s.vel * -0.08, 0.25, s.col, 1.4, true)
        var dead: bool = s.life <= 0.0
        if not dead:
            for e in enemies_in(s.pos, s.r):
                if s.hit.has(e.id):
                    continue
                s.hit[e.id] = true
                _shot_hit(s, e)
                s.pierce -= 1
                if s.pierce < 0:
                    dead = true
                    break
        if not dead:
            keep.append(s)
    shots = keep


func _shot_hit(s: Dictionary, e: Dictionary) -> void:
    var dir: Vector2 = s.vel.normalized()
    var sp: Vector2 = s.pos
    var dmg: float = s.dmg
    if s.elite > 1.0 and (e.boss or e.elite):
        dmg *= s.elite
    if s.boom > 0.0:
        blast(sp, s.boom, dmg, s.kb, s.el, s.st, s.sd)
        add_fx({"kind": "ring", "pos": sp, "r0": 4.0, "r1": s.boom, "col": s.col, "life": 0.3, "width": 3.0})
        burst(sp, s.col, 8, 100.0)
    else:
        hit(e, dmg, dir * s.kb, s.el, s.st, s.sd)
        burst(sp, s.col, 3, 50.0)
    if s.chain > 0:
        var n: int = 0
        for o in enemies_in(e.pos, 90.0):
            if o.id == e.id:
                continue
            hurt(o, dmg * 0.6)
            add_fx({"kind": "line", "a": e.pos, "b": o.pos, "col": Color("bfe9ff"), "life": 0.15})
            n += 1
            if n >= s.chain:
                break


func _update_bolts(delta: float) -> void:
    var pp: Vector2 = player.pos
    var keep: Array = []
    for b in bolts:
        b.pos += b.vel * delta
        b.life -= delta
        if b.life <= 0.0:
            continue
        if arsenal.blocks(b.pos):
            add_fx({"kind": "ring", "pos": b.pos, "r0": 2.0, "r1": 9.0, "col": Color("67dcf4"), "life": 0.2})
            burst(b.pos, Color("67dcf4"), 3, 50.0)
            continue
        if pp.distance_to(b.pos) < player.r + 3.0:
            damage_player(b.dmg)
            continue
        keep.append(b)
    bolts = keep


func _update_zones(delta: float) -> void:
    var keep: Array = []
    for z in zones:
        z.life -= delta
        z.tick_t -= delta
        var zp: Vector2 = z.pos
        var tick: bool = z.tick_t <= 0.0
        if tick:
            z.tick_t = 0.5
        if tick or z.pull > 0.0:
            for e in enemies_in(zp, z.r):
                if z.pull > 0.0 and not e.boss:
                    var to: Vector2 = zp - e.pos
                    e.pos += to.normalized() * minf(to.length(), z.pull * delta)
                if tick:
                    hit(e, z.dmg, Vector2.ZERO, z.el, z.st, z.sd)
        if tick and rng.randf() < 0.8:
            var off: Vector2 = Vector2.from_angle(rng.randf() * TAU) * rng.randf() * z.r
            spawn_part(zp + off, Vector2(0.0, -18.0), 0.6, z.col, 1.6, true)
        if z.life > 0.0:
            keep.append(z)
    zones = keep


func _update_gems(delta: float) -> void:
    var pp: Vector2 = player.pos
    var reach: float = Spells.pickup_radius(player)
    var pull_all: bool = director.boss_dead
    var keep: Array = []
    for g in gems:
        var d: Vector2 = pp - g.pos
        var l: float = d.length()
        if l < player.r + 6.0:
            if g.gold > 0:
                add_gold(int(g.gold))
            if g.xp > 0:
                _gain_xp(int(g.xp))
            spawn_part(pp, Vector2(rng.randf_range(-20.0, 20.0), -40.0), 0.35, Color("f0d278") if g.gold > 0 else Color("67dcf4"), 1.5, true)
            continue
        if l > 1500.0 and not pull_all:
            # Left far behind in the open world: gone.
            continue
        if l < reach or pull_all:
            g.pos += d / l * 300.0 * delta
        keep.append(g)
    gems = keep


func _update_fx(delta: float) -> void:
    var keep: Array = []
    for f in fx:
        f.t += delta
        if f.t < f.life:
            keep.append(f)
    fx = keep


func _update_parts(delta: float) -> void:
    var keep: Array = []
    for q in parts:
        q.t -= delta
        if q.t <= 0.0:
            continue
        var v: Vector2 = q.v
        v.y += q.a * delta
        q.v = v
        q.p += v * delta
        keep.append(q)
    parts = keep


# Weather and floating motes around the camera, different for every chapter.
func _ambient(delta: float) -> void:
    var kind: String = chapter.get("amb", "")
    var rate: float = float(AMB_RATE.get(kind, 0.0))
    if rate <= 0.0:
        return
    var half: Vector2 = view_world * 0.5 + Vector2(24.0, 24.0)
    _amb += delta
    while _amb > 0.0:
        _amb -= 1.0 / rate
        var at: Vector2 = cam + Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
        var drift := Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-10.0, 10.0))
        match kind:
            "rain", "storm":
                spawn_part(Vector2(at.x, cam.y - half.y + rng.randf() * half.y), Vector2(-50.0, 430.0), 0.55, Color(0.6, 0.75, 1.0, 0.45), 1.0, false, 1)
            "snow":
                spawn_part(at, Vector2(drift.x * 2.0, 34.0), 3.0, Color(1.0, 1.0, 1.0, 0.85), 1.6, false)
            "leaves":
                spawn_part(at, Vector2(34.0, 18.0) + drift, 4.0, Color(0.85, 0.55, 0.2, 0.9), 2.0, false)
            "wind":
                spawn_part(at, Vector2(300.0, 12.0), 0.6, Color(1.0, 1.0, 1.0, 0.22), 1.0, false, 1)
            "fireflies":
                spawn_part(at, drift, 3.0, Color(0.75, 1.0, 0.45), 1.4, true)
            "drip":
                spawn_part(at, Vector2(0.0, 220.0), 0.5, Color(0.5, 0.9, 0.75, 0.5), 1.0, false, 1)
            "dust":
                spawn_part(at, drift * 0.8, 3.5, Color(1.0, 0.85, 0.4), 1.0, true)
            "embers":
                spawn_part(at, Vector2(drift.x, -26.0), 2.6, Color(1.0, 0.5, 0.15), 1.4, true)
            "sparks":
                spawn_part(at, Vector2(drift.x, -34.0), 2.2, Color(0.3, 1.0, 0.5), 1.3, true)
    if kind == "storm":
        _storm_t -= delta
        if _storm_t <= 0.0:
            _storm_t = rng.randf_range(4.0, 9.0)
            storm_flash = 1.0
            sound.emit("burst")


# The camera simply follows the hero; there is no edge to stop at.
func _update_camera() -> void:
    if player.is_empty():
        return
    var c: Vector2 = player.pos
    if shake > 0.0 and bool(settings.get("shake", true)):
        c += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake * 3.0
    cam = c
    var screen_half := Vector2((view_size.x - HUD_STRIP) * 0.5, view_size.y * 0.5)
    position = (screen_half - c * ZOOM).round()
