extends RefCounted
## Enemy and boss archetypes plus the factory that turns them into runtime dictionaries.
## Display names live in i18n.gd as en_<type> and bo_<key>.

const HOSTILE := Color("ff7a2a")

# ai: chase | weave | ranged | charge. look: code-drawn sprite in art.gd.
# spr: painted sprite (art/gen/mob_<spr>.png) used when it exists. fly: hovers. dark: weak to Lumos Solem.
const TYPES := {
    "cauldron": {"hp": 11.0, "speed": 44.0, "r": 8.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "blob", "spr": "cauldron", "col": Color("3a3840"), "col2": Color("7be06a")},
    "pixie": {"hp": 7.0, "speed": 86.0, "r": 5.0, "dmg": 4.0, "xp": 1, "ai": "weave", "look": "pixie", "spr": "sprite", "fly": true, "col": Color("7ad8e8"), "col2": Color("d1ffff")},
    "display": {"hp": 46.0, "speed": 30.0, "r": 10.0, "dmg": 10.0, "xp": 3, "ai": "chase", "look": "box", "spr": "mimic", "col": Color("916a46"), "col2": Color("d39b4d")},
    "masked": {"hp": 24.0, "speed": 38.0, "r": 8.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "wizard", "spr": "caster", "col": Color("3a2e44"), "col2": Color("ff7a2a")},
    "armor": {"hp": 60.0, "speed": 28.0, "r": 10.0, "dmg": 11.0, "xp": 3, "ai": "chase", "look": "armor", "spr": "armor", "col": Color("7a7e78"), "col2": Color("eecc63")},
    "book": {"hp": 12.0, "speed": 78.0, "r": 6.0, "dmg": 5.0, "xp": 1, "ai": "weave", "look": "box", "spr": "book", "fly": true, "col": Color("7b3a2e"), "col2": Color("e6d7a8")},
    "portrait": {"hp": 30.0, "speed": 26.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "box", "spr": "portrait", "col": Color("3b4a5a"), "col2": Color("c9a24c")},
    "spider": {"hp": 18.0, "speed": 70.0, "r": 7.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "spider", "spr": "spider", "dark": true, "col": Color("5a3e3a"), "col2": Color("7a4a44")},
    "dementor": {"hp": 55.0, "speed": 36.0, "r": 10.0, "dmg": 12.0, "xp": 4, "ai": "weave", "look": "dementor", "spr": "wraith", "fly": true, "dark": true, "col": Color("1c242c"), "col2": Color("a4bfce")},
    "plant": {"hp": 40.0, "speed": 14.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "plant", "spr": "plant", "col": Color("35592f"), "col2": Color("b6d65a")},
    "centaur": {"hp": 70.0, "speed": 48.0, "r": 10.0, "dmg": 14.0, "xp": 5, "ai": "charge", "look": "beast", "spr": "centaur", "col": Color("7b6a54"), "col2": Color("b3a887")},
    "bludger": {"hp": 26.0, "speed": 60.0, "r": 6.0, "dmg": 12.0, "xp": 2, "ai": "charge", "look": "ball", "spr": "ball", "fly": true, "col": Color("3a3432"), "col2": Color("8a7f72")},
    "dummy": {"hp": 85.0, "speed": 26.0, "r": 10.0, "dmg": 10.0, "xp": 4, "ai": "chase", "look": "box", "spr": "automaton", "col": Color("7a6a4a"), "col2": Color("d8cb91")},
    "flier": {"hp": 34.0, "speed": 58.0, "r": 8.0, "dmg": 9.0, "xp": 4, "ai": "ranged", "look": "wizard", "spr": "caster", "fly": true, "col": Color("4a3f5a"), "col2": Color("ff7a2a")},
    "inferi": {"hp": 26.0, "speed": 74.0, "r": 7.0, "dmg": 9.0, "xp": 1, "ai": "chase", "look": "inferi", "spr": "drowned", "dark": true, "col": Color("58755c"), "col2": Color("9cb275")},
    "deatheater": {"hp": 60.0, "speed": 40.0, "r": 8.0, "dmg": 13.0, "xp": 5, "ai": "ranged", "look": "wizard", "spr": "caster", "col": Color("22262a"), "col2": Color("5de46a"), "bolt": Color("5de46a")},
    "echo": {"hp": 30.0, "speed": 82.0, "r": 7.0, "dmg": 8.0, "xp": 2, "ai": "weave", "look": "echo", "spr": "", "fly": true, "col": Color("6fa8c8"), "col2": Color("c4e8e7")},
    "construct": {"hp": 130.0, "speed": 34.0, "r": 12.0, "dmg": 16.0, "xp": 7, "ai": "charge", "look": "armor", "spr": "automaton", "col": Color("5a5446"), "col2": Color("d6b85a")},
    "snowman": {"hp": 30.0, "speed": 36.0, "r": 9.0, "dmg": 8.0, "xp": 2, "ai": "chase", "look": "blob", "spr": "", "col": Color("e4ecf0"), "col2": Color("ff9a4a")},
    "werewolf": {"hp": 60.0, "speed": 56.0, "r": 10.0, "dmg": 13.0, "xp": 5, "ai": "charge", "look": "beast", "spr": "", "dark": true, "col": Color("6a655a"), "col2": Color("b3a887")},
    "snatcher": {"hp": 44.0, "speed": 52.0, "r": 8.0, "dmg": 11.0, "xp": 4, "ai": "charge", "look": "wizard", "spr": "caster", "col": Color("4a3a2e"), "col2": Color("c8a070")},
    "snake": {"hp": 20.0, "speed": 80.0, "r": 6.0, "dmg": 8.0, "xp": 1, "ai": "weave", "look": "snake", "spr": "serpent", "col": Color("5a8a5c"), "col2": Color("bdcb8e")},
    "spawn": {"hp": 95.0, "speed": 40.0, "r": 11.0, "dmg": 15.0, "xp": 6, "ai": "charge", "look": "snake", "spr": "serpent", "col": Color("3e6a48"), "col2": Color("e6ce60")},
    "prisoner": {"hp": 34.0, "speed": 70.0, "r": 7.0, "dmg": 11.0, "xp": 2, "ai": "chase", "look": "inferi", "spr": "drowned", "dark": true, "col": Color("6a6a72"), "col2": Color("a8a8b4")},
    "wraith": {"hp": 40.0, "speed": 86.0, "r": 7.0, "dmg": 10.0, "xp": 3, "ai": "weave", "look": "echo", "spr": "wraith", "fly": true, "dark": true, "col": Color("8aa0c8"), "col2": Color("d8e4ff")},
    "frostwitch": {"hp": 40.0, "speed": 40.0, "r": 8.0, "dmg": 11.0, "xp": 4, "ai": "ranged", "look": "wizard", "spr": "frostwitch", "col": Color("8ab4d8"), "col2": Color("d8f0ff"), "bolt": Color("ff9a4a")},
    "cultist": {"hp": 44.0, "speed": 40.0, "r": 8.0, "dmg": 12.0, "xp": 4, "ai": "ranged", "look": "wizard", "spr": "caster", "col": Color("2e4a3a"), "col2": Color("54e39a"), "bolt": Color("5de46a")},
    "carriage": {"hp": 80.0, "speed": 50.0, "r": 11.0, "dmg": 16.0, "xp": 5, "ai": "charge", "look": "box", "spr": "carriage", "dark": true, "col": Color("3a3448"), "col2": Color("c45cff")},
    "owl": {"hp": 30.0, "speed": 88.0, "r": 6.0, "dmg": 10.0, "xp": 2, "ai": "weave", "look": "pixie", "spr": "owl", "fly": true, "col": Color("8a7a5a"), "col2": Color("d8c477")},
    "guard": {"hp": 90.0, "speed": 34.0, "r": 10.0, "dmg": 14.0, "xp": 5, "ai": "chase", "look": "armor", "spr": "guard", "col": Color("4c5a63"), "col2": Color("8edee9")},
    "gargoyle": {"hp": 70.0, "speed": 52.0, "r": 9.0, "dmg": 15.0, "xp": 5, "ai": "charge", "look": "beast", "spr": "gargoyle", "fly": true, "col": Color("6a6a7a"), "col2": Color("9c86ff")},
}

