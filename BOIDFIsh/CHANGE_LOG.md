# Changelog

## [Unreleased]
- Tank size now updates from the viewport each frame.
- Added built-in archetypes loading and override property in GameManager.
- Debug overlay scales with depth to match fish size.
- Added softbody fish prototype under `prototypes/softbody_fish`.
- Softbody fish rendering now uses Curve2D smoothing with bisection fallback to
  avoid polygon pop-out.
- Softbody fish can be dragged via head and tail gizmos; spring strength controls
  for head and tail added.

