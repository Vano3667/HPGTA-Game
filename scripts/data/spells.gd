extends RefCounted
## Spells, fusions, passives, evolutions, synergies, heroes and meta upgrades, plus the upgrade rules.
## Spells are data-driven: arsenal.gd only knows a handful of archetypes ("kind").
## Display names live in i18n.gd (sp_/sd_, fu_/fd_, pa_/pd_, ev_/ed_, sy_/sx_, he_/hd_, me_/md_);
## newer rows (x_) live in i18n2.gd.

const I18n = preload("res://scripts/core/i18n.gd")
const I18n2 = preload("res://scripts/core/i18n2.gd")

## Highest level of a spell and of a talisman, and the spell level an evolution needs.
const MAX_LEVEL := 7
const PASSIVE_MAX := 5
const EVOLVE_LEVEL := 5
const WEAPON_SLOTS := 8
const PASSIVE_SLOTS := 6
## Repeatable cards that fill the level-up choice once the regular upgrades run out.
const BOONS := ["power", "tempo", "vigor", "frog"]

# kind: bolt | nova | zone | strike | beam | orbit | stag | familiar
# el: element used by synergies. st/sd: status applied and its duration.
# d damage, cd cooldown, n count (grow: +1 at levels 3, 5 and 7), r radius, sp speed, kb knockback.
const WEAPONS := {
    "wand": {"kind": "bolt", "el": "arcane", "d": 10.0, "cd": 0.68, "n": 1, "grow": true, "sp": 340.0, "col": Color("67dcf4"), "snd": "wand"},
    "stupefy": {"kind": "bolt", "el": "force", "d": 22.0, "cd": 3.0, "n": 1, "grow": true, "spread": 0.22, "sp": 260.0, "sr": 5.0, "st": "stun", "sd": 1.0, "tgt": "tough", "col": Color("ff6a7a"), "snd": "stupefy"},
    "protego": {"kind": "orbit", "el": "light", "d": 6.0, "cd": 1.0, "col": Color("67dcf4"), "snd": ""},
    "patronus": {"kind": "stag", "el": "light", "d": 38.0, "cd": 9.5, "rng": 340.0, "st": "mark", "sd": 4.0, "col": Color("bfe9ff"), "snd": "patronus"},
    "incendio": {"kind": "nova", "el": "fire", "d": 18.0, "cd": 5.0, "r": 58.0, "kb": 110.0, "st": "burn", "sd": 3.0, "col": Color("ff9a3c"), "snd": "fire"},
    "glacius": {"kind": "zone", "el": "ice", "d": 3.0, "cd": 6.2, "r": 50.0, "life": 3.2, "st": "chill", "sd": 0.8, "rng": 240.0, "col": Color("8fdcff"), "snd": "ice"},
    "expelliarmus": {"kind": "bolt", "el": "force", "d": 13.0, "cd": 2.5, "sp": 230.0, "sr": 5.0, "life": 1.8, "turn": 5.0, "curve": true, "st": "disarm", "sd": 3.0, "tgt": "ranged", "col": Color("f0d278"), "snd": "wand"},
    "lumos": {"kind": "familiar", "el": "light", "d": 5.0, "cd": 0.95, "sp": 300.0, "sr": 3.0, "life": 0.9, "rng": 220.0, "st": "mark", "sd": 1.5, "col": Color("fff3c0"), "snd": ""},
    "bombarda": {"kind": "strike", "el": "force", "d": 34.0, "cd": 4.2, "r": 46.0, "kb": 150.0, "delay": 0.45, "tgt": "tough", "col": Color("ffb35a"), "snd": "burst"},
    "aguamenti": {"kind": "beam", "el": "water", "d": 9.0, "cd": 2.2, "rng": 170.0, "w": 16.0, "kb": 90.0, "st": "wet", "sd": 4.0, "col": Color("4aa8ff"), "snd": "ice"},
    "baubillious": {"kind": "strike", "el": "lightning", "d": 26.0, "cd": 2.8, "r": 18.0, "delay": 0.12, "n": 1, "grow": true, "st": "stun", "sd": 0.3, "tgt": "rand", "col": Color("fff27a"), "snd": "stupefy"},
    "confringo": {"kind": "bolt", "el": "fire", "d": 16.0, "cd": 3.4, "sp": 230.0, "sr": 5.0, "boom": 40.0, "st": "burn", "sd": 3.0, "col": Color("ff7a3c"), "snd": "fire"},
    "diffindo": {"kind": "bolt", "el": "arcane", "d": 14.0, "cd": 2.6, "sp": 300.0, "sr": 11.0, "life": 0.7, "pierce": 99, "col": Color("c9f2ff"), "snd": "wand"},
    "depulso": {"kind": "nova", "el": "force", "d": 8.0, "cd": 4.6, "r": 70.0, "kb": 260.0, "st": "stun", "sd": 0.4, "col": Color("d8c8ff"), "snd": "burst"},
    "leviosa": {"kind": "zone", "el": "arcane", "d": 0.5, "cd": 7.0, "r": 44.0, "life": 1.8, "st": "levitate", "sd": 0.7, "rng": 220.0, "col": Color("d9c2ff"), "snd": "level"},
    "descendo": {"kind": "strike", "el": "force", "d": 30.0, "cd": 4.8, "r": 50.0, "delay": 0.35, "st": "stun", "sd": 0.3, "tgt": "tough", "col": Color("c8b8a0"), "snd": "burst"},
    "petrificus": {"kind": "bolt", "el": "arcane", "d": 12.0, "cd": 4.5, "sp": 280.0, "sr": 5.0, "st": "petrify", "sd": 2.4, "tgt": "tough", "col": Color("b8c4c8"), "snd": "stupefy"},
    "impedimenta": {"kind": "nova", "el": "ice", "d": 4.0, "cd": 3.8, "r": 80.0, "st": "chill", "sd": 2.2, "col": Color("9ad0ff"), "snd": "ice"},
    "reducto": {"kind": "bolt", "el": "force", "d": 44.0, "cd": 3.6, "sp": 320.0, "sr": 5.0, "elite": 1.6, "tgt": "tough", "col": Color("9fe0ff"), "snd": "stupefy"},
    "avis": {"kind": "bolt", "el": "nature", "d": 8.0, "cd": 3.0, "n": 3, "grow": true, "spread": 0.6, "sp": 210.0, "life": 2.2, "turn": 6.0, "tgt": "rand", "col": Color("ffe07a"), "snd": "gem"},
    "incarcerous": {"kind": "bolt", "el": "nature", "d": 6.0, "cd": 5.0, "sp": 240.0, "sr": 5.0, "boom": 36.0, "st": "root", "sd": 2.2, "col": Color("b08a5a"), "snd": "wand"},
    "solem": {"kind": "nova", "el": "light", "d": 14.0, "cd": 6.0, "r": 85.0, "st": "mark", "sd": 4.0, "bane": true, "col": Color("fff0a0"), "snd": "patronus"},
    "flagrate": {"kind": "zone", "el": "fire", "d": 5.0, "cd": 1.1, "r": 20.0, "life": 2.4, "st": "burn", "sd": 2.0, "tgt": "self", "col": Color("ff8a2a"), "snd": ""},
    "arresto": {"kind": "nova", "el": "arcane", "d": 0.5, "cd": 11.0, "r": 260.0, "st": "chill", "sd": 3.0, "col": Color("b8d8ff"), "snd": "ice"},
    "episkey": {"kind": "nova", "el": "light", "d": 0.0, "cd": 9.0, "r": 20.0, "heal": 6.0, "col": Color("9dffb0"), "snd": "level"},
    "retractum": {"kind": "zone", "el": "arcane", "d": 2.0, "cd": 6.5, "r": 70.0, "life": 1.6, "pull": 140.0, "st": "grouped", "sd": 1.0, "rng": 240.0, "col": Color("ffb86a"), "snd": "wand"},
    "riddikulus": {"kind": "nova", "el": "arcane", "d": 3.0, "cd": 7.5, "r": 90.0, "st": "fear", "sd": 2.2, "col": Color("ffa0e0"), "snd": "level"},
    "finite": {"kind": "nova", "el": "arcane", "d": 6.0, "cd": 6.0, "r": 120.0, "dispel": true, "col": Color("e8e8ff"), "snd": "ice"},
}

