# Playable Prototype 0.3 Development Log

Date: 2026-08-29

## Scope

This checkpoint turns the existing systems into a player-visible prototype village without introducing a formal story, final world map, or final character roster.

## Completed In This Checkpoint

- Replaced residual test-character presentation paths and stabilized NPC idle presentation to avoid flicker.
- Added moving NPC presentation that uses walk animation only while moving.
- Hid misaligned building facade billboards while preserving their 3D collision shells.
- Expanded the prototype village with additional buildings, roads, water, forest edges, and basic world props.
- Added reusable interior transfer flow: door interaction moves the player to an interior test space and the exit returns to the village.
- Established a shared party inventory. Party members equip and use the player-owned inventory; consumables target the selected party member.
- Extended temporary dungeon rewards through artifact quality and removed internal generator counters from equipment display names.
- Added prototype-village regression coverage for interiors, shared inventory, equipment names, and high-quality dungeon rewards.

## Player-Facing Loop

1. Start from the title screen and enter the prototype village.
2. Explore, talk to NPCs, enter/leave a test interior, manage party equipment, and interact with the temporary dungeon.
3. Receive currency, experience, and randomized equipment through the current prototype interactions.

## Verification

- `tools/run_all_tests.ps1`: 23 test scenes passed, `TOTAL_FAILS=0`, `TOTAL_STDERR=0`.
- `tools/build_windows.ps1`: Windows export succeeded.
- `builds/windows/TheBrave.exe --headless --quit-after 120`: exited with code 0.
- `git diff --check`: no whitespace errors.

## Deliberate Prototype Limits

- All current doors lead to one reusable prototype interior, not building-specific interiors.
- Building billboards are hidden until visual alignment with the 3D collision shell is finalized.
- NPC wandering is local movement without navigation-agent avoidance.
- The dungeon is a text-driven reward loop, not a separate tactical battle map.
- Buildings, environment, and character visuals remain mixed placeholder and prototype asset integration.

## Next Milestone Recommendation

Build one short, player-complete village loop with distinct tavern, shop, smith, and residence interiors; then connect a real encounter, battle result, loot, equipment upgrade, and return-to-village flow. Validate every link in the Windows EXE, not only in headless tests.
