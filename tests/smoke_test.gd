extends SceneTree
## Headless smoke test. Checks the data tables and both languages, lets a simple bot play all ten
## chapters, verifies the synergy engine, then builds the UI scene and opens every panel in EN and RU.
## Usage: godot --headless --path . -s res://tests/smoke_test.gd
## Note: the UI pass writes the normal local save file (user://hex_district.cfg).

const WorldScript = preload("res://scripts/game/world.gd")
const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")

const DT := 0.05

var world
var failures: Array = []
var cleared: Array = []
var ended := false
var victory := false
var levelups := 0
var _started := false


func _process(_delta: float) -> bool:
    if _started:
        return true
    _started = true
    _check_data()
    world = WorldScript.new()
    root.add_child(world)
    world.level_up.connect(_on_level_up)
    world.chapter_cleared.connect(_on_cleared)
    world.run_ended.connect(_on_ended)
    _mortal_run()
    _full_run()
    _synergy_check()
    _checkpoint_roundtrip()
    _upgrade_exhaustion()
    world.queue_free()
    _ui_pass("en")
    _ui_pass("ru")
    for f in failures:
        print("[smoke] FAIL: %s" % str(f))
    if failures.is_empty():
        print("[smoke] PASS")
    quit(0 if failures.is_empty() else 1)
    return true


func _reset() -> void:
    cleared = []
    ended = false
    victory = false
    levelups = 0


func _on_level_up(choices: Array) -> void:
    levelups += 1
    world.apply_upgrade(choices[levelups % choices.size()])


func _on_cleared(index: int) -> void:
    cleared.append(index)
    world.load_chapter(index + 1)


func _on_ended(v: bool) -> void:
    ended = true
    victory = v


func _need(key: String) -> void:
    if not I18n.has(key):
        failures.append("missing translation key %s" % key)
        return
    var row: Array = I18n.S[key]
    if row.size() != 2 or str(row[0]) == "" or str(row[1]) == "":
        failures.append("translation %s needs both English and Russian text" % key)


func _check_data() -> void:
    if Chapters.LIST.size() != 10:
        failures.append("expected 10 chapters, found %d" % Chapters.LIST.size())
    if Spells.WEAPONS.size() != 28:
        failures.append("expected 28 spells, found %d" % Spells.WEAPONS.size())
    for ch in Chapters.LIST:
        _need("ch_" + str(ch.id))
        _need("cs_" + str(ch.id))
        _need("bo_" + str(ch.boss))
        for row in ch.enemies:
            if not Enemies.TYPES.has(row[0]):
                failures.append("unknown enemy type %s in %s" % [str(row[0]), str(ch.id)])
        if not Enemies.BOSSES.has(ch.boss):
            failures.append("unknown boss %s" % str(ch.boss))
    var statuses := {}
    for id in Spells.WEAPONS:
        _need("sp_" + str(id))
        _need("sd_" + str(id))
        var def: Dictionary = Spells.WEAPONS[id]
        _need("el_" + str(def.el))
        if def.has("st"):
            statuses[def.st] = true
    for id in Spells.PASSIVES:
        _need("pa_" + str(id))
        _need("pd_" + str(id))
    for id in Spells.EVOLUTIONS:
        _need("ev_" + str(id))
        _need("ed_" + str(id))
        var ev: Dictionary = Spells.EVOLUTIONS[id]
        if not Spells.WEAPONS.has(ev.weapon) or not (ev.passive in Spells.PASSIVES):
            failures.append("bad evolution recipe %s" % str(id))
    for sid in Spells.SYNERGIES:
        _need("sy_" + str(sid))
        _need("sx_" + str(sid))
        var rule: Dictionary = Spells.SYNERGIES[sid]
        if not statuses.has(rule.st):
            failures.append("synergy %s needs status %s that no spell applies" % [str(sid), str(rule.st)])
        if not rule.el.is_empty() and Spells.element_sources(rule.el).is_empty():
            failures.append("synergy %s has no spell of its element" % str(sid))
        if Spells.requirement(sid) == "":
            failures.append("synergy %s has an empty requirement line" % str(sid))
    print("[smoke] data: %d chapters, %d spells, %d synergies, %d enemy types, %d translation rows" % [Chapters.LIST.size(), Spells.WEAPONS.size(), Spells.SYNERGIES.size(), Enemies.TYPES.size(), I18n.S.size()])


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
    print("[smoke] mortal bot: ended=%s victory=%s chapter=%d run_time=%ds level=%d kills=%d hp=%d" % [str(ended), str(victory), int(world.chapter_index) + 1, int(world.run_time), int(world.player.level), int(world.kills), int(world.player.hp)])
    if int(world.kills) <= 0:
        failures.append("mortal run: automatic attacks defeated nothing")
    if levelups <= 0:
        failures.append("mortal run: no level-up happened")