# Fusions: own every spell in "need" (at level 5 - number of spells, or higher) and a bonus spell
# is offered at the next level-up. It takes no slot and grows with the average level of its parts.
# Extra keys: also {status: seconds}, scorch (leaves burning ground), mend (heals the hero).
const FUSIONS := {
    "firestorm": {"need": ["incendio", "depulso"], "kind": "nova", "el": "fire", "d": 30.0, "cd": 5.5, "r": 105.0, "kb": 220.0, "st": "burn", "sd": 4.0, "col": Color("ff7a2a"), "snd": "fire"},
    "blizzard": {"need": ["glacius", "aguamenti"], "kind": "zone", "el": "ice", "d": 7.0, "cd": 7.0, "r": 85.0, "life": 4.0, "st": "wet", "sd": 2.0, "rng": 240.0, "col": Color("bfe9ff"), "snd": "ice"},
    "thunderbird": {"need": ["baubillious", "avis"], "kind": "bolt", "el": "lightning", "d": 16.0, "cd": 2.6, "n": 4, "spread": 0.5, "sp": 250.0, "life": 2.4, "turn": 7.0, "st": "stun", "sd": 0.5, "tgt": "rand", "col": Color("fff27a"), "snd": "stupefy"},
    "sunlance": {"need": ["lumos", "solem"], "kind": "beam", "el": "light", "d": 30.0, "cd": 3.0, "rng": 260.0, "w": 22.0, "st": "mark", "sd": 4.0, "col": Color("fff0a0"), "snd": "patronus"},
    "tempest": {"need": ["aguamenti", "baubillious", "depulso"], "kind": "strike", "el": "lightning", "d": 40.0, "cd": 3.2, "r": 40.0, "delay": 0.2, "n": 5, "st": "wet", "sd": 4.0, "tgt": "rand", "col": Color("9fd0ff"), "snd": "stupefy"},
    "prison": {"need": ["petrificus", "incarcerous", "leviosa"], "kind": "nova", "el": "arcane", "d": 12.0, "cd": 8.0, "r": 130.0, "st": "petrify", "sd": 2.6, "col": Color("b8c4c8"), "snd": "burst"},
    "phoenix": {"need": ["incendio", "confringo", "flagrate"], "kind": "strike", "el": "fire", "d": 60.0, "cd": 5.0, "r": 78.0, "delay": 0.5, "st": "burn", "sd": 4.0, "tgt": "tough", "scorch": true, "col": Color("ffb04a"), "snd": "fire"},
    "legion": {"need": ["patronus", "protego", "lumos", "solem"], "kind": "nova", "el": "light", "d": 55.0, "cd": 8.0, "r": 210.0, "st": "mark", "sd": 5.0, "bane": true, "mend": 6.0, "col": Color("bfe9ff"), "snd": "patronus"},
    "elements": {"need": ["incendio", "glacius", "aguamenti", "baubillious"], "kind": "nova", "el": "lightning", "d": 70.0, "cd": 9.0, "r": 190.0, "kb": 120.0, "st": "burn", "sd": 4.0, "also": {"wet": 4.0, "chill": 3.0}, "col": Color("e8d8ff"), "snd": "burst"},
}

