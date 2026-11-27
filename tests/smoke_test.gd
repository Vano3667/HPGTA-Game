extends SceneTree
## Headless smoke test. Checks the data tables and both languages, lets a simple bot play the whole
## story (ten chapters and five boss stages) and three endless stages, walks far across the open
## world, loads every stage with code-drawn graphics, verifies synergies, fusions, the upgrade pool,
## meta upgrades, dodge and revive, then builds the UI scene and opens every panel in EN and RU.
## After that it keeps the real scene alive for a few frames so the drawing code runs as well
## (nothing reaches a screen, but script errors in draw code are caught).
## Usage: godot --headless --path . -s res://tests/smoke_test.gd
## Note: the UI pass writes the normal local save file (user://hex_district.cfg).

const WorldScript = preload("res://scripts/game/world.gd")
const Arena = preload("res://scripts/game/arena.gd")
const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")
const I18n2 = preload("res://scripts/core/i18n2.gd")
const Sprites = preload("res://scripts/core/sprites.gd")
const Style = preload("res://scripts/ui/style.gd")

const DT := 0.05
## Number of sound streams sfx.gd builds: 8 crystal notes, 4 wand notes and 10 single effects.
const SOUNDS := 22

var world
var failures: Array = []
var cleared: Array = []
var ended := false
var victory := false
var levelups := 0
var stages := 0
var _phase := 0
var _main = null
var _hud_draws := 0
var _world_draws := 0


func _process(_delta: float) -> bool:
    if _phase < 0:
        return true
    if _phase == 0:
        _phase = 1
        _check_data()
        world = WorldScript.new()
        root.add_child(world)
        world.level_up.connect(_on_level_up)
        world.chapter_cleared.connect(_on_cleared)
        world.run_ended.connect(_on_ended)
        world.stage_changed.connect(_on_stage)
        _mortal_run()
        _full_run()
        _endless_run()
        _open_world()
        _drawn_stages()
        _synergy_check()
        _fusion_check()
        _meta_check()
        _checkpoint_roundtrip()
        _upgrade_exhaustion()
        world.queue_free()
        _ui_pass("en")
        _ui_pass("ru")
        _draw_begin()
        return false
    _phase += 1
    if _draw_step():
        return false
    print("[smoke] draw pass: %d frames; the HUD drew %d times, the arena %d times" % [_phase - 2, _hud_draws, _world_draws])
    for f in failures:
        print("[smoke] FAIL: %s" % str(f))
    if failures.is_empty():
        print("[smoke] PASS")
    _phase = -1
    quit(0 if failures.is_empty() else 1)
    return true


func _reset() -> void:
    cleared = []
    ended = false
    victory = false
    levelups = 0
    stages = 0


func _on_level_up(choices: Array) -> void:
    levelups += 1
    world.apply_upgrade(choices[levelups % choices.size()])


func _on_cleared(index: int) -> void:
    cleared.append(index)
    world.load_chapter(index + 1)


func _on_ended(v: bool) -> void:
    ended = true
    victory = v


func _on_stage(_tier: int) -> void:
    stages += 1


func _need(key: String) -> void:
    if not I18n.has(key):
        failures.append("missing translation key %s" % key)
        return
    var row: Array = I18n.S[key]
    if row.size() != 2 or str(row[0]) == "" or str(row[1]) == "":
        failures.append("translation %s needs both English and Russian text" % key)


