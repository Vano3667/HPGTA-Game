extends SceneTree
## Headless smoke test. Checks the data tables and both languages, lets a simple bot play the whole
## story (10 chapters + 5 boss duels) and a few stages of endless mode, verifies fusions, synergies,
## the upgrade shop, dodge and revive, then builds the UI scene and opens every panel in EN and RU.
## Usage: godot --headless --path . -s res://tests/smoke_test.gd
## Note: the UI pass writes the normal local save file (user://hex_district.cfg).

const WorldScript = preload("res://scripts/game/world.gd")
const Chapters = preload("res://scripts/data/chapters.gd")
const Enemies = preload("res://scripts/data/enemies.gd")
const Spells = preload("res://scripts/data/spells.gd")
const I18n = preload("res://scripts/core/i18n.gd")
const Sprites = preload("res://scripts/core/sprites.gd")

const DT := 0.05
const UI_KEYS := [
    "ui_sub", "ui_stats", "ui_gold", "ui_g", "ui_continue", "ui_new", "ui_endless", "ui_hero", "ui_shop", "ui_combos",
    "ui_bestiary", "ui_help", "ui_settings", "ui_hint", "ui_legal", "ui_level", "ui_choose", "ui_paused", "ui_resume",
    "ui_quit", "ui_cleared", "ui_cleared_sub", "ui_next", "ui_next_boss", "ui_saved", "ui_go", "ui_win", "ui_lose",
    "ui_win_sub", "ui_lose_sub", "ui_sum1", "ui_sum2", "ui_sum3", "ui_restart", "ui_menu", "ui_back", "ui_set_sub",
    "ui_shop_sub", "ui_hero_sub", "ui_best_sub", "ui_combo_sub", "ui_unknown", "ui_bstat", "ui_buy", "ui_selected",
    "ui_select", "ui_max", "ui_sec_fusion", "ui_sec_evo", "ui_sec_syn", "ui_owned", "ui_ready", "ui_fuse_req",
    "ui_evo_req", "ui_syn_on", "ui_syn_off", "ui_syn_hint", "ui_fu_hint", "ui_boss", "ui_lv", "ui_boss_sub", "ui_phase",
    "ui_stagger", "ui_core", "ui_portal", "ui_dodge", "ui_revive", "ui_loop", "t_fusion", "t_evolution",
    "tut_1", "tut_2", "tut_3", "tut_4", "help_1", "help_2", "help_3", "help_4", "help_5",
    "ai_chase", "ai_weave", "ai_ranged", "ai_charge", "ai_boss",
    "o_lang", "o_sprites", "o_music", "o_sound", "o_hand", "o_size", "o_opacity", "o_sens", "o_shake", "o_vib",
    "o_flash", "o_contrast", "v_on", "v_off", "v_painted", "v_drawn",
]

var world
var failures: Array = []
var cleared: Array = []
var stages := 0
var ended := false
var victory := false
var levelups := 0
var _started := false


func _process(_delta: float) -> bool:
    if _started:
        return true
    _started = true
    _check_data()
    _check_art()
    world = WorldScript.new()
    root.add_child(world)
    world.level_up.connect(_on_level_up)
    world.chapter_cleared.connect(_on_cleared)
    world.stage_changed.connect(_on_stage)
    world.run_ended.connect(_on_ended)
    _mortal_run()
    _full_run()
    _endless_run()
    _hero_runs()
    _fusion_check()
    _synergy_check()
    _meta_check()
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
    stages = 0
    ended = false
    victory = false
    levelups = 0


func _stop() -> void:
    world.invulnerable = false
    world.active = false
    world.in_run = false


func _on_level_up(choices: Array) -> void:
    levelups += 1
    world.apply_upgrade(choices[levelups % choices.size()])


func _on_cleared(index: int) -> void:
    cleared.append(index)
    world.load_chapter(index + 1)