const PASSIVES := ["focus", "haste", "boots", "vitality", "magnet", "ward"]

# An evolution is offered once its weapon is at EVOLVE_LEVEL and the passive is owned.
const EVOLUTIONS := {
    "chain": {"weapon": "wand", "passive": "focus"},
    "maxima": {"weapon": "protego", "passive": "ward"},
    "inferno": {"weapon": "incendio", "passive": "haste"},
}

# A synergy fires when a hit of element "el" lands on an enemy that already has status "st".
# It is active while the player owns a spell that applies the status and a spell of that element
# (or every spell listed in "need"). Effects: mult, boom (+r), chain, apply (+dur), spread (+dur, r),
# heal, eat (consume the status), kill_xp (experience multiplier when the enemy dies with the status).
const SYNERGIES := {
    "steam": {"st": "burn", "el": ["ice", "water"], "boom": 28.0, "r": 48.0, "eat": true},
    "conductor": {"st": "wet", "el": ["lightning"], "chain": 4, "mult": 1.3},
    "deepfreeze": {"st": "wet", "el": ["ice"], "apply": "petrify", "dur": 1.6},
    "shatter": {"st": "petrify", "el": ["force"], "mult": 2.0},
    "skyfall": {"st": "levitate", "el": ["force"], "mult": 2.5, "boom": 14.0, "r": 40.0},
    "wildfire": {"st": "root", "el": ["fire"], "spread": "burn", "dur": 3.0, "r": 60.0},
    "sunbrand": {"st": "mark", "el": ["arcane"], "mult": 1.5},
    "radiance": {"st": "mark", "el": ["light"], "heal": 0.6},
    "gravity": {"st": "grouped", "el": ["fire", "light", "force"], "mult": 1.4},
    "stagefright": {"st": "fear", "el": [], "need": ["expelliarmus"], "kill_xp": 2},
    "riptide": {"st": "wet", "el": ["force"], "mult": 1.3},
    "brittle": {"st": "chill", "el": ["force"], "mult": 1.35},
}

