# HANDOFF — Hex District: Curfew

> **Mandatory for every future agent:** read this file at the start of each session and update it before ending. Keep the actual project status, changed files, test/build results, decisions, known issues, blockers and next concrete task here. This file is the persistent handoff; do not rely on chat history.

## Project Status

**Stage:** design package and five SVG level references are complete. Game code, engine project and APK have not yet been created.

**Last updated:** 2026-11-21

**GitHub:** https://github.com/Vano3667/HPGTA-Game — private repository, branch `main`. English README, concept, autonomous implementation prompt, HANDOFF and five English-labeled SVG references are published and verified.

**Immediate next action:** inspect the repository and local toolchain, select the implementation route, and build the complete playable five-district game autonomously.

## Approved Product Direction

- Working title: **Hex District: Curfew**.
- Platform/genre: Android portrait-first, top-down survival roguelite with automatic attacks and escalating enemy pressure. Use the accessible movement-focused auto-attacking survival genre as a high-level reference; do not copy another game's expressive assets or exact presentation.
- **Core input:** comfortable one-hand/one-thumb play. Place movement input in the bottom screen safe area; movement is free across the arena. All basic attacks, spells, target selection and pickups are automatic. No mandatory aim/fire/cast control or second hand.
- Player decisions: movement, positioning, upgrade selection, build synergies and route choice.
- Original world: city of Vesper, Gloam Academy, apprentice courier Mira Vale and the Starfall Orrery. No imported franchise characters, places, names, logos or crests.
- The complete first campaign has five authored districts, each with a unique hazard and boss. See `CONCEPT.md`.
- **Autonomy requirement:** coding agents must not ask the user clarification, approval, engine, art or design questions. Infer practical defaults from the approved brief, document consequential choices here, and continue end-to-end. If blocked, work around the problem and finish independent tasks; report exact remaining constraints, do not silently stop at a plan or first-level stub.

## Source Files

1. `README.md` — project entry point and reference index.
2. `CONCEPT.md` — complete game design, one-thumb controls, survival loop, five levels, spells and production target.
3. `PROMPT_FOR_AGENT.md` — autonomous coding-agent implementation prompt and acceptance checklist.
4. `refs/01_gloam_academy.svg` — Gloam Academy Rooftops.
5. `refs/02_lantern_market.svg` — Lantern Ward Night Market.
6. `refs/03_underline_metro.svg` — The Underline Metro.
7. `refs/04_briarwood.svg` — Briarwood Perimeter.
8. `refs/05_starfall_observatory.svg` — Starfall Observatory.

SVGs are self-contained authored concept maps, not final sprites or production-ready levels.

## Five Levels

1. Gloam Academy Rooftops — gust lanes; Copper Gargoylion.
2. Lantern Ward Night Market — warning lanterns and temporary safe lanes; The Glass Factor.
3. The Underline Metro — ghost-train lanes and leyline gates; The Faceless Conductor.
4. Briarwood Perimeter — telegraphed temporary roots; The Thornhart.
5. Starfall Observatory — rotating warned safe arc, interruptible phases; The Starfall Orrery.

## Work Completed Before the English Revision

- Authored the concept, original cast/world, combat progression and five authored level concepts.
- Created five standalone SVG scene/combat-layout references.
- Created the master implementation prompt, README, and persistent Handoff instructions.
- Created the private GitHub repository `Vano3667/HPGTA-Game` and uploaded all four documents and five SVGs to `main`.
- Validated all five SVGs as well-formed XML locally and verified the remote root contains the four docs and all five references.
- No game source code, engine project, Android build, device test or gameplay build exists yet.

## Current English Revision

- **Requested change:** all prompts and project information in English; redesign the game around a Vampire Survivors-like auto-attacking survival roguelite; one-handed bottom-screen movement; the development agent works autonomously without asking the user for decisions or clarifications.
- **Files updated:** `README.md`, `CONCEPT.md`, `PROMPT_FOR_AGENT.md`, `HANDOFF.md`. SVG artwork already contains English labels; no graphic relabeling was needed.
- **Publication state:** all four English Markdown files are published on private GitHub `main`. The remote root and `refs/` were verified to contain all four Markdown files and five SVG references.

## Implementation Principles

- Inspect the repo and local toolchain before choosing an engine; preserve unrelated work.
- If no existing project, autonomously choose Godot 4 2D/GDScript unless a clearly better installed toolchain is available; record rationale and versions here.
- Build/test vertical slices but continue to the full five-level campaign; do not stop after a plan or prototype if more work is possible.
- Prefer local/offline gameplay, data-driven weapon upgrades, automated combat, strong one-handed mobile usability and readable telegraphs.
- Never claim tests, Android export or device behavior passed unless actually executed.
- Before each session ends, log changed files, actual commands/results, unresolved issues and the next concrete task.

## Checks and Known Limitations

- All five SVGs were revalidated as well-formed XML during this revision.
- A text scan found no Cyrillic characters in the Markdown project documents.
- GitHub API verification confirmed the remote root contains `README.md`, `CONCEPT.md`, `PROMPT_FOR_AGENT.md` and `HANDOFF.md`; `refs/` contains the five expected SVGs.
- A local GitHub CLI clone attempt failed because Git's HTTPS credential acquisition was unavailable. The configured GitHub API integration successfully published the files.
- The documents and visual references do not constitute a game implementation. Engine import/render, Android build and gameplay have not been tested.

## Session Log

### 2026-11-21 — English brief and control redesign

- **Request:** translate all project information/prompts to English; pivot to automatic-attacking survival roguelite; use one-hand, one-thumb bottom-zone movement; require autonomous work without asking user decisions.
- **Design decisions:** treat the survival genre as a high-level reference, keep all world/art/UI original; retain five districts, adapt them to escalating timed survival, experience pickups, level-up choices and automatic spell synergies; remove mandatory dual-stick, manual aim/fire and required active buttons.
- **Next:** inspect the existing repository/toolchain and begin implementing the complete playable campaign autonomously. Do not ask the user for design or engine choices; record decisions and actual test results here.
