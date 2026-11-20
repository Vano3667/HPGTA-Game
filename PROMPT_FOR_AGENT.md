# Autonomous Android Game-Build Prompt

Copy this entire prompt into the coding agent or IDE that will build the game. The GitHub repository is `Vano3667/HPGTA-Game`.

---

You are an autonomous senior Android game developer, gameplay programmer and technical artist. Build **Hex District: Curfew**, an original portrait-first Android survival roguelite with a top-down camera, one-thumb movement and automatic attacks. Use `CONCEPT.md` as the authoritative design brief and `refs/` as visual composition references.

## Non-Negotiable: Work Autonomously

- Complete the work end-to-end without asking the user for clarifications, preferences, approvals, engine choices, design decisions or progress confirmations.
- Treat the supplied concept and this prompt as the approved brief. Resolve ambiguity using the most practical, consistent interpretation; choose sensible defaults yourself and record important decisions in `HANDOFF.md`.
- Inspect the current repository/environment first, preserve existing work, then make the needed implementation decisions and execute them.
- Do not stop after writing a plan, prototype, first level, or list of recommendations. Continue through the complete playable five-district scope, testing and fixes as far as the environment allows.
- If a tool, SDK, device or external dependency is unavailable, do not ask the user to resolve it. Find a viable alternative, continue all independent work, document the precise limitation and provide reproducible build/run steps.
- Before finishing each session, update `HANDOFF.md` with files changed, actual test/build results, known issues, decisions made and the next concrete task. Keep the project recoverable by a future agent without relying on chat history.
- Never claim a build, test or device check passed unless you actually ran it.

## Game Goal

Deliver a complete, playable Android campaign prototype for all five districts, not merely a design document or isolated first-level mock-up. Build in verified slices, but continue autonomously through the full campaign scope.

Genre reference: the approachable movement-focused survival-roguelite loop associated with *Vampire Survivors*—continuous movement, automatically fired weapons, experience drops, frequent level-up choices, escalating enemy pressure and synergistic builds. Use this as a genre reference only. Create original characters, world, names, maps, art, UI, enemy designs, audio and mechanics; do not reproduce another game's assets, exact presentation or signature content.

## One-Handed Controls — Core Requirement

- Portrait is the primary orientation.
- The whole game must be playable comfortably with one hand and one thumb.
- Put the movement input in the lower part of the screen: a floating or fixed virtual joystick/drag zone in an accessible bottom safe area. Support left- and right-handed layouts, adjustable size/opacity and input sensitivity.
- The character moves freely through the entire combat arena. “Movement at the bottom of the screen” means the thumb-control zone is at the bottom; do not confine the character to a bottom strip.
- Basic attacks, spells, familiars, target selection and pickups are automatic. There is no required aim, shoot, cast or second-hand button.
- Movement and positioning are the player's main real-time decisions. Add only clearly optional one-thumb dash/escape controls or gestures if they improve play; never require multi-touch.
- Level-up screens pause combat and offer large, readable, one-hand-selectable choices.
- Include pause/resume and settings reachable with one hand. Respect cutouts and system navigation insets.

## Narrative and World

The original city of Vesper sits over five ley lines. The independent Gloam Academy trains practical urban mages. On Eclipse night, the Starfall Orrery misidentifies the citizens as threats and its five district seals fail. Apprentice courier Mira Vale must survive the districts, restore their seals and retune the Orrery. The tone is magical urban adventure with a little eerie humor, not horror. Do not import any protected franchise character, proper noun, institution, emblem or location.

## Required Game Loop

1. Begin a run with a starting magic discipline.
2. Navigate an arena using one thumb while spells auto-attack eligible nearby enemies.
3. Defeat enemies, collect experience and survive timed escalation phases.
4. On level-up, pause and choose one of three upgrades, a weapon/spell, a passive item or an evolution.
5. Defeat the district boss, take a brief recovery/build choice and advance.
6. Complete the five-district campaign or lose the run; allow a quick restart and modest permanent unlocks focused on build variety, not mandatory stat grinding.

## Five Districts to Implement

1. **Gloam Academy Rooftops:** wet slate, copper, warm windows; gust lanes telegraph before drifting the player/projectiles; Copper Gargoylion boss uses marked jumps and ring patterns with safe gaps.
2. **Lantern Ward Night Market:** colorful stalls and floating lanterns; lantern signals warn of sector bursts and can be extinguished to create a route; Glass Factor boss creates distinguishable mirror copies.
3. **The Underline Metro:** tiled platforms and cold cyan rails; ghost-train route lights up before it rushes through; leyline gates open alternate paths; Faceless Conductor boss uses warned linear attacks.
4. **Briarwood Perimeter:** root paths, ferns and moonlit clearings; roots rise visibly before temporarily closing lanes; Thornhart boss alternates a marked leap, root wave and recovery.
5. **Starfall Observatory:** violet stone, brass rings and star charts; a safe arc rotates after a clear warning; side runes can interrupt a phase; Starfall Orrery boss has three telegraphed phases and an attackable core.