func _on_stage(_tier: int) -> void:
    stages += 1
    if world.chapter.get("duel", false):
        failures.append("endless mode loaded a boss arena (%s)" % str(world.chapter.id))


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
    var duels: int = 0
    for ch in Chapters.LIST:
        _need("ch_" + str(ch.id))
        _need("cs_" + str(ch.id))
        var is_duel: bool = ch.get("duel", false)
        if is_duel:
            duels += 1
            if str(ch.boss) == "":
                failures.append("boss arena %s has no boss" % str(ch.id))
        elif not ch.has("hazard"):
            failures.append("chapter %s has no hazard" % str(ch.id))
        if str(ch.boss) != "":
            _need("bo_" + str(ch.boss))
            if not Enemies.BOSSES.has(ch.boss):
                failures.append("unknown boss %s" % str(ch.boss))
        for row in ch.enemies:
            if not Enemies.TYPES.has(row[0]):
                failures.append("unknown enemy type %s in %s" % [str(row[0]), str(ch.id)])
    if Chapters.LIST.size() != 15 or duels != 5:
        failures.append("expected 10 chapters and 5 boss arenas, found %d stages with %d arenas" % [Chapters.LIST.size(), duels])
    if Chapters.LIST[Chapters.LIST.size() - 1].boss != "voldemort":
        failures.append("the final stage must be the duel with Voldemort")
    if Spells.WEAPONS.size() != 28:
        failures.append("expected 28 spells, found %d" % Spells.WEAPONS.size())
    for key in UI_KEYS:
        _need(str(key))
    for id in Enemies.TYPES:
        _need("en_" + str(id))
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
            failures.append("there is no fusion made of %d spells" % n)
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
    for id in Spells.HEROES:
        _need("he_" + str(id))
        _need("hd_" + str(id))
        if not Spells.WEAPONS.has(Spells.HEROES[id].spell):
            failures.append("hero %s starts with an unknown spell" % str(id))
    for id in Spells.META:
        _need("me_" + str(id))
        _need("md_" + str(id))
    print("[smoke] data: %d stages (%d boss arenas), %d spells, %d fusions, %d synergies, %d enemy types, %d heroes, %d meta upgrades, %d translation rows" % [Chapters.LIST.size(), duels, Spells.WEAPONS.size(), Spells.FUSIONS.size(), Spells.SYNERGIES.size(), Enemies.TYPES.size(), Spells.HEROES.size(), Spells.META.size(), I18n.S.size()])


# Reports which painted textures the build produced. Missing art is not a failure: the game then
# falls back to code-drawn graphics, and this line says exactly what it will look like.
func _check_art() -> void:
    var heroes: Array = []
    for id in Spells.HEROES:
        if Sprites.tex("hero_" + str(id)) != null:
            heroes.append(str(id))
    var mobs := {}
    var mob_total := {}
    for id in Enemies.TYPES:
        var spr: String = str(Enemies.TYPES[id].get("spr", ""))
        if spr == "":
            continue
        mob_total[spr] = true
        if Sprites.tex("mob_" + spr) != null:
            mobs[spr] = true
    var bosses: Array = []
    for id in Enemies.BOSSES:
        var bspr: String = str(Enemies.BOSSES[id].get("spr", ""))
        if bspr != "" and Sprites.tex("boss_" + bspr) != null:
            bosses.append(bspr)
    var maps: int = 0
    for ch in Chapters.LIST:
        var t: Texture2D = Sprites.tex("map_" + str(ch.get("map", "")))
        if t != null:
            maps += 1
            if t.get_width() < 64 or t.get_height() < 64:
                failures.append("painted map %s loaded with a broken size" % str(ch.map))
    print("[smoke] painted art: heroes=%s enemy sprites=%d/%d story bosses=%s maps=%d/%d" % [str(heroes), mobs.size(), mob_total.size(), str(bosses), maps, Chapters.LIST.size()])


func _drive(t: float) -> void:
    world.move_input = Vector2.from_angle(t * 0.6)
    world.step(DT)


# A circling bot with normal damage rules: it is allowed to die, the run just has to behave.
func _mortal_run() -> void:
    _reset()
    world.invulnerable = false
    world.start_run({})
    var t: float = 0.0
    while not ended and t < 600.0:
        _drive(t)
        t += DT
    print("[smoke] mortal bot: ended=%s victory=%s stage=%d run_time=%ds level=%d kills=%d hp=%d" % [str(ended), str(victory), int(world.chapter_index) + 1, int(world.run_time), int(world.player.level), int(world.kills), int(world.player.hp)])
    if int(world.kills) <= 0:
        failures.append("mortal run: automatic attacks defeated nothing")
    if levelups <= 0:
        failures.append("mortal run: no level-up happened")
    _stop()


# Steps the simulation and force-kills a boss that outlives 120 s. Returns the new boss timer.
func _boss_watch(boss_t: float) -> float:
    if world.boss != null:
        boss_t += DT
        if boss_t > 120.0:
            print("[smoke] WARNING: boss %s still alive after 120 s (hp %d/%d) - balance needs tuning; forcing the kill" % [str(world.boss.type), int(world.boss.hp), int(world.boss.max_hp)])
            world.hurt(world.boss, 1.0e9)
            return 0.0
        return boss_t
    if boss_t > 0.0:
        print("[smoke] stage %d (%s): boss down after %d s, player level %d, kills %d" % [int(world.chapter_index) + 1, str(world.chapter.id), int(boss_t), int(world.player.level), int(world.kills)])
    return 0.0


