extends RefCounted
## Enemy and boss archetypes plus the factory that turns them into runtime dictionaries.

const HOSTILE := Color("ff7a2a")
const CURSE := Color("5de46a")

# ai: chase | weave | ranged | charge. look: which code-drawn sprite art.gd uses.
const TYPES := {
    "cauldron": {"hp": 16.0, "speed": 44.0, "r": 8.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "blob", "col": Color("2b2a2e"), "col2": Color("7be06a")},
    "pixie": {"hp": 7.0, "speed": 86.0, "r": 5.0, "dmg": 4.0, "xp": 1, "ai": "weave", "look": "pixie", "col": Color("9ce8ec"), "col2": Color("d1ffff")},
    "display": {"hp": 46.0, "speed": 30.0, "r": 10.0, "dmg": 10.0, "xp": 3, "ai": "chase", "look": "box", "col": Color("916a46"), "col2": Color("d39b4d")},
    "masked": {"hp": 24.0, "speed": 38.0, "r": 8.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "wizard", "col": Color("2a2230"), "col2": Color("ff7a2a")},
    "armor": {"hp": 60.0, "speed": 28.0, "r": 10.0, "dmg": 11.0, "xp": 3, "ai": "chase", "look": "armor", "col": Color("5b5e59"), "col2": Color("eecc63")},
    "book": {"hp": 12.0, "speed": 78.0, "r": 6.0, "dmg": 5.0, "xp": 1, "ai": "weave", "look": "box", "col": Color("6b3a2e"), "col2": Color("e6d7a8")},
    "portrait": {"hp": 30.0, "speed": 26.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "box", "col": Color("3b4a5a"), "col2": Color("c9a24c")},
    "spider": {"hp": 18.0, "speed": 70.0, "r": 7.0, "dmg": 7.0, "xp": 1, "ai": "chase", "look": "spider", "col": Color("493431"), "col2": Color("5a3737")},
    "dementor": {"hp": 55.0, "speed": 36.0, "r": 10.0, "dmg": 12.0, "xp": 4, "ai": "weave", "look": "dementor", "col": Color("141a20"), "col2": Color("a4bfce")},
    "plant": {"hp": 40.0, "speed": 14.0, "r": 9.0, "dmg": 8.0, "xp": 3, "ai": "ranged", "look": "plant", "col": Color("35592f"), "col2": Color("b6d65a")},
    "centaur": {"hp": 70.0, "speed": 48.0, "r": 10.0, "dmg": 14.0, "xp": 5, "ai": "charge", "look": "beast", "col": Color("6b5a44"), "col2": Color("b3a887")},
    "bludger": {"hp": 26.0, "speed": 60.0, "r": 6.0, "dmg": 12.0, "xp": 2, "ai": "charge", "look": "ball", "col": Color("2a2422"), "col2": Color("8a7f72")},
    "dummy": {"hp": 85.0, "speed": 26.0, "r": 10.0, "dmg": 10.0, "xp": 4, "ai": "chase", "look": "box", "col": Color("7a6a4a"), "col2": Color("d8cb91")},
    "flier": {"hp": 34.0, "speed": 58.0, "r": 8.0, "dmg": 9.0, "xp": 4, "ai": "ranged", "look": "wizard", "col": Color("3a2f4a"), "col2": Color("ff7a2a")},
    "inferi": {"hp": 26.0, "speed": 74.0, "r": 7.0, "dmg": 9.0, "xp": 1, "ai": "chase", "look": "inferi", "col": Color("58755c"), "col2": Color("9cb275")},
    "deatheater": {"hp": 60.0, "speed": 40.0, "r": 8.0, "dmg": 13.0, "xp": 5, "ai": "ranged", "look": "wizard", "col": Color("171a1c"), "col2": Color("5de46a"), "bolt": Color("5de46a")},
    "echo": {"hp": 30.0, "speed": 82.0, "r": 7.0, "dmg": 8.0, "xp": 2, "ai": "weave", "look": "echo", "col": Color("6fa8c8"), "col2": Color("c4e8e7")},
    "construct": {"hp": 130.0, "speed": 34.0, "r": 12.0, "dmg": 16.0, "xp": 7, "ai": "charge", "look": "armor", "col": Color("4a4436"), "col2": Color("d6b85a")},
}

