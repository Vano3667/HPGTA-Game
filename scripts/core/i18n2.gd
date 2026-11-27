extends RefCounted
## Newer text rows, [English, Russian], kept apart from the big table in i18n.gd so that table does
## not have to be rewritten for every small addition. t() looks here first and then in i18n.gd.
## Keys here start with x_.

const I18n = preload("res://scripts/core/i18n.gd")

const S := {
    "x_limits": ["Spells %d/%d (up to level %d)   Talismans %d/%d (up to level %d)", "Заклинания %d/%d (до ур. %d)   Талисманы %d/%d (до ур. %d)"],
    "x_full": ["All spell slots are taken: only levels of your own spells are offered.", "Все ячейки заклинаний заняты: предлагаются только уровни ваших заклинаний."],
    "x_new_spell": ["NEW SPELL - slot %d of %d", "НОВОЕ ЗАКЛИНАНИЕ - ячейка %d из %d"],
    "x_spell_lv": ["SPELL LEVEL %d of %d", "ЗАКЛИНАНИЕ УР. %d из %d"],
    "x_new_passive": ["NEW TALISMAN - slot %d of %d", "НОВЫЙ ТАЛИСМАН - ячейка %d из %d"],
    "x_passive_lv": ["TALISMAN LEVEL %d of %d", "ТАЛИСМАН УР. %d из %d"],
    "x_boon": ["ENDLESS BONUS", "БЕСКОНЕЧНЫЙ БОНУС"],
    "x_bo_power": ["Wand Polish", "Полировка палочки"],
    "x_bd_power": ["+4% spell damage. Can be taken again and again.", "+4% урона заклинаний. Можно брать снова и снова."],
    "x_bo_tempo": ["Quick Wrist", "Быстрая кисть"],
    "x_bd_tempo": ["-2% spell cooldowns. Can be taken again and again.", "-2% перезарядки заклинаний. Можно брать снова и снова."],
    "x_bo_vigor": ["Pumpkin Pasty", "Тыквенный пирожок"],
    "x_bd_vigor": ["+12 max HP and heals 12. Can be taken again and again.", "+12 к макс. ОЗ и лечение 12. Можно брать снова и снова."],
    "x_frog": ["Restores 40 HP.", "Восстанавливает 40 ОЗ."],
    "x_rc_w": [" Recipe: level %d + %s = %s.", " Рецепт: ур. %d + %s = %s."],
    "x_rc_p": [" Recipe: %s at level %d = %s.", " Рецепт: «%s» ур. %d = %s."],
    "x_sec_evo": ["EVOLUTIONS - spell at level 5 + talisman", "ЭВОЛЮЦИИ - заклинание ур. 5 + талисман"],
    "x_help_limits": ["A run holds up to %d spells and %d talismans. Spells grow to level %d, talismans to level %d. Once nothing is left to learn, every level offers endless bonuses.", "В забеге до %d заклинаний и %d талисманов. Заклинания растут до ур. %d, талисманы до ур. %d. Когда учить больше нечего, каждый уровень даёт бесконечные бонусы."],
}


static func t(key: String) -> String:
    var row = S.get(key)
    if row == null:
        return I18n.t(key)
    if I18n.lang == "ru":
        return row[1]
    return row[0]


static func has(key: String) -> bool:
    return S.has(key)