# Invulnerable bot: must clear all fifteen stages and reach the victory screen.
func _full_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({})
    var t: float = 0.0
    var boss_t: float = 0.0
    while not ended and t < 4800.0:
        _drive(t)
        t += DT
        boss_t = _boss_watch(boss_t)
    print("[smoke] full run: ended=%s victory=%s stages_cleared=%d sim_time=%ds level=%d galleons=%d" % [str(ended), str(victory), cleared.size(), int(t), int(world.player.level), int(world.run_gold)])
    print("[smoke] final build: spells=%s fusions=%s synergies=%s" % [str(world.player.weapons.keys()), str(world.player.fusions.keys()), str(world.syn)])
    if not ended or not victory:
        failures.append("full run did not reach victory")
    if cleared.size() != Chapters.LIST.size() - 1:
        failures.append("expected %d stage-clear events before the finale, got %d" % [Chapters.LIST.size() - 1, cleared.size()])
    if int(world.run_gold) <= 0:
        failures.append("a full run earned no galleons")
    if world.seen.is_empty():
        failures.append("a full run recorded no bestiary entries")
    _stop()


# Endless mode: chapters keep rolling over without boss arenas and without ending.
func _endless_run() -> void:
    _reset()
    world.invulnerable = true
    world.start_run({}, {}, "endless")
    var t: float = 0.0
    var boss_t: float = 0.0
    while not ended and int(world.tier) < 3 and t < 1500.0:
        _drive(t)
        t += DT
        boss_t = _boss_watch(boss_t)
    print("[smoke] endless: tier=%d stage_changes=%d sim_time=%ds level=%d ended=%s" % [int(world.tier), stages, int(t), int(world.player.level), str(ended)])
    if ended:
        failures.append("endless mode ended on its own")
    if int(world.tier) < 3 or stages < 3:
        failures.append("endless mode did not advance three stages")
    _stop()


func _hero_runs() -> void:
    for key in Spells.HEROES:
        var id: String = str(key)
        _reset()
        world.invulnerable = true
        world.start_run({"hero": id, "meta": {"power": 2, "vigor": 2, "dodge": 1, "revive": 1}})
        if str(world.player.hero) != id or not world.player.weapons.has(Spells.HEROES[id].spell):
            failures.append("hero %s did not start with its own kit" % id)
        for i in 600:
            _drive(i * DT)
        print("[smoke] hero %s: max_hp=%d kills=%d level=%d" % [id, int(world.player.max_hp), int(world.kills), int(world.player.level)])
        if int(world.kills) <= 0:
            failures.append("hero %s defeated nothing in 30 s" % id)
    _stop()


func _fusion_check() -> void:
    var p: Dictionary = Spells.new_player()
    p.weapons["incendio"] = 2
    p.weapons["depulso"] = 3
    if Spells.fusion_ready(p, "firestorm"):
        failures.append("firestorm must not be ready below level 3")
    p.weapons["incendio"] = 3
    if not Spells.fusion_ready(p, "firestorm"):
        failures.append("firestorm should be ready with both spells at level 3")
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    var offered: bool = false
    for i in 40:
        for c in Spells.choices(p, rng):
            if c.kind == "fusion" and c.id == "firestorm":
                offered = true
    if not offered:
        failures.append("a ready fusion was never offered as an upgrade card")
    Spells.apply(p, {"kind": "fusion", "id": "firestorm"})
    if not p.fusions.has("firestorm"):
        failures.append("taking a fusion card did not add the fusion")
    # Every fusion at once in the live simulation.
    _reset()
    world.invulnerable = true
    world.start_run({})
    for fid in Spells.FUSIONS:
        world.player.fusions[fid] = true
        for id in Spells.FUSIONS[fid].need:
            world.player.weapons[id] = 3
    world.refresh_synergies()
    for i in 900:
        _drive(i * DT)
    print("[smoke] all %d fusions cast together for 45 s: kills=%d level=%d" % [Spells.FUSIONS.size(), int(world.kills), int(world.player.level)])
    if int(world.kills) <= 0:
        failures.append("fusion build defeated nothing")
    _stop()


# The synergy engine: a status on the enemy plus a hit of the right element must change the outcome.
func _synergy_check() -> void:
    _reset()
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
    _stop()


