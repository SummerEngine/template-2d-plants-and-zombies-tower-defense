# Signal Defense Kit

**Pitch:** A remixable 2D lane-defense construction kit for handmade joystick-and-buttons controllers.

**Core loop (30s):** Move a grid cursor across the lower rows of a 7-by-7 board, switch defender type, place defenders, build energy income, and stop enemies marching down from the top.

**Three mechanics:**
1. Map simple controller input into cursor movement, place, switch, remove, and restart actions.
2. Place modular defenders onto the player-owned bottom rows of a vertical lane grid to block or attack enemies.
3. Spawn modular enemy waves that pressure the base and reward energy when defeated.
4. Grow the economy through passive income and optional producer defenders like the Golden Goose.

**Current hero defender:** Hen, a Summer Studio-generated chunky sticker character viewed from behind with a vertical bamboo bazooka. The static character art has no egg; eggs appear only during the code-driven shooting animation, travel straight upward from the barrel, and burst into shell shards on impact.

**Current economy defender:** Golden Goose, a code-drawn chunky sticker defender that does not attack and instead adds energy on a timer.

**Current enemy style:** Farmers use a four-frame Summer Studio walk sheet in the same chunky 2D barnyard sticker style, with angry brows and heavier stomping poses so they read as mildly menacing.

**Current board style:** Farmer-domain rows use chunky pebble-and-dirt tiles; player placement rows use chunky pasture-grass tiles.

**Art direction (one phrase):** Chunky 2D barnyard stickers with readable board-game silhouettes.

**Scope:** Hackathon starter template.

**Win condition:** The prototype runs endless waves. Hackathon teams can add their own win conditions: survive 5 waves, defeat a boss, protect an object, earn a score, or complete a recipe.

**One thing this is NOT:** This is not a full Plants-vs-Zombies clone; it is a small vertical lane-defense kit with clear extension points.

**Inspirations:** Plants vs. Zombies lane structure, board-game tile clarity, MakeCode Arcade starter projects.

**Parked for later:** Deck-building, complex pathfinding, large unit rosters, animated art, save files, story, and online multiplayer.

## AI Extension Promise

The core should be easy to build upon. Future AI edits should have clear compartments:

- Controller changes belong in `InputBridge` or `ActionMapper`.
- Grid and tile rules belong in `LaneGrid`.
- Placement rules belong in `PlacementController`.
- Energy changes belong in `ResourceSystem`.
- Economy-producing defenders should expose `tick_economy(delta)` and receive `ResourceSystem` through `configure_resource_system`.
- Wave and enemy spawn changes belong in `WaveDirector`.
- Run summary and per-enemy-type counters belong in `RunStats`.
- HUD layout and game-over display belong in `DefenseHUD`.
- New defenders should extend `DefenderBase`.
- New animal art should live in `assets/art/` and be preloaded by the owning defender script.
- New enemies should follow `EnemyBase`.