func _check_data() -> void:
    var levels: int = 0
    var duels: int = 0
    var painted: int = 0
    for ch in Chapters.LIST:
        if ch.get("duel", false):
            duels += 1
        else:
            levels += 1
        if Sprites.tex("map_" + str(ch.get("map", ""))) != null:
            painted += 1
        _need("ch_" + str(ch.id))
        _need("cs_" + str(ch.id))
        for row in ch.enemies:
            if not Enemies.TYPES.has(row[0]):
                failures.append("unknown enemy type %s in %s" % [str(row[0]), str(ch.id)])
        if str(ch.boss) != "":
            _need("bo_" + str(ch.boss))
            if not Enemies.BOSSES.has(ch.boss):
                failures.append("unknown boss %s" % str(ch.boss))
        elif ch.get("duel", false):
            failures.append("boss stage %s has no boss" % str(ch.id))
    Sprites.forget("map_")
    if levels != 10 or duels != 5:
        failures.append("expected 10 chapters and 5 boss stages, found %d and %d" % [levels, duels])
    if Spells.WEAPONS.size() != 28:
        failures.append("expected 28 spells, found %d" % Spells.WEAPONS.size())
    if Spells.WEAPON_SLOTS > Spells.WEAPONS.size() or Spells.PASSIVE_SLOTS > Spells.PASSIVES.size():
        failures.append("more slots than there are spells or talismans")
    if Spells.EVOLVE_LEVEL > Spells.MAX_LEVEL:
        failures.append("evolutions need a spell level that cannot be reached")
    for type in Enemies.TYPES:
        _need("en_" + str(type))
        _need("ai_" + str(Enemies.TYPES[type].ai))
    for key in Enemies.BOSSES:
        _need("bo_" + str(key))
    for key in I18n2.S:
        var extra: Array = I18n2.S[key]
        if extra.size() != 2 or str(extra[0]) == "" or str(extra[1]) == "":
            failures.append("translation %s needs both English and Russian text" % str(key))
    var statuses := {}
    for id in Spells.WEAPONS:
        _need("sp_" + str(id))
        _need("sd_" + str(id))
        var def: Dictionary = Spells.WEAPONS[id]
        _need("el_" + str(def.el))
        if def.has("st"):
            statuses[def.st] = true
    var sizes := {}
    for fid in Spells.FUSIONS:
        _need("fu_" + str(fid))
        _need("fd_" + str(fid))
        var need: Array = Spells.FUSIONS[fid].need
        sizes[need.size()] = true
        for id in need:
            if not Spells.WEAPONS.has(id):
                failures.append("fusion %s needs unknown spell %s" % [str(fid), str(id)])
    for n in [2, 3, 4]:
        if not sizes.has(n):
            failures.append("no fusion made of %d spells" % n)
    for id in Spells.PASSIVES:
        _need("pa_" + str(id))
        _need("pd_" + str(id))
    for id in Spells.EVOLUTIONS:
        _need("ev_" + str(id))
        _need("ed_" + str(id))
        var ev: Dictionary = Spells.EVOLUTIONS[id]
        if not Spells.WEAPONS.has(ev.weapon) or not (ev.passive in Spells.PASSIVES):
            failures.append("bad evolution recipe %s" % str(id))
    for id in Spells.HEROES:
        _need("he_" + str(id))
        _need("hd_" + str(id))
        if not Spells.WEAPONS.has(Spells.HEROES[id].spell):
            failures.append("hero %s starts with an unknown spell" % str(id))
    for id in Spells.META:
        _need("me_" + str(id))
        _need("md_" + str(id))
    for sid in Spells.SYNERGIES:
        _need("sy_" + str(sid))
        _need("sx_" + str(sid))
        var rule: Dictionary = Spells.SYNERGIES[sid]
        if not statuses.has(rule.st):
            failures.append("synergy %s needs status %s that no spell applies" % [str(sid), str(rule.st)])
        if not rule.el.is_empty() and Spells.element_sources(rule.el).is_empty():
            failures.append("synergy %s has no spell of its element" % str(sid))
    var art: Array = []
    for name in ["hero_harry", "hero8_harry", "hero8_hermione", "hero8_ron", "boss8_quirrell", "boss8_basilisk", "top_basilisk_move", "boss_dementor", "boss_nagini", "boss_voldemort", "mob_spider", "mob_centaur"]:
        if Sprites.tex(name) != null:
            art.append(name)
    Style.load_fonts()
    print("[smoke] data: %d chapters + %d boss stages, %d spells, %d fusions, %d synergies, %d enemy types, %d + %d translation rows" % [levels, duels, Spells.WEAPONS.size(), Spells.FUSIONS.size(), Spells.SYNERGIES.size(), Enemies.TYPES.size(), I18n.S.size(), I18n2.S.size()])
    print("[smoke] build limits: %d spells to level %d, %d talismans to level %d" % [Spells.WEAPON_SLOTS, Spells.MAX_LEVEL, Spells.PASSIVE_SLOTS, Spells.PASSIVE_MAX])
    print("[smoke] painted art found: %d/%d maps, sheets %s" % [painted, Chapters.LIST.size(), str(art)])
    print("[smoke] fonts: %d of 3 interface font files found" % Style.found)


