# EchoVeil Forme — Current State Audit

## What is already implemented
- **Core player controller**: run/jump with coyote time + jump buffer, variable jump height, pickaxe swing, damage states, death/restart flow.
- **Global progression**: shards/health/lives/current level tracked in autoload `GameState`, plus JSON save/load.
- **Level flow**: menu → intro scroll → shift protocol → level scenes, and per-level `LevelExit` that saves and moves to next level.
- **Enemies/hazards**: drone patrol/chase/stun + stomp behavior, and a timed horizontal beam hazard.
- **Breakables/collectibles**: rocks can be broken, spawn shards, shards animate toward HUD and heal every 25.
- **UI systems**: HUD for shard count/health/lives, transition fade layer, game over screen, touch controls.

## What appears broken or fragile right now
- **Missing level scenes referenced by code**: `level_manager.gd` references `level3.tscn` and `level4.tscn`, but only `level1.tscn` and `level2.tscn` exist.
- **Potential missing asset path**: `drone.tscn` references `res://echoveil/Canvas/drones/Hovering robot with glowing trail.png` (capital `Canvas` path may not exist in repo listing).
- **Beam audio paths may be missing**: `canvas_beam.gd` loads `beam_warn.mp3` and `beam_fire.mp3` from `res://echoveil/music/animations/`; those files were not visible in the quick file listing.
- **Shared scene logic mismatch risk**: `LevelExit` falls back to main menu if next level scene is missing; this hides missing content rather than surfacing an explicit "to be continued" scene.

## Suggested continuation plan (small, incremental)
1. Add a dedicated `level3.tscn` (even a short prototype) so progression is continuous.
2. Add explicit placeholder handling after Level 2 (e.g., "Chapter complete") instead of silent menu fallback.
3. Verify/fix all asset paths with case-sensitive checks (especially drone sprite and beam sounds).
4. Add a lightweight debug overlay (toggle key) to show `health/lives/shards/current_level` during iteration.
5. Playtest pass focused on combat readability (drone contact window vs hit cooldown cadence).
