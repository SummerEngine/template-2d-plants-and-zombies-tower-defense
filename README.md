# Signal Defense Kit

A 2D Summer Studio starter template for handmade Arduino controller games using simple joystick-and-buttons input.

This is a small vertical lane-defense construction kit, not a finished game. The default prototype proves the core loop: move a cursor on a grid, place defenders, switch defender type, remove a defender, survive incoming waves, review a game-over score summary, and restart.

## Design Goals

- Work with a joystick or D-pad plus 2-3 buttons.
- Keep hardware input separate from game rules.
- Keep defenders, enemies, waves, resources, and grid rules modular.
- Make AI feature additions obvious and safe.
- Stay small enough for first-time Summer Studio users to understand.

## Default Prototype

The board has 7 vertical lanes and 7 rows. The player owns the lower rows, and enemies enter from the top row.

- Enemies spawn inside the grid and march from top to bottom.
- Defenders are placed on grid tiles.
- `Hen` fires eggs from a bamboo bazooka and uses the Summer Studio-generated chicken art.
- `Blocker` soaks enemy attacks.
- Energy regenerates over time and is spent on defenders.
- The base has 3 health. If enemies cross the bottom, base health drops.
- Game over shows total enemies defeated, defeated counts by enemy type, and waves reached.
- The HUD and board resize for wide, medium, and portrait-style screens.

## Controls

- Move cursor: `W`, `A`, `S`, `D`, arrow keys, joystick, or D-pad
- Place selected defender: `Space` or Button A
- Switch defender type: `E`, `Tab`, or Button B
- Remove defender on selected tile: `Backspace` or Button X
- Restart: `R`

## Core Modules

- `scripts/core/input_bridge.gd`: raw keyboard, joystick, and Arduino-as-keyboard bridge values.
- `scripts/core/action_mapper.gd`: converts raw values into named actions.
- `scripts/defense/lane_grid.gd`: grid size, cursor, tile occupancy, and lane geometry.
- `scripts/defense/placement_controller.gd`: cursor movement, place, switch, and remove behavior.
- `scripts/defense/resource_system.gd`: energy economy.
- `scripts/defense/wave_director.gd`: wave timing and enemy spawning.
- `scripts/defense/run_stats.gd`: defeated enemy totals and game-over summary data.
- `scripts/defense/defender_base.gd`: shared defender health/drawing.
- `scripts/defense/chicken_defender.gd`: animated hen defender with idle bob, bamboo-bazooka egg shot, broken egg shell impact, hit flash, and pop effects.
- `scripts/defense/egg_shell_burst_effect.gd`: broken shell and yolk burst VFX for egg impacts.
- `scripts/defense/shooter_defender.gd`: example attacking defender.
- `scripts/defense/blocker_defender.gd`: example blocking defender.
- `scripts/defense/pop_effect.gd`: reusable small VFX pop used by character attacks/defeat.
- `scripts/defense/enemy_base.gd`: example lane enemy.
- `scripts/defense/defense_game.gd`: top-level wiring and win/lose/restart flow.
- `scripts/ui/defense_hud.gd`: energy, base health, wave, selection, messages, and controls.

## Extension Rule

Add features by extending one module, not by rewriting the game.

Examples:

- Add a defender by creating a new defender script and registering it in `PlacementController`.
- Swap the hen art by replacing `assets/art/chicken_rear_bazooka_defender.png`.
- Add an enemy by creating a new enemy script and registering it in `WaveDirector`.
- Add a resource rule by editing `ResourceSystem`.
- Add a lane/tile rule by editing `LaneGrid`.
- Add controller hardware by editing `InputBridge`, then mapping to the existing actions.

## AI Prompt Starter

Use this when asking Summer Engine or another AI agent to change the template:

> This is a modular 2D lane-defense template for joystick-and-buttons handmade controllers. Keep input mapping separate from game rules. Do not rewrite the whole project. Add the feature in the smallest owning module, preserve keyboard fallback, and update docs if the extension pattern changes.

## Optional Verification

From the project root, maintainers can run these after feature changes:

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --import --quit --no-header
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/lane_defense_smoke_test.gd --no-header
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/keyboard_controls_smoke_test.gd --no-header
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/responsive_layout_smoke_test.gd --no-header
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/grid_resize_alignment_test.gd --no-header
```

The smoke tests confirm simulated input can place defenders, move the cursor, switch defender type, spawn an enemy, reward energy after defeat, show broken egg shell VFX at impact time, show game-over totals, restart, keep the HUD from overlapping the board, and keep actors aligned to grid cells after screen resizing.

## Generated Assets

- `assets/art/chicken_rear_bazooka_defender.png`: current Summer Studio-generated transparent rear-view hen sticker with vertical bamboo bazooka and no static egg.
- Current Summer asset id: `aa746026-6785-40d5-a3ac-4e304e7d0f26`.
- `assets/art/chicken_bazooka_defender.png`: earlier side/front bamboo-bazooka hen sprite, kept as a reference.
- `assets/art/chicken_defender.png`: previous egg-holding hen sprite, kept as a reference.

## License

MIT. See `LICENSE`.
