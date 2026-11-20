extends Node2D
## One run of Hex District: gameplay state, the simulation step and world rendering.
## The UI listens to signals; step() can also be driven headlessly (tests/smoke_test.gd).

signal level_up(choices)
signal chapter_cleared(index)
signal run_ended(victory)
signal boss_arrived(boss_name)
signal player_hurt(amount)
signal sound(id)

const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const Art = preload("res://scripts/game/art.gd")
const Arsenal = preload("res://scripts/game/arsenal.gd")
const Director = preload("res://scripts/game/director.gd")

# Hard caps keep busy fights cheap on phones.
const MAX_ENEMIES := 170
const MAX_SHOTS := 200
const MAX_BOLTS := 160
const MAX_GEMS := 240
const MAX_FX := 120
const CELL := 56.0
const HUD_STRIP := 48.0

var settings := {}
var rng := RandomNumberGenerator.new()
var in_run := false
var active := false
var invulnerable := false
var move_input := Vector2.ZERO
var view_size := Vector2(480.0, 854.0)

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
var obstacles: Array = []
var decor: Array = []
var grid := {}
var boss = null
var shake := 0.0
var flash := 0.0
var arsenal
var director

var _ogrid := {}
var _next_id := 1
var _dead := false
var _cleared := false
var _ground: ImageTexture = null
var _font: Font = null


func _init() -> void:
    rng.randomize()
    arsenal = Arsenal.new(self)
    director = Director.new(self)


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    _font = ThemeDB.fallback_font


func _process(delta: float) -> void:
    view_size = get_viewport_rect().size
    if active:
        step(delta)
    _update_camera()
    queue_redraw()


# ---------------------------------------------------------------- run control

func start_run(p_settings: Dictionary, checkpoint_data: Dictionary = {}) -> void:
    settings = p_settings
    kills = 0
    run_time = 0.0
    player = Spells.new_player()
    var index: int = 0
    if not checkpoint_data.is_empty():
        index = int(checkpoint_data.get("chapter", 0))
        kills = int(checkpoint_data.get("kills", 0))
        run_time = float(checkpoint_data.get("run_time", 0.0))
        var saved: Dictionary = checkpoint_data.get("player", {})
        var copy: Dictionary = saved.duplicate(true)
        for k in copy.keys():
            player[k] = copy[k]
        player.pending = 0
    in_run = true
    load_chapter(index)


## Snapshot taken when a chapter is cleared; start_run() can resume from it.
func checkpoint(next_index: int) -> Dictionary:
    return {"chapter": next_index, "kills": kills, "run_time": run_time, "player": player.duplicate(true)}


func load_chapter(index: int) -> void:
    chapter_index = clampi(index, 0, Chapters.LIST.size() - 1)
    chapter = Chapters.LIST[chapter_index]
    time = 0.0
    enemies = []
    pending = []
    shots = []
    bolts = []
    gems = []
    zones = []
    hazards = []
    fx = []
    grid = {}
    boss = null
    _dead = false
    _cleared = false
    player.pos = Chapters.ARENA * 0.5
    player.iframe = 1.5
    player.slow = 1.0
    if chapter_index > 0:
        player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.4)
    _build_layout()
    _index_obstacles()
    _build_ground()
    arsenal.reset()
    director.reset()
    active = true


func apply_upgrade(c: Dictionary) -> void:
    Spells.apply(player, c)
    player.pending = maxi(0, int(player.pending) - 1)
    if player.pending > 0:
        level_up.emit(Spells.choices(player, rng))
    else:
        active = true


func finish_chapter() -> void:
    _cleared = true


func step(delta: float) -> void:
    if not active:
        return
    delta = minf(delta, 0.05)
    time += delta
    run_time += delta
    shake = maxf(0.0, shake - delta * 3.0)
    flash = maxf(0.0, flash - delta * 3.0)
    if not pending.is_empty():
        enemies.append_array(pending)
        pending = []
    _update_player(delta)
    _rebuild_grid()
    director.step(delta)
    arsenal.step(delta)
    _update_enemies(delta)
    _update_shots(delta)
    _update_bolts(delta)
    _update_zones(delta)
    _update_gems(delta)
    _update_fx(delta)
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
        active = false
        if chapter_index >= Chapters.LIST.size() - 1:
            in_run = false
            run_ended.emit(true)
        else:
            chapter_cleared.emit(chapter_index)
    elif player.pending > 0:
        active = false
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
    pending.append(Enemies.make(type, pos, _next_id, hp_mult, elite))
    _next_id += 1


