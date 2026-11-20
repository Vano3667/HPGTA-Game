# Hex District: Curfew — Game Concept

> Working title. An original urban-fantasy world and cast. Do not use official characters, names, houses, crests, locations, logos, or other recognizable protected franchise elements.

## High Concept

**Hex District: Curfew** is a portrait-first Android survival roguelite with a top-down view, dense but readable enemy swarms, automatically triggered spells, and run-defining upgrade combinations. A young urban mage survives escalating nights across five districts of Vesper, gathering spell pages and choosing upgrades while magical wardens close in.

The broad genre reference is the accessible, movement-focused, auto-attacking survival loop popularized by *Vampire Survivors*: keep moving with one thumb, let the equipped arsenal attack automatically, gather experience, and shape a build through frequent level-up choices. The game must have its own original setting, characters, visual identity, enemies, interface, maps, names, sound, art and systems; do not reproduce another game's assets, exact UI, maps, characters or signature content.

**Player promise:** “Keep moving through a living magical city; every run turns a small spell kit into a spectacular survival build.”

## Product Snapshot

- **Platform:** Android phones and tablets; portrait orientation is the primary target.
- **Genre:** top-down survival action / auto-attacking roguelite.
- **Run structure:** five authored districts in sequence, each with its own arena, enemy roster, hazard and boss; aim for a complete run of roughly 20–30 minutes, adjustable through playtesting.
- **Core input:** one hand, one thumb. The player steers from a touch/virtual-stick zone along the bottom of the screen. Basic attacks, equipped spells and companion attacks fire automatically. No aiming or firing button is required.
- **Camera:** stable 2D top-down camera that follows the player smoothly and keeps nearby threats visible.
- **Tone:** adventurous, eerie-but-not-horror, with small humorous details of everyday magical city life.
- **Performance target:** smooth play on a representative mid-range Android device; establish and record a real benchmark during development rather than claiming an untested frame rate.

## World and Story

The city of **Vesper** was built over five old ley lines. The independent **Gloam Academy** teaches practical urban wardcraft: keeping lifts, streetlamps, trains, gardens and rooftops safe with everyday spells. During the annual Eclipse, the central **Starfall Orrery** misreads ordinary residents as threats. District seals fail, enchanted services turn hostile, and the city begins sealing itself off.

The protagonist, **Mira Vale**, is an apprentice courier sent to restore the five district seals and reach the observatory. She is neither a prophesied hero nor the heir to a famous bloodline; her strength is improvisation and combining spells that were never designed to work together. Short environmental details and brief in-run lines tell the story; long cutscenes are not required.

The final reveal is that the Orrery's protective logic has become dangerously overzealous. Mira must interrupt and retune the system, not destroy the city. A short epilogue restores the districts and opens a replayable Night Patrol mode.

## Core Run Loop

1. Pick a starting discipline and enter a district.
2. Move continuously with one thumb while the equipped arsenal auto-attacks nearby eligible targets.
3. Defeat enemies, collect experience pages/gems and watch for readable telegraphs, drops and environmental hazards.
4. On level-up, pause combat and choose one of three upgrades, a new spell, a passive item or a synergistic evolution.
5. Survive increasingly dense timed enemy phases and defeat the district boss.
6. Between districts, select a recovery or build adjustment, then continue with the current run.
7. Complete all five districts or be defeated. Unlock cosmetic options and new build choices between runs without requiring a stat-grind.

### Survival and Progression Rules

- Each district is a timed survival chapter, not just a small cleared room: enemy pressure escalates in authored phases, with breathing windows before major threats.
- The five districts have a fixed campaign order for the first clear; optional modifiers, encounter variations and reward choices add replay value.
- Level-up choices pause gameplay, are large enough for touch, and clearly describe the effect and any prerequisite.
- Weapons/spells have readable base behaviours and meaningful upgrade paths. A small number of compatible maxed spells and passive items can evolve into a distinctive signature spell.
- No pay-to-win requirement, account, network connection, ads, analytics or microtransactions in the initial game.

## One-Handed Android Controls

- Use a **single-thumb movement control in the lower portion of the screen**, preferably a floating or fixed virtual stick in the lower-left/lower-center safe area. The touch region must be configurable and comfortable for left- and right-handed players.
- A simple drag-to-move implementation is acceptable if it is easier to use and does not obscure gameplay; the user should not need two fingers or simultaneous controls.
- The hero can move throughout the full combat arena. “Movement control at the bottom of the screen” refers to the thumb input/control zone, not a restriction that traps the character in a bottom strip.
- All ordinary attacks, spell casts, summons, target selection and pickups work automatically while the player moves. There is no mandatory attack, aim, cast or dodge button.
- Dodging is primarily achieved by moving. If a dash or emergency escape is implemented, it must be optional and operable one-handed (for example, an auto-trigger or a reachable configurable bottom-zone gesture); never make a second hand or rapid multi-touch mandatory.
- Level-up selections and menus pause the run and use large, accessible controls. Touch the chosen card with the same hand; resume only after a choice.
- Respect Android display cutouts, navigation bars and safe areas. Allow control-side swap, virtual-stick size/opacity and input sensitivity settings.
- Include pause/resume, vibration, screen-shake and damage-flash settings. Provide high-contrast telegraphs that do not rely on color alone.

