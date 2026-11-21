# HANDOFF — Harry Potter: Hex District

> Mandatory for every future coding agent: read this file first and update it before ending every session. Record changed files, actual test/build results, autonomous decisions, constraints and the next concrete step. Do not rely on chat history.

## Status

**Current stage:** the repository README documents a playable Godot 4.3 prototype and a CI smoke-test/debug-APK workflow. This documentation task did not independently run the game or build. A production release keystore and signed release pipeline are not configured or verified.

**Repository:** https://github.com/Vano3667/HPGTA-Game — private GitHub repository, `main` branch. The repo includes the game prototype, English design/prompt docs, visual references, and the new Android signing guide.

**Next development step:** keep the existing debug CI workflow intact. Configure the four repository Actions secrets with the release keystore and credential values through GitHub settings, then implement and verify a separate release-signed build. Do not request or store those values in chat or committed files.

## Approved Brief

- Working title: **Harry Potter: Hex District**.
- Android, portrait-first, top-down survival roguelite.
- Inspiration: one-thumb movement/automatic survival attacks as in the Vampire Survivors genre; dense top-down shooter/survival crowd patterns from Crimsonland; compact gritty city-map composition from the user's GTA2 references.
- **Controls:** one hand, one thumb. Bottom screen safe-area movement zone; free character movement across the entire arena; wand and spells automatically attack; no required manual aim/shoot, second thumb or twin-stick input.
- Use recognizable Harry Potter fan-game canon/locations as the user requested. Keep mechanics, compositions, sprites, HUD and scene layouts original and verify use rights before any commercial release.
- Five chapters: Diagon Alley, Hogwarts Courtyard, Forbidden Forest, Quidditch Pitch, Ministry of Magic / Department of Mysteries.
- Coding agents are required to work end-to-end autonomously without requesting choices or approvals, and to keep this file updated after each session.

## Art and References

- `refs/source_examples/` — eight exact user-provided screenshots copied unchanged: three GTA2 city scenes and five Crimsonland survival-combat scenes.
- `refs/01_diagon_alley.svg` — illustrated overhead fan-game scene board.
- `refs/02_hogwarts_courtyard.svg` — overhead courtyard scene board.
- `refs/03_forbidden_forest.svg` — overhead forest combat scene board.
- `refs/04_quidditch_pitch.svg` — overhead flying-sport arena board.
- `refs/05_ministry_battle.svg` — overhead Ministry battle board.
- `refs/character_harry_topdown.svg` — Harry player sprite direction/silhouette sheet.
- `refs/enemies_topdown.svg` — eight top-down enemy concept designs.
- `refs/archive_previous/` — earlier, cleaner diagrams, preserved as obsolete historical references. Do not use them as the main visual direction; matching obsolete files were removed from the repository root `refs/` folder.

The new SVGs are hand-authored vector concept boards, not outputs from a configured image-generation model, not playable scenes and not production sprite assets. The image-generation provider was unavailable in this session; attempted delegated image work did not complete, so the references were drawn directly as SVGs. All 12 SVG files (seven current boards plus five archived diagrams) passed XML parsing. Browser screenshot rendering was attempted but failed with OS access/IPC errors; import/render in a capable SVG/game engine remains unverified. Don't report raster-tested or in-engine validation.

## Character and Enemy Direction

Harry: recognizable from the overhead silhouette through round glasses, dark hair, lightning scar, red/gold Gryffindor scarf, dark robe and wand direction. The sheet currently documents four cardinal directions and a larger silhouette breakdown; don't claim a complete 8-direction sprite animation is finished.

Enemy sheet currently outlines: Aragog/giant spider, Dementor, Death Eater, animated armor, Inferi, Cornish pixie, werewolf and basilisk. Each final sprite should retain a readable overhead collision silhouette and distinct movement/attack telegraph.

## Work Completed in This Revision

