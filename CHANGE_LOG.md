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
- Fixed type inference error in BoidSystem affecting build.
- Added depth-based scaling and randomized z positions for boids.
- Default population increased to over 50 fish across six groups.
- Updated Fishtank scripts to resolve resource paths from either standalone or root project.
