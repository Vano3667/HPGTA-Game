extends RefCounted
## Spell, passive, evolution and synergy data plus the upgrade rules. No scene access.
## Spells are data-driven: arsenal.gd only knows a handful of archetypes ("kind").
## Display names live in i18n.gd (sp_/sd_, pa_/pd_, ev_/ed_, sy_/sx_).

const I18n = preload("res://scripts/core/i18n.gd")

const MAX_LEVEL := 5
const WEAPON_SLOTS := 6
const PASSIVE_SLOTS := 4

# kind: bolt | nova | zone | strike | beam | orbit | stag | familiar
# el: element used by synergies. st/sd: status applied and its duration.
# d damage, cd cooldown, n count (grow: +1 at levels 3 and 5), r radius, sp speed, kb knockback.
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

const PASSIVES := ["focus", "haste", "boots", "vitality", "magnet", "ward"]

# An evolution is offered once its weapon is at max level and the passive is owned.
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


static func new_player() -> Dictionary:
    return {
        "pos": Vector2.ZERO, "facing": Vector2.DOWN, "aim": Vector2.DOWN, "r": 7.0,
        "hp": 100.0, "max_hp": 100.0, "iframe": 0.0, "slow": 1.0,
        "level": 1, "xp": 0, "xp_next": 8, "pending": 0,
        "weapons": {"wand": 1}, "passives": {}, "evolved": {},
    }


# ---------------------------------------------------------------- level scaling

static func dmg(def: Dictionary, lv: int) -> float:
    return float(def.get("d", 0.0)) * (1.0 + 0.28 * (lv - 1))


static func cooldown(def: Dictionary, lv: int) -> float:
    return float(def.cd) * (1.0 - 0.06 * (lv - 1))


static func count(def: Dictionary, lv: int) -> int:
    var n: int = int(def.get("n", 1))
    if def.get("grow", false):
        n += int(lv >= 3) + int(lv >= 5)
    return n


static func radius(def: Dictionary, lv: int) -> float:
    return float(def.get("r", 0.0)) * (1.0 + 0.08 * (lv - 1))


# ---------------------------------------------------------------- passives

static func passive(p: Dictionary, id: String) -> int:
    return int(p.passives.get(id, 0))


static func damage_mult(p: Dictionary) -> float:
    return 1.0 + 0.12 * passive(p, "focus")


static func cooldown_mult(p: Dictionary) -> float:
    return maxf(0.6, 1.0 - 0.07 * passive(p, "haste"))


static func move_speed(p: Dictionary) -> float:
    return 118.0 * (1.0 + 0.08 * passive(p, "boots"))


static func pickup_radius(p: Dictionary) -> float:
    return 62.0 * (1.0 + 0.3 * passive(p, "magnet"))


static func armor_mult(p: Dictionary) -> float:
    return maxf(0.5, 1.0 - 0.08 * passive(p, "ward"))


# ---------------------------------------------------------------- synergies

# Spell ids that apply a status (frozen-by-synergy also counts as a petrify source).
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


static func _names(ids: Array) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for id in ids:
        parts.append(I18n.t("sp_" + str(id)))
    return " / ".join(parts)


## Human-readable requirement line for the Synergies menu.
static func requirement(sid: String) -> String:
    var rule: Dictionary = SYNERGIES[sid]
    var right: Array = rule.get("need", [])
    if not rule.el.is_empty():
        right = element_sources(rule.el)
    return "%s  +  %s" % [_names(status_sources(rule.st)), _names(right)]


## Synergy names a spell takes part in (shown on upgrade cards).
static func hints(id: String) -> String:
    var def: Dictionary = WEAPONS[id]
    var names: PackedStringArray = PackedStringArray()
    for sid in SYNERGIES:
        var rule: Dictionary = SYNERGIES[sid]
        if def.get("st", "") == rule.st or def.el in rule.el or id in rule.get("need", []):
            names.append(I18n.t("sy_" + sid))
        if names.size() >= 3:
            break
    if names.is_empty():
        return ""
    return I18n.t("ui_syn_hint") % ", ".join(names)


# ---------------------------------------------------------------- upgrades

static func recipe(kind: String, id: String) -> String:
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if kind == "weapon" and ev.weapon == id:
            return I18n.t("ui_rc_w") % [I18n.t("pa_" + ev.passive), I18n.t("ev_" + ev_id)]
        if kind == "passive" and ev.passive == id:
            return I18n.t("ui_rc_p") % [I18n.t("sp_" + ev.weapon), I18n.t("ev_" + ev_id)]
    return ""


## Up to three weighted upgrade cards. Falls back to a heal when everything is maxed.
static func choices(p: Dictionary, rng: RandomNumberGenerator) -> Array:
    var pool: Array = []
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if p.evolved.has(ev_id):
            continue
        if int(p.weapons.get(ev.weapon, 0)) >= MAX_LEVEL and int(p.passives.get(ev.passive, 0)) >= 1:
            pool.append({"kind": "evolve", "id": ev_id, "tag": I18n.t("t_evolution"), "title": I18n.t("ev_" + ev_id), "text": I18n.t("ed_" + ev_id), "weight": 8.0})
    for w_id in WEAPONS:
        var lv: int = int(p.weapons.get(w_id, 0))
        if lv >= MAX_LEVEL or (lv == 0 and p.weapons.size() >= WEAPON_SLOTS):
            continue
        var tag: String = I18n.t("t_new_spell")
        if lv > 0:
            tag = I18n.t("t_spell_lv") % (lv + 1)
        tag += "  -  " + I18n.t("el_" + str(WEAPONS[w_id].el))
        var weight: float = 2.0 if lv == 0 else 5.0
        pool.append({"kind": "weapon", "id": w_id, "tag": tag, "title": I18n.t("sp_" + w_id), "text": I18n.t("sd_" + w_id) + recipe("weapon", w_id) + hints(w_id), "weight": weight})
    for p_id in PASSIVES:
        var plv: int = int(p.passives.get(p_id, 0))
        if plv >= MAX_LEVEL or (plv == 0 and p.passives.size() >= PASSIVE_SLOTS):
            continue
        var ptag: String = I18n.t("t_new_passive")
        if plv > 0:
            ptag = I18n.t("t_passive_lv") % (plv + 1)
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
    if out.is_empty():
        out.append({"kind": "heal", "id": "heal", "tag": I18n.t("t_recover"), "title": I18n.t("heal_title"), "text": I18n.t("heal_text"), "weight": 1.0})
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
        "heal":
            p.hp = minf(p.max_hp, p.hp + 30.0)
