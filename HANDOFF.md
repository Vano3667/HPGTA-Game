# HANDOFF — Harry Potter: Hex District

> Mandatory for every future coding agent: read this file first and update it before ending every session. Record changed files, actual test/build results, autonomous decisions, constraints and the next concrete step. Do not rely on chat history. Never write that a build or test happened unless it ran.

## Status

**Current stage:** playable Godot 4.3 game, "v3", on branch `feature/v3-heroes-bosses-meta` (draft PR #2). 15 story stages (10 chapters and 5 story-boss stages), 3 heroes, 28 spells, 9 fusions, 3 evolutions, 12 synergies, a galleon shop, endless mode, procedural music and sound, Russian and English, painted art sliced from `assets/visual-kit` at build time, and since 2026-11-23 an open world without borders whose obstacles are generated around the hero. The user plays the PR #2 APKs on a phone; the last one he reported on was the interface build (run 45123708489): "the menus all work".

**Repository:** https://github.com/Vano3667/HPGTA-Game (public).

**`main` does not build.** Its scripts fail to parse (`scripts/game/art.gd:145`); every `build` run on `main` since `d0187896` has failed. The user keeps pushing art to `main`; PR CI tests the branch merged with `main`, so that art is picked up. Merging PR #2 repairs `main`. Merge only after the user approves the look on a phone.

**Last verified by CI:** `build` run 45183452206, commit `d503a2ef` (bigger builds, tougher bosses, melodic sound effects). Both jobs passed: sprite build (69 files), fonts 3 of 3, import, `[smoke] PASS`, 0 engine errors, debug APK.

**Not confirmed when this file was written:**

- commit `09bf235a` (open world, generated obstacles, hero visibility, level-up sound), `build` run 45184458087, still running;
- the commit that adds this file version (smoke test for the open world, code-drawn stages, upgrade pool and sounds). Its new assertions have never run; a red result may be a mistake in the test, not in the game.

Read both runs before trusting the "open world" entry of the session log. The PR #2 description carries the results once they are known.

**Not verified by anyone:** how anything looks or sounds. No agent can see images or hear audio, and CI renders no frame. That covers the open world (floor tiling, obstacle density, the hero's ring and outline), the new sound effects, and everything listed under "Things only a human can check".

**Next concrete step:** read runs 45184458087 and the one after it; fix what they report. Then the user tries the newest green APK and reports on the items in "Open Work" 1.

## Approved Brief

- Working title: **Harry Potter: Hex District**. Non-commercial fan game. Android, portrait, top-down survival roguelite.
- **Controls:** one thumb. Bottom-screen movement zone; all spells fire automatically.
- Inspiration: Vampire Survivors (auto-attack survival), Crimsonland (dense swarms), GTA2 (gritty overhead city).
- Use recognizable Harry Potter canon as the user requested; keep mechanics and layouts original; verify rights before any public or commercial release.
- Agents work end-to-end without asking the user to make design choices and keep this file updated.

Later user requests, all implemented unless listed under "Open Work": pseudo-3D look and sharper rendering; larger hero; particles and weather; Russian and English; 10 levels; 20 more spells with synergies in their own menu; fusions of 2, 3 and 4 spells; galleons and a stat shop; Ron and Hermione; procedural music; endless mode; tutorial and bestiary; five story bosses between levels (Quirrell, Basilisk, Dementor, Nagini, Voldemort); painted sprites and maps; obstacles as separate sprites on an empty floor; more facing directions for the hero; the upgrade choice in the middle of the screen; an effect on gaining a level; a decorative font, frames and styled text in the menus.

Requests of 2026-11-23 13:07 UTC (this session): make the hero stand out from the floor and the obstacles; make bosses last longer (Quirrell and the Basilisk "died very fast"); show the limits on the number of skills and raise them ("at level 50 I could not pick anything and only took the frog"); generate the obstacles procedurally and remove the closed border of a location, so the hero never runs into the "frame" of the map and can keep running around obstacles; make the sounds more melodic.

## What the Game Contains

- **Stages** (`scripts/data/chapters.gd`): diagon (boss warden), hogwarts, *mirror* (Quirrell), forest (aragog), pitch, *dungeon* (Basilisk), ministry (hex), hogsmeade, *lake* (Dementor), vault (idol), crossroads, *classroom* (Nagini), prison (greyback), tower, *bridge* (Voldemort). Italic stages are boss stages: no waves, the boss walks in after 2.5 s. A chapter lasts 120 s; one without its own boss ends with a portal.
- **Heroes** (`Spells.HEROES`): Harry (free), Hermione and Ron (120 galleons each).
- **Build limits** (`scripts/data/spells.gd`): `WEAPON_SLOTS 8`, `MAX_LEVEL 7` (spells), `PASSIVE_SLOTS 6`, `PASSIVE_MAX 5` (talismans), `EVOLVE_LEVEL 5`. Before this session: 6 slots, 4 slots, level 5 for both. The limits are shown on the level-up screen, the pause screen, the Combos screen, the help screen, in the tag of every upgrade card ("NEW SPELL - slot 3 of 8", "SPELL LEVEL 4 of 7") and as `n/8` and `n/6` in the HUD strip.
- **Repeatable cards** (`Spells.BOONS`): when fewer than three regular upgrades are left, the choice is filled with Wand Polish (+4% damage), Quick Wrist (-2% cooldowns), Pumpkin Pasty (+12 max HP) and the Chocolate Frog (heal 40). A level-up is never an empty choice. Cooldown reduction is floored at 40% of the base in `Spells.cooldown_mult`; damage has no cap.
- **Fusions** (`Spells.FUSIONS`): offered as a level-up card when every part is at level `5 - number of parts` or higher; they take no slot.
- **Synergies:** 12 rules "enemy has status X and is hit by element Y".
- **Meta** (`Spells.META`): ten permanent upgrades bought with galleons.
- **Endless mode:** chapters loop, boss stages are skipped, `tier` raises difficulty.
- **Text:** `scripts/core/i18n.gd` holds the big table; `scripts/core/i18n2.gd` holds newer rows (keys `x_...`) and falls back to the big table.

## Open World

There is no arena any more. `scripts/game/arena.gd` cuts the ground into chunks of 400 world units (`CHUNK`) and keeps the 5 x 5 chunks around the hero (`KEEP = 2`); `Arena.update(w)` runs every step and does work only when the hero enters another chunk. A chunk is built from `hash(chunk x, chunk y, world.map_seed)`, so a place is the same when the hero comes back during a stage; `load_chapter` draws a new `map_seed`. The hero starts at the centre of chunk (0, 0), which is kept clear.

- **Painted stage** (a floor image exists and "Graphics: painted"): obstacles are the painted sprites `art/gen/prop_<map>_*.png` of that map (`Arena.palette`). Per chunk: a building with 60% chance, 1 to 3 medium things, 2 to 4 small ones, at least 52 units apart, so there is always a way through. The old hand-made `PAINTED` table is gone. `Arena.KNOWN` lists the Diagon Alley files as a fallback for exported builds, where the folder may not be listable.
- **Only Diagon Alley has painted obstacles.** The other 14 maps have none, so on them the hero walks over an empty repeated floor with nothing to run around. Their floor images are still the old full location paintings (buildings painted in), which will look wrong when repeated. They need what Diagon Alley got: an empty floor in `floors/` and sprites in `props/<map>/`. Nothing else has to change in code; `KNOWN` should get the new names.
- **Code-drawn stage** (no floor image, or "Graphics: simple"): blocks, trees, hoops and lamps in the chapter's colours, by `layout`.
- **Floor:** `render._floor` repeats the floor image as tiles, every second one mirrored, so edges always meet on identical pixels. `world.arena` is now only the size of one floor tile. `Chapters.ARENA` is the tile size without a painted floor; `Chapters.DUEL_ARENA` is unused.
- **Enemies:** spawn just outside the screen (`director.edge_pos`). One that is blocked by an obstacle steps sideways along it, to the left or right by the parity of its id. One left more than `world.LEASH` (640) behind the hero re-enters from the screen edge; this includes bosses. Crystals more than 1500 away are dropped.
- **Obstacles** block the hero and every enemy, flying ones included. Spells and hostile curses pass through.

## Hero Visibility

`render.gd`: a pulsing cyan ring with two turning gold arcs on the ground under the hero; a dark outline (the sprite drawn four times, offset, in near-black) around the painted sprite; on the additive glow layer a larger pool of light and the sprite once more at half brightness, so he stays brighter than the night veil and shows through an obstacle that stands in front of him. The painted floor is drawn at 84% brightness. All of this is unseen by any agent.

## Code Map

| Path | Role |
|---|---|
| `scripts/main.gd` | Entry point; wires world, HUD, joystick, audio, save; `_level_fx()` |
| `scripts/game/world.gd` | Simulation step, collisions, statuses and synergies, gold, camera |
| `scripts/game/arsenal.gd` | Automatic spells and fusions |
| `scripts/game/director.gd` | Waves, elites, hazards, boss state machine (`""`, `tell`, `dash`) |
| `scripts/game/arena.gd` | Endless chunk generator: painted and code-drawn obstacles |
| `scripts/game/render.gd` | All drawing passes; floor tiling; hero ring and outline |
| `scripts/game/art.gd` | Heroes, enemies and bosses: painted sprite if present, else code-drawn |
| `scripts/core/sprites.gd` | Loads `res://art/gen/*`; direction sectors with hysteresis; mirroring |
| `scripts/data/*.gd` | Stages, enemies and bosses, spells, fusions, heroes, upgrades, limits |
| `scripts/core/i18n.gd`, `i18n2.gd`, `music.gd`, `sfx.gd`, `save.gd` | Text rows `[English, Russian]`, audio, save |
| `scripts/ui/style.gd` | Fonts, theme, button, frame and card styles, drawn ornaments |
| `scripts/ui/hud.gd`, `joystick.gd` | HUD strip, all menu panels and their animated backdrop, one-thumb stick |
| `tools/build_sprites.gd` | Slices the masters into `art/gen/` (git-ignored) |
| `tests/smoke_test.gd` | Headless bot test used by CI, followed by a short "draw pass" over the real scene |

Run locally, in this order:

```
godot --headless --path . -s res://tools/build_sprites.gd
godot --headless --path . --import
godot --headless --path . -s res://tests/smoke_test.gd
```

## Sound

`scripts/core/sfx.gd` synthesises 22 streams on a worker thread at start (at once in headless runs). Everything is bell and pluck tones in A minor pentatonic, which fits the keys of the three music loops. Crystals climb an eight-note scale while the hero keeps collecting (the run resets after 1.1 s without a pickup); the wand cycles through four notes. Ids: `wand`, `stupefy`, `patronus`, `fire`, `ice`, `hurt`, `gem`, `warn`, `burst`, `boss_down`, `level` (a short charm chime that three spells use) and `levelup` (the level-up arpeggio, emitted by `world`). Music (`music.gd`) was not changed. Nobody has heard any of it.

## Interface

- **Fonts.** The workflow downloads three files from `github.com/google/fonts` at a fixed commit into `art/gen/` before the import: `font_title.ttf` (Yeseva One), `font_body.ttf` and `font_bold.ttf` (Philosopher Regular and Bold). All three cover Cyrillic and are under the SIL Open Font License. A local checkout has no fonts unless you fetch them the same way; `style.gd` then falls back to the engine font. The help screen names the fonts and the licence; before a public release the full licence text should ship with the game.
- **Panels.** `hud._panel()` builds a dimmed screen with one framed column. `low = true` keeps the frame at the bottom for the thumb (pause, stage clear, summary, heroes); the main menu and the level-up choice are centred. Long screens call `_scroll()`.
- **Level-up.** Centred, with an additive backdrop (flash, glow, rays, rings, sparks). A transparent guard swallows taps for the first 0.4 s. The limits line sits under the heading. With three cards and the limits line the frame is about 600 units tall on an 854-unit screen; whether long Russian card texts still fit is unseen.

## Testing

`tests/smoke_test.gd` runs everything in one `_process` call first: data and text checks, a mortal bot, an invulnerable bot through all 15 stages, three endless stages, a 55-second walk in one direction across the open world, all 15 stages with code-drawn graphics, synergies, fusions, the shop, a checkpoint round trip and the upgrade pool. Then it opens every panel in both languages. Then it builds the real scene once more and returns `false` from `_process` for a dozen frames, changing what is on screen each frame (menu, a run, level-up, two boss stages, pause, bestiary, heroes, then three code-drawn stages) so the draw code runs; it prints how often the HUD and the arena drew. A script error anywhere fails the CI job through the `SCRIPT ERROR` grep.

What this cannot show: whether anything looks or sounds right.

## Art Pipeline

Masters live in `assets/visual-kit/` (it has `.gdignore`). They are never modified. File names are matched ignoring case, stray spaces and a doubled extension (`name .png`, `name.png.png`).

| Master | Runtime file | Notes |
|---|---|---|
| `sprites/<hero>-8dir-idle.png`, `-walk-a`, `-walk-b` | `hero8_<id>.png` | One row of five figures: front, front-right, right, back-right, back. The game mirrors the left side. Idle is required; with idle only, the walk is a bob and lean in code; with idle and one step sheet the two alternate |
| `sprites/boss-NN-<name>-8dir-idle.png` plus one attack row | `boss8_<id>.png` | Same layout. Attack row: Quirrell `-cast` (every wind-up), Basilisk `-gaze` (the gaze wind-up) |
| `sprites/boss-02-cockatrice-basilisk-top-move.png`, `-top-lunge.png` | `top_basilisk_*.png` | One figure, true top-down, heading right; rotated in code while moving or dashing |
| `sprites/mobs/<name>.png` (or `<name> v2.png`) | `mob_<name>.png` | One enemy per file; overrides the atlas cell of the same name |
| `props/<map>/<type>-<size>-<name>.png` | `prop_<map>_<file>.png` | type `wall`, `low`, `pit`, `deco`; size `s`, `m`, `l`, `xl` (24, 52, 100, 180 world units wide). The generator places them by size class |
| `floors/<map>.png` or `locations/<map>.png` | `map_<map>.png` | Floor tile at scale 0.6, repeated mirrored; `floors/` wins |
| old atlases and single boss pictures | `hero_<id>.png`, `boss_<id>.png` | Fallbacks |

Results of the last verified sprite build (run 45183452206):

- `hero8_harry` is built from `hero-wizard-8dir-idle.png.png` and `hero-wizard-8dir-walk-a.png`. The idle sheet is clean. In the walk sheet all five figures touch (one shape); the cut crossed up to 8 px of art, the worst of all sheets, so Harry's step frames are the most likely to show a clipped wand or a sliver of a neighbour. There is no `walk-b` (the user's image generator refused it), so his walk alternates stand and one step.
- `hero8_hermione`: three clean rows. `hero8_ron`: clean idle; figures touch in both walk sheets (up to 6 px and 0 px crossed).
- `boss8_quirrell`: figures touch in both sheets (0 px and up to 7 px). `boss8_basilisk`: clean idle; figures touch in the gaze sheet (0 px).
- All 10 core enemies come from `sprites/mobs/`. All 9 Diagon Alley props and the floor were written.

When figures touch, the tool cuts at the emptiest column near each boundary and prints a WARNING with the number of pixels crossed. "0 px" means the cut ran through empty columns. The clean fix is a regenerated sheet with wider gaps.

Things only a human can check:

- Order of the five figures in every sheet (assumed to follow the prompt).
- Obstacle density and the solid part of each prop (`hit` in `arena._sprite`: 78% of a building's height, the base of a lamp post, the inner part of a pit).
- Whether the mirrored floor tiling looks acceptable.
- Whether the hero's ring, outline and glow are enough, or too much.
- How the sounds and the music sound together.

## Balance

The smoke bot is invulnerable, walks in circles and picks cards round-robin, so its build is luck.

| Run | Boss health | Bot build | Result |
|---|---|---|---|
| 44913528986 | first values (750 to 9800) | wand, expelliarmus, depulso, arresto, aguamenti, riddikulus | 9 of 10 bosses still alive after 120 s |
| 45108219487 | lowered (480 to 5200) | wand, expelliarmus, stupefy, bombarda, reducto, solem | every boss dead in 10 to 33 s |
| 45183452206 | current (1200 to 40000) | wand, expelliarmus, finite, glacius, riddikulus, incarcerous, leviosa, protego | warden dead in 68 s; the other 9 still alive after 120 s |

The user, playing the lowered values, said Quirrell (1500) and the Basilisk (2900) "died very fast". Current health: warden 1200, quirrell 5500, aragog 8000, basilisk 13000, hex 16000, dementor 19000, idol 22000, nagini 26000, greyback 28000, voldemort 40000. That is about 2.5 to 10 times the lowered values. It is a guess: build quality changes boss damage about sixfold in the bot logs, and the third run shows that a build of control spells cannot kill most bosses in two minutes at these values. A player with a poor build may find late bosses very long. Decision: ship the guess and correct it from the user's report of how long the Quirrell and Basilisk fights now take. Bosses also got a little harder to hide from: they re-enter at the screen edge when left 640 units behind.

The regular upgrade pool was 49 picks with the old limits (the user ran out at level 50). With the new limits the bot log printed 87, a number that may be a few picks off because the old test stopped on a random card; the new test prints the exact figure. After that, every level offers repeatable cards.

## Open Work

1. Confirm the two pending CI runs. Then the user's report on the newest green APK: does the hero stand out; how the open world feels (obstacle density, enemies getting around buildings, the repeated floor); how long Quirrell and the Basilisk take; whether the limits are clear; how the sounds are. Merge PR #2 when the user approves.
2. Floors and obstacle sprites for the other 14 maps (see "Open World"). Until then those stages are empty ground.
3. Flying enemies should cross pits; walls should stop spells. Both need per-obstacle flags in `world.push_out` and the shot update.
4. Enemies only sidestep; a deep pocket between two buildings can still hold a few until the leash pulls them out. A real path search is not implemented.
5. A second step sheet for Harry; regenerate the sheets whose figures touch if they look clipped.
6. Five-direction sheets for Dementor, Nagini, Voldemort; top-down poses for Nagini.
7. `README.md` still describes bordered arenas and the old limits (6 spells, 4 talismans, level 5). Update it.
8. Interface: spell icons on the cards; cards that grow with long text; the full font licence text in the game.
9. Release signing (below) is not configured.

## Art and References

- `assets/visual-kit/` — the user's painted masters and `VISUAL_BIBLE.md`. `locations — backup/` holds the user's copy of the old location paintings.
- `refs/` — earlier SVG concept boards, the user's GTA2 and Crimsonland screenshots (`source_examples/`), and `archive_previous/`. `refs/.gdignore` keeps Godot from importing them.

## Android Release Signing — Required for Future Updates

- `.github/workflows/build.yml` exports a debug APK with the CI debug keystore. It is not a stable release identity.
- A distributable update must keep the `applicationId` (`com.vano3667.hexdistrict`) and be signed with the same persistent release certificate; increase `versionCode` on every release.
- Losing the keystore or changing the signing identity normally prevents in-place updates and can cost users their save data.
- `ANDROID_SIGNING.md` lists the four Actions secrets: `HOMEMENU_KEYSTORE_BASE64`, `HOMEMENU_KEYSTORE_PASSWORD`, `HOMEMENU_KEY_ALIAS`, `HOMEMENU_KEY_PASSWORD`. Never put secret values in chat, source or docs.
- A release-signing workflow is **not configured or tested**.

## Session Log

### 2026-11-20/21 — v1 prototype (on `main`)

- 5 chapters, 8 spells, code-drawn art, smoke test, CI with debug APK. Commits `c7bdbf50` to `c295f866`. The user confirmed the APK works.

### 2026-11-21 — other agents on `main`

- Signing documentation (`ANDROID_SIGNING.md`). Then a ten-chapter rewrite made without a Godot binary plus the first `assets/visual-kit` masters; those scripts do not parse and `main` has been broken since.

### 2026-11-21 — v2 (PR #1, closed) and v3 (PR #2)

- v2: pseudo-3D props, glow, weather, RU/EN, 10 chapters, 28 spells, synergies. CI run 44861199414 passed. Carried into v3.
- v3: commits `0f18274e`, `ec7affd2`, `d16aa67d`, `dd102f10` (duplicate push, superseded), `2d7b47a9`. Painted art pipeline, heroes, story bosses, fusions, meta shop, endless mode, music, tutorial, bestiary.
- `0051b313`: boss health lowered from the first bot log; HANDOFF and README rewritten.

### 2026-11-23 — obstacles, eight directions, boss poses

- The user pushed to `main`: an empty Diagon Alley floor, 9 props, 10 single-enemy files, five-direction sheets for Hermione, Ron, Quirrell and the Basilisk, two top-down Basilisk poses, a transparent core enemy atlas.
- `a56c5093` (CI run 45108219487 passed), `6720709d` (run 45108826126 passed), `0dfd7127` (run 45114618505 passed): sprite formats, hand-placed painted obstacles in Diagon Alley, eight facing sectors with hysteresis, boss sheets and top-down poses, emptiest-column cut.

### 2026-11-23 — interface

- `288548d7` and `37942eb7`: `scripts/ui/style.gd`, restyled `hud.gd`, centred level-up screen with a burst of light, fonts downloaded by the workflow, `name.png.png` accepted by the sprite tool, draw pass in the smoke test. CI runs 45123518238 and 45123708489 passed (test and APK). The user then said the menus all work.

### 2026-11-23 — limits, bosses, sounds, open world

- `d503a2ef`: `spells.gd` (limits, repeatable cards, limits line), new `i18n2.gd`, `enemies.gd` (boss health), `sfx.gd` (rewritten), `hud.gd` (limits shown). CI run 45183452206 passed (test and APK).
- `09bf235a`: `arena.gd` rewritten as the chunk generator; `world.gd`, `director.gd` and `render.gd` lose every border; enemies sidestep and are leashed; hero ring, outline and glow; `sfx.gd` gets a separate `levelup` sound. CI run 45184458087 was still running when this was written.
- This commit: `tests/smoke_test.gd` (open world walk, code-drawn stages, exact upgrade pool, sound streams, three more draw frames) and this file. Unverified.
- Decisions made without asking: limits 8 and 6, spell level 7; repeatable bonus cards instead of a still higher cap; boss health as in "Balance"; boss stages are open ground too (the user asked for no frames anywhere); the hand-made Diagon Alley layout was dropped for the generator; enemies and bosses left far behind re-enter at the screen edge; music left as it was, only the effects were redone.