# A circling bot with normal damage rules: it is allowed to die, the run just has to behave.
func _mortal_run() -> void:
    _reset()
    world.invulnerable = false
    world.start_run({})
    var t: float = 0.0
    while not ended and t < 600.0:
        world.move_input = Vector2.from_angle(t * 0.6)
        world.step(DT)
        t += DT
    print("[smoke] mortal bot: ended=%s victory=%s stage=%d run_time=%ds level=%d kills=%d hp=%d gold=%d floor tile=%s" % [str(ended), str(victory), int(world.chapter_index) + 1, int(world.run_time), int(world.player.level), int(world.kills), int(world.player.hp), int(world.run_gold), str(world.arena)])
    if int(world.kills) <= 0:
        failures.append("mortal run: automatic attacks defeated nothing")
    if levelups <= 0:
        failures.append("mortal run: no level-up happened")


# Invulnerable bot: must clear all fifteen stages and reach the victory screen.
func _full_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({})
    var t: float = 0.0
    var boss_t: float = 0.0
    var forced: int = 0
    while not ended and t < 6000.0:
        world.move_input = Vector2.from_angle(t * 0.6)
        world.step(DT)
        t += DT
        if world.boss != null:
            boss_t += DT
            if boss_t > 120.0:
                forced += 1
                print("[smoke] WARNING: boss %s still alive after 120 s (hp %d/%d) - balance needs tuning; forcing the kill" % [str(world.boss.type), int(world.boss.hp), int(world.boss.max_hp)])
                world.hurt(world.boss, 1.0e9)
                boss_t = 0.0
        elif boss_t > 0.0:
            print("[smoke] stage %d (%s) boss down after %d s, player level %d, kills %d" % [int(world.chapter_index) + 1, str(world.chapter.id), int(boss_t), int(world.player.level), int(world.kills)])
            boss_t = 0.0
    world.invulnerable = false
    print("[smoke] full run: ended=%s victory=%s stages_cleared=%d sim_time=%ds level=%d gold=%d forced_boss_kills=%d" % [str(ended), str(victory), cleared.size(), int(t), int(world.player.level), int(world.run_gold), forced])
    print("[smoke] final build: spells=%s talismans=%s fusions=%s synergies=%s" % [str(world.player.weapons), str(world.player.passives), str(world.player.fusions.keys()), str(world.syn)])
    if not ended or not victory:
        failures.append("full run did not reach victory")
    if cleared.size() != Chapters.LIST.size() - 1:
        failures.append("expected %d stage-clear events before the finale, got %d" % [Chapters.LIST.size() - 1, cleared.size()])
    if int(world.run_gold) <= 0:
        failures.append("a full run earned no galleons")
    if world.seen.is_empty():
        failures.append("a full run recorded no bestiary entries")


# Endless mode: stages change by themselves, boss stages are skipped and nothing ends the run.
func _endless_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({}, {}, "endless")
    var t: float = 0.0
    var boss_t: float = 0.0
    while stages < 3 and not ended and t < 900.0:
        world.move_input = Vector2.from_angle(t * 0.6)
        world.step(DT)
        t += DT
        if world.boss != null:
            boss_t += DT
            if boss_t > 60.0:
                world.hurt(world.boss, 1.0e9)
                boss_t = 0.0
        else:
            boss_t = 0.0
    print("[smoke] endless: stages=%d tier=%d stage=%s sim_time=%ds" % [stages, int(world.tier), str(world.chapter.id), int(t)])
    if stages < 3 or int(world.tier) != stages:
        failures.append("endless mode did not advance through three stages")
    if world.chapter.get("duel", false):
        failures.append("endless mode entered a boss stage")
    if ended or not cleared.is_empty():
        failures.append("endless mode ended or raised a story stage-clear")
    world.invulnerable = false
    world.active = false
    world.in_run = false