# Playable heroes: a signature second starting spell and a few stat multipliers.
const HEROES := {
    "harry": {"spell": "expelliarmus", "hp": 100.0, "speed": 1.1, "dmg": 1.0, "cdm": 1.0, "armor": 1.0, "magnet": 1.2, "xp": 1.0, "cost": 0},
    "hermione": {"spell": "incendio", "hp": 85.0, "speed": 1.0, "dmg": 1.0, "cdm": 0.88, "armor": 1.0, "magnet": 1.0, "xp": 1.15, "cost": 120},
    "ron": {"spell": "depulso", "hp": 135.0, "speed": 0.95, "dmg": 1.1, "cdm": 1.0, "armor": 0.9, "magnet": 1.0, "xp": 1.0, "cost": 120},
}

# Permanent upgrades bought with galleons between runs: id -> [max level, base cost].
const META := {
    "power": [10, 20], "vigor": [10, 15], "swift": [5, 25], "tempo": [5, 30], "dodge": [5, 40],
    "guard": [5, 30], "reach": [5, 15], "greed": [5, 25], "wisdom": [5, 25], "revive": [1, 300],
}


static func _ml(meta: Dictionary, id: String) -> int:
    return int(meta.get(id, 0))


static func new_player(hero: String = "harry", meta: Dictionary = {}) -> Dictionary:
    if not HEROES.has(hero):
        hero = "harry"
    var h: Dictionary = HEROES[hero]
    var hp: float = float(h.hp) + 10.0 * _ml(meta, "vigor")
    var weapons := {"wand": 1}
    weapons[h.spell] = 1
    return {
        "hero": hero, "pos": Vector2.ZERO, "facing": Vector2.DOWN, "aim": Vector2.DOWN, "r": 7.0,
        "hp": hp, "max_hp": hp, "iframe": 0.0, "slow": 1.0,
        "level": 1, "xp": 0.0, "xp_next": 8, "pending": 0,
        "weapons": weapons, "passives": {}, "evolved": {}, "fusions": {},
        "m_dmg": float(h.dmg) * (1.0 + 0.05 * _ml(meta, "power")),
        "m_cd": float(h.cdm) * (1.0 - 0.03 * _ml(meta, "tempo")),
        "m_speed": float(h.speed) * (1.0 + 0.03 * _ml(meta, "swift")),
        "m_armor": float(h.armor) * (1.0 - 0.03 * _ml(meta, "guard")),
        "m_magnet": float(h.magnet) * (1.0 + 0.1 * _ml(meta, "reach")),
        "m_xp": float(h.xp) * (1.0 + 0.05 * _ml(meta, "wisdom")),
        "m_gold": 1.0 + 0.1 * _ml(meta, "greed"),
        "dodge": 0.03 * _ml(meta, "dodge"),
        "revives": _ml(meta, "revive"),
    }


