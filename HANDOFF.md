# HANDOFF — Harry Potter: Hex District

> Mandatory for every future coding agent: read this file first and update it before ending every session. Record changed files, actual test/build results, autonomous decisions, constraints and the next concrete step. Do not rely on chat history. Never write that a build or test happened unless it ran.

## Status

**Current stage:** playable Godot 4.3 game, "v3", on branch `feature/v3-heroes-bosses-meta` (draft PR #2). 15 story stages (10 chapters and 5 story-boss arenas), 3 heroes, 28 spells, 9 fusions, 3 evolutions, 12 synergies, a galleon shop, endless mode, procedural music, Russian and English, and painted art sliced from `assets/visual-kit` at build time. The user installed an earlier v3 APK on a phone and said the game works.

**Repository:** https://github.com/Vano3667/HPGTA-Game (public).

**`main` does not build.** Its scripts fail to parse (`scripts/game/art.gd:145`); every `build` run on `main` since `d0187896` has failed. The user keeps pushing art to `main`; PR CI tests the branch merged with `main`, so that art is picked up. Merging PR #2 repairs `main`. Merge only after the user approves the look on a phone.

**Last verified by CI:** `build` run 45108826126, commit `6720709d` merged with `main` `9277cb12`. Both jobs passed: sprite build (68 files), import, `[smoke] PASS` with 0 engine errors, debug APK of 55,614,691 bytes (artifact 14788482560). The commit that adds this file version comes after it; its result is in the PR #2 description.

**Not verified by anyone:** how the new art looks in the game. No agent can see images. The obstacle layout, the eight-direction heroes, the boss poses and every cut of a sheet whose figures touch are untested by eye.

**Next concrete step:** the user tries the newest PR #2 APK and reports on: obstacle positions and sizes in Diagon Alley, hero turning, Quirrell and Basilisk poses, and whether boss fights feel too short or too long. Fix from that feedback.

## Approved Brief

- Working title: **Harry Potter: Hex District**. Non-commercial fan game. Android, portrait, top-down survival roguelite.
- **Controls:** one thumb. Bottom-screen movement zone; all spells fire automatically.
- Inspiration: Vampire Survivors (auto-attack survival), Crimsonland (dense swarms), GTA2 (gritty overhead city).
- Use recognizable Harry Potter canon as the user requested; keep mechanics and layouts original; verify rights before any public or commercial release.
- Agents work end-to-end without asking the user to make design choices and keep this file updated.

Later user requests, all implemented unless listed under "Open Work": pseudo-3D look and sharper rendering; larger hero; particles and weather; Russian and English; 10 levels; 20 more spells with synergies in their own menu; fusions of 2, 3 and 4 spells; galleons and a stat shop; Ron and Hermione; procedural music; endless mode; tutorial and bestiary; five story bosses between levels (Quirrell, Basilisk, Dementor, Nagini, Voldemort); painted sprites and maps; obstacles as separate sprites on an empty floor; more facing directions for the hero.

## What the Game Contains

- **Stages** (`scripts/data/chapters.gd`): diagon (boss warden), hogwarts, *mirror* (Quirrell), forest (aragog), pitch, *dungeon* (Basilisk), ministry (hex), hogsmeade, *lake* (Dementor), vault (idol), crossroads, *classroom* (Nagini), prison (greyback), tower, *bridge* (Voldemort). Italic stages are duel arenas. A chapter lasts 120 s; one without its own boss ends with a portal.
- **Heroes** (`Spells.HEROES`): Harry (free), Hermione and Ron (120 galleons each).
- **Spells:** 28, data-driven by archetype. 6 spell slots, 4 passive slots, 5 levels.
- **Fusions** (`Spells.FUSIONS`): offered as a level-up card when every part is at level `5 - number of parts` or higher; they take no slot.
- **Synergies:** 12 rules "enemy has status X and is hit by element Y".
- **Meta** (`Spells.META`): ten permanent upgrades bought with galleons.
- **Endless mode:** chapters loop, duel arenas are skipped, `tier` raises difficulty.
- **Obstacles:** `world.obstacles` is a list of rectangles. They block the hero and every enemy, flying ones included. Spells and hostile curses pass through them.

## Code Map

| Path | Role |
|---|---|
| `scripts/main.gd` | Entry point; wires world, HUD, joystick, audio, save |
| `scripts/game/world.gd` | Simulation step, collisions, statuses and synergies, gold |
| `scripts/game/arsenal.gd` | Automatic spells and fusions |
| `scripts/game/director.gd` | Waves, elites, hazards, boss state machine (`""`, `tell`, `dash`) |
| `scripts/game/arena.gd` | Arena layouts; `PAINTED` table places painted obstacles per map |
| `scripts/game/render.gd` | All drawing passes; painted obstacles are sorted against the hero by `base` |
| `scripts/game/art.gd` | Heroes, enemies and bosses: painted sprite if present, else code-drawn |
| `scripts/core/sprites.gd` | Loads `res://art/gen/*`; direction sectors with hysteresis; mirroring |
| `scripts/data/*.gd` | Stages, enemies and bosses, spells, fusions, heroes, upgrades |
| `scripts/core/i18n.gd`, `music.gd`, `sfx.gd`, `save.gd` | Text rows `[English, Russian]`, audio, save |
| `scripts/ui/hud.gd`, `joystick.gd` | HUD strip, all menu panels, one-thumb stick |
| `tools/build_sprites.gd` | Slices the masters into `art/gen/` (git-ignored) |
| `tests/smoke_test.gd` | Headless bot test used by CI. It never draws a frame |

Run locally, in this order:

```
godot --headless --path . -s res://tools/build_sprites.gd
godot --headless --path . --import
godot --headless --path . -s res://tests/smoke_test.gd
```

The last step of the CI test job prints a "sprite build summary"; read it after every art change.

## Art Pipeline

Masters live in `assets/visual-kit/` (it has `.gdignore`). They are never modified. File formats the tool understands:

| Master | Runtime file | Notes |
|---|---|---|
| `sprites/<hero>-8dir-idle.png`, `-walk-a`, `-walk-b` | `hero8_<id>.png` | One row of five figures: front, front-right, right, back-right, back. The game mirrors the left side. Idle is required; with idle only, the walk is a bob and lean in code |
| `sprites/boss-NN-<name>-8dir-idle.png` plus one attack row | `boss8_<id>.png` | Same layout. Attack row: Quirrell `-cast` (every wind-up), Basilisk `-gaze` (the gaze wind-up) |
| `sprites/boss-02-cockatrice-basilisk-top-move.png`, `-top-lunge.png` | `top_basilisk_*.png` | One figure, true top-down, heading right; rotated in code while moving or dashing |
| `sprites/mobs/<name>.png` (or `<name> v2.png`) | `mob_<name>.png` | One enemy per file; overrides the atlas cell of the same name |
| `props/<map>/<type>-<size>-<name>.png` | `prop_<map>_<file>.png` | type `wall`, `low`, `pit`, `deco`; size `s`, `m`, `l`, `xl` (24, 52, 100, 180 world units wide) |
| `floors/<map>.png` or `locations/<map>.png` | `map_<map>.png` | Arena floor at scale 0.6; `floors/` wins |
| old atlases and single boss pictures | `hero_<id>.png`, `boss_<id>.png` | Fallbacks |

Results of the last verified sprite build:

- All 10 core enemies come from `sprites/mobs/` (the caster from `caster v2.png`). All 9 Diagon Alley props and the floor were written.
- `hero8_hermione`: three clean rows. `hero8_ron`: clean idle; in both walk sheets the figures touch.
- `boss8_quirrell`: figures touch in both sheets. `boss8_basilisk`: clean idle; figures touch in the gaze sheet.
- **Harry has no five-direction sheet**: `hero-wizard-8dir-idle.png` is not in the repository. He still uses the old four-direction atlas, where the back-facing pose has the wand arm pointing backward. The user's image generator refused Harry's walk sheets for likeness to third-party content.
- `ron-pseudo3d-8pose-atlas.png` and `hero-wizard-forward-wand-standing.png` were deleted by the user; the tool skips them.

When figures touch, the tool cuts at the emptiest column near each boundary and prints a WARNING with the number of pixels crossed. Such frames can show a clipped wand or a sliver of the neighbour. The clean fix is a regenerated sheet with wider gaps.

Things only a human eye can check:

- Order of the five figures in every sheet (assumed to follow the prompt).
- The `PAINTED` layout in `arena.gd` and the solid part of each prop (`hit`: 78% of a building's height, the base of a lamp post, the inner part of a pit).
- Old four-direction hero column order (`HEROES[...].cols` in `build_sprites.gd`).
- Mirrored sprites are now drawn with a flip transform around the feet. Before that, mirrored enemies may have been drawn one sprite-width to the side.

## Balance

The smoke bot is invulnerable, walks in circles and picks cards round-robin, so its build is luck.

| Run | Boss health | Bot build | Result |
|---|---|---|---|
| 44913528986 | old (750 to 9800) | wand, expelliarmus, depulso, arresto, aguamenti, riddikulus | 9 of 10 bosses still alive after 120 s |
| 45108219487 | current (480 to 5200) | wand, expelliarmus, stupefy, bombarda, reducto, solem | every boss dead in 10 to 33 s |

Build quality changes boss damage about sixfold, so boss health cannot be tuned from bot logs alone. Current values are the lowered ones from the first run. They are probably too low for a good build. Decision: leave them until the user says how the fights feel. A build is complete after 49 picks; later level-ups only heal.

## Open Work

1. User feedback on the newest APK, then fixes; merge PR #2 when the user approves.
2. Harry's five-direction sheet (needs a less recognizable design or another generator). Regenerate the sheets whose figures touch if they look clipped.
3. Obstacles for the other 14 maps: the user generates an empty floor and props per map, then add a `PAINTED` entry.
4. Flying enemies should cross pits; walls should stop spells. Both need per-obstacle flags in `world.push_out` and the shot update.
5. Five-direction sheets for Dementor, Nagini, Voldemort; top-down poses for Nagini.
6. Boss health once there is human feedback; a repeatable late-game card; a smarter test bot.
7. Release signing (below) is not configured.

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
- `a56c5093`: `tools/build_sprites.gd` learned the formats in the table above. CI run 45108219487 passed.
- `6720709d`: `arena.gd` places painted obstacles in Diagon Alley with collision; `render.gd` draws them in front of or behind the hero; `sprites.gd` got eight facing sectors with hysteresis, a four-phase walk cycle and in-place mirroring; the workflow prints a sprite summary. CI run 45108826126 passed.
- This commit: `art.gd` and `sprites.gd` show boss sheets and rotating top-down poses; `build_sprites.gd` cuts touching figures at the emptiest column instead of into equal parts.
- Decisions: boss health left alone (see "Balance"). The corrected back pose was not cut out of an opaque background by guesswork; the user was asked for clean art instead. Pits currently block flying enemies too.
