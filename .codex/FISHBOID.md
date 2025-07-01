# Fish Boid Visual Yaw Deformation

This document outlines the parameters controlling simulated Z-axis turning for `BoidFish`.

## New Archetype Fields
- `FA_z_steer_weight_IN` – interpolation weight used when smoothing `BF_z_angle_UP`.
- `FA_z_deform_min_x_IN` – X-scale factor at maximum turn.
- `FA_z_deform_max_y_IN` – Y-scale factor at maximum turn.
- `FA_z_flip_threshold_IN` – normalized threshold for horizontal flip when reversing.

## Visual Processing
`BoidFish._process()` adjusts sprite scale based on `BF_z_angle_UP` calculated in the boid system. When the angle crosses the flip threshold and polarity changes, the sprite’s `flip_h` flag toggles to avoid popping.

```gdscript
var squash_intensity := abs(BF_z_angle_UP) / PI
scale.x *= lerp(1.0, FA_z_deform_min_x_IN, squash_intensity)
scale.y *= lerp(1.0, FA_z_deform_max_y_IN, squash_intensity)
```

Flips occur only when `squash_intensity` exceeds `FA_z_flip_threshold_IN`.