# The world has no borders: the hero walks one way for almost a minute and must keep going,
# obstacles must keep appearing around him, and the crowd must keep up.
func _open_world() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({})
    var start: Vector2 = world.player.pos
    for o in world.obstacles:
        var rect: Rect2 = o
        if rect.grow(float(world.player.r)).has_point(start):
            failures.append("the hero starts inside an obstacle")
    var first: Dictionary = Arena._chunk(world, 3, -2)
    var again: Dictionary = Arena._chunk(world, 3, -2)
    if str(first.obstacles) != str(again.obstacles):
        failures.append("a chunk is not the same when it is built twice")
    var dir: Vector2 = Vector2(1.0, 0.4).normalized()
    var most: int = 0
    var seen_obstacles: int = 0
    for i in 1100:
        world.move_input = dir
        world.step(DT)
        most = maxi(most, world.chunks.size())
        seen_obstacles = maxi(seen_obstacles, world.obstacles.size())
    var pp: Vector2 = world.player.pos
    var gone: Vector2 = pp - start
    var far: float = 0.0
    for e in world.enemies:
        if e.hp > 0.0:
            far = maxf(far, pp.distance_to(e.pos))
    print("[smoke] open world: walked %d right and %d down in 55 s; at most %d chunks kept; %d obstacles and %d props around the hero now (palette of %d painted obstacles); %d enemies, the farthest %d away" % [int(gone.x), int(gone.y), most, world.obstacles.size(), world.props.size(), world.palette.size(), world.enemies.size(), int(far)])
    if gone.x < 1500.0:
        failures.append("the hero got only %d units to the right in 55 s: something still fences the world in" % int(gone.x))
    if most > 49:
        failures.append("too many chunks are kept (%d)" % most)
    if seen_obstacles <= 0:
        failures.append("the open world generated no obstacles")
    if world.enemies.is_empty():
        failures.append("no enemies followed the hero across the open world")
    if far > float(world.LEASH) + 40.0:
        failures.append("an enemy was left %d units behind" % int(far))
    world.invulnerable = false
    world.active = false
    world.in_run = false


# Every stage with "Graphics: simple": no painted floor, so the code-drawn generator runs.
func _drawn_stages() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({"sprites": false})
    var counts: Array = []
    for i in Chapters.LIST.size():
        world.load_chapter(i)
        if world.floor_tex != null:
            failures.append("stage %d kept its painted floor with graphics set to simple" % (i + 1))
        for k in 60:
            world.move_input = Vector2(0.4, 1.0).normalized()
            world.step(DT)
        counts.append(world.obstacles.size())
        if world.obstacles.is_empty():
            failures.append("code-drawn stage %d (%s) has no obstacles" % [i + 1, str(world.chapter.layout)])
    print("[smoke] code-drawn stages: obstacles around the hero per stage %s" % str(counts))
    Sprites.enabled = true
    world.invulnerable = false
    world.active = false
    world.in_run = false


# The synergy engine: a status on the enemy plus a hit of the right element must change the outcome.
func _synergy_check() -> void:
    world.invulnerable = true
    world.start_run({})
    world.player.weapons = {"aguamenti": 1, "baubillious": 1, "incendio": 1, "glacius": 1}
    world.refresh_synergies()
    for sid in ["conductor", "steam", "deepfreeze"]:
        if not world.syn.has(sid):
            failures.append("synergy %s should be active for the test build" % sid)
    var e: Dictionary = Enemies.make("dummy", world.player.pos + Vector2(60.0, 0.0), 999001, 50.0, false)
    world.enemies.append(e)
    var hp0: float = e.hp
    world.hurt(e, 10.0, Vector2.ZERO, "lightning")
    var plain: float = hp0 - float(e.hp)
    world.apply_status(e, "wet", 5.0)
    var hp1: float = e.hp
    world.hurt(e, 10.0, Vector2.ZERO, "lightning")
    var boosted: float = hp1 - float(e.hp)
    print("[smoke] synergy conductor: plain hit %.1f, on a soaked enemy %.1f" % [plain, boosted])
    if boosted <= plain * 1.2:
        failures.append("conductor synergy did not boost lightning on a soaked enemy")
    world.hurt(e, 1.0, Vector2.ZERO, "ice")
    if not e.s.has("petrify"):
        failures.append("deepfreeze synergy did not freeze a soaked enemy")
    world.apply_status(e, "burn", 5.0)
    world.hurt(e, 1.0, Vector2.ZERO, "water")
    if e.s.has("burn"):
        failures.append("steam synergy did not consume the burn")
    world.invulnerable = false
    world.active = false
    world.in_run = false


