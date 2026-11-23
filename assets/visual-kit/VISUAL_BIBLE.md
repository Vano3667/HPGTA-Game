# Hex District pseudo-3D visual kit

This folder contains the high-resolution master images created for the pseudo-3D rebuild. They are source-reference assets: preserve them at full resolution, do not bake them into the 480×854 viewport, and never upscale from the runtime low-resolution output.

`.gdignore` deliberately keeps these masters out of Godot's import cache. Remove it only for a deliberate preview task; runtime should consume cleaned, purpose-built exports instead.

The playable build still renders compact procedural silhouettes in `scripts/game/art.gd`. That is intentional: it keeps a dense mobile swarm readable and memory-stable. A future art pass can crop, clean, animate and export the master material into production atlases without changing gameplay code or collision bounds.

## Visual rules

- Camera: near-vertical orthographic top-down; subtle depth and extruded props are allowed, but never a 45-degree isometric RPG camera.
- Readability: player effects are cyan/gold/blue; hostile effects are amber/red/green/violet and also use shape/motion telegraphs.
- Materials: wet cobble, aged stone, dark metal, cloth and magical glow should retain a real light direction: bright top-left planes and short lower-right contact shadows.
- Mobile scale: retain a clear collision silhouette before adding surface detail. Every large prop must leave at least one recoverable movement path.
- Copyright: these are original production references for a non-commercial fan prototype. Before public/commercial distribution, replace or license any protected character, place-name or brand references.

## Sprite masters

| Source | Intended use | Crop/export guidance |
|---|---|---|
| `sprites/hero-wizard-pseudo3d-atlas.png` | Hero presentation atlas: four aiming directions and four run poses | Treat as visual master only. Crop every pose to a common canvas with 10–15% transparent padding, then repaint interpolation frames rather than scaling the full sheet. |
| `sprites/hero-wizard-run-left-clean.png` | Clean left-facing running pose with one wand arm and one bent free arm | Use as the corrected running reference; the extra empty rear sleeve from the marked-up reference has been removed. |
| `sprites/hermione-full-body.png` | Adult witch companion with voluminous chestnut hair, book satchel and forward wand | Full-body transparent character master; preserve silhouette and wand direction when making gameplay crops. |
| `sprites/ron-full-body.png` | Tall, lanky adult wizard companion with ginger hair, freckles and forward wand | Full-body transparent character master with a distinct silhouette from the other party members. |
| `sprites/hermione-pseudo3d-8pose-atlas.png` | Hermione-style companion animation reference: 4 cardinal idle poses + 4 matching run poses | 4 columns × 2 rows; top row idle, bottom row run. Use this as the directional sprite-sheet master. |
| `sprites/ron-pseudo3d-8pose-atlas.png` | Ron-style companion animation reference: 4 cardinal idle poses + 4 matching run poses | 4 columns × 2 rows; top row idle, bottom row run. Use this as the directional sprite-sheet master. |
| `sprites/enemies-core-pseudo3d-atlas.png` | Main campaign enemy material: cauldron, sprite, mimic, spellcaster, armor, book, portrait, spider, wraith and plant language | Extract into individual 256–512 px source sprites; preserve the dark outline and contained ground shadow. |
| `sprites/enemies-expansion-pseudo3d-atlas.png` | Expansion enemy material: centaur, cursed ball, drowned, automaton, serpent, frost witch, carriage shade, gargoyle, prison guard and owl construct | Use as the canonical finish/material reference for chapters 6–10; individual sprites need a clean 4- or 8-direction redraw before runtime use. |

## Boss sprite masters

| Encounter | Single-pose source | Full atlas | Visual reference |
|---:|---|---|---|
| 1 | `sprites/boss-01-quirrell-dual-face.png` | `sprites/boss-01-quirrell-8pose-atlas.png` | Turbaned professor with a second pale face at the back of his head; preserve the dual-face silhouette and distinct attack tells. |
| 2 | `sprites/boss-02-cockatrice-basilisk.png` | `sprites/boss-02-cockatrice-basilisk-8pose-atlas.png` | Giant coiled serpent with a rooster-like head and scaled body; keep the long body readable in turns and strikes. |
| 3 | `sprites/boss-03-dementor.png` | `sprites/boss-03-dementor-8pose-atlas.png` | Floating hooded wraith with a tattered robe and cold spectral glow; preserve the hood and trailing silhouette. |
| 4 | `sprites/boss-04-nagini.png` | `sprites/boss-04-nagini-8pose-atlas.png` | Large dark viper with a heavy coiled body; retain a clear head direction and coil silhouette for lunges. |
| 5 | `sprites/boss-05-voldemort.png` | `sprites/boss-05-voldemort-8pose-atlas.png` | Pale, hairless final wizard with green magic; keep spell effects distinct from the body in animation exports. |

