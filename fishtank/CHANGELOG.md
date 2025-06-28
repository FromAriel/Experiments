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