## Auto-Combat and Build Design

The player makes tactical decisions through movement, route choice and upgrade selection. Auto-combat reduces input load without removing positioning skill.

### Starting Disciplines

- **Spark:** frequent straight bolts; upgrades add piercing, chaining or a short ricochet.
- **Frost:** automatically places brief slowing fields and fires icy shards; controls lanes and approaching crowds.
- **Aether:** rotating ward-runes orbit the player, absorb/deflect a limited number of hits, and damage close threats.

### Example Spells and Synergies

- **Comet Mark:** periodically marks a visible ground zone and detonates after a clear warning. Frost extends the slow; Spark triggers an extra burst.
- **Paper Familiar:** circles Mira and automatically attacks a nearby target; upgrades change projectile, cadence or orbit.
- **Mirror Echo:** leaves a decoy after a timed or optional dash, drawing a telegraphed attack away from Mira.
- **Thunder Stitch:** links two marks with a damaging line, especially effective in alleys and metro platforms.
- **Evolution example:** maxed Spark plus a compatible focus item unlocks a broad chain-lightning spell. Keep recipes discoverable and explain the result in the upgrade UI.

### Readability and Fairness

- Enemy attacks visibly telegraph shape, target area and timing before damage occurs. Use silhouette and animation as well as color.
- Preserve safe movement routes; do not fill the entire screen with indistinguishable bullets, particles or UI.
- Give major attacks an audible cue with independent volume control. Avoid sudden loudness peaks and excessive flashing.
- Make the player, pickups, hostile attacks and friendly projectiles distinguishable on a phone-sized screen and in color-vision accessibility modes.
- Enemies should be dangerous through varied approach and projectile patterns, not only inflated health.
- Provide a simple recent-damage/defeat explanation where practical.

## Five Districts / Levels

| # | District | Visual identity | Signature survival mechanic | Boss |
|---|---|---|---|---|
| 1 | Gloam Academy Rooftops | Wet slate, copper pipes, warm windows | Telegraphing gusts subtly nudge Mira and drift light projectiles | Copper Gargoylion |
| 2 | Lantern Ward Night Market | Colorful awnings, stalls and floating lanterns | Lantern colors warn of sector bursts; disabled lanterns create temporary safe lanes | The Glass Factor |
| 3 | The Underline Metro | Tiled platforms, rails, cold cyan lighting | A ghost train's full path is shown before it rushes through; leyline gates open alternate routes | The Faceless Conductor |
| 4 | Briarwood Perimeter | Root paths, ferns, fireflies, moonlit clearings | Roots visibly rise before briefly closing a lane | The Thornhart |
| 5 | Starfall Observatory | Violet stone, brass rings, star charts | A clearly highlighted safe arc rotates in advance; side runes can interrupt a phase | The Starfall Orrery |

### Level 1 — Gloam Academy Rooftops: “Night Rounds”

- **Purpose:** teach movement, auto-attacks, experience pickups, level-up choices and basic telegraphs.
- **Layout:** several connected roof decks and broad routes around a greenhouse, tower and chimneys. Landmarks remain legible when the screen is busy.
- **Enemy roster:** Yard Spark (slow single bolts), Bell Warden (brief cone attack), tiny airborne page-familiar (light pressure, clear silhouette).
- **Hazard:** gust lanes glow and ripple before pushing Mira or drifting selected light projectiles. The player can route around the gust.
- **Boss:** Copper Gargoylion marks its landing zone, leaps, then sends a ring of projectiles with a wide safe gap. Later it adds three aimed bolts. It must be readable on a narrow portrait viewport.
- **Reward:** district seal and a familiar-related starting build option.

### Level 2 — Lantern Ward Night Market: “Too Many Customers”

