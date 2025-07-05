# Changelog

## [Unreleased]
- Tank size now updates from the viewport each frame.
- Added built-in archetypes loading and override property in GameManager.
- Debug overlay scales with depth to match fish size.
- Added softbody fish prototype under `prototypes/softbody_fish`.
- Softbody fish can be dragged via head and tail gizmos; spring strength controls
  for head and tail added.
- Softbody fish now uses twice as many points with lower spring strength for a smoother shape.
- Updated softbody fish vertex coordinates for improved accuracy.
- Softbody fish renderer uses precomputed triangulation to avoid runtime errors.
- Softbody shader adds fake normal lighting with dynamic bulge.

