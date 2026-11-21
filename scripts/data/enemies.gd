extends RefCounted
## Enemy and boss archetypes plus the factory that turns them into runtime dictionaries.
## Boss display names live in i18n.gd as bo_<key>.

const HOSTILE := Color("ff7a2a")
const CURSE := Color("5de46a")

# ai: chase | weave | ranged | charge. look: which code-drawn sprite art.gd uses.
# fly: hovers above the ground. dark: takes double damage from Lumos Solem.
const TYPES := {
    "cauldron": {"hp": 11.0, "speed": 44.0, "r": 8.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "blob", "col": Color("3a3840"), "col2": Color("7be06a")},
    "pixie": {"hp": 7.0, "speed": 86.0, "r": 5.0, "dmg": 4.0, "xp": 1, "ai": "weave", "look": "pixie", "fly": true, "col": Color("7ad8e8"), "col2": Color("d1ffff")},
    "display": {"hp": 46.0, "speed": 30.0, "r": 10.0, "dmg": 10.0, "xp": 3, "ai": "chase", "look": "box", "col": Color("916a46"), "col2": Color("d39b4d")},
    "masked": {"hp": 24.0, "speed": 38.0, "r": 8.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "wizard", "col": Color("3a2e44"), "col2": Color("ff7a2a")},
    "armor": {"hp": 60.0, "speed": 28.0, "r": 10.0, "dmg": 11.0, "xp": 3, "ai": "chase", "look": "armor", "col": Color("7a7e78"), "col2": Color("eecc63")},
    "book": {"hp": 12.0, "speed": 78.0, "r": 6.0, "dmg": 5.0, "xp": 1, "ai": "weave", "look": "box", "fly": true, "col": Color("7b3a2e"), "col2": Color("e6d7a8")},
    "portrait": {"hp": 30.0, "speed": 26.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "box", "col": Color("3b4a5a"), "col2": Color("c9a24c")},
    "spider": {"hp": 18.0, "speed": 70.0, "r": 7.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "spider", "dark": true, "col": Color("5a3e3a"), "col2": Color("7a4a44")},
    "dementor": {"hp": 55.0, "speed": 36.0, "r": 10.0, "dmg": 12.0, "xp": 4, "ai": "weave", "look": "dementor", "fly": true, "dark": true, "col": Color("1c242c"), "col2": Color("a4bfce")},
    "plant": {"hp": 40.0, "speed": 14.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "plant", "col": Color("35592f"), "col2": Color("b6d65a")},
    "centaur": {"hp": 70.0, "speed": 48.0, "r": 10.0, "dmg": 14.0, "xp": 5, "ai": "charge", "look": "beast", "col": Color("7b6a54"), "col2": Color("b3a887")},
    "bludger": {"hp": 26.0, "speed": 60.0, "r": 6.0, "dmg": 12.0, "xp": 2, "ai": "charge", "look": "ball", "fly": true, "col": Color("3a3432"), "col2": Color("8a7f72")},
    "dummy": {"hp": 85.0, "speed": 26.0, "r": 10.0, "dmg": 10.0, "xp": 4, "ai": "chase", "look": "box", "col": Color("7a6a4a"), "col2": Color("d8cb91")},
    "flier": {"hp": 34.0, "speed": 58.0, "r": 8.0, "dmg": 9.0, "xp": 4, "ai": "ranged", "look": "wizard", "fly": true, "col": Color("4a3f5a"), "col2": Color("ff7a2a")},
    "inferi": {"hp": 26.0, "speed": 74.0, "r": 7.0, "dmg": 9.0, "xp": 1, "ai": "chase", "look": "inferi", "dark": true, "col": Color("58755c"), "col2": Color("9cb275")},
    "deatheater": {"hp": 60.0, "speed": 40.0, "r": 8.0, "dmg": 13.0, "xp": 5, "ai": "ranged", "look": "wizard", "col": Color("22262a"), "col2": Color("5de46a"), "bolt": Color("5de46a")},
    "echo": {"hp": 30.0, "speed": 82.0, "r": 7.0, "dmg": 8.0, "xp": 2, "ai": "weave", "look": "echo", "fly": true, "col": Color("6fa8c8"), "col2": Color("c4e8e7")},
    "construct": {"hp": 130.0, "speed": 34.0, "r": 12.0, "dmg": 16.0, "xp": 7, "ai": "charge", "look": "armor", "col": Color("5a5446"), "col2": Color("d6b85a")},
    "snowman": {"hp": 30.0, "speed": 36.0, "r": 9.0, "dmg": 8.0, "xp": 2, "ai": "chase", "look": "blob", "col": Color("e4ecf0"), "col2": Color("ff9a4a")},
    "werewolf": {"hp": 60.0, "speed": 56.0, "r": 10.0, "dmg": 13.0, "xp": 5, "ai": "charge", "look": "beast", "dark": true, "col": Color("6a655a"), "col2": Color("b3a887")},
    "snatcher": {"hp": 44.0, "speed": 52.0, "r": 8.0, "dmg": 11.0, "xp": 4, "ai": "charge", "look": "wizard", "col": Color("4a3a2e"), "col2": Color("c8a070")},
    "snake": {"hp": 20.0, "speed": 80.0, "r": 6.0, "dmg": 8.0, "xp": 1, "ai": "weave", "look": "snake", "col": Color("5a8a5c"), "col2": Color("bdcb8e")},
    "spawn": {"hp": 95.0, "speed": 40.0, "r": 11.0, "dmg": 15.0, "xp": 6, "ai": "charge", "look": "snake", "col": Color("3e6a48"), "col2": Color("e6ce60")},
    "goblin": {"hp": 24.0, "speed": 84.0, "r": 6.0, "dmg": 9.0, "xp": 1, "ai": "chase", "look": "inferi", "col": Color("8a7a5a"), "col2": Color("d6b85a")},
    "cart": {"hp": 70.0, "speed": 50.0, "r": 10.0, "dmg": 16.0, "xp": 4, "ai": "charge", "look": "box", "col": Color("5a4a3a"), "col2": Color("a8a8b0")},
    "dragonling": {"hp": 60.0, "speed": 44.0, "r": 9.0, "dmg": 14.0, "xp": 5, "ai": "ranged", "look": "beast", "fly": true, "col": Color("8a3a2e"), "col2": Color("ffb04a")},
    "prisoner": {"hp": 34.0, "speed": 70.0, "r": 7.0, "dmg": 11.0, "xp": 2, "ai": "chase", "look": "inferi", "dark": true, "col": Color("6a6a72"), "col2": Color("a8a8b4")},
    "wraith": {"hp": 40.0, "speed": 86.0, "r": 7.0, "dmg": 10.0, "xp": 3, "ai": "weave", "look": "echo", "fly": true, "dark": true, "col": Color("8aa0c8"), "col2": Color("d8e4ff")},
    "peacock": {"hp": 22.0, "speed": 90.0, "r": 6.0, "dmg": 9.0, "xp": 2, "ai": "weave", "look": "pixie", "col": Color("e8e8f0"), "col2": Color("8ad0c0")},
}