- Preserved all eight user-supplied screenshot files unchanged under `refs/source_examples/` and published all eight to the GitHub repository.
- Created five new fan-game SVG scene boards for the requested Harry Potter locations and published them under `refs/`.
- Created overhead Harry player design and top-down enemy roster boards and published them under `refs/`.
- Moved the five previous schematic maps to `refs/archive_previous/` locally and remotely; removed their obsolete root paths.
- Rewrote README, concept and implementation prompt in English. Defined one-thumb bottom-zone movement, automatic wand/spell attacks, five recognizable canon chapters and autonomous full-scope agent expectations.
- Image generation/delegation was unavailable; custom vector reference boards were made directly instead. Do not say an image model or subagent generated them.

## Checks / Known Limits

- All 12 SVG files parsed as XML successfully: seven current concept boards, five archived diagrams.
- Eight user-provided PNG sources exist locally; all eight were verified on the GitHub `refs/source_examples/` path with expected names and file sizes.
- English Markdown documents were scanned; no Cyrillic characters were found.
- GitHub root and reference directories were verified: four English Markdown docs, five new scene boards, two character/enemy boards, eight original screenshot references and five archived diagrams.
- Browser screenshot preview of SVG failed in this environment with browser OS access/IPC errors; use a renderer in a future environment to inspect and revise art. Continue all independent game work rather than asking the user.
- This documentation update did not rerun the Android/game CI smoke test or export an APK. Use the `build` GitHub Actions workflow linked in the README for current prototype verification; release signing remains unconfigured.
- Two automated upload scripts completed all content updates but returned exit code 1 during cleanup because a temporary Windows path did not exist. The actual uploads completed; remote directory checks confirmed the files are present.

## Android Release Signing — Required for Future Updates

- The current `.github/workflows/build.yml` exports a debug APK using a CI debug keystore; it is for testing and is not a stable release identity.
- A distributable update must keep the same Android `applicationId` and be signed with the same persistent release certificate as the installed version; increase `versionCode` on every release.
- Do not generate a replacement release key casually. Losing the original keystore or changing signing identity normally prevents in-place install updates; users may need to uninstall and can lose local save data.
- Read `ANDROID_SIGNING.md` for the four repository Actions secrets: `HOMEMENU_KEYSTORE_BASE64`, `HOMEMENU_KEYSTORE_PASSWORD`, `HOMEMENU_KEY_ALIAS`, and `HOMEMENU_KEY_PASSWORD`.
- Do not request or place secret values in chat, source code, docs, `export_presets.cfg`, or repository files. Users must configure them under GitHub repository Settings → Secrets and variables → Actions.
- A production release-signing workflow is **not yet configured or tested**. The next coding agent must preserve the existing debug CI workflow, add a separate release signing path using those secrets, verify the signature and perform a same-key upgrade test, then record actual results here.

## Current Session Log

### 2026-11-21 — signing and update documentation

- Added `ANDROID_SIGNING.md` with Android update compatibility requirements, exact Actions secret names, secure handling guidance and CI release workflow requirements.
- Updated README and autonomous agent prompt to distinguish debug APKs from signed release builds and preserve signing identity.
- Added keystore/certificate and environment secret patterns to `.gitignore`.
- No secret values were provided or stored. The release workflow, keystore availability and signing/update test have not been verified.
- Next: configure the four GitHub Actions repository secrets without sharing values in chat, then implement and verify a release-signed APK workflow while retaining debug CI.

### 2026-11-21 — fan-game visual direction revision

- **User request:** use the GTA2-like screenshots and Crimsonland as examples; keep supplied screenshots for future reference; add top-down character and enemy designs; recognizable Harry Potter elements are required; handle failed agents independently.
- **Decisions:** preserve canon as fan-game content; set Harry as main playable character, familiar spells/creatures/locations; compose five campaign arenas from source screenshots' overhead street/survival readability; maintain the one-thumb automatic-combat loop from earlier approved revision.
- **Next:** continue autonomous game implementation; read this HANDOFF and the concept first, make engine/design choices independently, and record actual progress here.
