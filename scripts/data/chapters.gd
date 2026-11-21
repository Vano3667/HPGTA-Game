extends RefCounted
## Chapter data: palette, layout, ambience, enemy mix, hazard and boss. Pure data, no logic.
## Display names live in i18n.gd as ch_<id> / cs_<id>.

const ARENA := Vector2(1400.0, 1900.0)
## Seconds of escalating waves before the chapter boss arrives.
const SURVIVE_TIME := 120.0

# "enemies" rows are [type, unlock time in seconds, spawn weight].
# "amb" picks the weather/particle ambience, "dark" is the night overlay strength (lights cut through it).
const LIST := [
    {
        "id": "diagon", "layout": "street", "amb": "rain", "dark": 0.34, "tint": Color("1a2a44"),
        "ground": Color("51483e"), "ground2": Color("6d6050"), "ground3": Color("383630"),
        "prop": Color("7a4a3e"), "prop2": Color("34454a"), "edge": Color("ae8c58"), "accent": Color("ffc860"),
        "enemies": [["cauldron", 0.0, 6.0], ["pixie", 12.0, 4.0], ["display", 35.0, 3.0], ["masked", 60.0, 2.0]],
        "hazard": {"kind": "lane", "every": 8.0, "warn": 1.5, "life": 0.6, "damage": 14.0, "w": 44.0},
        "boss": "warden",
    },
    {
        "id": "hogsmeade", "layout": "village", "amb": "snow", "dark": 0.22, "tint": Color("2a3a5a"),
        "ground": Color("b9c4cc"), "ground2": Color("d3dde2"), "ground3": Color("8f9ca6"),
        "prop": Color("6a4a3a"), "prop2": Color("e4ecef"), "edge": Color("8a6a4a"), "accent": Color("ffd27a"),
        "enemies": [["snowman", 0.0, 5.0], ["pixie", 10.0, 4.0], ["werewolf", 40.0, 2.0], ["snatcher", 65.0, 2.0]],
        "hazard": {"kind": "fog", "every": 7.5, "warn": 1.4, "life": 5.0, "damage": 4.0, "n": 3, "r": 62.0},
        "boss": "greyback",
    },
    {
        "id": "hogwarts", "layout": "courtyard", "amb": "leaves", "dark": 0.2, "tint": Color("3a3020"),
        "ground": Color("4a4d47"), "ground2": Color("5e625a"), "ground3": Color("33362f"),
        "prop": Color("74776f"), "prop2": Color("4a4d4b"), "edge": Color("a99563"), "accent": Color("ffcf70"),
        "enemies": [["book", 0.0, 5.0], ["armor", 8.0, 4.0], ["pixie", 30.0, 4.0], ["portrait", 55.0, 2.0]],
        "hazard": {"kind": "glyph", "every": 9.0, "warn": 1.6, "life": 3.0, "damage": 12.0, "n": 1},
        "boss": "sentinel",
    },
    {
        "id": "pitch", "layout": "pitch", "amb": "wind", "dark": 0.1, "tint": Color("203a20"),
        "ground": Color("3f5a34"), "ground2": Color("4d6b3e"), "ground3": Color("31482a"),
        "prop": Color("7a5a48"), "prop2": Color("8a2a34"), "edge": Color("d8cb91"), "accent": Color("f0d278"),
        "enemies": [["pixie", 0.0, 5.0], ["dummy", 0.0, 3.0], ["bludger", 20.0, 4.0], ["flier", 55.0, 3.0]],
        "hazard": {"kind": "sweep", "every": 9.0, "warn": 1.5, "life": 4.0, "damage": 16.0, "n": 1},
        "boss": "snitch",
    },
    {
        "id": "forest", "layout": "forest", "amb": "fireflies", "dark": 0.5, "tint": Color("0a1a1a"),
        "ground": Color("2f3a2a"), "ground2": Color("3d4a33"), "ground3": Color("1e2619"),
        "prop": Color("4a3828"), "prop2": Color("2a4a2a"), "edge": Color("5d6b45"), "accent": Color("9fe8ff"),
        "enemies": [["spider", 0.0, 6.0], ["plant", 15.0, 2.0], ["dementor", 35.0, 3.0], ["centaur", 65.0, 2.0]],
        "hazard": {"kind": "fog", "every": 7.0, "warn": 1.4, "life": 6.0, "damage": 5.0, "n": 1, "r": 95.0},
        "boss": "aragog",
    },
    {
        "id": "chamber", "layout": "chamber", "amb": "drip", "dark": 0.48, "tint": Color("062018"),
        "ground": Color("2a3a36"), "ground2": Color("354a44"), "ground3": Color("1a2622"),
        "prop": Color("4a5a54"), "prop2": Color("2a3a34"), "edge": Color("6a9a7a"), "accent": Color("6aff9a"),
        "enemies": [["snake", 0.0, 6.0], ["inferi", 20.0, 3.0], ["spawn", 45.0, 2.0], ["masked", 70.0, 2.0]],
        "hazard": {"kind": "lane", "every": 7.5, "warn": 1.8, "life": 0.7, "damage": 22.0, "w": 90.0},
        "boss": "basilisk",
    },
    {
        "id": "vaults", "layout": "vaults", "amb": "dust", "dark": 0.42, "tint": Color("2a1a08"),
        "ground": Color("4a4038"), "ground2": Color("5a4e42"), "ground3": Color("2e2822"),
        "prop": Color("6a5a3a"), "prop2": Color("3a3a40"), "edge": Color("d6b85a"), "accent": Color("ffd860"),
        "enemies": [["goblin", 0.0, 6.0], ["cart", 15.0, 3.0], ["dragonling", 40.0, 2.0], ["construct", 70.0, 2.0]],
        "hazard": {"kind": "sweep", "every": 8.0, "warn": 1.4, "life": 4.0, "damage": 20.0, "n": 2},
        "boss": "ironbelly",
    },
    {
        "id": "azkaban", "layout": "fortress", "amb": "storm", "dark": 0.5, "tint": Color("0a1020"),
        "ground": Color("2e3238"), "ground2": Color("3a4048"), "ground3": Color("1c2026"),
        "prop": Color("3e444c"), "prop2": Color("22262c"), "edge": Color("6a7480"), "accent": Color("a8d8ff"),
        "enemies": [["prisoner", 0.0, 6.0], ["wraith", 15.0, 3.0], ["dementor", 30.0, 3.0], ["deatheater", 65.0, 2.0]],
        "hazard": {"kind": "bolts", "every": 6.0, "warn": 1.1, "life": 0.3, "damage": 22.0, "n": 4, "r": 44.0},
        "boss": "lord",
    },
    {
        "id": "manor", "layout": "manor", "amb": "embers", "dark": 0.44, "tint": Color("1a0a20"),
        "ground": Color("34303a"), "ground2": Color("423c4a"), "ground3": Color("221e28"),
        "prop": Color("2e4a34"), "prop2": Color("1e3424"), "edge": Color("8a7aa0"), "accent": Color("7aff8a"),
        "enemies": [["snatcher", 0.0, 5.0], ["peacock", 10.0, 4.0], ["deatheater", 30.0, 3.0], ["construct", 60.0, 2.0]],
        "hazard": {"kind": "glyph", "every": 7.0, "warn": 1.5, "life": 2.5, "damage": 20.0, "n": 2},
        "boss": "bellatrix",
    },
    {
        "id": "ministry", "layout": "ministry", "amb": "sparks", "dark": 0.46, "tint": Color("061a10"),
        "ground": Color("24282c"), "ground2": Color("343b3f"), "ground3": Color("181d21"),
        "prop": Color("3c4a56"), "prop2": Color("1b2022"), "edge": Color("928660"), "accent": Color("45ff7a"),
        "enemies": [["inferi", 0.0, 6.0], ["echo", 12.0, 3.0], ["deatheater", 30.0, 3.0], ["construct", 60.0, 2.0]],
        "hazard": {"kind": "orb", "every": 6.5, "warn": 1.6, "life": 0.5, "damage": 24.0},
        "boss": "hex",
    },
]