func spawn_boss(key: String) -> void:
    var a: Vector2 = Chapters.ARENA
    var pp: Vector2 = player.pos
    var pos: Vector2 = pp + Vector2(0.0, -260.0)
    if pos.y < 60.0:
        pos.y = pp.y + 260.0
    pos.x = clampf(pos.x, 60.0, a.x - 60.0)
    boss = Enemies.make_boss(key, pos, _next_id)
    _next_id += 1
    pending.append(boss)
    add_fx({"kind": "ring", "pos": pos, "r0": 10.0, "r1": 120.0, "col": Color("f0d278"), "life": 0.8, "width": 3.0})
    boss_arrived.emit(boss.name)


func hurt(e: Dictionary, amount: float, knock: Vector2 = Vector2.ZERO) -> void:
    if e.hp <= 0.0:
        return
    var dmg: float = amount * Spells.damage_mult(player)
    if e.weak > 0.0:
        dmg *= 1.3
    e.hp -= dmg
    e.flash = 0.1
    if e.boss:
        e.kb += knock * 0.04
    else:
        e.kb += knock
    if e.hp <= 0.0:
        _kill(e)


func _kill(e: Dictionary) -> void:
    kills += 1
    add_fx({"kind": "ring", "pos": e.pos, "r0": e.r * 0.5, "r1": e.r * 2.2, "col": e.col2, "life": 0.25})
    if e.boss:
        boss = null
        director.on_boss_dead()
        sound.emit("boss_down")
        for i in 12:
            _drop_gem(e.pos + Vector2.from_angle(TAU * i / 12.0) * 30.0, 10)
    else:
        _drop_gem(e.pos, int(e.xp))


func _drop_gem(pos: Vector2, xp: int) -> void:
    if gems.size() >= MAX_GEMS:
        gems[rng.randi() % gems.size()].xp += xp
        return
    gems.append({"pos": pos, "xp": xp})


func damage_player(amount: float) -> void:
    if invulnerable or not active or _dead or player.iframe > 0.0:
        return
    var dmg: float = amount * Spells.armor_mult(player)
    player.hp -= dmg
    player.iframe = 0.6
    shake = 1.0
    flash = 1.0
    player_hurt.emit(dmg)
    sound.emit("hurt")
    if player.hp <= 0.0:
        player.hp = 0.0
        _dead = true


func fire_shot(s: Dictionary) -> void:
    if shots.size() >= MAX_SHOTS:
        return
    s["hit"] = {}
    for k in ["pierce", "stun", "disarm", "turn", "chain"]:
        if not s.has(k):
            s[k] = 0
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


func _gain_xp(amount: int) -> void:
    player.xp += amount
    while player.xp >= player.xp_next:
        player.xp -= player.xp_next
        player.level += 1
        player.xp_next = 6 + player.level * 5
        player.pending += 1
    sound.emit("gem")


# ---------------------------------------------------------------- simulation

func _update_player(delta: float) -> void:
    var slow: float = player.slow
    player.slow = 1.0
    var mv: Vector2 = move_input
    if mv.length() > 1.0:
        mv = mv.normalized()
    var a: Vector2 = Chapters.ARENA
    var pos: Vector2 = player.pos + mv * Spells.move_speed(player) * slow * delta
    pos.x = clampf(pos.x, 12.0, a.x - 12.0)
    pos.y = clampf(pos.y, 12.0, a.y - 12.0)
    player.pos = push_out(pos, player.r)
    if mv.length() > 0.1:
        player.facing = mv.normalized()
    player.iframe = maxf(0.0, player.iframe - delta)