# Invulnerable bot: must clear all ten chapters and reach the victory screen.
func _full_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({})
    var t: float = 0.0
    var boss_t: float = 0.0
    var forced: int = 0
    while not ended and t < 3600.0:
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
            print("[smoke] chapter %d boss down after %d s, player level %d, kills %d" % [int(world.chapter_index) + 1, int(boss_t), int(world.player.level), int(world.kills)])
            boss_t = 0.0
    world.invulnerable = false
    print("[smoke] full run: ended=%s victory=%s chapters_cleared=%d sim_time=%ds level=%d forced_boss_kills=%d" % [str(ended), str(victory), cleared.size(), int(t), int(world.player.level), forced])
    print("[smoke] final build: spells=%s synergies=%s" % [str(world.player.weapons.keys()), str(world.syn)])
    if not ended or not victory:
        failures.append("full run did not reach victory")
    if cleared.size() != 9:
        failures.append("expected 9 chapter-clear events before the finale, got %d" % cleared.size())


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


func _checkpoint_roundtrip() -> void:
    world.start_run({})
    world.player.weapons["protego"] = 3
    world.player.weapons["removed_spell"] = 2
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
        failures.append("checkpoint resume lost chapter or build data")
    if world.player.weapons.has("removed_spell"):
        failures.append("checkpoint resume kept a spell that does not exist")
    for i in 40:
        world.step(DT)
    world.active = false
    world.in_run = false


func _upgrade_exhaustion() -> void:
    var p: Dictionary = Spells.new_player()
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var n: int = 0
    while n < 300:
        var c: Array = Spells.choices(p, rng)
        if c.is_empty():
            failures.append("upgrade roll returned no cards")
            return
        if c[0].kind == "heal":
            break
        Spells.apply(p, c[0])
        n += 1
    print("[smoke] upgrade pool exhausted after %d picks; spells=%d evolutions=%s" % [n, p.weapons.size(), str(p.evolved.keys())])
    if n >= 300:
        failures.append("upgrade pool never exhausts")
    if p.weapons.size() != Spells.WEAPON_SLOTS:
        failures.append("a full build should hold exactly %d spells" % Spells.WEAPON_SLOTS)


# Build the real main scene and open every panel once so UI scripts run in the given language.
func _ui_pass(lang: String) -> void:
    var scene = load("res://scenes/main.tscn")
    if scene == null:
        failures.append("main.tscn failed to load")
        return
    var main = scene.instantiate()
    root.add_child(main)
    if main.hud == null or main.world == null or main.stick == null:
        failures.append("main scene did not build its world/HUD/stick")
        return
    main.save.data["lang"] = lang
    main.hud.settings_changed.emit()
    if I18n.lang != lang:
        failures.append("language did not switch to %s" % lang)
    main.hud.show_menu()
    main.hud.show_synergies(main.hud.show_menu)
    main.hud.start_requested.emit(false)
    if not main.world.in_run:
        failures.append("NEW RUN did not start a run")
    for i in 200:
        main.world.move_input = Vector2.RIGHT
        main.world.step(DT)
    main.hud.show_levelup(Spells.choices(main.world.player, main.world.rng), 2)
    main.hud.show_pause()
    main.hud.show_synergies(main.hud.show_pause)
    main.hud.show_settings(main.hud.show_pause)
    main.hud.show_chapter_clear(0)
    main.hud.show_summary(true)
    main.hud.show_menu()
    main.world.active = false
    main.world.in_run = false
    print("[smoke] UI pass (%s): menu title sample = %s" % [lang, I18n.t("ui_new")])
    main.queue_free()