# ---------------------------------------------------------------- meta shop

static func meta_cost(id: String, level: int) -> int:
    return int(META[id][1]) * (level + 1)


## Buys one level of a permanent upgrade. "data" is the save dictionary. Returns false when it cannot.
static func meta_buy(data: Dictionary, id: String) -> bool:
    var meta: Dictionary = data.get("meta", {})
    var level: int = _ml(meta, id)
    if level >= int(META[id][0]):
        return false
    var cost: int = meta_cost(id, level)
    if int(data.get("gold", 0)) < cost:
        return false
    data["gold"] = int(data.get("gold", 0)) - cost
    meta[id] = level + 1
    data["meta"] = meta
    return true


## Selects a hero, buying it first when needed. Returns false when the player cannot afford it.
static func hero_pick(data: Dictionary, id: String) -> bool:
    var owned: Array = data.get("heroes", ["harry"])
    if not (id in owned):
        var cost: int = int(HEROES[id].cost)
        if int(data.get("gold", 0)) < cost:
            return false
        data["gold"] = int(data.get("gold", 0)) - cost
        owned.append(id)
        data["heroes"] = owned
    data["hero"] = id
    return true


# ---------------------------------------------------------------- level scaling

static func dmg(def: Dictionary, lv: int) -> float:
    return float(def.get("d", 0.0)) * (1.0 + 0.28 * (lv - 1))


static func cooldown(def: Dictionary, lv: int) -> float:
    return float(def.cd) * (1.0 - 0.06 * (lv - 1))


static func count(def: Dictionary, lv: int) -> int:
    var n: int = int(def.get("n", 1))
    if def.get("grow", false):
        n += int(lv >= 3) + int(lv >= 5) + int(lv >= 7)
    return n


static func radius(def: Dictionary, lv: int) -> float:
    return float(def.get("r", 0.0)) * (1.0 + 0.08 * (lv - 1))


# ---------------------------------------------------------------- passives (talismans x hero x meta)

static func passive(p: Dictionary, id: String) -> int:
    return int(p.passives.get(id, 0))


static func damage_mult(p: Dictionary) -> float:
    return (1.0 + 0.12 * passive(p, "focus")) * float(p.get("m_dmg", 1.0))


static func cooldown_mult(p: Dictionary) -> float:
    return maxf(0.4, (1.0 - 0.07 * passive(p, "haste")) * float(p.get("m_cd", 1.0)))


static func move_speed(p: Dictionary) -> float:
    return 118.0 * (1.0 + 0.08 * passive(p, "boots")) * float(p.get("m_speed", 1.0))


static func pickup_radius(p: Dictionary) -> float:
    return 62.0 * (1.0 + 0.3 * passive(p, "magnet")) * float(p.get("m_magnet", 1.0))


static func armor_mult(p: Dictionary) -> float:
    return maxf(0.4, (1.0 - 0.08 * passive(p, "ward")) * float(p.get("m_armor", 1.0)))


## One line with the size limits of a build and how much of them is used (level-up, pause, combos).
static func limits(p: Dictionary) -> String:
    var spells: Dictionary = p.get("weapons", {})
    var charms: Dictionary = p.get("passives", {})
    return I18n2.t("x_limits") % [spells.size(), WEAPON_SLOTS, MAX_LEVEL, charms.size(), PASSIVE_SLOTS, PASSIVE_MAX]


# ---------------------------------------------------------------- fusions

static func fusion_min(fid: String) -> int:
    return maxi(1, 5 - FUSIONS[fid].need.size())


static func fusion_ready(p: Dictionary, fid: String) -> bool:
    var lv: int = fusion_min(fid)
    for id in FUSIONS[fid].need:
        if int(p.weapons.get(id, 0)) < lv:
            return false
    return true


## A fusion is as strong as the average level of the spells it was made from.
static func fusion_level(p: Dictionary, fid: String) -> int:
    var need: Array = FUSIONS[fid].need
    var sum: int = 0
    for id in need:
        sum += int(p.weapons.get(id, 1))
    return clampi(int(sum / float(need.size())), 1, MAX_LEVEL)