# patterns[phase] lists the attacks a boss cycles through; phases switch at 66% and 33% health.
const BOSSES := {
    "warden": {
        "name": "The Alley Warden", "hp": 1500.0, "speed": 40.0, "r": 20.0, "dmg": 16.0, "look": "armor",
        "col": Color("4f4a42"), "col2": Color("eecc63"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.5, "patronus_weak": false,
        "patterns": [["ring", "charge"], ["ring", "fan", "charge"], ["ring", "summon", "fan"]],
    },
    "sentinel": {
        "name": "The Stone Sentinel", "hp": 2600.0, "speed": 30.0, "r": 24.0, "dmg": 20.0, "look": "armor",
        "col": Color("6a6d66"), "col2": Color("c4a149"), "bolt": Color("ff7a2a"), "tell": 1.0, "rest": 1.4, "patronus_weak": false,
        "patterns": [["fan", "slam"], ["fan", "slam", "summon"], ["slam", "fan", "slam", "ring"]],
    },
    "aragog": {
        "name": "Aragog", "hp": 4000.0, "speed": 46.0, "r": 26.0, "dmg": 22.0, "look": "spider",
        "col": Color("493431"), "col2": Color("704038"), "bolt": Color("ff7a2a"), "tell": 0.95, "rest": 1.3, "patronus_weak": true,
        "patterns": [["web", "ring"], ["web", "charge", "ring"], ["summon", "web", "ring", "charge"]],
    },
    "snitch": {
        "name": "The Snitch Storm", "hp": 5500.0, "speed": 70.0, "r": 16.0, "dmg": 24.0, "look": "snitch",
        "col": Color("d9b23c"), "col2": Color("fff0a8"), "bolt": Color("ffb020"), "tell": 0.9, "rest": 1.2, "patronus_weak": false,
        "patterns": [["spin", "charge"], ["spin", "charge", "fan"], ["spin", "summon", "charge"]],
    },
    "hex": {
        "name": "The Hex Disturbance", "hp": 8000.0, "speed": 34.0, "r": 28.0, "dmg": 26.0, "look": "hex",
        "col": Color("15191d"), "col2": Color("47ed5b"), "bolt": Color("5de46a"), "tell": 0.9, "rest": 1.2, "patronus_weak": false,
        "patterns": [["fan", "fan", "summon"], ["ring", "spin", "fan"], ["core", "fan", "ring"]],
    },
}


static func _base(id: int, type: String, pos: Vector2) -> Dictionary:
    return {
        "id": id, "type": type, "pos": pos, "kb": Vector2.ZERO, "face": Vector2.DOWN, "dir": Vector2.DOWN,
        "t": 0.0, "flash": 0.0, "stun": 0.0, "slow": 0.0, "weak": 0.0, "disarm": 0.0,
        "cd": 1.5, "shot_cd": 2.8, "state": "", "state_t": 0.0, "boss": false, "elite": false,
    }


static func make(type: String, pos: Vector2, id: int, hp_mult: float, elite: bool) -> Dictionary:
    var d: Dictionary = TYPES[type]
    var e: Dictionary = _base(id, type, pos)
    var m: float = hp_mult * (6.0 if elite else 1.0)
    e["hp"] = d.hp * m
    e["max_hp"] = d.hp * m
    e["speed"] = d.speed
    e["r"] = d.r * (1.4 if elite else 1.0)
    e["dmg"] = d.dmg * (1.5 if elite else 1.0)
    e["xp"] = d.xp * (8 if elite else 1)
    e["ai"] = d.ai
    e["look"] = d.look
    e["col"] = d.col
    e["col2"] = d.col2
    e["bolt"] = d.get("bolt", HOSTILE)
    e["elite"] = elite
    return e


static func make_boss(key: String, pos: Vector2, id: int) -> Dictionary:
    var d: Dictionary = BOSSES[key]
    var e: Dictionary = _base(id, key, pos)
    e["hp"] = d.hp
    e["max_hp"] = d.hp
    e["speed"] = d.speed
    e["r"] = d.r
    e["dmg"] = d.dmg
    e["xp"] = 0
    e["ai"] = "boss"
    e["look"] = d.look
    e["col"] = d.col
    e["col2"] = d.col2
    e["bolt"] = d.bolt
    e["boss"] = true
    e["name"] = d.name
    e["patterns"] = d.patterns
    e["tell"] = d.tell
    e["rest"] = d.rest
    e["patronus_weak"] = d.patronus_weak
    e["pat"] = ""
    e["gap"] = 0.0
    e["mark"] = pos
    e["repeat"] = 0
    e["phase"] = 0
    e["cd"] = 2.0
    return e
