extends RefCounted
## Spell, passive and evolution data plus the upgrade rules. No scene access.

const MAX_LEVEL := 5
const WEAPON_SLOTS := 5
const PASSIVE_SLOTS := 4

const WEAPONS := {
    "wand": {"name": "Wand Bolt", "desc": "Auto-fires at the nearest enemy. Levels add bolts and piercing."},
    "stupefy": {"name": "Stupefy Burst", "desc": "Periodic red stun bolt at the toughest foe. Splits at level 3."},
    "protego": {"name": "Protego Orbit", "desc": "Shield runes circle Harry, hurt close enemies and stop curses."},
    "patronus": {"name": "Expecto Patronum", "desc": "A blue-white stag charges through the horde and clears a lane."},
    "incendio": {"name": "Incendio Ring", "desc": "A timed ring of fire bursts around Harry."},
    "glacius": {"name": "Glacius Field", "desc": "Freezes a patch of ground: slows and chills enemies."},
    "expelliarmus": {"name": "Expelliarmus Arc", "desc": "Curving bolt that disarms casters and weakens its target."},
    "lumos": {"name": "Lumos Familiar", "desc": "A floating light that fires small bolts on its own."},
}

const PASSIVES := {
    "focus": {"name": "Phoenix Feather Core", "desc": "+12% spell damage per level."},
    "haste": {"name": "Time-Turner Cog", "desc": "-7% spell cooldowns per level."},
    "boots": {"name": "Seeker Reflexes", "desc": "+8% movement speed per level."},
    "vitality": {"name": "Chocolate Frog Card", "desc": "+20 max HP and heals 20 per level."},
    "magnet": {"name": "Accio Charm", "desc": "+30% pickup radius per level."},
    "ward": {"name": "Cloak Thread", "desc": "-8% damage taken per level."},
}

# An evolution is offered once its weapon is at max level and the passive is owned.
const EVOLUTIONS := {
    "chain": {"name": "Chain Lightning Charm", "weapon": "wand", "passive": "focus", "desc": "Wand bolts arc to three nearby enemies."},
    "maxima": {"name": "Protego Maxima", "weapon": "protego", "passive": "ward", "desc": "Six runes on a wider orbit."},
    "inferno": {"name": "Incendio Maxima", "weapon": "incendio", "passive": "haste", "desc": "Every fire ring leaves burning ground behind."},
}


static func new_player() -> Dictionary:
    return {
        "pos": Vector2.ZERO, "facing": Vector2.DOWN, "aim": Vector2.DOWN, "r": 7.0,
        "hp": 100.0, "max_hp": 100.0, "iframe": 0.0, "slow": 1.0,
        "level": 1, "xp": 0, "xp_next": 11, "pending": 0,
        "weapons": {"wand": 1}, "passives": {}, "evolved": {},
    }


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


## Text shown on upgrade cards so the player can see evolution recipes while choosing.
static func recipe(kind: String, id: String) -> String:
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if kind == "weapon" and ev.weapon == id:
            return " Recipe: max level + %s = %s." % [PASSIVES[ev.passive].name, ev.name]
        if kind == "passive" and ev.passive == id:
            return " Recipe: with max %s = %s." % [WEAPONS[ev.weapon].name, ev.name]
    return ""


## Up to three weighted upgrade cards. Falls back to a heal when everything is maxed.
static func choices(p: Dictionary, rng: RandomNumberGenerator) -> Array:
    var pool: Array = []
    for ev_id in EVOLUTIONS:
        var ev: Dictionary = EVOLUTIONS[ev_id]
        if p.evolved.has(ev_id):
            continue
        if int(p.weapons.get(ev.weapon, 0)) >= MAX_LEVEL and int(p.passives.get(ev.passive, 0)) >= 1:
            pool.append({"kind": "evolve", "id": ev_id, "tag": "EVOLUTION", "title": ev.name, "text": ev.desc, "weight": 8.0})
    for w_id in WEAPONS:
        var lv: int = int(p.weapons.get(w_id, 0))
        if lv >= MAX_LEVEL or (lv == 0 and p.weapons.size() >= WEAPON_SLOTS):
            continue
        var tag: String = "NEW SPELL" if lv == 0 else "SPELL LEVEL %d" % (lv + 1)
        var weight: float = 2.0 if lv == 0 else 3.0
        pool.append({"kind": "weapon", "id": w_id, "tag": tag, "title": WEAPONS[w_id].name, "text": WEAPONS[w_id].desc + recipe("weapon", w_id), "weight": weight})
    for p_id in PASSIVES:
        var plv: int = int(p.passives.get(p_id, 0))
        if plv >= MAX_LEVEL or (plv == 0 and p.passives.size() >= PASSIVE_SLOTS):
            continue
        var ptag: String = "NEW PASSIVE" if plv == 0 else "PASSIVE LEVEL %d" % (plv + 1)
        pool.append({"kind": "passive", "id": p_id, "tag": ptag, "title": PASSIVES[p_id].name, "text": PASSIVES[p_id].desc + recipe("passive", p_id), "weight": 2.0})
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
        out.append({"kind": "heal", "id": "heal", "tag": "RECOVER", "title": "Chocolate Frog", "text": "Every spell is mastered. Restore 30 HP.", "weight": 1.0})
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
