# HANDOFF — Harry Potter: Hex District

> Mandatory for every future coding agent: read this file first and update it before ending every session. Record changed files, actual test/build results, autonomous decisions, constraints and the next concrete step. Do not rely on chat history. Never write that a build or test happened unless it ran.

## Status

**Current stage:** playable Godot 4.3 game, version "v3", on branch `feature/v3-heroes-bosses-meta` (draft PR #2). It has 15 story stages (10 chapters and 5 story-boss arenas), 3 heroes, 28 spells, 9 spell fusions, 3 evolutions, 12 synergies, a galleon shop with permanent upgrades, endless mode, procedural music, Russian and English text, and painted art sliced from `assets/visual-kit` at build time.

**Repository:** https://github.com/Vano3667/HPGTA-Game (public).

**`main` does not build.** Commits `d0187896` and `3af70f4f` on `main` (ten-chapter expansion written without a Godot binary) fail CI with a parse error at `scripts/game/art.gd:145`; see `build` runs #6 and #7. The v3 branch was created from `main` HEAD `3af70f4f`, replaces those scripts and passes CI. Merging PR #2 repairs `main`. Do not merge it before the user has tried the APK on a phone.

**Verified by CI** (`build` run 44913528986, commit `2d7b47a9`, merged with `main` `3af70f4f`):

- Sprite build wrote 33 files: 3 hero sheets, 5 story-boss sprites, 10 enemy sprites from the expansion atlas, 15 arena floors.
- Project import, then `[smoke] PASS` with 0 engine `ERROR:` lines. Data check: 10 chapters + 5 boss arenas, 28 spells, 9 fusions, 12 synergies, 31 enemy types, 338 translation rows with both languages filled.
- Bot results are in "Balance" below.
- Debug APK exported: 55,211,298 bytes, artifact `hex-district-debug-apk` (id 14710383390).

The commit that adds this file version also lowers boss health (data only). Its CI result is recorded in the PR #2 description, not here.

**Not verified by anyone:** how anything looks or sounds. Nobody has run v3 on a device or seen a frame of it. Specifically unverified: hero facing directions, which enemy got which painted sprite, floor scale, readability of the new menus on a phone, the music, and all balance beyond the bot numbers.

**Next concrete step:** get the user's on-device feedback on the PR #2 APK, fix what it shows, then merge PR #2. After that, work through "Open work" below.

## Approved Brief

- Working title: **Harry Potter: Hex District**. Non-commercial fan game.
- Android, portrait-first, top-down survival roguelite.
- Inspiration: one-thumb movement and automatic attacks as in the Vampire Survivors genre; dense crowd patterns from Crimsonland; compact gritty city-map composition from the user's GTA2 references.
- **Controls:** one hand, one thumb. Bottom-screen movement zone; wand and spells attack automatically; no manual aim, second thumb or twin-stick input.
- Use recognizable Harry Potter canon as the user requested. Keep mechanics, compositions, HUD and layouts original. Verify use rights before any public or commercial release.
- Coding agents work end-to-end without asking the user to make design choices, and keep this file updated.

Scope changes the user asked for later (all implemented in v3 unless noted under "Open work"):

- Pseudo-3D look, sharper rendering, a larger hero on screen, environment effects and particles.
- Russian and English, switchable.
- 10 levels; 20 more spells with effects and synergies; synergies in their own menu item.
- Fusions made of two, three and four spells.
- A currency kept between runs and a shop for permanent stats.
- Ron and Hermione as playable heroes.
- Procedural music.
- Endless mode.
- Tutorial and bestiary.
- Five story bosses fought between levels: Quirrell, Basilisk, Dementor, Nagini, Voldemort (final).
- Use the user's painted sprites and maps from `assets/visual-kit`.

## What the Game Contains (v3)

- **Stages** (`scripts/data/chapters.gd`): diagon (boss warden), hogwarts, *mirror* (Quirrell), forest (aragog), pitch, *dungeon* (Basilisk), ministry (hex), hogsmeade, *lake* (Dementor), vault (idol), crossroads, *classroom* (Nagini), prison (greyback), tower, *bridge* (Voldemort). Italic stages are small duel arenas. A chapter lasts 120 s; one without its own boss ends with a portal.
- **Heroes** (`Spells.HEROES`): Harry (free), Hermione and Ron (120 galleons each), each with a second starting spell and different stats.
- **Spells:** 28, data-driven by archetype (bolt, nova, zone, strike, beam, orbit, stag, familiar). 6 spell slots, 4 passive slots, 5 levels.
- **Fusions** (`Spells.FUSIONS`): 4 of two spells, 3 of three, 2 of four. Offered as a level-up card when every part is at level `5 - number of parts` or higher. They take no slot.
- **Synergies:** 12 rules of the form "enemy has status X and is hit by element Y".
- **Meta** (`Spells.META`): ten permanent upgrades bought with galleons, including dodge and a one-time revive.
- **Endless mode:** chapters loop, duel arenas are skipped, `tier` raises difficulty, best tier is saved.
- **UI:** hero select, shop, Combos (fusions, evolutions, synergies), bestiary, how-to-play, first-run hints, settings including language, music and "Graphics: painted / simple".

## Code Map

| Path | Role |
|---|---|
| `scripts/main.gd` | Entry point; wires world, HUD, joystick, audio, save |
| `scripts/game/world.gd` | Simulation step, collisions, statuses and synergies, gold, rendering layers |
| `scripts/game/arsenal.gd` | Automatic spells and fusions |
| `scripts/game/director.gd` | Waves, elites, hazards, boss patterns, duels, endless mode |
| `scripts/game/arena.gd` | Arena layouts and props |
| `scripts/game/render.gd` | Pseudo-3D helpers (`Render.lift`), glow textures |
| `scripts/game/art.gd` | Code-drawn heroes and enemies; draws the painted sprite instead when one exists |
| `scripts/data/chapters.gd`, `enemies.gd`, `spells.gd` | All tunable data |
| `scripts/core/i18n.gd` | Every string as an `[English, Russian]` row |
| `scripts/core/sprites.gd` | Loads runtime art from `res://art/gen/` |
| `scripts/core/music.gd`, `sfx.gd` | Procedural music and sound effects |
| `scripts/core/save.gd` | Local save (`user://hex_district.cfg`) |
| `scripts/ui/hud.gd`, `joystick.gd` | HUD strip, all menu panels, one-thumb stick |
| `tools/build_sprites.gd` | Slices the masters into `art/gen/` (git-ignored) |
| `tools/asset_probe.gd` | Prints size, alpha and cell layout of each master (workflow `asset-probe`) |
| `tests/smoke_test.gd` | Headless bot test used by CI |

Run locally, in this order:

```
godot --headless --path . -s res://tools/build_sprites.gd
godot --headless --path . --import
godot --headless --path . -s res://tests/smoke_test.gd
```

Without the first command the game still runs; everything is then drawn in code.

## Art Pipeline

- Masters live in `assets/visual-kit/` (it has `.gdignore`, so Godot does not import them). They are never modified. Read `assets/visual-kit/VISUAL_BIBLE.md` first.
- `tools/build_sprites.gd` writes `hero_<id>.png` (4 columns down/left/right/up, 2 rows idle/step, 144 px cells), `boss_<id>.png` (288 px), `mob_<name>.png` (128 px) and `map_<file>.png`.
- Anything it cannot slice is skipped and the game draws that actor in code. Telegraphs and status markers are always code-drawn.

Two masters were skipped in the verified run because they have no transparent background:

| Master | Effect |
|---|---|
| `sprites/enemies-core-pseudo3d-atlas.png` (every pixel is semi-transparent) | cauldron, sprite, mimic, caster, armor, book, portrait, spider, wraith and plant are code-drawn |
| `sprites/hero-wizard-forward-wand-standing.png` (corrected back-facing pose) | Harry's back-facing frames still come from the atlas, where the wand arm points backward |

If the user re-uploads either file under the same name with a truly transparent background, the next build picks it up with no code change.

Guesses that need a human eye:

- Hero column order per sheet (`HEROES[...].cols` in `build_sprites.gd`): Harry `[0,3,1,2]`, Hermione and Ron `[2,3,1,0]`.
- Enemy names are assigned to atlas cells in reading order from `VISUAL_BIBLE.md` (`MOBS` in `build_sprites.gd`).
- Story bosses use the single-pose masters; the five 8-pose boss atlases are unused.
- Location paintings are used as the arena floor at scale 0.6 with no collision; walls painted on them do not block anyone.

## Balance

Bot log of run 44913528986 (invulnerable bot, picks upgrade cards round-robin, runs in circles):

- Mortal bot: died at 74 s in stage 1, level 3, 46 kills.
- Full run: victory, 14 stage clears, 2429 s simulated, level 66, 592 galleons. The bot's final build was wand, expelliarmus, depulso, arresto, aguamenti, riddikulus with no fusions, which is a weak damage build.
- The test force-kills a boss after 120 s. That happened to 9 of 10 bosses.
- Endless: 3 stages in 462 s. Upgrade pool is exhausted after 49 picks.

| Boss | Stage | Old HP | Bot damage in 120 s | New HP |
|---|---|---|---|---|
| warden | 1 | 750 | 296 | 480 |
| quirrell | 3 | 1700 | 1673 | 1500 |
| aragog | 4 | 2400 | killed in 98 s | 2400 |
| basilisk | 6 | 3400 | 3083 | 2900 |
| hex | 7 | 4000 | 2732 | 3000 |
| dementor | 9 | 5000 | 2792 | 3300 |
| idol | 10 | 5600 | 1873 | 2800 |
| nagini | 12 | 6600 | 2476 | 3600 |
| greyback | 13 | 7200 | 1416 | 2600 |
| voldemort | 15 | 9800 | 3610 | 5200 |

Reasoning: bot damage per second stops growing at stage 4 to 6 (about 20 to 30) because a build is complete after 49 picks, while boss health kept doubling. The new values assume a human with a sensible build deals roughly twice the bot's damage and aim at fights of one to one and a half minutes. That factor of two is an assumption, not a measurement. Charging bosses (greyback, nagini) take much less damage because they leave spell range.

## Open Work

1. On-device check of the PR #2 APK by the user; fix findings; merge PR #2.
2. Art: transparent re-exports of the two skipped masters (user), then check hero directions and enemy name mapping against what the user sees.
3. Use the boss 8-pose atlases (facing and attack frames).
4. Collision for painted maps (per-map obstacle rectangles in `chapters.gd`).
5. Late-game growth: after 49 picks every level-up offers only a heal. Add a repeatable card (for example +4% damage) so long runs and endless mode keep scaling.
6. Smarter test bot (prefers damage and fusions) so the balance table means more.
7. Release signing (below) is still not configured.

## Art and References

- `assets/visual-kit/` — the user's high-resolution pseudo-3D masters: 10 location paintings, 5 boss arenas, hero, Hermione and Ron atlases, two enemy atlases, five story bosses (single pose and 8-pose atlas each). This is the current visual direction.
- `refs/source_examples/` — eight user-provided screenshots, unchanged: three GTA2 city scenes and five Crimsonland scenes.
- `refs/01_diagon_alley.svg` … `refs/05_ministry_battle.svg`, `refs/character_harry_topdown.svg`, `refs/enemies_topdown.svg` — earlier hand-authored SVG concept boards.
- `refs/archive_previous/` — obsolete diagrams, kept for history.
- `refs/.gdignore` keeps Godot from importing the folder.

## Android Release Signing — Required for Future Updates

- `.github/workflows/build.yml` exports a debug APK with the CI debug keystore. It is for testing and is not a stable release identity.
- A distributable update must keep the same Android `applicationId` (`com.vano3667.hexdistrict`) and be signed with the same persistent release certificate as the installed version; increase `versionCode` on every release.
- Do not generate a replacement release key casually. Losing the keystore or changing the signing identity normally prevents in-place updates; users may need to uninstall and lose local save data.
- Read `ANDROID_SIGNING.md` for the four repository Actions secrets: `HOMEMENU_KEYSTORE_BASE64`, `HOMEMENU_KEYSTORE_PASSWORD`, `HOMEMENU_KEY_ALIAS`, `HOMEMENU_KEY_PASSWORD`.
- Never put secret values in chat, source, docs, `export_presets.cfg` or repository files. The user sets them under Settings → Secrets and variables → Actions.
- A release-signing workflow is **not configured or tested**. Keep the debug workflow, add a separate release path, verify the signature and a same-key upgrade, then record the result here.

## Session Log

### 2026-11-20/21 — v1 prototype (on `main`)

- Built the first playable game: 5 chapters, 8 spells, 6 passives, 3 evolutions, code-drawn art, procedural sound, local save, smoke test, CI with debug APK. Commits `c7bdbf50`, `0e304a29`, `ebf8eefb`, `be92587d`, `c4151b48`, `c295f866`.
- CI: the first attempt of runs #1 and #2 failed before any step and passed on re-run; runs #3 and #4 passed. The user installed the APK and confirmed the game works.

### 2026-11-21 — signing documentation (another agent)

- Added `ANDROID_SIGNING.md`, updated README and the agent prompt, added keystore patterns to `.gitignore`. No secrets stored; nothing about signing was tested.

### 2026-11-21 — ten-chapter expansion and visual kit (another agent, on `main`)

- Added `assets/visual-kit` masters and `VISUAL_BIBLE.md`, and rewrote several scripts for ten chapters without a Godot binary. Those script changes do not parse (`art.gd:145`); `build` runs #6 and #7 failed. `main` has been broken since.

### 2026-11-21 — v2 (branch `feature/v2-pseudo3d-ru-10-levels`, PR #1, closed)

- Pseudo-3D props with roof parallax, glow layer, weather and particles, native-resolution rendering, larger hero, RU/EN, 10 chapters, 28 spells, 12 synergies, Synergies menu.
- CI run 44861199414 passed (smoke test and APK). The branch conflicted with the new `main`, so its content was carried into v3 and PR #1 was closed.

### 2026-11-21 — v3 (branch `feature/v3-heroes-bosses-meta`, draft PR #2)

- Commits `0f18274e` (asset probe), `ec7affd2` (data), `d16aa67d` (game), `dd102f10` and `2d7b47a9` (UI, sprite tool, test, workflow). The last two touch the same five files; `dd102f10` is a duplicate push and is fully superseded by `2d7b47a9`.
- Everything listed under "What the Game Contains" and "Art Pipeline". Also fixed the second strip of the `sweep` hazard, and spells now aim at the boss 60% of the time when it is in range.
- CI: `asset-probe` run 44910649648 passed; `build` runs 44913487244 (`dd102f10`) and 44913528986 (`2d7b47a9`) passed both jobs.

### 2026-11-21 — balance and documentation

- Read the sprite and smoke logs of run 44913528986; recorded the results above.
- Lowered boss health in `scripts/data/enemies.gd` as in the "Balance" table. No other code changed.
- Rewrote this file and README for v3. Corrected the earlier statement that the repository is private.
- Decision: did not try to cut the corrected back-facing pose or the core enemy atlas out of their non-transparent backgrounds. Nobody on the agent side can look at the result, and a bad cut-out of the main hero is worse than the current pose. Asked the user for transparent exports instead.