# Fusions: the readiness rule, the level-up card, and every fusion firing in a live fight.
func _fusion_check() -> void:
    var p: Dictionary = Spells.new_player()
    p.weapons = {"wand": 1, "incendio": 3, "depulso": 3}
    if not Spells.fusion_ready(p, "firestorm"):
        failures.append("firestorm should be ready with Incendio 3 + Depulso 3")
    if Spells.fusion_ready(p, "elements") or Spells.fusion_ready(p, "phoenix"):
        failures.append("a fusion is ready without its spells")
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    var offered: bool = false
    for i in 12:
        for c in Spells.choices(p, rng):
            if c.kind == "fusion" and c.id == "firestorm":
                offered = true
                Spells.apply(p, c)
    if not offered or not p.fusions.has("firestorm"):
        failures.append("the firestorm fusion card was never offered")
    world.invulnerable = true
    world.start_run({})
    world.player.weapons = {"wand": 5, "incendio": 5, "glacius": 5, "aguamenti": 5, "baubillious": 5, "depulso": 5}
    for fid in Spells.FUSIONS:
        world.player.fusions[fid] = true
    world.refresh_synergies()
    var t: float = 0.0
    while t < 45.0:
        world.move_input = Vector2.from_angle(t * 0.6)
        world.step(DT)
        t += DT
    print("[smoke] fusions: all %d active for 45 s, kills %d" % [Spells.FUSIONS.size(), int(world.kills)])
    if int(world.kills) < 20:
        failures.append("nine fusions together defeated almost nothing")
    world.invulnerable = false
    world.active = false
    world.in_run = false


# Meta shop, hero purchase, and the dodge / revive upgrades in a live run.
func _meta_check() -> void:
    var data := {"gold": 100, "meta": {}, "heroes": ["harry"], "hero": "harry"}
    if not Spells.meta_buy(data, "power") or int(data.gold) != 80 or int(data.meta.get("power", 0)) != 1:
        failures.append("buying Wand Mastery for 20 galleons failed")
    if Spells.meta_buy(data, "revive"):
        failures.append("Phoenix Tear was sold without enough galleons")
    if Spells.hero_pick(data, "ron"):
        failures.append("Ron was sold without enough galleons")
    data["gold"] = 500
    if not Spells.hero_pick(data, "ron") or str(data.hero) != "ron" or int(data.gold) != 380:
        failures.append("buying Ron failed")
    var p: Dictionary = Spells.new_player("ron", {"vigor": 2})
    if int(p.max_hp) != 155 or not p.weapons.has("depulso"):
        failures.append("Ron with Vitality 2 should start with 155 HP and Depulso")
    _reset()
    world.invulnerable = false
    world.start_run({"hero": "hermione", "meta": {"dodge": 5, "revive": 1}})
    if str(world.player.hero) != "hermione" or int(world.player.revives) != 1:
        failures.append("the run did not pick up the hero and meta upgrades")
    world.player.dodge = 1.0
    world.player.iframe = 0.0
    var hp0: float = world.player.hp
    world.damage_player(50.0)
    if float(world.player.hp) != hp0:
        failures.append("a guaranteed dodge still lost health")
    world.player.dodge = 0.0
    world.player.iframe = 0.0
    world.damage_player(9999.0)
    if float(world.player.hp) <= 0.0 or int(world.player.revives) != 0:
        failures.append("Phoenix Tear did not revive the hero")
    world.player.iframe = 0.0
    world.damage_player(9999.0)
    world.step(DT)
    if not ended or victory:
        failures.append("the hero did not fall after the revive was spent")
    print("[smoke] meta: shop, hero purchase, dodge and revive checked")


func _checkpoint_roundtrip() -> void:
    world.start_run({})
    world.player.weapons["protego"] = 3
    world.player.weapons["removed_spell"] = 2
    world.player.fusions["removed_fusion"] = true
    world.player.level = 9
    var cp: Dictionary = world.checkpoint(7)
    var cfg := ConfigFile.new()
    cfg.set_value("save", "checkpoint", cp)
    var text: String = cfg.encode_to_text()
    var cfg2 := ConfigFile.new()
    if cfg2.parse(text) != OK:
        failures.append("checkpoint did not survive ConfigFile encoding")
        return
    var back: Dictionary = cfg2.get_value("save", "checkpoint", {})
    world.start_run({}, back)
    if int(world.chapter_index) != 7 or int(world.player.weapons.get("protego", 0)) != 3 or int(world.player.level) != 9:
        failures.append("checkpoint resume lost stage or build data")
    if world.player.weapons.has("removed_spell") or world.player.fusions.has("removed_fusion"):
        failures.append("checkpoint resume kept a spell or fusion that does not exist")
    for i in 40:
        world.step(DT)
    world.active = false
    world.in_run = false