func _update_enemies(delta: float) -> void:
    var pp: Vector2 = player.pos
    var a: Vector2 = Chapters.ARENA
    var alive: Array = []
    for e in enemies:
        if e.hp <= 0.0:
            continue
        e.t += delta
        e.flash = maxf(0.0, e.flash - delta)
        e.weak = maxf(0.0, e.weak - delta)
        e.disarm = maxf(0.0, e.disarm - delta)
        e.slow = maxf(0.0, e.slow - delta)
        if e.stun > 0.0:
            e.stun -= delta
        elif e.boss:
            director.boss_step(e, delta)
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
        pos = push_out(pos, e.r)
        pos.x = clampf(pos.x, 8.0, a.x - 8.0)
        pos.y = clampf(pos.y, 8.0, a.y - 8.0)
        e.pos = pos
        if e.stun <= 0.0 and pos.distance_to(pp) < e.r + player.r:
            damage_player(e.dmg)
        alive.append(e)
    enemies = alive


func _ai(e: Dictionary, delta: float, pp: Vector2) -> void:
    var to: Vector2 = pp - e.pos
    var dist: float = to.length()
    var dir: Vector2 = to / maxf(dist, 0.001)
    var spd: float = e.speed * (0.5 if e.slow > 0.0 else 1.0)
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
                if dist > 150.0:
                    e.pos += dir * spd * delta
                elif dist < 95.0:
                    e.pos -= dir * spd * 0.6 * delta
                e.cd -= delta
                if e.cd <= 0.0 and e.disarm <= 0.0 and dist < 270.0:
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
                if e.cd <= 0.0 and dist < 170.0:
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
    hurt(e, s.dmg, dir * 40.0)
    if s.stun > 0.0:
        e.stun = maxf(e.stun, s.stun * (0.35 if e.boss else 1.0))
    if s.disarm > 0.0:
        e.disarm = s.disarm
        e.weak = maxf(e.weak, s.disarm)
    if s.chain > 0:
        var n: int = 0
        for o in enemies_in(e.pos, 90.0):
            if o.id == e.id:
                continue
            hurt(o, s.dmg * 0.6)
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
        if z.tick_t <= 0.0:
            z.tick_t = 0.5
            for e in enemies_in(z.pos, z.r):
                if z.slow:
                    e.slow = 0.7
                hurt(e, z.dmg)
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
            _gain_xp(int(g.xp))
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


func _update_camera() -> void:
    if player.is_empty():
        return
    var half := Vector2((view_size.x - HUD_STRIP) * 0.5, view_size.y * 0.5)
    var a: Vector2 = Chapters.ARENA
    var c: Vector2 = player.pos
    c.x = clampf(c.x, half.x - 40.0, a.x - half.x + 40.0)
    c.y = clampf(c.y, half.y - 40.0, a.y - half.y + 40.0)
    var off := Vector2.ZERO
    if shake > 0.0 and bool(settings.get("shake", true)):
        off = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake * 5.0
    position = (half - c + off).round()


# ---------------------------------------------------------------- arena building

func _rect(rect: Rect2, col: Color) -> void:
    decor.append({"kind": "rect", "rect": rect, "col": col})


func _frame(rect: Rect2, col: Color) -> void:
    decor.append({"kind": "frame", "rect": rect, "col": col})


func _ring(pos: Vector2, r: float, col: Color) -> void:
    decor.append({"kind": "ring", "pos": pos, "r": r, "col": col})


func _dot(pos: Vector2, r: float, col: Color) -> void:
    decor.append({"kind": "dot", "pos": pos, "r": r, "col": col})


func _label(pos: Vector2, text: String, col: Color) -> void:
    decor.append({"kind": "label", "pos": pos, "text": text, "col": col})


