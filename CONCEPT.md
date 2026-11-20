# Harry Potter: Hex District — Game Concept

> Fan-game concept for an original mobile survival roguelite using recognizable Harry Potter characters, locations, spells and props. This is a non-commercial creative design brief. Replace or license assets appropriately before commercial release.

## High Concept

**Harry Potter: Hex District** is a portrait-first Android survival roguelite inspired by the movement and automatic-fire loop of *Vampire Survivors* and the dense top-down combat readability of *Crimsonland*, presented with the dirty, compact, 1990s city-game density of the user's GTA 2 references.

The player controls Harry Potter from a near-vertical overhead view. One thumb moves him from a control zone at the bottom of the screen; the wand, spells, familiars and passive effects attack automatically. The player survives escalating swarms, gathers experience, chooses upgrades and combines recognizable wizarding-world spells into a build.

**Important visual target:** not clean fantasy key art, not a 45-degree isometric RPG, and not a generic magic-school illustration. The target is a readable old-school game screen: dark muddy environments, compact map geometry, small characters, heavy texture, strong spell flashes, crowded enemy formations, simple HUD panels and a clear open lane around the player.

## Core Player Promise

“Keep moving through iconic wizarding locations while Harry's wand fights automatically; build a new spell loadout every run and survive the next minute of chaos.”

## Platform and Session

- Android phones/tablets, portrait-first.
- One hand / one thumb only during combat.
- 20–30 minute campaign target, five authored chapters, with shorter practice runs possible.
- Local/offline first. No mandatory account, ads, analytics, network or purchases in the prototype.
- Automatic attacks are the default and cannot be replaced by a required manual-aim scheme.

## One-Handed Controls

- A floating or fixed virtual-stick / drag-to-move control occupies the lower-left or lower-center safe area.
- The player can swap the control to the lower-right for the other hand and adjust size, opacity and sensitivity.
- Harry moves freely around the entire map; the bottom location is only the thumb input zone, not a movement boundary.
- Wand shots, spell casts, familiars, target selection, XP magnet and ordinary pickups are automatic.
- Dodging is achieved by movement. An optional one-thumb dash/escape gesture may be added, but no second hand, twin-stick aiming or mandatory attack button is allowed.
- Level-up cards, pause and settings use large controls and stop combat while open.
- Support safe areas, cutouts, vibration toggle, screen-shake toggle, damage-flash setting and high-contrast telegraphs.

## Story Setup

After a magical disturbance spreads through London and Hogwarts, familiar wards begin classifying students and civilians as hostile. Harry must cross five locations, gather fragments of a broken **Hex District Seal**, and confront the source at the Ministry. The story uses recognizable canon places and names for this fan concept, while the combat arenas and enemy behaviours are designed as original game systems.

## Automatic Arsenal

### Starting weapons

- **Wand Bolt:** automatic nearest-target shot; upgrades add piercing, ricochet, chain hit or faster cadence.
- **Stupefy Burst:** periodic automatic red stun bolt; upgraded versions can split or briefly interrupt an elite.
- **Protego Orbit:** a rotating shield rune that absorbs or deflects limited hits and damages close enemies.
- **Expecto Patronum:** an automatic blue-white guardian pass that clears a lane on a cooldown.

### Additional spells and synergies

- **Expelliarmus Arc:** automatic curved projectile that disarms or weakens wand enemies.
- **Incendio Ring:** a timed fire ring around Harry; Crimsonland-like crowd control, with clear red/orange telegraph.
- **Glacius Field:** slows a visible patch of enemies.
- **Lumos Familiar:** a floating light that reveals enemies and fires small bolts.
- **Sectumsempra:** late-run high-risk evolution for an adult/advanced mode only; use clear content rating and accessibility review.
- **Evolution example:** max Wand Bolt plus a focus passive creates **Chain Lightning Charm**; show the recipe in the level-up UI.

## Survival Rules

- Timed enemy phases escalate density, speed, elite frequency and projectile complexity.
- Experience drops are large, bright enough to read at phone scale and attracted by a generous magnet radius.
- Every level-up pauses the world and offers three large choices: weapon, passive, spell level or evolution ingredient.
- Keep the hero visually distinct from enemies and spells. Friendly effects use cyan/gold/blue; hostile telegraphs use amber/red/green plus shape and motion.
- Avoid filling the entire screen with indistinguishable particles. Preserve safe movement paths.
- Bosses telegraph before jumps, sweeps, charges and area attacks. Use audio cues and shape, not color alone.

