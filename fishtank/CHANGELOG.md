# Changelog

## [Unreleased]
- Initial project skeleton.
- Added empty `ui/` and `tools/` directories and updated README.
- Introduced Mono solution with `FishTank.sln` and `FishTank.csproj`.
- Expanded `.gitignore` rules for IDE and build artifacts.
- Added ignore rules for temporary files inside `ui/` and `tools/`.
- Created `scripts/data/` with resource classes for core data structures.
- Implemented `ArchetypeLoader` with placeholder texture fallback and loaded in `FishTank`.
- Added `art/shape_generator.gd` to create ellipse and triangle placeholders.
- Updated loader and JSON to use generated textures when sprites are missing.
- Implemented `BoidSystem` with per-archetype weight overrides and basic flocking.
- Added `GenerateTargetFrameworkAttribute` property in `FishTank.csproj` to avoid
  duplicate attribute build errors.
- Enhanced `BoidSystem` with random spawn counts, group logic, and wall
  avoidance to prevent fish from exiting the tank.
- Fixed fish spawning at `(0,0)` by spawning at tank center and added
  a sanity check that gently pushes stray fish back toward the middle.
- Removed placeholder `Tank` node and compute boundaries from viewport so
  fish stay within the visible tank.
- Improved boid steering using spatial grid, separation distance, and wander.
- Introduced `FishBehavior` enum and new behavior-related exports for `BoidFish`.
  Updated `FishArchetype` with a matching `FA_behavior_IN` field.
- Added `TankCollider` node and script to enforce tank boundaries with gentle wall sliding.
