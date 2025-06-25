###############################################################
# FISHYX3_BUILD_PLAN.md
# Key funcs/classes: Design doc only, describes build steps
# Critical consts    • N/A
###############################################################

# FISHYX3 – Godot Softbody Fish Tank Simulation

This document outlines the development plan for creating a softbody fish-tank simulation in Godot 4.4.1 using Boids for schooling behavior. The project will be modular and data-driven to support performance tuning and future extensions.

## Overview

* **Engine**: Godot 4.4.1 with Mono (.NET 8) and optional Rust
* **Visuals**: 2D sprites with softbody dynamics and faux 3D normals
* **Scale**: Fake Z-axis via sprite scaling within a 16:9:5.5 volume
* **Lighting**: Directional light affecting all fish uniformly via shader
* **Behavior**: Boids algorithm blended with individual wandering

## References

Public projects that inspired this design:

* **tkwebster/FishSimulation** – A boids fish simulation in Godot【875c1c†L3-L4】
* **Pugulishus/Prelim.-Boid-AI** – Preliminary Boid AI demo for Godot【875c1c†L5-L7】

These repositories demonstrate approaches to boid-based movement that can be adapted for this project.

## Iterative Build Steps

1. **Project Setup**
    * Initialize a Godot project with Git version control.
    * Create main scene placeholder; configure 16:9:5.5 viewport ratio.
    * Add scripts directory structure: `scripts/boids/`, `scripts/entities/`, `scripts/utils/`, `shaders/`, `data/`.
    * Write `.gdignore` and minimal project settings for headless CI.

2. **Base Data Models**
    * Define JSON data templates describing fish appearance and physical parameters (node counts, spring constants, mass distribution).
    * Establish a `fish.json` schema to drive fish generation.
    * Create placeholder scripts for softbody nodes and boid parameters.

3. **Boid System**
    * Implement C# or GDScript module for classic flocking rules (separation, alignment, cohesion).
    * Add wander behavior using Perlin noise or random jitter.
    * Optimize with spatial partitioning (grid or quadtree) for performance.

4. **Softbody Fish**
    * Create a `FishBody` scene that instantiates a 2D softbody with variable node density (dense tail, sparse head).
    * Apply spring constraints to mimic body flexibility.
    * Connect boid output to softbody forces for natural turning and tail swish.

5. **Fake Z-Axis**
    * Add `z_depth` property to fish; update scale based on depth.
    * Bound movement within 16:9:5.5 via clamping or periodic wrapping.

6. **Lighting Shader**
    * Write a custom shader that approximates 3D lighting with adjustable direction.
    * Use normal map to inflate the middle of the sprite for a plump appearance.
    * Integrate highlight and backscatter parameters for tuning.

7. **Emergent Behavior Tuning**
    * Blend boid forces with softbody drag and input from wander behavior.
    * Allow scriptable modifiers for species-specific traits (speed, agility).

8. **Performance Considerations**
    * Profile with >100 fish to verify stable frame rate.
    * Offload heavy calculations to C# or Rust modules if necessary.
    * Implement object pooling for fish instances.

9. **Data-Driven Extensibility**
    * Use JSON or TSV to define fish types, environment parameters, and lighting presets.
    * Support runtime reloading for fast iteration.

10. **Testing & CI**
    * Add headless import and script parse steps in CI pipeline.
    * Include minimal unit tests for boid math and softbody integration.

## Example Script Skeleton (GDScript)

```gdscript
class_name Boid
extends Node2D

# Placeholder for boid parameters
var velocity: Vector2
var acceleration: Vector2

func _physics_process(delta: float) -> void:
    # Update will use separation, alignment, and cohesion forces
    pass
```

## Next Steps

1. Finalize data schemas and create stub scenes.
2. Implement boid logic and simple sprite fish before adding softbody complexity.
3. Gradually integrate shading and fake Z-depth once movement is stable.

