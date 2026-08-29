# Playable Prototype 0.3 Player Experience Gap Audit

## Scope and Method

Audit date: 2026-08-29.

The audited build was `builds/windows/TheBrave.exe`, with the in-game label
`PLAYABLE PROTOTYPE 0.3.0`. This audit used the exported EXE, not any scene
under `scenes/tests/`. The executable was started from Windows and its title
screen was captured at runtime.

The tester attempted the visible `开始游戏` button with the mouse and `Enter`.
Neither action advanced the screen. The same failure was reported during a
normal player run, so this is treated as a player-facing blocker rather than a
test-automation limitation.

Runtime evidence captured outside the project tree:

- `C:\Users\Half_river\.codex\visualizations\2026\08\28\01a04698-8389-7110-8c69-15a940facb8a\audit-title-0.3.png`
- `C:\Users\Half_river\.codex\visualizations\2026\08\28\01a04698-8389-7110-8c69-15a940facb8a\audit-main-menu.png`

## Actual Player Path

| Step | Player sees | Player can do | Result |
| --- | --- | --- | --- |
| Double-click EXE | Dark gray background, text title, version text, one `开始游戏` button and a visible `Title` debug label. | Point and click the only button; press `Enter`. | Blocked. The screen does not advance. |
| Main menu | Not reachable. | Not reachable. | No player verification possible. |
| Character creation | Not reachable. | Not reachable. | No player verification possible. |
| Village/world | Not reachable. | Not reachable. | No player verification possible. |
| NPC/dialogue/shop/inventory/equipment/quest/party/combat/save-load | Not reachable. | Not reachable. | No player verification possible. |

The farthest point a first-time player can reach is the title screen. The
current executable therefore does not meet the 15-30 minute playable-demo
target.

## Player-Visible Asset Use

Assets actually visible in the EXE audit:

- Godot application icon.
- Text rendered by runtime `Label` nodes.
- A default-style runtime `Button`.

No authored title background, UI frame, portrait, item icon, character sprite,
environment art, audio, or music was reachable through the player path.

The title screen is created procedurally by
`scripts/menu/main_menu_controller.gd`; it currently uses runtime
`Control`, `Label`, `VBoxContainer`, and `Button` nodes rather than the
existing UI asset set. It also exposes the internal navigation state as the
`Title` label, which must not be present in the demo.

## Status by Player Experience

### A. Implemented and directly usable

None verified in the exported build beyond launching the title screen.

### B. Implemented with test or placeholder presentation

The repository contains test and prototype scenes for character visuals,
technical 2.5D presentation, UI, combat, and world exploration. These do not
count as demo functionality because a player cannot reach them from the EXE.

### C. Code or interfaces present but not player-accessible

- Main menu, mode selection, character-creation, load, and settings states.
- World scene transition to `scenes/world/test_region.tscn`.
- Dialogue, quests, shops, inventory, equipment, party, combat, interaction,
  fishing, save/load, time, and weather interfaces.
- Existing asset registries and the world sprite adapter.

Each item may have automated-test coverage, but none is confirmed usable by a
player in the exported build while the title transition is blocked.

### D. Missing from the playable demo

- A non-test `scenes/demo/` entry scene and a Prototype Village.
- An authored title screen with a visual background, music, UI skin, working
  start/load/settings/exit flows, and no debug text.
- A complete, art-backed village layout with streets, buildings, props,
  vegetation, water, forest entrance, and named points of interest.
- Five dialogue-ready NPCs with portraits, multi-line dialogue, choices, and
  quest hooks.
- Three complete player-visible quests, a 10-item buy/sell shop, grid
  inventory, visible equipment changes, recruitable party members, fishing,
  theft consequences, and a world-to-combat-to-world encounter loop.
- Actual EXE screenshots for Main Menu, Character Creation, World, NPC,
  Dialogue, Shop, Inventory, Equipment, Quest, Party, and Combat. Such
  screenshots must be created only after these paths are playable.

## Root Blockers and Priorities

1. **P0: Fix the title-to-game input path in the exported EXE.** Verify it by
   starting from a fresh EXE, using the mouse, and reaching the village. Do
   not accept a unit-test transition as proof.
2. **P0: Replace the demo entry point.** Add a player-facing
   `scenes/demo/` flow and remove debug/internal text from the display.
3. **P0: Build a real Prototype Village from an internally coherent existing
   asset set.** The current technical test region is not acceptable as a demo
   location.
4. **P0: Put actual NPC, dialogue, quest, shop, inventory, equipment, party,
   fishing, encounter, combat, and save/load loops on that village path.**
5. **P1: Fill visual gaps with compatible downloadable pixel-art assets only
   when the existing asset library cannot provide a consistent set.** Original
   downloaded assets remain unmodified.

## Acceptance Evidence Required After Remediation

The final review must include a second real-player playthrough from the EXE:

`Title -> Start -> Character Creation -> Village -> NPC -> Dialogue -> Quest ->
Shop -> Inventory -> Equipment -> Recruit -> Fishing -> Forest -> Encounter ->
Combat -> Loot -> Return -> Save -> Exit -> Load`.

It must provide runtime screenshots for each requested stage, list the exact
player operation that reaches it, and distinguish any remaining placeholders
from player-complete functionality.