# Each chapter gets its own seeded layout. The centre is always left open for the player.
func _build_layout() -> void:
    obstacles = []
    decor = []
    var a: Vector2 = Chapters.ARENA
    var c: Vector2 = a * 0.5
    var lr := RandomNumberGenerator.new()
    lr.seed = 4200 + chapter_index
    var edge: Color = chapter.edge
    var accent: Color = chapter.accent
    match chapter.layout:
        "street":
            _rect(Rect2(c.x - 210.0, 0.0, 420.0, a.y), Color("353a38"))
            _rect(Rect2(c.x - 214.0, 0.0, 6.0, a.y), Color("8a7960"))
            _rect(Rect2(c.x + 208.0, 0.0, 6.0, a.y), Color("8a7960"))
            var y: float = 50.0
            var n: int = 0
            while y < a.y - 280.0:
                var h: float = lr.randf_range(170.0, 250.0)
                var wl: float = lr.randf_range(200.0, 300.0)
                var wr: float = lr.randf_range(200.0, 300.0)
                obstacles.append(Rect2(40.0, y, wl, h))
                obstacles.append(Rect2(a.x - 40.0 - wr, y, wr, h))
                if n == 2:
                    _label(Vector2(52.0, y + h + 18.0), "OLLIVANDERS", Color("f4d787"))
                if n == 3:
                    _label(Vector2(a.x - 28.0 - wr, y + h + 18.0), "GRINGOTTS", Color("efd17a"))
                _dot(Vector2(c.x - 196.0, y + h * 0.5), 5.0, accent)
                _dot(Vector2(c.x + 196.0, y + h), 5.0, accent)
                y += h + lr.randf_range(70.0, 110.0)
                n += 1
            for i in 16:
                var crate := Vector2(lr.randf_range(c.x - 190.0, c.x + 150.0), lr.randf_range(80.0, a.y - 120.0))
                if crate.distance_to(c) < 130.0:
                    continue
                obstacles.append(Rect2(crate, Vector2(lr.randf_range(28.0, 44.0), lr.randf_range(28.0, 44.0))))
        "courtyard":
            _rect(Rect2(c - Vector2(390.0, 390.0), Vector2(780.0, 780.0)), Color("56594f"))
            _frame(Rect2(c - Vector2(390.0, 390.0), Vector2(780.0, 780.0)), edge)
            _ring(c, 150.0, edge)
            _ring(c, 60.0, accent)
            for sx in [-1.0, 1.0]:
                for sy in [-1.0, 1.0]:
                    obstacles.append(Rect2(c.x + sx * 440.0 - 70.0, c.y + sy * 440.0 - 70.0, 140.0, 140.0))
                obstacles.append(Rect2(c.x + sx * 400.0 - 210.0, c.y - 660.0, 420.0, 40.0))
                obstacles.append(Rect2(c.x + sx * 400.0 - 210.0, c.y + 620.0, 420.0, 40.0))
            for i in 8:
                var statue: Vector2 = c + Vector2.from_angle(TAU * i / 8.0 + 0.4) * 270.0
                obstacles.append(Rect2(statue - Vector2(13.0, 13.0), Vector2(26.0, 26.0)))
            _label(Vector2(c.x - 40.0, c.y - 676.0), "GREAT HALL", Color("f0d278"))
        "forest":
            _rect(Rect2(c.x - 70.0, 0.0, 140.0, a.y), Color(0.16, 0.13, 0.1, 0.55))
            for i in 46:
                var trunk := Vector2(lr.randf_range(60.0, a.x - 60.0), lr.randf_range(60.0, a.y - 60.0))
                if trunk.distance_to(c) < 150.0:
                    continue
                var s: float = lr.randf_range(18.0, 30.0)
                obstacles.append(Rect2(trunk - Vector2(s, s) * 0.5, Vector2(s, s)))
                _ring(trunk, s * 1.5, Color("23301f"))
            for i in 24:
                _dot(Vector2(lr.randf_range(40.0, a.x - 40.0), lr.randf_range(40.0, a.y - 40.0)), 2.5, accent)
        "pitch":
            _frame(Rect2(130.0, 170.0, a.x - 260.0, a.y - 340.0), edge)
            _ring(c, 120.0, edge)
            _rect(Rect2(130.0, c.y - 2.0, a.x - 260.0, 4.0), edge)
            for sy in [-1.0, 1.0]:
                for dx in [-120.0, 0.0, 120.0]:
                    var hoop := Vector2(c.x + dx, c.y + sy * 640.0)
                    obstacles.append(Rect2(hoop - Vector2(9.0, 9.0), Vector2(18.0, 18.0)))
                    _ring(hoop, 24.0, accent)
            obstacles.append(Rect2(20.0, 320.0, 70.0, a.y - 640.0))
            obstacles.append(Rect2(a.x - 90.0, 320.0, 70.0, a.y - 640.0))
        "ministry":
            _ring(c, 330.0, edge)
            _ring(c, 260.0, Color("5b5d57"))
            _ring(c, 170.0, edge)
            for sx in [-1.0, 1.0]:
                obstacles.append(Rect2(c.x + sx * 520.0 - 50.0, c.y - 250.0, 100.0, 500.0))
                for k in 6:
                    _dot(Vector2(c.x + sx * 520.0, c.y - 210.0 + k * 84.0), 6.0, Color("7bb9cd"))
                for sy in [-1.0, 1.0]:
                    obstacles.append(Rect2(c.x + sx * 300.0 - 110.0, c.y + sy * 560.0 - 28.0, 220.0, 56.0))
            for i in 3:
                var fire_x: float = c.x - 400.0 + i * 400.0
                _rect(Rect2(fire_x - 42.0, 14.0, 84.0, 60.0), Color("121619"))
                _dot(Vector2(fire_x, 50.0), 12.0, accent)
                _rect(Rect2(fire_x - 42.0, a.y - 74.0, 84.0, 60.0), Color("121619"))
                _dot(Vector2(fire_x, a.y - 44.0), 12.0, accent)
            _label(Vector2(c.x - 78.0, c.y - 344.0), "HALL OF PROPHECY", Color("bfc8d4"))