- **Purpose:** teach route selection through partial cover and readable overlapping attack zones.
- **Layout:** three stall rows, a central square/canal and short side alleys with multiple ways around the market.
- **Enemies:** Market Double (briefly mirrors Mira's recent movement), Courier Beetle (fast but fragile), Hollow Mannequin (slowly occupies a lane).
- **Hazard:** suspicious lanterns change silhouette/glow before a sector burst. Automatically fired spells can extinguish a lantern when it is a valid target, creating a temporary opening.
- **Boss:** The Glass Factor creates mirror copies; the real one has a distinct warm shadow. It then uses two crossing fans with a clear central path.

### Level 3 — The Underline Metro: “Last Train”

- **Purpose:** train reading of linear threats and movement between platforms.
- **Layout:** two long platforms, track trenches and leyline gates. Keep enough width for one-thumb evasion; do not use camera motion to hide hazards.
- **Enemies:** Signal Wisp marks a rail, Dust Conductor fires a slow fan, echo-passengers appear with a clear arrival warning.
- **Hazard:** the ghost train illuminates its complete lane before entering. A platform pocket or alternate leyline crossing provides a route to safety.
- **Boss:** The Faceless Conductor warns with a luminous rail stripe, attacks along it, and follows with two cross-lines leaving a viable escape window.

### Level 4 — Briarwood Perimeter: “The Forest Answers”

- **Purpose:** contrast urban scenes with open organic routes and temporary terrain changes.
- **Layout:** an open loop around a moonlit clearing; tree clusters stay near edges so the central combat area remains readable; at least two passages stay open.
- **Enemies:** Root Snapper (slow lunge), decoy Firefly (diverts attention but does not cause surprise damage), Spore Witch (bounded cloud with visible edge).
- **Hazard:** roots visibly lift the ground for at least 0.8 seconds before blocking a route. Never seal every exit or trap Mira in a dead end.
- **Boss:** The Thornhart alternates a marked leap, a root wave and a recovery window; patterns have stable timing and silhouettes.

### Level 5 — Starfall Observatory: “Retuning”

- **Purpose:** combine established skills in a final encounter without introducing an untelegraphed new control system.
- **Layout:** circular room, central Orrery, an outer ring route and four small cover points. Keep the player and every entrance/exit visible.
- **Enemies:** short mixed waves of familiar foes with altered timing; limit simultaneous elite threats.
- **Hazard:** a safe arc rotates clockwise after a visible warning. Two side runes can briefly interrupt the rotation.
- **Boss:** The Starfall Orrery has three phases: (1) orbiting projectiles with wide gaps; (2) rotating safe arc plus two warned linear attacks; (3) exposed core after activating side runes. Reward positioning and attack uptime; avoid an opaque DPS check.
- **Epilogue:** Mira retunes the defense protocol, the districts reopen and the replayable Night Patrol mode unlocks.

## Visual Direction

- Original top-down urban-fantasy pixel art / carefully controlled low-resolution art. Compact blocky geometry, deep navy/violet shadow, warm windows, copper details and distinct magical highlights.
- Evoke the energy of a gritty 1990s city action game viewed from above, but do not reproduce any specific game's maps, HUD, logos, characters, sprites or signature locations.
- Magical city details should feel practical and lived in: warded streetlamps, copper pipes, enchanted service kiosks, floating spell pages and animated roof gardens.
- Maintain clean silhouettes and readable movement corridors. Do not let decorative roof geometry imply false collision.
- Friendly attacks may use turquoise/gold; hostile telegraphs may use amber/coral plus distinct shapes and motion. Validate in a color-vision mode.
- The five SVG files in `refs/` are authored composition/color/combat-lane references, not final sprites or production-ready maps.

## Audio

- Low-fi electronic night-city music with a shared motif and a distinct timbral layer per district.
- Short, differentiable spell/enemy sounds; a gentle sound cue accompanies major telegraphs.
- Separate music, effects and warning volumes; avoid harsh peaks.

## Production Scope and Acceptance

The intended deliverable is a complete, playable five-district campaign prototype, not merely a concept or isolated first-level mock-up. Develop in short vertical slices, but continue autonomously through the full scope.

1. Inspect the existing project and environment. Preserve existing user work. Choose a suitable engine and implementation path based on the repository; if none exists, Godot 4 / 2D / GDScript is a reasonable default. Record the decision and any environment limitations in `HANDOFF.md`.
2. Build and test the one-thumb movement plus automatic combat loop first.
3. Implement upgrade drafts, experience collection, survival pacing, pause and run restart.
4. Deliver all five authored districts with their stated signature mechanic and boss, plus a complete win/defeat loop.
5. Validate portrait layouts, safe areas, one-handed touch reach, performance and save behavior. Build an APK if the environment supports it; otherwise give exact reproducible export steps and accurately record what remains unverified.
6. Finish with clear launch/build instructions, known issues and an up-to-date `HANDOFF.md`.

**Performance target:** smooth on an agreed representative mid-range Android device; measure and report actual profiling/test results.

## Visual References

- [01 — Gloam Academy Rooftops](refs/01_gloam_academy.svg)
- [02 — Lantern Ward Night Market](refs/02_lantern_market.svg)
- [03 — The Underline Metro](refs/03_underline_metro.svg)
- [04 — Briarwood Perimeter](refs/04_briarwood.svg)
- [05 — Starfall Observatory](refs/05_starfall_observatory.svg)
