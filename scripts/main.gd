extends Node
## Entry point: owns the world, HUD, joystick, audio and save data and wires them together.

const WorldScript = preload("res://scripts/game/world.gd")
const HudScript = preload("res://scripts/ui/hud.gd")
const StickScript = preload("res://scripts/ui/joystick.gd")
const SaveScript = preload("res://scripts/core/save.gd")
const SfxScript = preload("res://scripts/core/sfx.gd")
const I18n = preload("res://scripts/core/i18n.gd")
const Chapters = preload("res://scripts/data/chapters.gd")

var save
var sfx
var world
var hud
var stick


func _ready() -> void:
    get_tree().quit_on_go_back = false
    save = SaveScript.new()
    save.load_data()
    # First launch follows the device language; afterwards the saved choice wins.
    if str(save.data.get("lang", "")) == "":
        save.data["lang"] = I18n.system_lang()
    I18n.lang = str(save.data["lang"])
    sfx = SfxScript.new()
    add_child(sfx)
    world = WorldScript.new()
    add_child(world)
    var layer := CanvasLayer.new()
    add_child(layer)
    stick = StickScript.new()
    layer.add_child(stick)
    hud = HudScript.new()
    hud.setup(world, save)
    layer.add_child(hud)

    world.level_up.connect(_on_level_up)
    world.chapter_cleared.connect(_on_chapter_cleared)
    world.run_ended.connect(_on_run_ended)
    world.boss_arrived.connect(_on_boss)
    world.player_hurt.connect(_on_hurt)
    world.sound.connect(_on_sound)
    hud.start_requested.connect(_on_start)
    hud.upgrade_chosen.connect(_on_upgrade)
    hud.continue_requested.connect(_on_continue)
    hud.settings_changed.connect(_apply_settings)
    hud.pause_requested.connect(_on_pause)
    hud.resume_requested.connect(_on_resume)
    hud.menu_requested.connect(_on_menu)

    _apply_settings()
    hud.show_menu()


func _process(_delta: float) -> void:
    # One thumb on the stick is the whole control scheme; the keyboard is only a desktop test aid.
    var v: Vector2 = stick.vector
    if v == Vector2.ZERO:
        var right: bool = Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
        var left: bool = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
        var down: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
        var up: bool = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
        v = Vector2(float(right) - float(left), float(down) - float(up))
        if v.length() > 1.0:
            v = v.normalized()
    world.move_input = v
    stick.enabled = world.active


func _notification(what: int) -> void:
    # Android back button, app switch or lost focus pauses instead of quitting mid-fight.
    if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        if world != null and world.in_run and world.active:
            _on_pause()


func _apply_settings() -> void:
    var d: Dictionary = save.data
    I18n.lang = str(d.get("lang", "en"))
    stick.right_handed = bool(d.get("right_handed", true))
    stick.stick_size = float(d.get("stick_size", 56.0))
    stick.stick_opacity = float(d.get("stick_opacity", 0.5))
    stick.sensitivity = float(d.get("sensitivity", 1.0))
    stick.queue_redraw()
    sfx.enabled = bool(d.get("sound", true))


func _announce() -> void:
    var id: String = str(world.chapter.id)
    hud.show_banner(I18n.t("ch_" + id), I18n.t("cs_" + id))


func _on_start(resume: bool) -> void:
    hud.close_panel()
    stick.reset()
    var cp: Dictionary = save.data.get("checkpoint", {})
    if resume and not cp.is_empty():
        world.start_run(save.data, cp)
    else:
        save.data["checkpoint"] = {}
        world.start_run(save.data)
        save.data["runs"] = int(save.data["runs"]) + 1
    save.save_data()
    _announce()


func _on_level_up(choices: Array) -> void:
    stick.reset()
    sfx.play("level")
    hud.show_levelup(choices, int(world.player.level))


func _on_upgrade(choice: Dictionary) -> void:
    hud.close_panel()
    world.apply_upgrade(choice)


func _on_chapter_cleared(index: int) -> void:
    stick.reset()
    save.data["best_chapter"] = maxi(int(save.data["best_chapter"]), index + 1)
    save.data["checkpoint"] = world.checkpoint(index + 1)
    save.save_data()
    hud.show_chapter_clear(index)


func _on_continue() -> void:
    hud.close_panel()
    world.load_chapter(world.chapter_index + 1)
    _announce()


func _on_run_ended(victory: bool) -> void:
    stick.reset()
    var d: Dictionary = save.data
    d["best_kills"] = maxi(int(d["best_kills"]), int(world.kills))
    d["checkpoint"] = {}
    if victory:
        d["wins"] = int(d["wins"]) + 1
        d["best_chapter"] = Chapters.LIST.size()
    else:
        d["best_chapter"] = maxi(int(d["best_chapter"]), int(world.chapter_index))
    save.save_data()
    hud.show_summary(victory)


func _on_pause() -> void:
    if not world.active:
        return
    world.active = false
    stick.reset()
    hud.show_pause()


func _on_resume() -> void:
    hud.close_panel()
    world.active = true


func _on_menu() -> void:
    world.active = false
    world.in_run = false
    hud.show_menu()


func _on_boss(boss_key: String) -> void:
    hud.show_banner(I18n.t("bo_" + boss_key), I18n.t("ui_boss_sub"))
    sfx.play("warn")


func _on_hurt(_amount: float) -> void:
    if bool(save.data.get("vibration", true)):
        Input.vibrate_handheld(40)


func _on_sound(id: String) -> void:
    sfx.play(id)