Each full atlas is a transparent 4-column × 2-row sheet: four cardinal idle poses in the top row and matching move or attack poses in the bottom row. Keep these high-resolution masters intact; crop and clean individual cells into consistently sized runtime frames as a separate production step.

## Location masters

| # | Game chapter | Source image | Gameplay promise |
|---:|---|---|---|
| 1 | Diagon Alley — Curfew on the Alley | `locations/01-diagon-alley.png` | Wet market lanes, compact cover and a vertical escape street. |
| 2 | Hogwarts Courtyard — Castle Under Lock | `locations/02-academy-courtyard.png` | Rune circle, statue cover and four dependable loops. |
| 3 | Forbidden Forest — Patronus at Midnight | `locations/03-forbidden-forest.png` | Open moonlit clearing with roots and deliberate exit paths. |
| 4 | Quidditch Pitch — Golden Snitch Run | `locations/04-storm-pitch.png` | Long flight lanes, goal posts and rotating safe gaps. |
| 5 | Ministry — Department of Mysteries | `locations/05-mysteries-archive.png` | Concentric archive rings, shelf islands and prophecy-orb sight lines. |
| 6 | Hogsmeade — Frost on the High Street | `locations/06-frost-village.png` | Ice crossroads and snowy side lanes. |
| 7 | Serpent Vault — Below the Old Temple | `locations/07-serpent-vault.png` | Central boss dais, toxic-water rings and flanking corridors. |
| 8 | Midnight Crossroads — Last Carriage Out | `locations/08-midnight-crossroads.png` | Four road approaches and straight rail-charge telegraphs. |
| 9 | Storm Prison — Break the Black Tide | `locations/09-storm-prison.png` | Flooded cell loops and a central drain arena. |
| 10 | Astronomy Tower — Storm Above the Clouds | `locations/10-astronomy-tower.png` | Radial platform routes, exposed edges and lightning telegraphs. |

## Boss arena masters

| Encounter | Boss | Source image | Arena layout |
|---:|---|---|---|
| 1 | Quirrell with the second face | `locations/boss-01-mirror-chamber.png` | Compact chamber centered on the Mirror of Erised, with an open fighting floor. |
| 2 | Cockatrice basilisk | `locations/boss-02-underground-dungeon.png` | Underground stone arena with a central dais and surrounding channels. |
| 3 | Dementor | `locations/boss-03-lakeside-forest-clearing.png` | Open forest-edge loop beside a moonlit lake, with trees and rocks around the perimeter. |
| 4 | Nagini | `locations/boss-04-ruined-classroom.png` | Damaged classroom with a clear central lane and desks, rubble and shelves around the edges. |
| 5 | Voldemort | `locations/boss-05-broken-bridge.png` | Broad damaged bridge with stone railings, a continuous central lane and drops beyond both sides. |

Each arena image is a high-resolution environment reference. Convert it into separate ground, obstacle, collision and foreground layers before using it as a playable scene.

## Production handoff

1. Keep these PNGs as immutable masters and create non-destructive working copies per animation/tileset task.
2. For runtime, crop foreground props and characters to individual transparent sprites. Export desktop source at 4× target size, then author a separate 1× or 2× gameplay atlas; do not use browser-style filtering.
3. Use 4 directions for standard mobs, 8 directions for the hero and boss locomotion, and at least idle / move / attack / hurt / defeat states.
4. Put gameplay collision and foot/contact-shadow placement in metadata, not in image canvas guesses.
5. Every scene needs a tileable ground, a walkable/decor layer, an obstruction layer, a telegraph layer and a front/occlusion layer. Existing `world.gd` layouts are the authoritative collision prototypes.

## Generation prompts

The built-in image generator was used for every PNG in this folder. The location prompt pattern was: **high-resolution portrait 9:16 environment keyframe, near-vertical orthographic pseudo-3D combat arena, original dark magical setting, no characters/text/UI/logos, readable loops and escape lanes, subtle top-left light and lower-right contact shadows**. Character prompts additionally required transparent alpha, isolated cells, strong collision silhouettes and no scenery.

When generating a new asset, preserve those constraints and make the output original. Generate a separate image for each distinct asset; do not use an arbitrary multi-subject board as an imported runtime sprite sheet without a cleanup/redraw pass.