# patterns[phase] lists the attacks a boss cycles through; phases switch at 66% and 33% health.
const BOSSES := {
    "warden": {"hp": 900.0, "speed": 40.0, "r": 20.0, "dmg": 16.0, "look": "armor", "col": Color("5f5a52"), "col2": Color("eecc63"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.5,
        "patterns": [["ring", "charge"], ["ring", "fan", "charge"], ["ring", "summon", "fan"]]},
    "greyback": {"hp": 1400.0, "speed": 62.0, "r": 18.0, "dmg": 18.0, "look": "beast", "dark": true, "col": Color("5a554a"), "col2": Color("c8bfa0"), "bolt": Color("ff7a2a"), "tell": 0.8, "rest": 1.1,
        "patterns": [["charge", "charge", "fan"], ["charge", "summon", "charge"], ["charge", "charge", "ring"]]},
    "sentinel": {"hp": 2000.0, "speed": 30.0, "r": 24.0, "dmg": 20.0, "look": "armor", "col": Color("7a7d76"), "col2": Color("c4a149"), "bolt": Color("ff7a2a"), "tell": 1.0, "rest": 1.4,
        "patterns": [["fan", "slam"], ["fan", "slam", "summon"], ["slam", "fan", "slam", "ring"]]},
    "snitch": {"hp": 2700.0, "speed": 70.0, "r": 16.0, "dmg": 22.0, "look": "snitch", "fly": true, "col": Color("d9b23c"), "col2": Color("fff0a8"), "bolt": Color("ffb020"), "tell": 0.9, "rest": 1.2,
        "patterns": [["spin", "charge"], ["spin", "charge", "fan"], ["spin", "summon", "charge"]]},
    "aragog": {"hp": 3500.0, "speed": 46.0, "r": 26.0, "dmg": 22.0, "look": "spider", "dark": true, "patronus_weak": true, "col": Color("5a403a"), "col2": Color("80483e"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.3,
        "patterns": [["web", "ring"], ["web", "charge", "ring"], ["summon", "web", "ring", "charge"]]},
    "basilisk": {"hp": 4400.0, "speed": 44.0, "r": 24.0, "dmg": 24.0, "look": "snake", "col": Color("4e7a52"), "col2": Color("e6ce60"), "bolt": Color("5de46a"), "tell": 0.95, "rest": 1.2,
        "patterns": [["fan", "charge"], ["fan", "summon", "charge"], ["spin", "fan", "charge"]]},
    "ironbelly": {"hp": 5400.0, "speed": 36.0, "r": 28.0, "dmg": 26.0, "look": "beast", "col": Color("7a7e86"), "col2": Color("ffb04a"), "bolt": Color("ff7a2a"), "tell": 1.0, "rest": 1.2,
        "patterns": [["breath", "slam"], ["breath", "fan", "slam"], ["breath", "breath", "ring"]]},
    "lord": {"hp": 6500.0, "speed": 40.0, "r": 24.0, "dmg": 26.0, "look": "dementor", "fly": true, "dark": true, "patronus_weak": true, "col": Color("141a22"), "col2": Color("a4bfce"), "bolt": Color("8ad0ff"), "tell": 0.9, "rest": 1.2,
        "patterns": [["web", "ring"], ["web", "summon", "fan"], ["blink", "ring", "web"]]},
    "bellatrix": {"hp": 7700.0, "speed": 60.0, "r": 12.0, "dmg": 28.0, "look": "wizard", "col": Color("1c1a22"), "col2": Color("5de46a"), "bolt": Color("5de46a"), "tell": 0.8, "rest": 1.0,
        "patterns": [["fan", "blink"], ["spin", "blink", "fan"], ["blink", "fan", "spin", "summon"]]},
    "hex": {"hp": 9500.0, "speed": 34.0, "r": 28.0, "dmg": 28.0, "look": "hex", "fly": true, "col": Color("15191d"), "col2": Color("47ed5b"), "bolt": Color("5de46a"), "tell": 0.9, "rest": 1.2,
        "patterns": [["fan", "fan", "summon"], ["ring", "spin", "blink"], ["core", "fan", "ring"]]},
}


static func _base(id: int, type: String, pos: Vector2, d: Dictionary) -> Dictionary:
    return {
        "id": id, "type": type, "pos": pos, "kb": Vector2.ZERO, "face": Vector2.DOWN, "dir": Vector2.DOWN,
        "t": 0.0, "flash": 0.0, "hold": 0.0, "burn_t": 0.0, "s": {}, "dead": false,
        "cd": 1.5, "shot_cd": 2.8, "state": "", "state_t": 0.0, "boss": false, "elite": false,
        "speed": d.speed, "ai": d.get("ai", "boss"), "look": d.look, "col": d.col, "col2": d.col2,
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
