# Project Structure

This is the intended layout for the lane-defense handmade-controller starter.

## Current Scaffold

- `project.godot`: Summer/Godot project file.
- `main.tscn`: playable vertical 2D lane-defense prototype scene.
- `.summer/GameSoul.md`: high-level game brief read by Summer workflows.
- `.summer/mechanics/energy-economy.md`: economy design note for future AI edits.
- `README.md`: human-facing overview.
- `docs/AI_EXTENSION_GUIDE.md`: module boundaries and AI extension recipes.
- `docs/CONTROLLER_INPUT.md`: controller mapping notes.

## Runtime Folders

- `scripts/core/`: stable input abstraction.
- `scripts/defense/`: grid, placement, resource, wave, defender, and enemy modules.
- `scripts/defense/egg_shell_burst_effect.gd`: code-drawn broken shell impact VFX.
- `scripts/defense/golden_goose_defender.gd`: code-drawn energy producer defender.
- `scripts/ui/`: HUD and player-facing UI.
- `tests/`: headless gameplay and responsive-layout smoke tests for future AI edits.
- `assets/`: replaceable art, audio, and theme files.
- `assets/art/grid_grass_tile.png`: placeable player-domain grid tile.
- `assets/art/grid_pebble_tile.png`: non-placeable farmer-domain grid tile.
- `assets/art/chicken_rear_bazooka_defender.png`: current Summer Studio-generated hen defender art.
- `assets/art/chicken_bazooka_defender.png`: earlier bazooka hen art reference.
- `assets/art/chicken_defender.png`: earlier egg-holding hen art reference.
- `assets/art/farmer_walk_sheet.png`: current four-frame Summer Studio farmer enemy walk sheet.

## Rule For Future Agents

Keep the project openable and playable after each change. Add new gameplay by extending the owning module instead of replacing `main.tscn` wholesale.
