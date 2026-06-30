# AI Extension Guide

This project is built for AI-assisted remixing. Treat it as a stable vertical lane-defense kit with small replaceable modules.

## Prime Directive

Do not rewrite the whole game to add a feature. Find the smallest module that owns the behavior, change that module, and keep the rest of the architecture intact.

## Architecture Boundaries

### InputBridge

Owns raw input.

Use this for joystick, D-pad, buttons, keyboard fallback, Arduino serial values, and calibration.

Do not put game rules here.

Current file: `scripts/core/input_bridge.gd`

### ActionMapper

Turns raw input into named actions.

Current action vocabulary:

- `move`
- `primary`
- `primary_just_pressed`
- `secondary`
- `secondary_just_pressed`
- `modifier`
- `modifier_just_pressed`
- `restart_just_pressed`

Current file: `scripts/core/action_mapper.gd`

### LaneGrid

Owns rows, columns, tile occupancy, cursor drawing, and lane geometry.

Use this for changing grid size, placement rows, blocked tiles, special lane rules, tile effects, board-skin textures, actor scale, or how the board fits different screen sizes.

Current default: 7 columns by 7 rows, with placement allowed in the lower rows. Enemy spawn positions must stay fully inside `get_board_rect()`.

Current board skin: `assets/art/grid_pebble_tile.png` marks the farmer domain above `placement_start_row`, and `assets/art/grid_grass_tile.png` marks the player placement rows. The textures are exported on `LaneGrid` as `farmer_domain_tile_texture` and `player_domain_tile_texture` so remixers can swap the visuals without changing placement rules.

When the grid refits for a new screen size, it emits `layout_changed`. Defenders in occupied cells are snapped back to their cell centers and rescaled by `LaneGrid`; active enemies should listen for the signal, preserve lane/progress, and call `apply_actor_scale()` so characters stay proportional to the cells.

Current file: `scripts/defense/lane_grid.gd`

### PlacementController

Owns cursor movement and player placement actions.

Use this for adding new defender types, changing placement cost rules, adding remove/cancel behavior, or changing how selection works.

Current file: `scripts/defense/placement_controller.gd`

### ResourceSystem

Owns energy. The current economy has three sources: passive drip, enemy defeat rewards, and producer defenders.

Use this for income rate, max energy, starting energy, refunds, harvest rules, or alternate resource systems. Keep producer-specific timing inside the producer defender script, then call `ResourceSystem.add_energy()` through the resource reference passed by `PlacementController`.

Current file: `scripts/defense/resource_system.gd`

### WaveDirector

Owns enemy wave timing and spawning.

Use this for wave lists, boss waves, enemy type mixes, spawn speed, difficulty curves, or custom round goals.

Current file: `scripts/defense/wave_director.gd`

### Defenders

Each defender should be a small script.

Current examples:

- `scripts/defense/chicken_defender.gd`
- `scripts/defense/golden_goose_defender.gd`
- `scripts/defense/shooter_defender.gd`
- `scripts/defense/blocker_defender.gd`

Shared base:

- `scripts/defense/defender_base.gd`

Reusable VFX:

- `scripts/defense/egg_shell_burst_effect.gd`
- `scripts/defense/pop_effect.gd`

Current art assets:

- `assets/art/grid_grass_tile.png`: placeable player-domain tile, model-generated chunky pasture sticker style.
- Current grass tile Summer Studio asset id: `cb918240-90da-4108-a0ee-6c611e9a1f45`
- `assets/art/grid_pebble_tile.png`: non-placeable farmer-domain tile, model-generated chunky pebble-and-dirt sticker style.
- Current pebble tile Summer Studio asset id: `19d6d54f-0110-4a8e-932c-be8bead6e9cc`
- `assets/art/chicken_rear_bazooka_defender.png`: current rear-view hen with vertical bamboo bazooka and no egg in the static character art.
- Current Summer Studio asset id: `aa746026-6785-40d5-a3ac-4e304e7d0f26`
- `assets/art/chicken_bazooka_defender.png`: earlier side/front bazooka hen, kept only as a reference.
- `assets/art/chicken_defender.png`: older egg-holding hen, kept only as a reference.
- `assets/art/farmer_walk_sheet.png`: current four-frame menacing farmer walk sprite sheet, generated in Summer Studio and locally processed into a transparent horizontal row.
- Current farmer Summer Studio asset id: `3af71f54-3290-436d-bf34-bcd62f68bbba`

