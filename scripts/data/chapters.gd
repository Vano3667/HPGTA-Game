extends RefCounted
## Stage data: ten chapters plus five story-boss duels between them. Pure data, no logic.
## Display names live in i18n.gd as ch_<id> / cs_<id>. "map" names the painted floor
## (art/gen/map_<map>.png, built from assets/visual-kit/locations); without it the arena is procedural.

const ARENA := Vector2(1400.0, 1900.0)
const DUEL_ARENA := Vector2(640.0, 900.0)
## Seconds of escalating waves before the chapter guardian arrives (or the way to the boss opens).
const SURVIVE_TIME := 120.0
## World units per pixel of a painted map.
const MAP_SCALE := 0.6

# "enemies" rows are [type, unlock time in seconds, spawn weight]. "boss" may be "" (no guardian).
# "duel": a boss arena - no waves, the story boss appears at once.
const LIST := [
    {
        "id": "diagon", "map": "01-diagon-alley", "layout": "street", "amb": "rain", "dark": 0.3, "tint": Color("1a2a44"),
        "ground": Color("51483e"), "ground2": Color("6d6050"), "ground3": Color("383630"),
        "prop": Color("7a4a3e"), "prop2": Color("34454a"), "edge": Color("ae8c58"), "accent": Color("ffc860"),
        "enemies": [["cauldron", 0.0, 6.0], ["pixie", 12.0, 4.0], ["display", 35.0, 3.0], ["masked", 60.0, 2.0]],
        "hazard": {"kind": "lane", "every": 8.0, "warn": 1.5, "life": 0.6, "damage": 14.0, "w": 44.0},
        "boss": "warden",
    },
    {
        "id": "hogwarts", "map": "02-academy-courtyard", "layout": "courtyard", "amb": "leaves", "dark": 0.16, "tint": Color("3a3020"),
        "ground": Color("4a4d47"), "ground2": Color("5e625a"), "ground3": Color("33362f"),
        "prop": Color("74776f"), "prop2": Color("4a4d4b"), "edge": Color("a99563"), "accent": Color("ffcf70"),
        "enemies": [["book", 0.0, 5.0], ["armor", 8.0, 4.0], ["pixie", 30.0, 4.0], ["portrait", 55.0, 2.0]],
        "hazard": {"kind": "glyph", "every": 9.0, "warn": 1.6, "life": 3.0, "damage": 12.0, "n": 1},
        "boss": "",
    },
    {
        "id": "mirror", "duel": true, "map": "boss-01-mirror-chamber", "layout": "duel", "amb": "dust", "dark": 0.3, "tint": Color("1a1020"),
        "ground": Color("3a3440"), "ground2": Color("4a4452"), "ground3": Color("26222c"),
        "prop": Color("5a5466"), "prop2": Color("3a3444"), "edge": Color("c9a24c"), "accent": Color("ffd27a"),
        "enemies": [["masked", 0.0, 3.0], ["book", 0.0, 3.0]],
        "boss": "quirrell",
    },
    {
        "id": "forest", "map": "03-forbidden-forest", "layout": "forest", "amb": "fireflies", "dark": 0.32, "tint": Color("0a1a1a"),
        "ground": Color("2f3a2a"), "ground2": Color("3d4a33"), "ground3": Color("1e2619"),
        "prop": Color("4a3828"), "prop2": Color("2a4a2a"), "edge": Color("5d6b45"), "accent": Color("9fe8ff"),
        "enemies": [["spider", 0.0, 6.0], ["plant", 15.0, 2.0], ["dementor", 35.0, 3.0], ["centaur", 65.0, 2.0]],
        "hazard": {"kind": "fog", "every": 7.0, "warn": 1.4, "life": 6.0, "damage": 5.0, "n": 1, "r": 95.0},
        "boss": "aragog",
    },
    {
        "id": "pitch", "map": "04-storm-pitch", "layout": "pitch", "amb": "storm", "dark": 0.16, "tint": Color("203a20"),
        "ground": Color("3f5a34"), "ground2": Color("4d6b3e"), "ground3": Color("31482a"),
        "prop": Color("7a5a48"), "prop2": Color("8a2a34"), "edge": Color("d8cb91"), "accent": Color("f0d278"),
        "enemies": [["pixie", 0.0, 5.0], ["dummy", 0.0, 3.0], ["bludger", 20.0, 4.0], ["flier", 55.0, 3.0]],
        "hazard": {"kind": "sweep", "every": 9.0, "warn": 1.5, "life": 4.0, "damage": 16.0, "n": 1},
        "boss": "",
    },
    {
        "id": "dungeon", "duel": true, "map": "boss-02-underground-dungeon", "layout": "duel", "amb": "drip", "dark": 0.3, "tint": Color("062018"),
        "ground": Color("2a3a36"), "ground2": Color("354a44"), "ground3": Color("1a2622"),
        "prop": Color("4a5a54"), "prop2": Color("2a3a34"), "edge": Color("6a9a7a"), "accent": Color("6aff9a"),
        "enemies": [["snake", 0.0, 4.0]],
        "boss": "basilisk",
    },
    {
        "id": "ministry", "map": "05-mysteries-archive", "layout": "ministry", "amb": "sparks", "dark": 0.28, "tint": Color("061a10"),
        "ground": Color("24282c"), "ground2": Color("343b3f"), "ground3": Color("181d21"),
        "prop": Color("3c4a56"), "prop2": Color("1b2022"), "edge": Color("928660"), "accent": Color("45ff7a"),
        "enemies": [["inferi", 0.0, 6.0], ["echo", 12.0, 3.0], ["deatheater", 30.0, 3.0], ["construct", 60.0, 2.0]],
        "hazard": {"kind": "orb", "every": 6.5, "warn": 1.6, "life": 0.5, "damage": 20.0},
        "boss": "hex",
    },
    {
        "id": "hogsmeade", "map": "06-frost-village", "layout": "village", "amb": "snow", "dark": 0.14, "tint": Color("2a3a5a"),
        "ground": Color("b9c4cc"), "ground2": Color("d3dde2"), "ground3": Color("8f9ca6"),
        "prop": Color("6a4a3a"), "prop2": Color("e4ecef"), "edge": Color("8a6a4a"), "accent": Color("ffd27a"),
        "enemies": [["snowman", 0.0, 5.0], ["frostwitch", 10.0, 3.0], ["werewolf", 40.0, 2.0], ["snatcher", 65.0, 2.0]],
        "hazard": {"kind": "fog", "every": 7.5, "warn": 1.4, "life": 5.0, "damage": 4.0, "n": 3, "r": 62.0},
        "boss": "",
    },
    {
        "id": "lake", "duel": true, "map": "boss-03-lakeside-forest-clearing", "layout": "duel", "amb": "fireflies", "dark": 0.34, "tint": Color("0a1424"),
        "ground": Color("2a3a3a"), "ground2": Color("3a4a48"), "ground3": Color("1a2628"),
        "prop": Color("3a4a44"), "prop2": Color("24342e"), "edge": Color("6a8a9a"), "accent": Color("9fe8ff"),
        "enemies": [["wraith", 0.0, 3.0], ["dementor", 0.0, 1.0]],
        "boss": "dementor",
    },
    {
        "id": "vault", "map": "07-serpent-vault", "layout": "chamber", "amb": "drip", "dark": 0.3, "tint": Color("062018"),
        "ground": Color("2e4039"), "ground2": Color("456153"), "ground3": Color("172720"),
        "prop": Color("566557"), "prop2": Color("26362d"), "edge": Color("c4a65a"), "accent": Color("54e39a"),
        "enemies": [["snake", 0.0, 6.0], ["cultist", 18.0, 3.0], ["inferi", 40.0, 3.0], ["spawn", 70.0, 2.0]],
        "hazard": {"kind": "lane", "every": 7.5, "warn": 1.8, "life": 0.7, "damage": 22.0, "w": 90.0},
        "boss": "idol",
    },
    {
        "id": "crossroads", "map": "08-midnight-crossroads", "layout": "crossroads", "amb": "embers", "dark": 0.3, "tint": Color("140a24"),
        "ground": Color("363847"), "ground2": Color("57566d"), "ground3": Color("1d202c"),
        "prop": Color("4b4358"), "prop2": Color("282534"), "edge": Color("c9a7e8"), "accent": Color("c45cff"),
        "enemies": [["carriage", 0.0, 3.0], ["masked", 0.0, 4.0], ["bludger", 30.0, 4.0], ["owl", 60.0, 3.0]],
        "hazard": {"kind": "sweep", "every": 8.0, "warn": 1.4, "life": 4.0, "damage": 20.0, "n": 2},
        "boss": "",
    },
    {
        "id": "classroom", "duel": true, "map": "boss-04-ruined-classroom", "layout": "duel", "amb": "dust", "dark": 0.26, "tint": Color("1a1020"),
        "ground": Color("4a4450"), "ground2": Color("5a5462"), "ground3": Color("302c36"),
        "prop": Color("6a5a4a"), "prop2": Color("4a3e34"), "edge": Color("a08a6a"), "accent": Color("7aff8a"),
        "enemies": [["snake", 0.0, 4.0], ["book", 0.0, 2.0]],
        "boss": "nagini",
    },
    {
        "id": "prison", "map": "09-storm-prison", "layout": "fortress", "amb": "storm", "dark": 0.3, "tint": Color("0a1020"),
        "ground": Color("394954"), "ground2": Color("567080"), "ground3": Color("1d2b33"),
        "prop": Color("4c5a63"), "prop2": Color("222d33"), "edge": Color("8edee9"), "accent": Color("a8d8ff"),
        "enemies": [["prisoner", 0.0, 6.0], ["guard", 15.0, 3.0], ["dementor", 30.0, 3.0], ["deatheater", 65.0, 2.0]],
        "hazard": {"kind": "bolts", "every": 6.0, "warn": 1.1, "life": 0.3, "damage": 22.0, "n": 4, "r": 44.0},
        "boss": "greyback",
    },
    {
        "id": "tower", "map": "10-astronomy-tower", "layout": "tower", "amb": "storm", "dark": 0.26, "tint": Color("140a2a"),
        "ground": Color("37334e"), "ground2": Color("524b70"), "ground3": Color("1d1c31"),
        "prop": Color("56506d"), "prop2": Color("29263c"), "edge": Color("d8c477"), "accent": Color("9c86ff"),
        "enemies": [["gargoyle", 0.0, 4.0], ["owl", 10.0, 4.0], ["construct", 40.0, 3.0], ["frostwitch", 65.0, 2.0]],
        "hazard": {"kind": "bolts", "every": 5.5, "warn": 1.2, "life": 0.3, "damage": 24.0, "n": 5, "r": 44.0},
        "boss": "",
    },
    {
        "id": "bridge", "duel": true, "map": "boss-05-broken-bridge", "layout": "duel", "amb": "embers", "dark": 0.26, "tint": Color("0a1a12"),
        "ground": Color("4a4a52"), "ground2": Color("5c5c66"), "ground3": Color("2e2e36"),
        "prop": Color("5a5a64"), "prop2": Color("3a3a42"), "edge": Color("9aa0b0"), "accent": Color("45ff7a"),
        "enemies": [["deatheater", 0.0, 3.0], ["inferi", 0.0, 3.0]],
        "boss": "voldemort",
    },
]
