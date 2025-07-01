# TODO
- Scaffolded empty `ui/` and `tools/` directories for future development.
- Added `FishTank.sln` and `FishTank.csproj` to enable C# scripting.
- Refined `.gitignore` to ignore Mono, build, and IDE files.
- Expand `.gitignore` to exclude temporary files in `ui/` and `tools/`.

- Added resource scripts for core data models in `scripts/data/`.

- [x] Implement FishArchetype parsing from JSON.
- [x] Integrate ArchetypeLoader in FishTank scene.
- [x] Create ShapeGenerator script for ellipse/triangle placeholders.
- [x] Add boid behavior system.
- Create UI for spawning fish.
- [x] Verify spawn location and boundary sanity checks for fish.
- [x] Resolve duplicate TargetFramework build attribute.
- [x] Improve boid flocking with wander and spatial grid.
- [x] Add FishBehavior enum and behavior fields to fish boids.
- [x] Integrate TankCollider for graceful wall constraints.
- [x] Tune boundary modes and group centering.
- [x] Implement flip-turn movement mode for smoother reversals.
- [x] Upgrade internal boid math to Vector3 for depth-aware movement.
- [x] Animate fish reveal and ensure spawn uses tank center.
- [x] Fix runtime error from Vector2 argument to move_toward.
- [x] Simulated Z-axis turning and deformation.

- [x] Fix fish orientation drift
- [x] Maintain dynamic squash alignment with orientation
- [x] Track head and tail positions to compute 3D orientation
