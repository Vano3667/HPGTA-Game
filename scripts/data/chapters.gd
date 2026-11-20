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
]
