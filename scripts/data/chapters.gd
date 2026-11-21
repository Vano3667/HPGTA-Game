extends RefCounted
## Chapter data: palette, layout, enemy mix, hazard and boss. Pure data, no logic.

const ARENA := Vector2(1400.0, 1900.0)
## Seconds of escalating waves before the chapter boss arrives.
const SURVIVE_TIME := 180.0

# "enemies" rows are [type, unlock time in seconds, spawn weight].
const LIST := [
    {
        "id": "diagon", "name": "Diagon Alley", "subtitle": "Curfew on the Alley", "layout": "street",
        "ground": Color("51483e"), "ground2": Color("6d6050"), "ground3": Color("383630"),
        "prop": Color("653f36"), "prop2": Color("243135"), "edge": Color("ae8c58"), "accent": Color("e5b550"),
        "enemies": [["cauldron", 0.0, 6.0], ["pixie", 15.0, 4.0], ["display", 45.0, 3.0], ["masked", 75.0, 2.0]],
        "hazard": {"kind": "lane", "every": 8.0, "warn": 1.5, "life": 0.6, "damage": 14.0},
        "boss": "warden",
    },
    {
        "id": "hogwarts", "name": "Hogwarts Courtyard", "subtitle": "Castle Under Lock", "layout": "courtyard",
        "ground": Color("4a4d47"), "ground2": Color("5e625a"), "ground3": Color("33362f"),
        "prop": Color("5b5e59"), "prop2": Color("3a3d3b"), "edge": Color("a99563"), "accent": Color("c4a149"),
        "enemies": [["book", 0.0, 5.0], ["armor", 10.0, 4.0], ["pixie", 40.0, 4.0], ["portrait", 70.0, 2.0]],
        "hazard": {"kind": "glyph", "every": 9.0, "warn": 1.6, "life": 3.0, "damage": 12.0},
        "boss": "sentinel",
    },
    {
        "id": "forest", "name": "Forbidden Forest", "subtitle": "Patronus at Midnight", "layout": "forest",
        "ground": Color("2f3a2a"), "ground2": Color("3d4a33"), "ground3": Color("1e2619"),
        "prop": Color("3a2c22"), "prop2": Color("2a1f18"), "edge": Color("5d6b45"), "accent": Color("9fe8ff"),
        "enemies": [["spider", 0.0, 6.0], ["plant", 20.0, 2.0], ["dementor", 45.0, 3.0], ["centaur", 80.0, 2.0]],
        "hazard": {"kind": "fog", "every": 7.0, "warn": 1.4, "life": 6.0, "damage": 5.0},
        "boss": "aragog",
    },
    {
        "id": "pitch", "name": "Quidditch Pitch", "subtitle": "The Golden Snitch Run", "layout": "pitch",
        "ground": Color("3f5a34"), "ground2": Color("4d6b3e"), "ground3": Color("31482a"),
        "prop": Color("6a5041"), "prop2": Color("4a3a30"), "edge": Color("d8cb91"), "accent": Color("f0d278"),
        "enemies": [["pixie", 0.0, 5.0], ["dummy", 0.0, 3.0], ["bludger", 25.0, 4.0], ["flier", 70.0, 3.0]],
        "hazard": {"kind": "sweep", "every": 9.0, "warn": 1.5, "life": 4.0, "damage": 16.0},
        "boss": "snitch",
    },
    {
        "id": "ministry", "name": "Ministry of Magic", "subtitle": "Department of Mysteries", "layout": "ministry",
        "ground": Color("24282c"), "ground2": Color("343b3f"), "ground3": Color("181d21"),
        "prop": Color("34404a"), "prop2": Color("1b2022"), "edge": Color("928660"), "accent": Color("45bf69"),
        "enemies": [["inferi", 0.0, 6.0], ["echo", 15.0, 3.0], ["deatheater", 40.0, 3.0], ["construct", 80.0, 2.0]],
        "hazard": {"kind": "orb", "every": 6.5, "warn": 1.6, "life": 0.5, "damage": 18.0},
        "boss": "hex",
    },
    {
        "id": "hogsmeade", "name": "Hogsmeade", "subtitle": "Frost on the High Street", "layout": "village",
        "ground": Color("b8c6d9"), "ground2": Color("dbe5f0"), "ground3": Color("71859b"),
        "prop": Color("4a5664"), "prop2": Color("27333e"), "edge": Color("e7eff7"), "accent": Color("8edbff"),
        "enemies": [["frostwitch", 0.0, 3.0], ["icegolem", 15.0, 3.0], ["pixie", 35.0, 4.0], ["centaur", 70.0, 2.0]],
        "hazard": {"kind": "frost", "every": 7.5, "warn": 1.5, "life": 3.0, "damage": 10.0},
        "boss": "frostmaiden",
    },
    {
        "id": "vault", "name": "Serpent Vault", "subtitle": "Below the Old Temple", "layout": "vault",
        "ground": Color("2e4039"), "ground2": Color("456153"), "ground3": Color("172720"),
        "prop": Color("566557"), "prop2": Color("26362d"), "edge": Color("c4a65a"), "accent": Color("54e39a"),
        "enemies": [["serpent", 0.0, 5.0], ["cultist", 18.0, 3.0], ["inferi", 40.0, 3.0], ["wisp", 78.0, 3.0]],
        "hazard": {"kind": "venom", "every": 6.8, "warn": 1.3, "life": 4.0, "damage": 8.0},
        "boss": "basilisk",
    },
    {
        "id": "crossroads", "name": "Midnight Crossroads", "subtitle": "Last Carriage Out", "layout": "crossroads",
        "ground": Color("363847"), "ground2": Color("57566d"), "ground3": Color("1d202c"),
        "prop": Color("4b4358"), "prop2": Color("282534"), "edge": Color("c9a7e8"), "accent": Color("c45cff"),
        "enemies": [["shadecarriage", 0.0, 3.0], ["masked", 12.0, 3.0], ["bludger", 35.0, 4.0], ["owl", 72.0, 3.0]],
        "hazard": {"kind": "rail", "every": 7.2, "warn": 1.3, "life": 0.7, "damage": 15.0},
        "boss": "nightcoach",
    },
    {
        "id": "prison", "name": "Storm Prison", "subtitle": "Break the Black Tide", "layout": "prison",
        "ground": Color("394954"), "ground2": Color("567080"), "ground3": Color("1d2b33"),
        "prop": Color("4c5a63"), "prop2": Color("222d33"), "edge": Color("8edee9"), "accent": Color("62e7ea"),
        "enemies": [["prisoner", 0.0, 5.0], ["dementor", 18.0, 3.0], ["wisp", 45.0, 3.0], ["sentinel", 82.0, 2.0]],
        "hazard": {"kind": "tide", "every": 8.0, "warn": 1.5, "life": 3.0, "damage": 12.0},
        "boss": "jailer",
    },
    {
        "id": "tower", "name": "Astronomy Tower", "subtitle": "Storm Above the Clouds", "layout": "tower",
        "ground": Color("37334e"), "ground2": Color("524b70"), "ground3": Color("1d1c31"),
        "prop": Color("56506d"), "prop2": Color("29263c"), "edge": Color("d8c477"), "accent": Color("9c86ff"),
        "enemies": [["gargoyle", 0.0, 4.0], ["owl", 16.0, 4.0], ["construct", 42.0, 3.0], ["frostwitch", 76.0, 2.0]],
        "hazard": {"kind": "storm", "every": 6.4, "warn": 1.4, "life": 0.4, "damage": 18.0},
        "boss": "astromancer",
    },
]