# A 64 px noisy tile gives the crunchy low-res ground; it is repeated across the arena.
func _build_ground() -> void:
    var img: Image = Image.create(64, 64, false, Image.FORMAT_RGB8)
    var g: Color = chapter.ground
    var g2: Color = chapter.ground2
    var g3: Color = chapter.ground3
    var seams: bool = chapter.layout != "forest" and chapter.layout != "pitch"
    var tr := RandomNumberGenerator.new()
    tr.seed = 77 + chapter_index
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
            img.set_pixel(x, y, col)
    _ground = ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- rendering

func _draw() -> void:
    if chapter.is_empty() or player.is_empty():
        return
    var a: Vector2 = Chapters.ARENA
    var hc: bool = bool(settings.get("high_contrast", false))
    var lw: float = 3.0 if hc else 1.5
    var view := Rect2(-position - Vector2(40.0, 40.0), view_size + Vector2(80.0, 80.0))
    var edge: Color = chapter.edge
    var prop: Color = chapter.prop
    var prop2: Color = chapter.prop2
    draw_rect(Rect2(Vector2(-600.0, -600.0), a + Vector2(1200.0, 1200.0)), Color("0b0e10"))
    if _ground != null:
        draw_texture_rect(_ground, Rect2(Vector2.ZERO, a), true)
    for d in decor:
        match d.kind:
            "rect":
                draw_rect(d.rect, d.col)
            "frame":
                draw_rect(d.rect, d.col, false, 3.0)
            "ring":
                draw_arc(d.pos, d.r, 0.0, TAU, 32, d.col, 3.0)
    for o in obstacles:
        var rect: Rect2 = o
        if not view.intersects(rect):
            continue
        draw_rect(rect, prop)
        if rect.size.x > 24.0 and rect.size.y > 24.0:
            draw_rect(rect.grow(-7.0), prop2)
        draw_rect(rect, edge, false, 2.0)
    for d in decor:
        match d.kind:
            "dot":
                draw_circle(d.pos, d.r * 2.0, Color(d.col, 0.22))
                draw_circle(d.pos, d.r, d.col)
            "label":
                draw_string(_font, d.pos, d.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, d.col)
    draw_rect(Rect2(Vector2.ZERO, a), edge, false, 4.0)

    # Friendly ground effects.
    for z in zones:
        var zc: Color = Color(0.5, 0.86, 1.0) if z.kind == "ice" else Color(1.0, 0.55, 0.15)
        draw_circle(z.pos, z.r, Color(zc, 0.16))
        draw_arc(z.pos, z.r, 0.0, TAU, 24, Color(zc, 0.7), 1.5)

    # Hazards: amber blinking outline while warning, solid red when live. Shape + motion, not colour alone.
    var pulse: float = 0.5 + 0.5 * sin(run_time * 14.0)
    for h in hazards:
        var warn: bool = h.warn > 0.0
        var fill: Color = Color(1.0, 0.72, 0.1, 0.08 + 0.14 * pulse) if warn else Color(1.0, 0.25, 0.12, 0.5)
        var line: Color = Color(1.0, 0.8, 0.2, 0.95) if warn else Color(1.0, 0.95, 0.8, 1.0)
        if h.slow and not warn:
            fill = Color(0.6, 0.72, 0.78, 0.32)
            line = Color(0.8, 0.9, 0.95, 0.8)
        if h.has("path"):
            draw_rect(h.path, Color(line, 0.35), false, 1.0)
        for r in h.rects:
            draw_rect(r, fill)
            draw_rect(r, line, false, lw)
        if h.r > 0.0:
            draw_circle(h.pos, h.r, fill)
            draw_arc(h.pos, h.r, 0.0, TAU, 28, line, lw)
            if warn:
                draw_arc(h.pos, maxf(2.0, h.r * (1.0 - h.warn / h.warn_max)), 0.0, TAU, 24, line, lw)

    for g in gems:
        if not view.has_point(g.pos):
            continue
        if g.xp >= 5:
            draw_rect(Rect2(g.pos - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color("f0d278"))
        else:
            draw_rect(Rect2(g.pos - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color("67dcf4"))
        draw_rect(Rect2(g.pos - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 1.0, 1.0))

    for e in enemies:
        if e.hp > 0.0 and view.has_point(e.pos):
            Art.enemy(self, e, run_time, hc)

    arsenal.draw(self)

    # Friendly shots are round with cyan/gold trails; hostile bolts are outlined squares.
    for s in shots:
        var sp: Vector2 = s.pos
        var tail: Vector2 = sp - s.vel.normalized() * 9.0
        match s.kind:
            "wand":
                draw_line(tail, sp, Color("67dcf4"), 2.0)
                draw_circle(sp, 2.0, Color(1.0, 1.0, 1.0))
            "stupefy":
                draw_line(tail, sp, Color("ff6a7a"), 3.0)
                draw_circle(sp, 3.5, Color("ffd0d6"))
            "expelliarmus":
                draw_line(tail, sp, Color("f0d278"), 2.0)
                draw_circle(sp, 3.0, Color("fff3c0"))
            _:
                draw_circle(sp, 2.0, Color("fff3c0"))
    for b in bolts:
        var bp: Vector2 = b.pos
        var bc: Color = b.col
        var box := Rect2(bp - Vector2(3.0, 3.0), Vector2(6.0, 6.0))
        draw_line(bp - b.vel.normalized() * 7.0, bp, Color(bc, 0.5), 2.0)
        draw_rect(box, bc)
        draw_rect(box, Color(1.0, 1.0, 1.0, 0.9), false, 2.0 if hc else 1.0)

    var ghost: bool = player.iframe > 0.0 and fmod(run_time * 16.0, 2.0) < 1.0
    Art.harry(self, player.pos, player.facing, player.aim, run_time, ghost)

    for f in fx:
        var k: float = clampf(f.t / f.life, 0.0, 1.0)
        var fc: Color = f.col
        fc.a = 1.0 - k
        match f.kind:
            "ring":
                draw_arc(f.pos, lerpf(f.r0, f.r1, k), 0.0, TAU, 20, fc, float(f.get("width", 2.0)))
            "line":
                draw_line(f.a, f.b, fc, 2.0)
            "text":
                draw_string(_font, f.pos + Vector2(0.0, -18.0 * k), str(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, fc)

    if flash > 0.0 and bool(settings.get("flash", true)):
        draw_rect(view, Color(1.0, 0.2, 0.15, flash * 0.22))
