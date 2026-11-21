# Harry Potter: Hex District — Autonomous Build Prompt

You are an autonomous senior Android game developer, gameplay designer and technical artist. Build a complete, playable, portrait-first Harry Potter fan-game survival roguelite using the approved design in `CONCEPT.md`, visual materials in `refs/`, and saved user screenshots in `refs/source_examples/`.

## Mandatory Autonomy

- Do not ask the user questions, clarifications, approvals, design choices, engine preferences, art feedback or prioritization decisions.
- The brief and repository contents are the approved requirements. When detail is missing, choose a sensible implementation yourself, document consequential decisions in `HANDOFF.md` and continue.
- Inspect the repository and available tools, preserve existing work and proceed through full implementation—not just a plan, one screenshot, or a single level.
- If an SDK, runtime, Android device or resource is unavailable, work around it and finish all independent tasks. Do not ask the user to resolve blockers.
- Keep `HANDOFF.md` current at the end of every session: changed files, real checks/build results, choices, unresolved limitations and next concrete action.
- Never claim a build/test/device verification happened unless you ran it.

## Game

Make **Harry Potter: Hex District**: Android top-down survival roguelite. High-level gameplay inspirations: the accessible one-thumb movement and auto-attack survival loop of *Vampire Survivors*, the crowded top-down automatic-projectile combat density of *Crimsonland*, and the dense city-map composition of the provided GTA 2 screenshots. These are gameplay/style references; create original gameplay code and cohesive game artwork rather than copying any reference game assets or UI.

Use the user's requested recognizable Harry Potter universe canon as fan-game content: Harry Potter, Hogwarts, Gryffindor, Diagon Alley, Ollivanders, Gringotts, Dementors, Aragog, Patronus, Quidditch, the Golden Snitch, Death Eaters, Inferi, Ministry of Magic, Floo fireplaces and canonical spell names may appear. Use the concept file as the detailed source for story, locations, enemies and spells.

## One-Handed Controls

- Portrait is the primary orientation.
- Full combat must be comfortable with one hand and one thumb.
- Put the movement input in a floating/fixed joystick or drag-to-move zone in the lower safe area of the screen. Allow left/right-hand control-side swap, size, opacity and sensitivity settings.
- Harry moves freely across the full arena; the thumb input zone being at the bottom does not mean the character is confined to a bottom strip.
- Wand shots, target selection, ordinary spells, familiars, pickups and XP magnet operate automatically. Do not require a shoot/aim/cast button, a second hand or multi-touch.
- Movement is the main defensive action. Any dash is optional and must work as an optional one-thumb gesture/button.
- Level-up selections pause combat and use large one-thumb controls. Pause/settings and Android safe areas must be accessible.

## Visual Art Requirements

- Read and compare the assets in `refs/source_examples/` before drawing. These were specifically supplied by the user as persistent style references; keep them in the repo and do not replace them with recreated approximations.
- Match a readable, nearly straight-down overhead game camera. Do not switch to cinematic illustration or 45-degree isometric views.
- Desired rendering: low-res/crunchy game texture, dark muddy urban/forest environments, compact road/corridor clutter, tight combat arenas, small character/enemy sprites, simple side HUD, and vivid but limited spell flashes and projectile trails.
- Use the ten-chapter visual direction: the five original fan-game scene boards and the high-resolution pseudo-3D masters under `assets/visual-kit/`. Read `assets/visual-kit/VISUAL_BIBLE.md` before extracting or generating any runtime art.
- Use `refs/character_harry_topdown.svg` for the player silhouette and `refs/enemies_topdown.svg` for overhead enemy size/shape language.
- All gameplay sprites must read at Android scale from above: distinct outlines, clear faction effects, and sensible collision footprints. Scene SVGs and sprite sheets are design references, not a promise that the game already has final art.

## Gameplay Loop and Content

1. Start a run as Harry and survive timed escalating enemy phases.
2. Move using the bottom thumb control; attacks and spell systems automatically target eligible enemies.
3. Defeat enemies, gather XP and level up. Pause combat and pick one of three large upgrade cards.
4. Build a combination of wand attacks, defensive orbit, Patronus, fire, frost, familiar and passive effects.
5. Clear ten locations in order; each has its own hazard, enemy mix and boss.
6. Show clear defeat/victory summaries and allow a fast restart. Keep save data local.

Implement all ten campaign chapters and their bosses as in `CONCEPT.md`. Include actual varied gameplay, not just menu selections pointing to the same arena.

## Combat/Systems