# ---------------------------------------------------------------- synergies

static func status_sources(st: String) -> Array:
    var out: Array = []
    for id in WEAPONS:
        if WEAPONS[id].get("st", "") == st:
            out.append(id)
    return out


static func element_sources(els: Array) -> Array:
    var out: Array = []
    for id in WEAPONS:
        if WEAPONS[id].el in els:
            out.append(id)
    return out


static func _owns_any(p: Dictionary, ids: Array) -> bool:
    for id in ids:
        if p.weapons.has(id):
            return true
    return false


static func is_active(p: Dictionary, sid: String) -> bool:
    var rule: Dictionary = SYNERGIES[sid]
    var has_status: bool = _owns_any(p, status_sources(rule.st))
    if rule.st == "petrify" and not has_status:
        has_status = is_active(p, "deepfreeze")
    if not has_status:
        return false
    for id in rule.get("need", []):
        if not p.weapons.has(id):
            return false
    if rule.el.is_empty():
        return true
    return _owns_any(p, element_sources(rule.el))


static func active(p: Dictionary) -> Array:
    var out: Array = []
    for sid in SYNERGIES:
        if is_active(p, sid):
            out.append(sid)
    return out


static func names(ids: Array, sep: String = " / ") -> String:
    var parts: PackedStringArray = PackedStringArray()
    for id in ids:
        parts.append(I18n.t("sp_" + str(id)))
    return sep.join(parts)


## Human-readable requirement line for the Combos menu.
static func requirement(sid: String) -> String:
    var rule: Dictionary = SYNERGIES[sid]
    var right: Array = rule.get("need", [])
    if not rule.el.is_empty():
        right = element_sources(rule.el)
    return "%s  +  %s" % [names(status_sources(rule.st)), names(right)]


## Synergies and fusions a spell takes part in (shown on upgrade cards).
static func hints(id: String) -> String:
    var def: Dictionary = WEAPONS[id]
    var out: String = ""
    var syn: PackedStringArray = PackedStringArray()
    for sid in SYNERGIES:
        var rule: Dictionary = SYNERGIES[sid]
        if syn.size() < 2 and (def.get("st", "") == rule.st or def.el in rule.el or id in rule.get("need", [])):
            syn.append(I18n.t("sy_" + sid))
    if not syn.is_empty():
        out += I18n.t("ui_syn_hint") % ", ".join(syn)
    var fus: PackedStringArray = PackedStringArray()
    for fid in FUSIONS:
        if fus.size() < 2 and id in FUSIONS[fid].need:
            fus.append(I18n.t("fu_" + fid))
    if not fus.is_empty():
        out += I18n.t("ui_fu_hint") % ", ".join(fus)
    return out


# ---------------------------------------------------------------- upgrades

static func recipe(kind: String, id: String) -> String:
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if kind == "weapon" and ev.weapon == id:
            return I18n2.t("x_rc_w") % [EVOLVE_LEVEL, I18n.t("pa_" + ev.passive), I18n.t("ev_" + ev_id)]
        if kind == "passive" and ev.passive == id:
            return I18n2.t("x_rc_p") % [I18n.t("sp_" + ev.weapon), EVOLVE_LEVEL, I18n.t("ev_" + ev_id)]
    return ""


# A repeatable card. "frog" is the plain heal.
static func _boon(id: String) -> Dictionary:
    if id == "frog":
        return {"kind": "heal", "id": "heal", "tag": I18n.t("t_recover"), "title": I18n.t("heal_title"), "text": I18n2.t("x_frog"), "weight": 1.0}
    return {"kind": "boon", "id": id, "tag": I18n2.t("x_boon"), "title": I18n2.t("x_bo_" + id), "text": I18n2.t("x_bd_" + id), "weight": 1.0}