# patterns[phase] lists the attacks a boss cycles through; phases switch at 66% and 33% health.
# The first five are chapter guardians, the last five are the story bosses fought in their own arenas.
# Health follows the bot log of CI run 44913528986: a maxed build stops growing around stage 6, so
# the curve is flat after that instead of doubling (see HANDOFF.md, "Balance").
const BOSSES := {
    "warden": {"hp": 480.0, "speed": 40.0, "r": 20.0, "dmg": 16.0, "look": "armor", "col": Color("5f5a52"), "col2": Color("eecc63"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.5,
        "patterns": [["ring", "charge"], ["ring", "fan", "charge"], ["ring", "summon", "fan"]]},
    "aragog": {"hp": 2400.0, "speed": 46.0, "r": 26.0, "dmg": 20.0, "look": "spider", "spr": "", "dark": true, "patronus_weak": true, "col": Color("5a403a"), "col2": Color("80483e"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.3,
        "patterns": [["web", "ring"], ["web", "charge", "ring"], ["summon", "web", "ring", "charge"]]},
    "hex": {"hp": 3000.0, "speed": 34.0, "r": 26.0, "dmg": 22.0, "look": "hex", "fly": true, "col": Color("15191d"), "col2": Color("47ed5b"), "bolt": Color("5de46a"), "tell": 0.9, "rest": 1.2,
        "patterns": [["fan", "fan", "summon"], ["ring", "spin", "blink"], ["core", "fan", "ring"]]},
    "idol": {"hp": 2800.0, "speed": 30.0, "r": 24.0, "dmg": 24.0, "look": "armor", "col": Color("4e6a52"), "col2": Color("e6ce60"), "bolt": Color("5de46a"), "tell": 1.0, "rest": 1.3,
        "patterns": [["fan", "slam"], ["gaze", "slam", "summon"], ["slam", "gaze", "fan", "ring"]]},
    "greyback": {"hp": 2600.0, "speed": 64.0, "r": 18.0, "dmg": 26.0, "look": "beast", "dark": true, "col": Color("5a554a"), "col2": Color("c8bfa0"), "bolt": Color("ff7a2a"), "tell": 0.8, "rest": 1.1,
        "patterns": [["charge", "charge", "fan"], ["charge", "summon", "charge"], ["charge", "charge", "ring"]]},
    "quirrell": {"hp": 1500.0, "speed": 46.0, "r": 14.0, "dmg": 18.0, "look": "wizard", "spr": "quirrell", "col": Color("4a3a5a"), "col2": Color("c8a0ff"), "bolt": Color("c45cff"), "tell": 0.9, "rest": 1.3,
        "patterns": [["fan", "twin"], ["twin", "ring", "blink"], ["twin", "spin", "blink", "summon"]]},
    "basilisk": {"hp": 2900.0, "speed": 48.0, "r": 24.0, "dmg": 22.0, "look": "snake", "spr": "basilisk", "col": Color("4e7a52"), "col2": Color("e6ce60"), "bolt": Color("5de46a"), "tell": 0.95, "rest": 1.2,
        "patterns": [["gaze", "charge"], ["gaze", "web", "charge"], ["gaze", "fan", "charge", "summon"]]},
    "dementor": {"hp": 3300.0, "speed": 42.0, "r": 22.0, "dmg": 24.0, "look": "dementor", "spr": "dementor", "fly": true, "dark": true, "patronus_weak": true, "col": Color("141a22"), "col2": Color("a4bfce"), "bolt": Color("8ad0ff"), "tell": 0.9, "rest": 1.2,
        "patterns": [["web", "ring"], ["web", "summon", "fan"], ["blink", "ring", "web", "spin"]]},
    "nagini": {"hp": 3600.0, "speed": 62.0, "r": 20.0, "dmg": 26.0, "look": "snake", "spr": "nagini", "dark": true, "col": Color("3a4a3a"), "col2": Color("9adf7a"), "bolt": Color("5de46a"), "tell": 0.8, "rest": 1.0,
        "patterns": [["charge", "fan"], ["charge", "charge", "web"], ["charge", "summon", "charge", "ring"]]},
    "voldemort": {"hp": 5200.0, "speed": 50.0, "r": 14.0, "dmg": 28.0, "look": "wizard", "spr": "voldemort", "dark": true, "col": Color("1c1a22"), "col2": Color("5de46a"), "bolt": Color("5de46a"), "tell": 0.8, "rest": 1.0,
        "patterns": [["fan", "blink", "twin"], ["spin", "blink", "gaze", "summon"], ["core", "blink", "twin", "breath", "spin"]]},
}


static func _base(id: int, type: String, pos: Vector2, d: Dictionary) -> Dictionary:
    return {
        "id": id, "type": type, "pos": pos, "kb": Vector2.ZERO, "face": Vector2.DOWN, "dir": Vector2.DOWN,
        "t": 0.0, "flash": 0.0, "hold": 0.0, "burn_t": 0.0, "s": {}, "dead": false,
        "cd": 1.5, "shot_cd": 2.8, "state": "", "state_t": 0.0, "boss": false, "elite": false,
        "speed": d.speed, "ai": d.get("ai", "boss"), "look": d.look, "spr": d.get("spr", ""), "col": d.col, "col2": d.col2,
        "bolt": d.get("bolt", HOSTILE), "fly": d.get("fly", false), "dark": d.get("dark", false),
    }


static func make(type: String, pos: Vector2, id: int, hp_mult: float, elite: bool) -> Dictionary:
    var d: Dictionary = TYPES[type]
    var e: Dictionary = _base(id, type, pos, d)
    var m: float = hp_mult * (6.0 if elite else 1.0)
    e["hp"] = d.hp * m
    e["max_hp"] = d.hp * m
    e["r"] = d.r * (1.4 if elite else 1.0)
    e["dmg"] = d.dmg * (1.5 if elite else 1.0)
    e["xp"] = d.xp * (8 if elite else 1)
    e["elite"] = elite
    return e


static func make_boss(key: String, pos: Vector2, id: int) -> Dictionary:
    var d: Dictionary = BOSSES[key]
    var e: Dictionary = _base(id, key, pos, d)
    e["hp"] = d.hp
    e["max_hp"] = d.hp
    e["r"] = d.r
    e["dmg"] = d.dmg
    e["xp"] = 0
    e["boss"] = true
    e["patterns"] = d.patterns
    e["tell"] = d.tell
    e["rest"] = d.rest
    e["patronus_weak"] = d.get("patronus_weak", false)
    e["pat"] = ""
    e["gap"] = 0.0
    e["mark"] = pos
    e["repeat"] = 0
    e["phase"] = 0
    e["cd"] = 2.0
    return e
