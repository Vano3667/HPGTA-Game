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
| `sprites/enemies-core-pseudo3d-atlas.png` | Main campaign enemy material: cauldron, sprite, mimic, spellcaster, armor, book, portrait, spider, wraith and plant language | Extract into individual 256–512 px source sprites; preserve the dark outline and contained ground shadow. |
| `sprites/enemies-expansion-pseudo3d-atlas.png` | Expansion enemy material: centaur, cursed ball, drowned, automaton, serpent, frost witch, carriage shade, gargoyle, prison guard and owl construct | Use as the canonical finish/material reference for chapters 6–10; individual sprites need a clean 4- or 8-direction redraw before runtime use. |

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

## Production handoff

1. Keep these PNGs as immutable masters and create non-destructive working copies per animation/tileset task.
2. For runtime, crop foreground props and characters to individual transparent sprites. Export desktop source at 4× target size, then author a separate 1× or 2× gameplay atlas; do not use browser-style filtering.
3. Use 4 directions for standard mobs, 8 directions for the hero and boss locomotion, and at least idle / move / attack / hurt / defeat states.
4. Put gameplay collision and foot/contact-shadow placement in metadata, not in image canvas guesses.
5. Every scene needs a tileable ground, a walkable/decor layer, an obstruction layer, a telegraph layer and a front/occlusion layer. Existing `world.gd` layouts are the authoritative collision prototypes.

## Generation prompts

The built-in image generator was used for every PNG in this folder. The location prompt pattern was: **high-resolution portrait 9:16 environment keyframe, near-vertical orthographic pseudo-3D combat arena, original dark magical setting, no characters/text/UI/logos, readable loops and escape lanes, subtle top-left light and lower-right contact shadows**. Character prompts additionally required transparent alpha, isolated cells, strong collision silhouettes and no scenery.

When generating a new asset, preserve those constraints and make the output original. Generate a separate image for each distinct asset; do not use an arbitrary multi-subject board as an imported runtime sprite sheet without a cleanup/redraw pass.
