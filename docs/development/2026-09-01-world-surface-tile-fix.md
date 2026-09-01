# World Surface Tile Fix

Date: 2026-09-01

## Scope

Correct the prototype village runtime surface-tile extraction without changing gameplay, scene topology, or the shared world-surface shader.

## Changes

- Updated `tools/generate_world_surface_tiles.ps1` to accept explicit source X and Y coordinates for every extracted tile.
- Kept the grass, farmland, road, and water surfaces as individual padded 48px source tiles.
- Changed the road source from `(0, 288)` to `(0, 336)` while farmland remains at `(0, 288)`.
- Regenerated the runtime tile textures under `assets/environment/runtime/`.

## Result

- Farmland and road no longer resolve to byte-identical texture files.
- Edge, object, and transition tiles remain excluded from the repeated base-surface path.
- The existing `world_surface_tile.gdshader` remains the sole shared surface shader; semantic surfaces continue to use separate `ShaderMaterial` instances.

## Verification

- `scenes/tests/world_surface_visual_validation.tscn --validate`: `VALIDATION_DONE failures=0`.
- Validation stderr: empty.

## Follow-up

The road network still uses per-mesh local UV repeats. A later visual pass can align UV phase across road intersections if seams remain visible in the rendered scene.