# Take a regular upgrade at every level until none is left. A level-up must always offer three
# cards; once the regular ones are gone they are repeatable bonuses, and a bonus must do something.
func _upgrade_exhaustion() -> void:
    var p: Dictionary = Spells.new_player()
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var n: int = 0
    var last: Array = []
    while n < 400:
        last = Spells.choices(p, rng)
        if last.size() != 3:
            failures.append("a level-up offered %d cards instead of 3 (after %d picks)" % [last.size(), n])
            return
        var pick = null
        for c in last:
            if c.kind != "heal" and c.kind != "boon":
                pick = c
                break
        if pick == null:
            break
        Spells.apply(p, pick)
        n += 1
    print("[smoke] upgrades: the regular pool lasts %d picks; then every level offers repeatable cards. Final build: %d spells, %d talismans, fusions %s, evolutions %s" % [n, p.weapons.size(), p.passives.size(), str(p.fusions.keys()), str(p.evolved.keys())])
    if n >= 400:
        failures.append("the upgrade pool never runs out")
    if p.weapons.size() != Spells.WEAPON_SLOTS or p.passives.size() != Spells.PASSIVE_SLOTS:
        failures.append("a full build should hold exactly %d spells and %d talismans" % [Spells.WEAPON_SLOTS, Spells.PASSIVE_SLOTS])
    for id in p.weapons:
        if int(p.weapons[id]) != Spells.MAX_LEVEL:
            failures.append("spell %s stopped at level %d" % [str(id), int(p.weapons[id])])
    for id in p.passives:
        if int(p.passives[id]) != Spells.PASSIVE_MAX:
            failures.append("talisman %s stopped at level %d" % [str(id), int(p.passives[id])])
    var boons: int = 0
    for c in last:
        if c.kind != "boon":
            continue
        boons += 1
        var before: String = "%.4f %.4f %.1f" % [float(p.m_dmg), float(p.m_cd), float(p.max_hp)]
        Spells.apply(p, c)
        var after: String = "%.4f %.4f %.1f" % [float(p.m_dmg), float(p.m_cd), float(p.max_hp)]
        if before == after:
            failures.append("the repeatable card %s changed nothing" % str(c.id))
    if boons < 2:
        failures.append("a finished build was offered fewer than two repeatable bonuses")


# Build the real main scene and open every panel once so UI scripts run in the given language.
func _ui_pass(lang: String) -> void:
    var scene = load("res://scenes/main.tscn")
    if scene == null:
        failures.append("main.tscn failed to load")
        return
    var main = scene.instantiate()
    root.add_child(main)
    if main.hud == null or main.world == null or main.stick == null or main.music == null:
        failures.append("main scene did not build its world/HUD/stick/music")
        return
    main.save.data["lang"] = lang
    main.save.data["seen"] = {"cauldron": true, "spider": true, "voldemort": true}
    main.hud.settings_changed.emit()
    if I18n.lang != lang:
        failures.append("language did not switch to %s" % lang)
    var hud = main.hud
    hud.show_menu()
    hud.show_heroes(hud.show_menu)
    hud.show_shop(hud.show_menu)
    hud.show_combos(hud.show_menu)
    hud.show_bestiary(hud.show_menu)
    hud.show_help(hud.show_menu)
    hud.start_requested.emit("story")
    if not main.world.in_run:
        failures.append("NEW STORY RUN did not start a run")
    for i in 200:
        main.world.move_input = Vector2.RIGHT
        main.world.step(DT)
    hud.show_levelup(Spells.choices(main.world.player, main.world.rng), 2)
    hud.show_pause()
    hud.show_combos(hud.show_pause)
    hud.show_settings(hud.show_pause)
    hud.show_chapter_clear(0)
    hud.show_chapter_clear(1)
    hud.show_summary(true)
    hud.menu_requested.emit()
    hud.start_requested.emit("endless")
    if str(main.world.mode) != "endless" or not main.world.in_run:
        failures.append("ENDLESS MODE did not start")
    for i in 40:
        main.world.step(DT)
    hud.show_summary(false)
    hud.menu_requested.emit()
    print("[smoke] UI pass (%s): menu title sample = %s; limits line = %s" % [lang, I18n.t("ui_new"), Spells.limits(main.world.player)])
    main.queue_free()


