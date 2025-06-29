# Changelog

## [Unreleased]
- Initial repository documentation files.
- Disabled auto-generated assembly metadata to avoid duplicate attributes.
- Added explicit `GenerateTargetFrameworkAttribute` property to fix duplicate
  `TargetFramework` errors on some systems.
- Improved fish tank boid simulation with group assignment and boundary
  avoidance to keep fish inside the tank.
- Boundaries now derive from the viewport and the placeholder Tank node was
  removed.
- Fixed a parse error in `boid_system.gd` by explicitly typing `BS_diff_UP`.