The hen's egg appears in `ChickenDefender._draw_throw_egg()` during attack animation, not in the static character texture. The egg path is vertical: `_egg_start.x` and `_egg_end.x` should match the centered bamboo barrel. Enemy damage and broken shell VFX should both happen at impact time, after the throw animation reaches the target.

### Enemies

Each enemy should own its own movement, health, animation, and attack differences. The default farmer uses `assets/art/farmer_walk_sheet.png`, a four-frame Summer Studio walk sheet sampled by `EnemyBase` while the enemy moves down the grid.

Current example:

- `scripts/defense/enemy_base.gd`

### HUD

Owns only presentation.

Use this for labels, selected defender display, wave display, controls, messages, game-over summaries, and later tutorial prompts. Keep layout changes inside the responsive sizing helpers instead of hard-coding positions in gameplay modules.

Current file: `scripts/ui/defense_hud.gd`

### RunStats

Owns score-summary data for the current run.

Use this for defeated enemy counts, per-type totals, waves reached, survival time, or other game-over statistics.

Current file: `scripts/defense/run_stats.gd`

## Common Feature Recipes

### Add A New Defender

1. Create a new script in `scripts/defense/`.
2. Extend `scripts/defense/defender_base.gd`.
3. Set `display_name`, `kind`, `cost`, `max_health`, `health`, and `body_color`.
4. Add any custom behavior, such as healing, slowing, splash damage, or resource generation.
5. Register it in `DEFENDER_TYPES` inside `scripts/defense/placement_controller.gd`.

For resource generators, add `configure_resource_system(resource_ref)` and `tick_economy(delta)`. `DefenseGame` calls `tick_economy` every frame, while `PlacementController` passes the shared `ResourceSystem` reference when the defender is created.

### Add A New Animal Defender With Art

1. Generate or import a transparent PNG into `assets/art/`.
2. Create a defender script that preloads the PNG as a `Texture2D`.
3. Keep animation state local to that defender, such as idle bob, attack timing, hit flash, and VFX spawn.
4. Reuse `PopEffect` for small impact/defeat feedback before adding a new VFX module.
5. Register the defender in `DEFENDER_TYPES`.

### Add A New Enemy

1. Create a new enemy script in `scripts/defense/`.
2. Follow the same configure/take_damage signal pattern as `enemy_base.gd`.
3. Give it a stable `kind` string so `RunStats` can count it on game over.
4. Register it in `WaveDirector`.
5. Keep lane movement simple unless the feature explicitly needs a new movement rule.

### Add A New Controller Mapping

1. Read the raw controller value in `InputBridge`.
2. Map it to the existing action vocabulary in `ActionMapper`.
3. Keep keyboard fallback working.
4. Do not edit defender, enemy, or wave logic for hardware mapping.

### Add A New Win Condition

1. Add the condition in `defense_game.gd` or a small rule module.
2. Let `WaveDirector`, `ResourceSystem`, and units keep doing their own jobs.
3. Update the HUD message when the win condition fires.

### Change The Screen Layout

1. Edit `DefenseHUD._apply_responsive_layout` for HUD panels.
2. Edit `LaneGrid._fit_to_viewport` for board sizing and reserved HUD space.
3. Run `tests/responsive_layout_smoke_test.gd`.
4. Avoid moving UI logic into defenders, enemies, input, or wave spawning.

## Prompt Template For Feature Work

> Add [feature] to Signal Defense Kit. Keep the architecture modular. Do not rewrite the whole game. Identify the owning module first, make the smallest change there, preserve keyboard fallback, and update docs if the extension pattern changes.