# Every sound a spell, a fusion or the world asks for must have been synthesised.
func _sound_check(sfx) -> void:
    var ready: int = int(sfx.ready_count())
    var wanted: Array = ["hurt", "warn", "burst", "level", "levelup", "boss_down", "gem"]
    for table in [Spells.WEAPONS, Spells.FUSIONS]:
        for id in table:
            var snd: String = str(table[id].get("snd", ""))
            if snd != "" and not (snd in wanted):
                wanted.append(snd)
    var missing: Array = []
    for item in wanted:
        var key: String = str(item)
        if key == "gem" or key == "wand":
            key += "0"
        if not sfx._streams.has(key):
            missing.append(item)
    print("[smoke] sound: %d of %d effect streams synthesised; ids in use %s" % [ready, SOUNDS, str(wanted)])
    if ready < SOUNDS:
        failures.append("only %d of %d sound effects were synthesised" % [ready, SOUNDS])
    if not missing.is_empty():
        failures.append("no sound for %s" % str(missing))


# ---------------------------------------------------------------- draw pass
# The scene built here stays in the tree while _process returns false, so the engine runs whole
# frames in between and sends the draw notifications for whatever each step left on screen.

func _draw_begin() -> void:
    var scene = load("res://scenes/main.tscn")
    if scene == null:
        return
    _main = scene.instantiate()
    root.add_child(_main)
    if _main.hud == null or _main.world == null:
        _main = null
        return
    _sound_check(_main.sfx)
    _main.save.data["lang"] = "ru"
    _main.save.data["tutorial"] = false
    _main.save.data["seen"] = {"cauldron": true, "spider": true, "quirrell": true, "basilisk": true}
    _main.hud.settings_changed.emit()
    _main.hud.draw.connect(func(): _hud_draws += 1)
    _main.world.draw.connect(func(): _world_draws += 1)
    _main.hud.show_menu()


# Play for n steps through the real scene, picking the first card whenever a level arrives.
func _sim(n: int) -> void:
    var w = _main.world
    for i in n:
        if not w.active:
            if int(w.player.pending) > 0:
                _main.hud.upgrade_chosen.emit(Spells.choices(w.player, w.rng)[0])
            else:
                return
        w.move_input = Vector2.from_angle(i * 0.07)
        w.step(DT)


# One step per frame. Returns false when the pass is over.
func _draw_step() -> bool:
    if _main == null:
        return false
    var hud = _main.hud
    var w = _main.world
    match _phase:
        2:
            # The main menu was drawn. Start a run: floor tiles, obstacles, hero, enemies, HUD strip.
            hud.start_requested.emit("story")
            w.invulnerable = true
            _sim(160)
        3:
            # The level-up screen with its backdrop, part-way through the burst.
            w.player.pending = 0
            hud.show_levelup(Spells.choices(w.player, w.rng), 2)
            hud._fx_t = 0.7
        4:
            # Quirrell's stage.
            hud.close_panel()
            w.load_chapter(2)
            _sim(110)
        5:
            # The Basilisk's stage.
            hud.close_panel()
            w.player.pending = 0
            w.load_chapter(5)
            _sim(110)
        6:
            hud.show_pause()
        7:
            hud.show_bestiary(hud.show_menu)
        8:
            hud.show_heroes(hud.show_menu)
        9:
            hud.menu_requested.emit()
        10:
            # "Graphics: simple": code-drawn street blocks, hero and enemies.
            _main.save.data["sprites"] = false
            hud.settings_changed.emit()
            hud.start_requested.emit("story")
            w.invulnerable = true
            _sim(120)
        11:
            # Code-drawn forest (trees).
            hud.close_panel()
            w.player.pending = 0
            w.load_chapter(3)
            _sim(80)
        12:
            # Code-drawn pitch (hoops and stands).
            hud.close_panel()
            w.player.pending = 0
            w.load_chapter(4)
            _sim(80)
        13:
            _main.save.data["sprites"] = true
            hud.settings_changed.emit()
            hud.menu_requested.emit()
        _:
            _main.queue_free()
            _main = null
            return false
    return true