## Three weighted upgrade cards. When fewer than three regular upgrades are left, the rest of the
## choice is filled with repeatable bonuses, so a level-up is never an empty choice.
static func choices(p: Dictionary, rng: RandomNumberGenerator) -> Array:
    var pool: Array = []
    for fid in FUSIONS:
        if not p.fusions.has(fid) and fusion_ready(p, fid):
            pool.append({"kind": "fusion", "id": fid, "tag": I18n.t("t_fusion") % FUSIONS[fid].need.size(), "title": I18n.t("fu_" + fid), "text": I18n.t("fd_" + fid), "weight": 9.0})
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if p.evolved.has(ev_id):
            continue
        if int(p.weapons.get(ev.weapon, 0)) >= EVOLVE_LEVEL and int(p.passives.get(ev.passive, 0)) >= 1:
            pool.append({"kind": "evolve", "id": ev_id, "tag": I18n.t("t_evolution"), "title": I18n.t("ev_" + ev_id), "text": I18n.t("ed_" + ev_id), "weight": 8.0})
    var owned_w: int = p.weapons.size()
    for w_id in WEAPONS:
        var lv: int = int(p.weapons.get(w_id, 0))
        if lv >= MAX_LEVEL or (lv == 0 and owned_w >= WEAPON_SLOTS):
            continue
        var tag: String = I18n2.t("x_new_spell") % [owned_w + 1, WEAPON_SLOTS]
        if lv > 0:
            tag = I18n2.t("x_spell_lv") % [lv + 1, MAX_LEVEL]
        tag += "  -  " + I18n.t("el_" + str(WEAPONS[w_id].el))
        var weight: float = 2.0 if lv == 0 else 5.0
        pool.append({"kind": "weapon", "id": w_id, "tag": tag, "title": I18n.t("sp_" + w_id), "text": I18n.t("sd_" + w_id) + recipe("weapon", w_id) + hints(w_id), "weight": weight})
    var owned_p: int = p.passives.size()
    for p_id in PASSIVES:
        var plv: int = int(p.passives.get(p_id, 0))
        if plv >= PASSIVE_MAX or (plv == 0 and owned_p >= PASSIVE_SLOTS):
            continue
        var ptag: String = I18n2.t("x_new_passive") % [owned_p + 1, PASSIVE_SLOTS]
        if plv > 0:
            ptag = I18n2.t("x_passive_lv") % [plv + 1, PASSIVE_MAX]
        pool.append({"kind": "passive", "id": p_id, "tag": ptag, "title": I18n.t("pa_" + p_id), "text": I18n.t("pd_" + p_id) + recipe("passive", p_id), "weight": 6.0})
    var out: Array = []
    while out.size() < 3 and pool.size() > 0:
        var total: float = 0.0
        for c in pool:
            total += c.weight
        var roll: float = rng.randf() * total
        var idx: int = pool.size() - 1
        for i in pool.size():
            roll -= pool[i].weight
            if roll <= 0.0:
                idx = i
                break
        out.append(pool[idx])
        pool.remove_at(idx)
    var extra: Array = BOONS.duplicate()
    while out.size() < 3 and not extra.is_empty():
        var k: int = rng.randi() % extra.size()
        out.append(_boon(str(extra[k])))
        extra.remove_at(k)
    return out


static func apply(p: Dictionary, c: Dictionary) -> void:
    match c.kind:
        "weapon":
            p.weapons[c.id] = int(p.weapons.get(c.id, 0)) + 1
        "passive":
            p.passives[c.id] = int(p.passives.get(c.id, 0)) + 1
            if c.id == "vitality":
                p.max_hp += 20.0
                p.hp = minf(p.max_hp, p.hp + 20.0)
        "evolve":
            p.evolved[c.id] = true
        "fusion":
            p.fusions[c.id] = true
        "boon":
            if c.id == "power":
                p["m_dmg"] = float(p.get("m_dmg", 1.0)) * 1.04
            elif c.id == "tempo":
                p["m_cd"] = float(p.get("m_cd", 1.0)) * 0.98
            elif c.id == "vigor":
                p.max_hp += 12.0
                p.hp = minf(p.max_hp, p.hp + 12.0)
        "heal":
            p.hp = minf(p.max_hp, p.hp + 40.0)
