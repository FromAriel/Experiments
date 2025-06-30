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
- [ ] Improve boid flocking with wander and spatial grid.
- [x] Add FishBehavior enum and behavior fields to fish boids.
- [x] Reintroduce Tank collider and smooth wall steering.