## Five Campaign Chapters

### 1. Diagon Alley — “Curfew on the Alley”

- Wet cobblestone, brick shop fronts, **Ollivanders**, **Gringotts**, cauldrons, broom displays and cramped road lanes.
- Enemies: runaway enchanted objects, pixies, hostile masked wizards and animated shop displays.
- Hazard: shop signs and street lamps flash before a short lane burst; alley clutter is cover but never a dead end.
- Boss: **The Alley Warden**, a cursed armored shop guardian with wand rings and a clear central safe gap.
- Reference: `refs/01_diagon_alley.svg` and saved user example screenshots in `refs/source_examples/`.

### 2. Hogwarts Courtyard — “Castle Under Lock”

- Recognizable Hogwarts stone, Great Hall roof line, courtyard, house crest, stair marks and castle corridors.
- Enemies: animated armor, spell books, pixies and rogue portraits.
- Hazard: moving staircase glyphs shift a route after a visible warning; keep a second open path.
- Boss: **The Stone Sentinel**, with shield cones and a slow ground slam.
- Reference: `refs/02_hogwarts_courtyard.svg`.

### 3. Forbidden Forest — “Patronus at Midnight”

- Dark trees, mud paths, the **Dementors**, **Aragog** spiders and a blue-white stag **Patronus**.
- Enemies: spiders, Dementor wisps, centaurs and hostile plant clusters.
- Hazard: roots and fog zones close lanes only after a clear pre-warning.
- Boss: **Aragog**, with web telegraphs and a multi-leg ring attack; Expecto Patronum creates an obvious counter-window.
- Reference: `refs/03_forbidden_forest.svg`.

### 4. Quidditch Pitch — “The Golden Snitch Run”

- Grass pitch, six goal hoops, stands, broom flight lanes, **Golden Snitch**, Quaffle and Bludgers.
- Enemies: rogue Bludgers, hostile training dummies, flying pixies and opposing masked fliers.
- Hazard: marked flight lanes sweep across the arena; safe gaps rotate and stay visible.
- Boss: **The Snitch Storm**, a swarm-boss that creates a rotating golden ring with a readable gap.
- Reference: `refs/04_quidditch_pitch.svg`.

### 5. Ministry of Magic — “Department of Mysteries”

- Dark tile floors, Ministry corridors, **Floo fireplaces**, prophecy shelves and the circular prophecy chamber.
- Enemies: Death Eaters, Inferi, spell echoes and enchanted security constructs.
- Hazard: prophecy orbs glow before burst lines; keep the centre readable and leave escape routes around shelves.
- Boss: **The Hex Disturbance**, three phases: green curse fans, blue-white defensive rings, and a final exposed seal core.
- Reference: `refs/05_ministry_battle.svg`.

## Art Direction

- Use the user-provided screenshots in `refs/source_examples/` as style anchors: compact top-down composition, rough low-resolution texture, dirty green/brown/grey palette, readable right-edge HUD, dense crowds and strong spell trails.
- Use the GTA 2 references for urban density, street/vehicle clutter and map readability; use the Crimsonland references for swarm density, automatic projectile patterns, gore-free impact marks, XP pressure and ring-shaped attacks.
- The five authored SVGs are layout/style boards, not final raster sprites. The character and enemy sheets specify the strict overhead silhouettes required for gameplay scale.
- Do not use a cinematic isometric camera. The camera must read as nearly vertical overhead and keep the player's movement lane visible.

## Required Concept Art

- `refs/character_harry_topdown.svg`: Harry overhead sprite sheet with round glasses, lightning scar, Gryffindor red/gold, dark hair and wand direction.
- `refs/enemies_topdown.svg`: Aragog/spider, Dementor, Death Eater, animated armor, Inferi swarm, Cornish pixie, werewolf and basilisk overhead enemy roster.
- These sheets are concept references; final game assets should be authored as cohesive top-down sprites, with size variants and clear collision silhouettes.

## Production Acceptance

The agent must autonomously inspect the repository, choose the most practical engine, build and test the complete five-chapter playable prototype, and update `HANDOFF.md` every session. It must not ask the user to choose an engine, resolve design ambiguity, approve a change or prioritize a task. When a choice is unspecified, use the brief, pick a sensible default, record it and proceed. If Android export is unavailable, finish every runnable alternative and record exact unverified steps.
