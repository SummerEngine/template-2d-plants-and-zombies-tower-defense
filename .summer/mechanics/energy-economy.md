# Mechanic: Energy Economy

**Purpose:** Give players a readable build resource that supports both simple survival and deeper remixable strategy.

**Inputs:** No direct input. Players spend energy by placing defenders. They choose economy strategy by placing or skipping producer defenders.

**Sources:**
- Passive drip from `ResourceSystem.energy_per_second`, currently slow enough to prevent a stall.
- Enemy defeat reward from `DefenseGame.enemy_defeat_energy`.
- Producer defenders, starting with `GoldenGooseDefender`, which adds energy on a timer.

**Feedback:**
- HUD shows `Energy: current / max`.
- HUD energy bar fills against `ResourceSystem.max_energy`.
- Golden Goose has a small local production meter and pulse when it successfully adds energy.

**Failure Modes:**
- If energy is full, producer defenders do not overfill the resource.
- If the player cannot afford a defender, `PlacementController` shows the existing "Need X energy" message.
- If a producer is destroyed or removed, its production stops with the node.

**Depth:**
Players choose between short-term defense and long-term economy. A Golden Goose costs more than a blocker and does not attack, so placing one early creates a meaningful risk/reward choice.

**Tunables:**
- `ResourceSystem.starting_energy`
- `ResourceSystem.max_energy`
- `ResourceSystem.energy_per_second`
- `DefenseGame.enemy_defeat_energy`
- `GoldenGooseDefender.cost`
- `GoldenGooseDefender.production_interval`
- `GoldenGooseDefender.energy_per_cycle`