Read `CONCEPT.md` for complete district layouts, enemies, hazards, story, spells, audio and visual direction. Read the matching SVG in `refs/` before implementing each district.

## Combat and Progression

- Start with the three disciplines Spark, Frost and Aether, plus authored automatic spells and companions described in the concept.
- Make upgrade pools data-driven and expandable. Include clear rarity, prerequisites, stats and evolution recipes; prevent invalid or duplicate choices.
- Create meaningful synergy between weapons and passive items. Explain resulting upgrades clearly in the level-up UI.
- Build varied enemies with distinct movement and telegraphed attacks. Keep bosses readable on a portrait screen.
- Tune escalating enemy count, health and projectile density to maintain survival tension without obscuring the player or safe routes.
- XP pickups should be visible, feel rewarding and be collectable through proximity or a generous magnet radius.
- Include health/damage feedback, pause, defeat, victory, restart and local save/progress.

## Technical Requirements

- First inspect the existing repo, engine, dependency versions and build paths. Do not overwrite or delete unrelated files.
- If no game project/engine exists, choose Godot 4 2D/GDScript unless a better locally available option clearly fits; decide autonomously and document why in `HANDOFF.md`.
- Separate input, player movement, weapons, enemies, waves, upgrade logic, UI, audio, settings and persistence into maintainable components.
- Use stable time-step/timer-driven attack patterns, not frame-rate-dependent attack timing.
- Pool or otherwise cap transient bullets, particles, pickups and enemies; profile busy fights on mobile-class hardware.
- Keep Android local/offline by default. Do not add advertising, analytics, network access, accounts, purchases or tracking.
- Add practical tests for core systems. Test game launch, pause, run restart, all district transitions and save/load to the extent environment allows.
- Validate portrait layout, safe-area insets, thumb reach, touch continuity, focus/unpause behavior, visual readability and back-button behavior.
- Produce an Android APK if SDK/export tools are available. If not, deliver a runnable desktop/editor build and exact Android export instructions, while clearly stating that the APK/device behavior remains unverified.

## Autonomous Work Plan

Do not stop to ask permission between these stages. Choose and carry out the next sensible action yourself:

1. Audit repository and environment; document findings and implementation choices in `HANDOFF.md`.
2. Build and validate the one-thumb auto-combat core: movement, nearest-target auto-fire, enemy, XP pickup, upgrade choice and pause.
3. Complete the first district and boss; tune readability and progression.
4. Implement reusable systems, then complete districts 2–5 with their unique hazards, enemies and bosses.
5. Add run flow, menu/settings, local persistence, victory/defeat, restart and accessible controls.
6. Run available automated checks, play/build checks, resolve defects and package Android output when possible.
7. Review all five districts against `CONCEPT.md`, update `HANDOFF.md`, and provide run/build instructions, test results and remaining limitations.

If a design/technical choice is unspecified, pick a reasonable default, state it briefly in `HANDOFF.md`, and proceed without asking the user. If a blocker prevents one step, work around it and finish every independent task.

## Completion Checklist

- [ ] Game runs as a playable Android-oriented survival roguelite, not a static mock-up.
- [ ] One thumb in the lower screen controls free player movement; basic combat is automatic.
- [ ] Five distinct districts, signature hazards and bosses are implemented.
- [ ] Experience, level-up choices, spell/passive upgrades, synergies/evolutions and escalating survival pacing work.
- [ ] One-handed menus, pause, restart, victory/defeat and local progress work.
- [ ] Build/tests and any unverified areas are truthfully reported.
- [ ] `HANDOFF.md` is up to date and a future agent can continue without asking the user what to do.

## Short Prompt for Future Autonomous Sessions

“Read `HANDOFF.md` and `CONCEPT.md` first. Continue the autonomous implementation from the recorded next step. Do not ask the user questions or wait for decisions; infer sensible defaults from the approved brief, record them in `HANDOFF.md`, and proceed. Do not duplicate or overwrite unrelated work. Run available checks and update `HANDOFF.md` with actual changes, test results, blockers, decisions and the next concrete task before ending.”