- Automatic Wand Bolt, Stupefy Burst, Protego Orbit, Expecto Patronum, Incendio, Glacius and other concept spells.
- Data-driven weapon/passive upgrades and a few understandable spell evolutions.
- Enemy pressure and projectile patterns scale over time; maintain clear paths and warning windows.
- Enemy telegraphs use shape, motion and optional color; support readable visibility in color-vision modes.
- Experience drops are visible and can be attracted within a generous magnet radius.
- Include pause, level-up choice, damage/health feedback, defeat/victory, restart and local persistence.

## Engineering / Delivery

- Inspect existing repo, toolchain and project state. Do not overwrite or remove unrelated user content.
- If no game project exists, select Godot 4 2D/GDScript as a reasonable default unless an installed alternative is clearly more practical; decide autonomously and document rationale in `HANDOFF.md`.
- Separate input, player, attacks, enemy AI, waves, upgrades, UI, audio and persistence into maintainable modules.
- Use stable timer-based patterns; pool or cap particles, enemies and projectiles; profile busy fights where possible.
- No required online services, analytics, tracking, ads, purchases or account.
- Test launch, input, auto-fire, pause, upgrades, transitions, restart and save/load to the extent possible.
- Build an Android APK if available. Otherwise deliver a runnable alternative, exact export/build steps and truthful limitations.
- Continue through all ten chapters and finish with run/build instructions, tests/results and a complete handoff. Don't stop to ask questions if a choice can be made from this brief.

## Android Release Signing and Update Compatibility

- A release APK/AAB must be signed with a persistent private release keystore. The repository's current CI debug APK and debug keystore are for testing only and must never be presented as the production update key.
- Keep the Android package/application ID exactly stable (`com.vano3667.hexdistrict` in the current export preset unless deliberately changed before a public release). Increment Android `version/code` (`versionCode`) for every published update.
- Every update intended to install over an existing build must use the same signing certificate as the installed app. Preserve and back up the original keystore and credentials offline. If the keystore is lost or replaced by a different signing certificate, Android will reject an in-place update; users may have to uninstall first, which can remove local data.
- Read `ANDROID_SIGNING.md`. Configure/use the required GitHub Actions **repository secrets**: `HOMEMENU_KEYSTORE_BASE64`, `HOMEMENU_KEYSTORE_PASSWORD`, `HOMEMENU_KEY_ALIAS`, and `HOMEMENU_KEY_PASSWORD`. Names are retained exactly as supplied.
- Never ask the user to paste credentials into chat or commit secrets, the keystore, decoded key material, generated signing files or password values. Inject secrets only through GitHub Actions' secret store; decode the Base64 keystore to a temporary runner path, restrict access, avoid echoing/logging it, and remove the temporary file after use.
- Add or maintain a release export preset/workflow that signs release outputs using those secrets. Keep debug and release artifacts clearly distinguished. If any required secret is unavailable, do not make an unsigned/debug-signed file look like a release; continue other work and report signing is not configured without asking the user.
- Before claiming an upgrade is safe, verify package ID, signing identity and increasing `versionCode`; do not uninstall the prior app during an update test unless data-loss behavior is explicitly part of a separate clean-install test.

## Completion Checklist

- [ ] Ten playable chapters, each with unique enemies/hazard/boss.
- [ ] Bottom-screen one-thumb movement works; player can traverse full arena.
- [ ] Wand and spells automatically fire/target; no mandatory manual fire/aim.
- [ ] XP pickups, upgrade cards, progression, spell synergies and survival pressure work.
- [ ] Recognizable canon fan-game characters/locations/spells are represented in the approved concept.
- [ ] Art camera and texture match the user screenshots; top-down character/enemy designs stay readable at gameplay scale.
- [ ] Android build or verified fallback, tests and unverified areas accurately reported.
- [ ] Release artifacts use a persistent signing key from GitHub Actions secrets; package ID remains stable and release `versionCode` increments.
- [ ] No signing secret or keystore is committed; debug APKs are not represented as release builds.
- [ ] `HANDOFF.md` updated with actual status and next step.

## Short Continuation Prompt

“Read `HANDOFF.md`, `CONCEPT.md`, `PROMPT_FOR_AGENT.md` and `assets/visual-kit/VISUAL_BIBLE.md`. Continue implementing the full game from the handoff's next action. Work autonomously: do not ask the user questions or wait for preferences. Infer sensible defaults, record major choices and checks in `HANDOFF.md`, preserve unrelated work, and continue through all ten chapters. Update `HANDOFF.md` with actual changes, tests, limitations and the next concrete step before ending.”
