# HANDOFF — Harry Potter: Hex District

> Mandatory for every future coding agent: read this file first and update it before ending every session. Record changed files, actual test/build results, autonomous decisions, constraints and the next concrete step. Do not rely on chat history. Never write that a build or test happened unless it ran.

Last updated 2026-11-27. The agent that built v1 to v3 stops here and another agent continues. This file, `ART_PROMPTS.md` and the description of PR #2 are everything that carries over. No chat history is available to you.

## Кратко по-русски (для владельца проекта)

- Рабочая игра лежит в ветке `feature/v3-heroes-bosses-meta` (черновой PR #2). Ветка `main` не собирается; в неё кладутся только картинки.
- Последняя проверенная сборка: прогон `build` 45185443478 от 23.11.2026. APK лежит в его Artifacts.
- Работа остановилась на вопросе от 24.11: почему герои и враги стали нарисованы кодом. Причина не найдена, проверка настройки «Графика» осталась без ответа. Подробности в разделе `Where the Work Stopped`.
- Промты для картинок сохранены в `ART_PROMPTS.md`.
- Новому агенту достаточно написать: «Открой ветку `feature/v3-heroes-bosses-meta` репозитория Vano3667/HPGTA-Game, прочитай HANDOFF.md и продолжай с раздела Where the Work Stopped».

## Start Here

| What | Where |
|---|---|
| Working code | branch `feature/v3-heroes-bosses-meta` |
| Review and CI | draft PR #2, https://github.com/Vano3667/HPGTA-Game/pull/2 |
| Last tested code | commit `12b27c38`, `build` run 45185443478, https://github.com/Vano3667/HPGTA-Game/actions/runs/45185443478 |
| APK of that run | artifact `hex-district-debug-apk`, id 14822548616, on the run page |
| The user's art | pushed by the user to `main` under `assets/visual-kit/` |
| Image prompts | `ART_PROMPTS.md` |

Working rules that came out of this project:

- **Work only on the branch.** Do not merge PR #2 and do not change code on `main` until the user has approved the game on a phone. `main` holds the user's art uploads and a script rewrite by another agent that does not parse; the branch is the only working game.
- **Do not edit `HANDOFF.md` or `README.md` on `main`.** Both differ on the branch. An edit on `main` creates a merge conflict, and PR CI (which tests the branch merged with `main`) stops running while a conflict exists. `main` has a `START_HERE.md` that points to this file.
- **CI is the test bench** if you have no Godot binary. Every push to the branch starts the `build` workflow for PR #2: sprite build, font download, import, headless smoke test, debug APK. A run takes about three and a half minutes. Read the job log; the lines that matter start with `[sprites]` and `[smoke]`. The very first runs of this repository failed within seconds before any step and passed when re-run.
- **Nobody on the agent side has seen or heard the game.** The previous agent could not view images or hear audio, and CI renders no frame. Say plainly what is unverified.
- **The user** writes in Russian, installs the debug APK from the run's Artifacts on an Android phone and reports in words. He makes art with an image generator and uploads it to `main` under `assets/visual-kit/`. File names sometimes carry typos (`name .png`, `name.png.png`); the sprite tool tolerates them.
- **Never modify the masters** in `assets/visual-kit/`. Do not cut a subject out of an opaque background by guesswork; ask for transparent art.
- **Do not reword image prompts to get past the image generator's likeness filter.** It refused the hero's walk sheets; the decision was to animate the walk in code instead.
- Artifacts are deleted by GitHub after a retention period (an artifact of 23 November was listed as expiring on 2027-02-21). If the APK is gone, push a commit to the branch or re-run the workflow.

## Status

**What exists:** a playable Godot 4.3 game, called v3 here. 15 story stages (10 chapters and 5 story-boss stages), 3 heroes, 28 spells, 9 fusions, 3 evolutions, 12 synergies, a galleon shop, endless mode, procedural music and sound, Russian and English, painted art sliced from `assets/visual-kit` at build time, and an open world without borders whose obstacles are generated around the hero.

**Repository:** https://github.com/Vano3667/HPGTA-Game (public).

**`main` does not build.** Its scripts fail to parse (`scripts/game/art.gd:145`); every `build` run on `main` since commit `d0187896` has failed. Merging PR #2 repairs `main`.

**Last code verified by CI:** commit `12b27c38`, `build` run 45185443478 (2026-11-23). Both jobs passed.

- Test job 137729717829: sprite build wrote 69 files; fonts 3 of 3; import; `[smoke] PASS`; 0 engine errors.
- APK job 137730668560: `hex-district-debug.apk`, 56,331,930 bytes, signed with the CI debug key.
- `build` run 45184458087 (commit `09bf235a`, the open-world commit) also concluded with success. Its log was never read; the same code is covered by the run above.

**The commit that adds this file version** changes documents only (`HANDOFF.md`, `ART_PROMPTS.md`, `README.md`). Its CI run had not finished when this was written.

**Not verified by anyone on the agent side:** how anything looks or sounds. See `Things only a human can check`.

**What the user has confirmed on a phone:**

- v1 works (2026-11-21).
- v3 works (2026-11-22, said before asking about obstacles).
- The interface build, run 45123708489: the menus all work (2026-11-23).
- Nothing about the newest build except the question in the next section.

## Where the Work Stopped

In the order the next agent should deal with them.

### 1. Open question: the user sees code-drawn heroes and enemies

On 2026-11-24 01:35 UTC, after getting the build of run 45185443478, the user asked: why did the hero and enemy assets change to code-generated ones? **The cause was not found.**

Facts:

- The sprite build of that run wrote every sheet: `hero_harry`, `hero_hermione`, `hero8_harry`, `hero8_hermione`, `hero8_ron`, five `boss_` pictures, `boss8_quirrell`, `boss8_basilisk`, two `top_basilisk_` poses, 20 `mob_` files, 9 Diagon Alley props and 15 floors.
- The headless smoke test of that run found them (`[smoke] painted art found: 15/15 maps`).
- The APK artifact is 55.9 MB, about the size of the earlier builds with painted art (55.6 MB for run 45108826126).
- In the code the only switch for painted art is `Sprites.enabled`. It is set from the save key `sprites` in `main._apply_settings` and `world.start_run`. The save file `user://hex_district.cfg` survives installing a newer APK.
- On the build before (run 45123708489) the user wrote that the hero gets lost against the assets and the floor, so painted art was showing then.

The user was asked to open Settings and look at the second button (`Graphics: PAINTED / SIMPLE`, in Russian `Графика: РИСОВАННАЯ / ПРОСТАЯ`), and, if it already says painted, to tell whether the floor and buildings are simple too and whether all actors or only some are code-drawn. **No answer came before the handoff.**

Explanations, none confirmed:

1. The Graphics option was switched to SIMPLE while the user was trying the menus. Against it: in that mode the floor and the obstacles are code-drawn as well, and the user named only heroes and enemies.
2. An APK from another run was installed. The v1 builds from `main` are entirely code-drawn (and have 5 chapters).
3. The user met actors that never have a painted sprite: the chapter guardians `warden` (the boss of stage 1), `aragog`, `hex`, `idol`, `greyback`, and the enemies `echo`, `snowman`, `werewolf`. This does not explain the heroes.
4. A fault that only shows on a device. Between the build where art showed (`37942eb7`) and this one, the drawing changes are in `render.gd` (hero ring; the hero sprite drawn four more times in near-black as an outline; the hero sprite drawn once more additively at half brightness on the glow layer; floor tiling), `arena.gd` and `world.gd`. To the previous agent's knowledge `art.gd` and `sprites.gd` were last changed in `0dfd7127`, before the build where art showed; check the commit history. Nobody has seen what the outline and the additive pass do to the hero's look.

Suggested first steps:

- Ask the user for a screenshot, or for the answers above.
- Put a small build stamp on the main menu: short commit id, the Graphics setting, and how many painted sheets were found at start. Then any report from the phone identifies the build and the state of the art.
- If it is a device-only fault, make the outline and the additive hero pass switchable and bisect with two APKs.

### 2. The user's report on the newest build is still owed

The user was asked to report on the APK of run 45185443478:

- does the hero stand out now;
- how the open world feels (obstacle density, enemies getting around buildings, the mirrored floor);
- how long the Quirrell and Basilisk fights take;
- whether the build limits are clear;
- how the new sounds are.

None of this has been answered. Boss health in particular is a guess waiting for that report (see `Balance`).

### 3. Art for the other 14 maps

On 2026-11-23 the user asked for image prompts and got prompts for an empty floor and for obstacle sprites of the 14 maps that have none. They are in `ART_PROMPTS.md`. As of 2026-11-27 nothing new was uploaded (`main` is still at `1f64950f`). When files arrive:

- check the `[sprites]` log lines for every new prop and floor;
- add the new prop names to `Arena.KNOWN` in `scripts/game/arena.gd` (whether an exported APK can list `res://art/gen/` on its own is unverified; `KNOWN` is the fallback);
- the advice given to the user was to do two maps first (`02-academy-courtyard`, `boss-01-mirror-chamber`) and look at the floor tiling on the phone before making the rest.

### 4. An unconfirmed reading of a request

The user's message was `1. Напиши промты для генерации изображений` (write prompts for image generation). It was read as floors and obstacles. The reply offered boss prompts (Dementor, Nagini, Voldemort) in case that was meant; the user did not say. Those boss prompts were never written.

### 5. PR #2 is a draft and is not merged

The user has not approved the newest build.

## Approved Brief

- Working title: **Harry Potter: Hex District**. Non-commercial fan game. Android, portrait, top-down survival roguelite.
- **Controls:** one thumb. Bottom-screen movement zone; all spells fire automatically.
- Inspiration: Vampire Survivors (auto-attack survival), Crimsonland (dense swarms), GTA2 (gritty overhead city).
- Use recognizable Harry Potter canon as the user requested; keep mechanics and layouts original; verify rights before any public or commercial release.
- Agents work end-to-end without asking the user to make design choices and keep this file updated.

Later user requests, all implemented unless listed under `Open Work`: pseudo-3D look and sharper rendering; larger hero; particles and weather; Russian and English; 10 levels; 20 more spells with synergies in their own menu; fusions of 2, 3 and 4 spells; galleons and a stat shop; Ron and Hermione; procedural music; endless mode; tutorial and bestiary; five story bosses between levels (Quirrell, Basilisk, Dementor, Nagini, Voldemort); painted sprites and maps; obstacles as separate sprites on an empty floor; more facing directions for the hero; the upgrade choice in the middle of the screen; an effect on gaining a level; a decorative font, frames and styled text in the menus; a hero that stands out from the floor; tougher bosses; visible and higher limits on the number of skills; procedurally placed obstacles and no border around a location; more melodic sounds.

## What the Game Contains

Stages (`scripts/data/chapters.gd`). A chapter lasts 120 s (`SURVIVE_TIME`); one without its own boss ends with a portal. In a boss stage there are no waves and the boss walks in after 2.5 s.

| # | id | Type | Boss | Map (file base name) |
|---|---|---|---|---|
| 1 | diagon | chapter | warden | 01-diagon-alley |
| 2 | hogwarts | chapter | none | 02-academy-courtyard |
| 3 | mirror | boss stage | quirrell | boss-01-mirror-chamber |
| 4 | forest | chapter | aragog | 03-forbidden-forest |
| 5 | pitch | chapter | none | 04-storm-pitch |
| 6 | dungeon | boss stage | basilisk | boss-02-underground-dungeon |
| 7 | ministry | chapter | hex | 05-mysteries-archive |
| 8 | hogsmeade | chapter | none | 06-frost-village |
| 9 | lake | boss stage | dementor | boss-03-lakeside-forest-clearing |
| 10 | vault | chapter | idol | 07-serpent-vault |
| 11 | crossroads | chapter | none | 08-midnight-crossroads |
| 12 | classroom | boss stage | nagini | boss-04-ruined-classroom |
| 13 | prison | chapter | greyback | 09-storm-prison |
| 14 | tower | chapter | none | 10-astronomy-tower |
| 15 | bridge | boss stage | voldemort | boss-05-broken-bridge |

- **Heroes** (`Spells.HEROES`). Everyone starts with the wand and one more spell. Harry: Expelliarmus, 100 HP, speed x1.1, pickup radius x1.2, free. Hermione: Incendio, 85 HP, cooldowns x0.88, experience x1.15, 120 galleons. Ron: Depulso, 135 HP, speed x0.95, damage x1.1, damage taken x0.9, 120 galleons.
- **Build limits** (`scripts/data/spells.gd`): `WEAPON_SLOTS 8`, `MAX_LEVEL 7` (spells), `PASSIVE_SLOTS 6`, `PASSIVE_MAX 5` (talismans), `EVOLVE_LEVEL 5`. The limits are shown on the level-up screen, the pause screen, the Combos screen, the help screen, in the tag of every upgrade card and as `n/8` and `n/6` in the HUD strip.
- **Repeatable cards** (`Spells.BOONS`): when fewer than three regular upgrades are left, the choice is filled with Wand Polish (+4% damage), Quick Wrist (-2% cooldowns), Pumpkin Pasty (+12 max HP) and the Chocolate Frog (heal 40). A level-up is never an empty choice. Cooldown reduction is floored at 40% of the base in `Spells.cooldown_mult`; damage has no cap.
- **Fusions** (`Spells.FUSIONS`): offered as a level-up card when every part is at level `5 - number of parts` or higher; they take no slot. Two spells: firestorm (incendio + depulso), blizzard (glacius + aguamenti), thunderbird (baubillious + avis), sunlance (lumos + solem). Three: tempest (aguamenti + baubillious + depulso), prison (petrificus + incarcerous + leviosa), phoenix (incendio + confringo + flagrate). Four: legion (patronus + protego + lumos + solem), elements (incendio + glacius + aguamenti + baubillious).
- **Evolutions:** chain (wand + focus), maxima (protego + ward), inferno (incendio + haste).
- **Synergies:** 12 rules of the form: an enemy with status X is hit by element Y. The engine is `world.hurt` and `world._synergy`.
- **Meta** (`Spells.META`): ten permanent upgrades bought with galleons; the price is base x (level + 1). Galleons drop from 7% of regular enemies (1), from elites (4) and from bosses (20 + 4 x tier).
- **Endless mode:** chapters loop, boss stages are skipped, `tier` raises difficulty.
- **Text:** `scripts/core/i18n.gd` holds the big table of `[English, Russian]` rows; `scripts/core/i18n2.gd` holds newer rows (keys `x_...`) and falls back to the big table.
- **Enemies and bosses:** `scripts/data/enemies.gd`. 31 enemy types, 10 bosses. `spr` names the painted sprite; an empty or missing `spr` means the actor is always code-drawn.

## Open World

There is no arena. `scripts/game/arena.gd` cuts the ground into chunks of 400 world units (`CHUNK`) and keeps the 5 x 5 chunks around the hero (`KEEP = 2`); `Arena.update(w)` runs every step and does work only when the hero enters another chunk. A chunk is built from `hash(chunk x, chunk y, world.map_seed)`, so a place is the same when the hero comes back during a stage; `load_chapter` draws a new `map_seed`. The hero starts at the centre of chunk (0, 0), which is kept clear.

- **Painted stage** (a floor image exists and Graphics is set to painted): obstacles are the painted sprites `art/gen/prop_<map>_*.png` of that map (`Arena.palette`). Per chunk: a building with 60% chance, 1 to 3 medium things, 2 to 4 small ones, at least 52 units apart, so there is always a way through. `Arena.KNOWN` lists the Diagon Alley files as a fallback for exported builds, where the folder may not be listable.
- **Only Diagon Alley has painted obstacles.** On the other 14 maps the hero walks over an empty repeated floor with nothing to run around. Their floor images are still the old full location paintings with buildings painted in, which will look wrong when repeated. They need what Diagon Alley got: an empty floor in `floors/` and sprites in `props/<map>/`.
- **Code-drawn stage** (no floor image, or Graphics set to simple): blocks, trees, hoops and lamps in the chapter's colours, by `layout`.
- **Floor:** `render._floor` repeats the floor image as tiles, every second one mirrored, so edges always meet on identical pixels. `world.arena` is only the size of one floor tile. `Chapters.DUEL_ARENA` is unused.
- **Enemies:** spawn just outside the screen (`director.edge_pos`). One that is blocked by an obstacle steps sideways along it, to the left or right by the parity of its id. One left more than `world.LEASH` (640) behind the hero re-enters from the screen edge; this includes bosses. Crystals more than 1500 away are dropped.
- **Obstacles** block the hero and every enemy, flying ones included. Spells and hostile curses pass through.

The smoke test of run 45185443478 walked the hero 6059 units right and 2624 down in 55 s: at most 35 chunks were kept, 152 obstacles stood around the hero at the end from a palette of 9, and the farthest of 29 enemies was 626 units away.

## Hero Visibility

`render.gd`: a pulsing cyan ring with two turning gold arcs on the ground under the hero; a dark outline (the sprite drawn four times, offset, in near-black) around the painted sprite; on the additive glow layer a larger pool of light and the sprite once more at half brightness, so he stays brighter than the night veil and shows through an obstacle in front of him. The painted floor is drawn at 84% brightness. All of this is unseen by any agent, and it is the newest change to how the hero is drawn (see the open question).

## Code Map

| Path | Role |
|---|---|
| `scripts/main.gd` | Entry point; wires world, HUD, joystick, audio, save; `_level_fx()` |
| `scripts/game/world.gd` | Simulation step, collisions, statuses and synergies, gold, camera |
| `scripts/game/arsenal.gd` | Automatic spells and fusions |
| `scripts/game/director.gd` | Waves, elites, hazards, boss state machine (empty state, `tell`, `dash`) |
| `scripts/game/arena.gd` | Endless chunk generator: painted and code-drawn obstacles |
| `scripts/game/render.gd` | All drawing passes; floor tiling; hero ring and outline |
| `scripts/game/art.gd` | Heroes, enemies and bosses: painted sprite if present, else code-drawn |
| `scripts/core/sprites.gd` | Loads `res://art/gen/*`; direction sectors with hysteresis; mirroring |
| `scripts/data/*.gd` | Stages, enemies and bosses, spells, fusions, heroes, upgrades, limits |
| `scripts/core/i18n.gd`, `i18n2.gd`, `music.gd`, `sfx.gd`, `save.gd` | Text, audio, save |
| `scripts/ui/style.gd` | Fonts, theme, button, frame and card styles, drawn ornaments |
| `scripts/ui/hud.gd`, `joystick.gd` | HUD strip, all menu panels and their animated backdrop, one-thumb stick |
| `tools/build_sprites.gd` | Slices the masters into `art/gen/` (git-ignored) |
| `tools/asset_probe.gd`, `.github/workflows/asset-probe.yml` | One-off probe that printed sizes and transparency of the masters; not part of the build |
| `tests/smoke_test.gd` | Headless bot test used by CI, followed by a short draw pass over the real scene |

Run locally, in this order:

```
godot --headless --path . -s res://tools/build_sprites.gd
godot --headless --path . --import
godot --headless --path . -s res://tests/smoke_test.gd
```

The game: Godot 4.3, GDScript, GL Compatibility renderer, portrait, stretch mode `canvas_items`, world zoom 1.5 (`world.ZOOM`). Package `com.vano3667.hexdistrict`.

## Sound

`scripts/core/sfx.gd` synthesises 22 streams on a worker thread at start (at once in headless runs). Everything is bell and pluck tones in A minor pentatonic. Crystals climb an eight-note scale while the hero keeps collecting (the run resets after 1.1 s without a pickup); the wand cycles through four notes. Ids: `wand`, `stupefy`, `patronus`, `fire`, `ice`, `hurt`, `gem`, `warn`, `burst`, `boss_down`, `level` (a short charm chime that three spells use) and `levelup` (the level-up arpeggio, emitted by `world`). `main._on_level_up` also plays `level`, so both sound on a level-up. Music (`music.gd`, three loops: menu, battle, boss) was not changed. Nobody has heard any of it.

## Interface

- **Fonts.** The workflow downloads three files from `github.com/google/fonts` at a fixed commit into `art/gen/` before the import: `font_title.ttf` (Yeseva One), `font_body.ttf` and `font_bold.ttf` (Philosopher Regular and Bold). All three cover Cyrillic and are under the SIL Open Font License. A local checkout has no fonts unless you fetch them the same way; `style.gd` then falls back to the engine font. The help screen names the fonts and the licence; before a public release the full licence text should ship with the game.
- **Panels.** `hud._panel()` builds a dimmed screen with one framed column. `low = true` keeps the frame at the bottom for the thumb (pause, stage clear, summary, heroes); the main menu and the level-up choice are centred. Long screens call `_scroll()`.
- **Level-up.** Centred, with an additive backdrop (flash, glow, rays, rings, sparks). A transparent guard swallows taps for the first 0.4 s. Whether long Russian card texts fit the fixed-height cards is unseen.
- **Settings** (`hud.show_settings`): language, graphics (painted or simple), music, sound, hand, stick size, stick opacity, sensitivity, screen shake, vibration, damage flash, high-contrast telegraphs.

## Testing

`tests/smoke_test.gd` runs everything in one `_process` call first: data and text checks, a mortal bot, an invulnerable bot through all 15 stages, three endless stages, a 55-second walk in one direction across the open world, all 15 stages with code-drawn graphics, synergies, fusions, the shop, a checkpoint round trip and the upgrade pool. Then it opens every panel in both languages and checks the sound streams. Then it builds the real scene once more and returns `false` from `_process` for a dozen frames, changing what is on screen each frame, so the draw code runs; it prints how often the HUD and the arena drew. A script error anywhere fails the CI job through the `SCRIPT ERROR` grep.

What this cannot show: whether anything looks or sounds right, and anything that happens only on a device.

Results of run 45185443478:

- Data: 10 chapters and 5 boss stages, 28 spells, 9 fusions, 12 synergies, 31 enemy types, 338 + 18 text rows.
- Mortal bot: died at 62 s in stage 1, level 2, 35 kills.
- Invulnerable bot: victory, 14 stage clears, 2451 s simulated, level 99, 847 galleons; all 10 bosses had to be force-killed after 120 s (see `Balance`).
- Endless: 3 stages in 487 s.
- Upgrade pool: 85 regular picks, then repeatable cards.
- Sound: 22 of 22 streams. Draw pass: 12 frames, the HUD drew 28 times, the arena 20 times.

## Art Pipeline

Masters live in `assets/visual-kit/` (it has `.gdignore`). They are never modified. `tools/build_sprites.gd` writes the runtime files into `res://art/gen/`, which is not in git. File names are matched ignoring case, stray spaces and a doubled extension.

| Master | Runtime file | Notes |
|---|---|---|
| `sprites/<hero>-8dir-idle.png`, `-walk-a`, `-walk-b` | `hero8_<id>.png` | One row of five figures: front, front-right, right, back-right, back. The game mirrors the left side. Idle is required; with idle only, the walk is a bob and lean in code; with idle and one step sheet the two alternate. Base names: `hero-wizard`, `hermione`, `ron` |
| `sprites/boss-01-quirrell-8dir-idle.png`, `-8dir-cast.png` | `boss8_quirrell.png` | Same layout; the cast row shows during every wind-up |
| `sprites/boss-02-cockatrice-basilisk-8dir-idle.png`, `-8dir-gaze.png` | `boss8_basilisk.png` | The gaze row shows during the gaze wind-up |
| `sprites/boss-02-cockatrice-basilisk-top-move.png`, `-top-lunge.png` | `top_basilisk_*.png` | One figure, true top-down, heading right; rotated in code while moving or dashing |
| `sprites/mobs/<name>.png` (or `<name> v2.png`) | `mob_<name>.png` | One enemy per file; overrides the atlas cell of the same name. Only the 20 names in `MOBS` are looked up |
| `props/<map>/<type>-<size>-<name>.png` | `prop_<map>_<file>.png` | type `wall`, `low`, `pit`, `deco`; size `s`, `m`, `l`, `xl` (24, 52, 100, 180 world units wide). Any map folder is picked up |
| `floors/<map>.png` or `locations/<map>.png` | `map_<map>.png` | Floor tile at scale 0.6, repeated mirrored; `floors/` wins |
| old atlases and single boss pictures | `hero_<id>.png`, `boss_<id>.png`, `mob_<name>.png` | Fallbacks |

New five-direction sheets for other bosses need a line in `DIR_SHEETS` (and `TOPS` for top-down poses) in `tools/build_sprites.gd`, and, if the attack row should show only for some patterns, a line in `BOSS_ATTACK` in `scripts/game/art.gd`.

Sprite build of run 45185443478:

- `hero8_harry` is built from `hero-wizard-8dir-idle.png.png` and `hero-wizard-8dir-walk-a.png`. The idle sheet is clean. In the walk sheet all five figures touch; the cut crossed up to 8 px of art, the worst of all sheets. There is no `walk-b` (the image generator refused it), so his walk alternates stand and one step.
- `hero8_hermione`: three clean rows. `hero8_ron`: clean idle; figures touch in both walk sheets (up to 6 px and 0 px crossed).
- `boss8_quirrell`: figures touch in both sheets (0 px and up to 7 px). `boss8_basilisk`: clean idle; figures touch in the gaze sheet (0 px).
- Ten enemies come from `sprites/mobs/` (`cauldron`, `sprite`, `mimic`, `caster` from `caster v2.png`, `armor`, `book`, `portrait`, `spider`, `wraith`, `plant`); ten more come from the expansion atlas (`centaur`, `ball`, `drowned`, `automaton`, `serpent`, `frostwitch`, `carriage`, `gargoyle`, `guard`, `owl`), matched to atlas cells by order.
- Dementor, Nagini and Voldemort use their single pictures. There is no `hero_ron` (the old Ron atlas was deleted by the user); Ron uses `hero8_ron`.
- All 9 Diagon Alley props and 15 floors were written.

When figures touch, the tool cuts at the emptiest column near each boundary and prints a WARNING with the number of pixels crossed. 0 px means the cut ran through empty columns. The clean fix is a regenerated sheet with wider gaps.

Things only a human can check:

- Order of the five figures in every sheet (assumed to follow the prompt), and which atlas cell is which enemy.
- Obstacle density and the solid part of each prop (`hit` in `arena._sprite`: 78% of a building's height, the base of a lamp post, the inner part of a pit).
- Whether the mirrored floor tiling looks acceptable.
- Whether the hero's ring, outline and glow are enough, too much, or wrong.
- How the sounds and the music sound together.

## Balance

The smoke bot is invulnerable, walks in circles and picks cards round-robin, so its build is luck.

| Run | Boss health | Bot build | Result |
|---|---|---|---|
| 44913528986 | first values (750 to 9800) | wand, expelliarmus, depulso, arresto, aguamenti, riddikulus | 9 of 10 bosses still alive after 120 s |
| 45108219487 | lowered (480 to 5200) | wand, expelliarmus, stupefy, bombarda, reducto, solem | every boss dead in 10 to 33 s |
| 45183452206 | current (1200 to 40000) | wand, expelliarmus, finite, glacius, riddikulus, incarcerous, leviosa, protego | warden dead in 68 s; the other 9 still alive after 120 s |
| 45185443478 | current | wand, expelliarmus, riddikulus, flagrate, aguamenti, baubillious, incarcerous, arresto | all 10 still alive after 120 s |

Health left after 120 s in the last run: warden 266 of 1200, quirrell 1706 of 5500, aragog 3045 of 8000, basilisk 4427 of 13000, hex 11241 of 16000, dementor 8706 of 19000, idol 15581 of 22000, nagini 14723 of 26000, greyback 14501 of 28000, voldemort 19144 of 40000.

The user, playing the lowered values, said Quirrell (1500) and the Basilisk (2900) died very fast. The current values are about 2.5 to 10 times the lowered ones. They are a guess: build quality changes boss damage about sixfold in the bot logs, and the last two runs show that a build of control spells cannot kill most bosses in two minutes. A fight has no time limit, so a player with a poor build may find late bosses very long. Decision taken: ship the guess and correct it from the user's report of how long the Quirrell and Basilisk fights take. That report has not come.

## Open Work

1. Everything in `Where the Work Stopped`.
2. Floors and obstacle sprites for the other 14 maps. Until then those stages are empty ground.
3. Flying enemies should cross pits; walls should stop spells. Both need per-obstacle flags in `world.push_out` and the shot update.
4. Enemies only sidestep; a deep pocket between two buildings can still hold a few until the leash pulls them out. A real path search is not implemented.
5. A second step sheet for Harry; regenerate the sheets whose figures touch if they look clipped.
6. Five-direction sheets for Dementor, Nagini, Voldemort; top-down poses for Nagini. Prompts are not written.
7. Boss health, from the user's report.
8. Interface: spell icons on the cards; cards that grow with long text; the full font licence text in the game.
9. Release signing (below) is not configured.
10. Housekeeping the user may want: the branch `feature/v2-pseudo3d-ru-10-levels` (PR #1, closed) is superseded by v3 and can be deleted.

Improvements once proposed to the user and not asked for since: difficulty levels; more evolutions.

## Art and References

- `assets/visual-kit/` — the user's painted masters and `VISUAL_BIBLE.md`. `locations — backup/` holds the user's copy of the old location paintings.
- `refs/` — earlier SVG concept boards, the user's GTA2 and Crimsonland screenshots (`source_examples/`), and `archive_previous/`. `refs/.gdignore` keeps Godot from importing them.
- `ART_PROMPTS.md` — the image prompts given to the user and the file names the game expects.

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
- `09bf235a`: `arena.gd` rewritten as the chunk generator; `world.gd`, `director.gd` and `render.gd` lose every border; enemies sidestep and are leashed; hero ring, outline and glow; `sfx.gd` gets a separate `levelup` sound. CI run 45184458087 concluded with success.
- `12b27c38`: `tests/smoke_test.gd` (open world walk, code-drawn stages, exact upgrade pool, sound streams, three more draw frames) and HANDOFF. CI run 45185443478 passed (test and APK); its log is quoted in this file.
- Decisions made without asking: limits 8 and 6, spell level 7; repeatable bonus cards instead of a still higher cap; boss health as in `Balance`; boss stages are open ground too (the user asked for no frames anywhere); the hand-made Diagon Alley layout was dropped for the generator; enemies and bosses left far behind re-enter at the screen edge; music left as it was, only the effects were redone.
- The user asked for image prompts and received prompts for floors and obstacles of 14 maps (now in `ART_PROMPTS.md`).

### 2026-11-24 — the question about code-drawn actors

- The user asked why heroes and enemies are now code-drawn. The log of run 45185443478 and the code paths (`sprites.gd`, `art.gd`, `render.gd`, `main.gd`, `world.gd`, `save.gd`, `arena.gd`, `hud.gd`, `enemies.gd`) were read; no cause was found. The user was asked to check the Graphics setting. No code was changed.

### 2026-11-27 — handoff

- The user said his subscription is ending and another agent will continue, and asked to save all work and where it stopped.
- No new commits by the user since 2026-11-23; `main` at `1f64950f`, the branch at `12b27c38` before this commit.
- This commit (documents only): this file rewritten; `ART_PROMPTS.md` added; `README.md` updated for the open world, the limits, the fonts and the obstacle sprites. On `main` a new file `START_HERE.md` points to this branch; nothing else on `main` was touched. The PR #2 description was rewritten.
- Not done: no code was changed, so the open question in `Where the Work Stopped` is exactly where it was.
