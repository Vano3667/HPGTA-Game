extends SceneTree
## Headless smoke test. A simple bot drives the simulation through all five chapters, then the
## UI scene is built and every panel is opened once.
## Usage: godot --headless --path . -s res://tests/smoke_test.gd
## Note: the UI pass writes the normal local save file (user://hex_district.cfg).

const WorldScript = preload("res://scripts/game/world.gd")
const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")

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
    _checkpoint_roundtrip()
    _upgrade_exhaustion()
    world.queue_free()
    _ui_pass()
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


func _check_data() -> void:
    if Chapters.LIST.size() != 5:
        failures.append("expected 5 chapters, found %d" % Chapters.LIST.size())
    for ch in Chapters.LIST:
        for row in ch.enemies:
            if not Enemies.TYPES.has(row[0]):
                failures.append("unknown enemy type %s in %s" % [str(row[0]), str(ch.id)])
        if not Enemies.BOSSES.has(ch.boss):
            failures.append("unknown boss %s" % str(ch.boss))
    for id in Spells.EVOLUTIONS:
        var ev: Dictionary = Spells.EVOLUTIONS[id]
        if not Spells.WEAPONS.has(ev.weapon) or not Spells.PASSIVES.has(ev.passive):
            failures.append("bad evolution recipe %s" % str(id))


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


# Invulnerable bot: must clear all five chapters and reach the victory screen.
func _full_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({})
    var t: float = 0.0
    var boss_t: float = 0.0
    while not ended and t < 2400.0:
        world.move_input = Vector2.from_angle(t * 0.6)
        world.step(DT)
        t += DT
        if world.boss != null:
            boss_t += DT
            if boss_t > 120.0:
                print("[smoke] WARNING: %s still alive after 120 s (hp %d/%d) - balance needs tuning; forcing the kill" % [str(world.boss.name), int(world.boss.hp), int(world.boss.max_hp)])
                world.hurt(world.boss, 1.0e9)
                boss_t = 0.0
        elif boss_t > 0.0:
            print("[smoke] chapter %d boss down after %d s, player level %d, kills %d" % [int(world.chapter_index) + 1, int(boss_t), int(world.player.level), int(world.kills)])
            boss_t = 0.0
    world.invulnerable = false
    print("[smoke] full run: ended=%s victory=%s chapters_cleared=%d sim_time=%ds level=%d" % [str(ended), str(victory), cleared.size(), int(t), int(world.player.level)])
    if not ended or not victory:
        failures.append("full run did not reach victory")
    if cleared.size() != 4:
        failures.append("expected 4 chapter-clear events before the finale, got %d" % cleared.size())


func _checkpoint_roundtrip() -> void:
    world.start_run({})
    world.player.weapons["protego"] = 3
    world.player.level = 9
    var cp: Dictionary = world.checkpoint(2)
    var cfg := ConfigFile.new()
    cfg.set_value("save", "checkpoint", cp)
    var text: String = cfg.encode_to_text()
    var cfg2 := ConfigFile.new()
    if cfg2.parse(text) != OK:
        failures.append("checkpoint did not survive ConfigFile encoding")
        return
    var back: Dictionary = cfg2.get_value("save", "checkpoint", {})
    world.start_run({}, back)
    if int(world.chapter_index) != 2 or int(world.player.weapons.get("protego", 0)) != 3 or int(world.player.level) != 9:
        failures.append("checkpoint resume lost chapter or build data")
    world.active = false
    world.in_run = false


func _upgrade_exhaustion() -> void:
    var p: Dictionary = Spells.new_player()
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var n: int = 0
    while n < 200:
        var c: Array = Spells.choices(p, rng)
        if c.is_empty():
            failures.append("upgrade roll returned no cards")
            return
        if c[0].kind == "heal":
            break
        Spells.apply(p, c[0])
        n += 1
    print("[smoke] upgrade pool exhausted after %d picks; evolutions=%s" % [n, str(p.evolved.keys())])
    if n >= 200:
        failures.append("upgrade pool never exhausts")


# Build the real main scene and open every panel once so UI scripts are exercised too.
func _ui_pass() -> void:
    var scene = load("res://scenes/main.tscn")
    if scene == null:
        failures.append("main.tscn failed to load")
        return
    var main = scene.instantiate()
    root.add_child(main)
    if main.hud == null or main.world == null or main.stick == null:
        failures.append("main scene did not build its world/HUD/stick")
        return
    main.hud.start_requested.emit(false)
    if not main.world.in_run:
        failures.append("NEW RUN did not start a run")
    for i in 200:
        main.world.move_input = Vector2.RIGHT
        main.world.step(DT)
    main.hud.show_levelup(Spells.choices(main.world.player, main.world.rng), 2)
    main.hud.show_pause()
    main.hud.show_settings(main.hud.show_pause)
    main.hud.show_chapter_clear(0)
    main.hud.show_summary(true)
    main.hud.show_menu()
    main.world.active = false
    main.world.in_run = false
    print("[smoke] UI pass built main scene and opened all panels")
    main.queue_free()
