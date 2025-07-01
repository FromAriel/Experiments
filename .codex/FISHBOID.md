# Fish Boid Z-Axis Deformation

This document outlines the simulated yaw system for fish boids. A fake Z-angle is interpolated from steering vectors and drives visual-only deformation.

## Configuration Fields
- `FA_z_steer_weight_IN` – interpolation weight for yaw targeting
- `FA_z_deform_min_x_IN` – minimum X scale at max bend
- `FA_z_deform_max_y_IN` – maximum Y scale at max bend
- `FA_z_flip_threshold_IN` – normalized intensity at which the sprite flips horizontally

## Visual Processing
`BoidFish._process()` scales the node based on `BF_z_angle_UP`:
```
var squash_intensity := abs(BF_z_angle_UP) / PI
scale.x *= lerp(1.0, FA_z_deform_min_x_IN, squash_intensity)
scale.y *= lerp(1.0, FA_z_deform_max_y_IN, squash_intensity)
```
If the intensity exceeds `FA_z_flip_threshold_IN` and the yaw sign reverses, `Sprite2D.flip_h` toggles to complete the turn.

## Behavior Diagram
```
angle ↑  flip_h
 |      /
 |     /
1.0 --*---- intensity
 |    /
 |   /
0 --/  squash
```