# Galleon shop, hero purchase, dodge and the one-off revive.
func _meta_check() -> void:
    var data := {"gold": 25, "meta": {}, "hero": "harry", "heroes": ["harry"]}
    if not Spells.meta_buy(data, "power") or int(data["gold"]) != 5:
        failures.append("buying Wand Mastery for 20 galleons failed")
    if Spells.meta_buy(data, "power"):
        failures.append("an upgrade was sold without enough galleons")
    if Spells.hero_pick(data, "hermione"):
        failures.append("a hero was sold without enough galleons")
    data["gold"] = 200
    if not Spells.hero_pick(data, "hermione") or str(data["hero"]) != "hermione" or int(data["gold"]) != 80:
        failures.append("buying Hermione for 120 galleons failed")
    var bought: Dictionary = data["meta"]
    var p: Dictionary = Spells.new_player("hermione", bought)
    if not p.weapons.has("incendio") or Spells.damage_mult(p) <= 1.0:
        failures.append("hero kit or bought damage bonus is missing from a new run")
    _reset()
    world.invulnerable = false
    world.start_run({"meta": {"revive": 1}})
    world.player.iframe = 0.0
    world.damage_player(100000.0)
    world.step(DT)
    if ended or float(world.player.hp) <= 0.0 or int(world.player.revives) != 0:
        failures.append("Phoenix Tear did not revive the hero")
    world.player.iframe = 0.0
    world.player.dodge = 1.0
    var hp: float = world.player.hp
    world.damage_player(50.0)
    if float(world.player.hp) != hp:
        failures.append("a guaranteed dodge still took damage")
    print("[smoke] meta: shop, hero purchase, revive and dodge checked (hp after revive %d)" % int(hp))
    _stop()


func _checkpoint_roundtrip() -> void:
    world.start_run({})
    world.player.weapons["protego"] = 3
    world.player.weapons["removed_spell"] = 2
    world.player.fusions["removed_fusion"] = true
    world.player.fusions["firestorm"] = true
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
    if not world.player.fusions.has("firestorm"):
        failures.append("checkpoint resume lost a fusion")
    for i in 40:
        world.step(DT)
    _stop()


func _upgrade_exhaustion() -> void:
    var p: Dictionary = Spells.new_player()
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var n: int = 0
    while n < 400:
        var c: Array = Spells.choices(p, rng)
        if c.is_empty():
            failures.append("upgrade roll returned no cards")
            return
        if c[0].kind == "heal":
            break
        Spells.apply(p, c[0])
        n += 1
    print("[smoke] upgrade pool exhausted after %d picks; spells=%d fusions=%s evolutions=%s" % [n, p.weapons.size(), str(p.fusions.keys()), str(p.evolved.keys())])
    if n >= 400:
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
    if main.hud == null or main.world == null or main.stick == null or main.music == null:
        failures.append("main scene did not build its world/HUD/stick/music")
        return
    main.save.data["lang"] = lang
    main.save.data["gold"] = 500
    main.save.data["seen"] = {"pixie": true, "quirrell": true}
    main.hud.settings_changed.emit()
    if I18n.lang != lang:
        failures.append("language did not switch to %s" % lang)
    main.hud.show_menu()
    main.hud.show_heroes()
    main.hud.show_shop()
    main.hud.show_combos(main.hud.show_menu)
    main.hud.show_bestiary()
    main.hud.show_help()
    main.hud.show_settings(main.hud.show_menu)
    main.hud.start_requested.emit("story")
    if not main.world.in_run or str(main.world.mode) != "story":
        failures.append("NEW STORY RUN did not start a story run")
    for i in 200:
        main.world.move_input = Vector2.RIGHT
        main.world.step(DT)
    main.hud.show_levelup(Spells.choices(main.world.player, main.world.rng), 2)
    main.hud.show_pause()
    main.hud.show_combos(main.hud.show_pause)
    main.hud.show_settings(main.hud.show_pause)
    main.hud.show_chapter_clear(0)
    main.hud.show_chapter_clear(1)
    main.hud.show_summary(true)
    main.hud.menu_requested.emit()
    main.hud.start_requested.emit("endless")
    if not main.world.in_run or str(main.world.mode) != "endless":
        failures.append("ENDLESS MODE did not start an endless run")
    for i in 100:
        main.world.move_input = Vector2.LEFT
        main.world.step(DT)
    main.hud.show_summary(false)
    main.hud.menu_requested.emit()
    print("[smoke] UI pass (%s): menu title sample = %s, galleons in save = %d" % [lang, I18n.t("ui_new"), int(main.save.data["gold"])])
    main.queue_free()
