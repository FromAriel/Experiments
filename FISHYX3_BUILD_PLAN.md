<!-- ###############################################################
# FISHYX3_BUILD_PLAN.md
# Key funcs/classes: Design doc only, describes build steps
# Critical consts    • N/A
############################################################### -->

```text
###############################################################
# FISHYX3_BUILD_PLAN.md
# Key funcs/classes: Design doc only, describes build steps
# Critical consts    • N/A
###############################################################
```

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

FISHYX3 PLAN REVISION 2.0 and supplemental research.


# FishyX3 Enhanced Build Plan and Research Report

## 1 · Executive Overview

**FishyX3** is a **2.5D soft-body fish-tank simulator** built in Godot 4.4.1 (Mono). It aims to simulate a lively school of fish with convincing movement and lighting, using optimized 2D techniques to achieve 3D-like visuals at high performance. Key features include:

* **Flocking Behavior:** Boids algorithm (separation, alignment, cohesion) combined with per-fish wander (Perlin noise) for natural schooling.
* **Soft-Body Fish Animation:** Each fish is a chain of 2D physics bodies (rigid segments) connected by `DampedSpringJoint2D` springs for a flexible, swishing tail and a stable head. The tail has denser joints for fluid motion while the head is stiffer for control.
* **Pseudo-3D Depth:** A simulated depth axis (Z) in a 16:9:5.5 volume. Fish scale down and dim as they move “farther” into the tank, creating the illusion of depth without full 3D.
* **Fake 3D Lighting:** Normal-mapped fish sprites under a custom 2D shader that simulates dynamic lighting. Uniforms control a global highlight color (light source tint), lowlight (ambient), and back-scatter (subsurface glow) to mimic underwater light effects.
* **Performance Target:** **500–1000 fish at 60 FPS** on a mid-tier GPU (e.g. GeForce RTX 2060). The design emphasizes spatial optimization, batched rendering, and offloading heavy computations to native code or GPU as needed to meet this goal.

---

## 2 · Research Snapshot

Key findings from research into similar projects and techniques are summarized below:

| **Topic**                     | **Key Takeaways**                                                                                                                                                                                                                                                                                                                                                                                                                               | **Source**                           |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| Godot boids optimization      | **Spatial partitioning** (quadtree or grid) drastically reduces neighbor checks, enabling \~700 fish at 30+ FPS. Using Godot’s physics (Area2D overlap) can leverage built-in broadphase optimizations. Also, updating boids in **staggered groups** (each group updates on alternate frames) yields big gains.                                                                                                                                 | Reddit (Godot fish school)           |
| Reference boid implementation | Centralized “Flock” controller computing forces for all boids (instead of each boid node doing its own) can improve efficiency. Clean separation/alignment/cohesion weighting and code structure available in open-source Godot demos.                                                                                                                                                                                                          | GitHub – SergioAbreu’s Godot Boids   |
| Soft-body physics in Godot    | Godot’s built-in 2D joints (e.g. `DampedSpringJoint2D`) provide spring-like connections between body segments. Proper tuning of stiffness and damping per joint index (e.g. decreasing stiffness toward the tail) yields natural motion. Real-time performance is decent for moderate joint counts, but heavy loads may require native code optimization.                                                                                       | Godot Docs (DampedSpringJoint2D)     |
| GPU-based fish animation      | Godot’s **GPUParticles** can move instanced meshes entirely on the GPU. The official demo shows thousands of fish instances controlled by a particle shader. By updating per-instance transforms/velocities in a shader, the CPU cost is minimal. This technique achieved 32k+ boids at \~30 FPS using compute shaders and spatial binning in Godot 4. 2D projects can use `MultiMeshInstance2D` with a custom shader to similar effect.        | Godot Docs (Particles demo)          |
| 2D normal-mapped lighting     | Using normal maps on sprites and a 2D Light can fake volume and lighting on flat art. Godot 4’s renderer supports dynamic 2D lights (Light2D nodes) that interact with normal maps for highlights and shadows. Custom shaders can extend this to implement backlighting or water effects (e.g. back-scatter).                                                                                                                                   | GDQuest 2D Normal Map Guide          |
| Multi-language extensions     | Heavy math can be offloaded via **GDExtension** to C++ or Rust for major speedups. C# (Mono) is also available and faster than GDScript for CPU-intensive tasks. High-level languages (Python, JavaScript, etc.) can be embedded for tools or offline generation, but are too slow for per-frame logic. Integrating low-level code (even SIMD via ISPC) or GPU compute can leverage modern hardware (AVX, CUDA/OpenCL) for extreme performance. | VileLasagna (Godot GDExtension blog) |

*Insights from these sources have been incorporated into the design below.*

---

## 3 · Directory Layout

```
res://
  ├─ scenes/          # .tscn scene files (main scene, fish, UI, etc.)
  ├─ scripts/         # Source code, organized by subsystem:
  │    ├─ boids/      # Boid steering logic (GDScript/C#)
  │    ├─ softbody/   # Soft-body physics and fish body controllers
  │    ├─ managers/   # Managers (e.g. TankManager, LightManager)
  │    └─ util/       # Utilities (spatial hash, math helpers)
  ├─ shaders/         # Shader files (e.g. fish normal-map shader)
  ├─ data/            # JSON/Tres configs (fish species, tank presets)
  ├─ addons/          # Optional GDExtension modules (Rust/C++) or plugins
  └─ tests/           # Test suites (GUT for GDScript, NUnit for C#, etc.)
```

This standardized structure separates concerns and makes it easy to locate relevant code or assets. For example, boid AI logic lives in `scripts/boids/`, independent of soft-body physics in `scripts/softbody/`. This also facilitates unit testing of each part in isolation.

---

## 4 · Iterative Roadmap (P0 → P9)

Planned phases (P0–P9) with goals and deliverables:

| **Phase**                     | **Goal**                           | **Key Tasks & Artifacts**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ----------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0 – Setup**                | Project scaffolding & CI           | Initialize empty Godot project (`project.godot`); set up GitHub Actions for headless builds (Godot CLI). Add `.gdignore` for cache files. Ensure CI can run `godot --headless`, `dotnet build`, and any GDExtension build (e.g. cargo for Rust).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **P1 – Data**                 | Define fish/tank data schemas      | Create `fish_schema.json` and `tank_schema.json` (species stats, tank parameters). Generate strong-typed classes (e.g. `FishParams.cs` or GDScript constants) from JSON. Implement JSON validation on load.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **P2 – Boids**                | Basic boid movement (2D)           | Implement `Boid.gd` (GDScript) or `Boid.cs` (C#) for core steering: separation, alignment, cohesion, plus wander. Introduce a **SpatialHash2D** utility for neighbor queries (grid cell \~30px) to avoid O(n²) scans. Optionally, use Godot’s `Area2D` nodes as an alternate neighbor detection method to leverage engine optimizations. Include toggles to compare performance with/without quadtree.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **P3 – Soft-body**            | Soft-body fish prototype           | Create a `FishBody.tscn` scene: a chain of rigid bodies (head + body segments + tail segments) linked by `DampedSpringJoint2D`. Aim for \~3 joints in head region (stiff), \~5 in mid-body, \~8 in tail (flexible). Expose spring constants in an inspector script so different species can have different stiffness profiles.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **P4 – Boids ↔ Soft-body**    | Integrate steering with body       | Bridge boid output to soft-body input. Each `FishBody` should receive a desired velocity/turn from the boid logic. Apply forces/impulses or adjust target positions on the soft-body so that the fish turns and accelerates smoothly. Implement an **analytical tail wag** formula: e.g. tail oscillation frequency proportional to fish speed (so faster fish wag tails faster). This can be done by driving an animated bone or applying a small periodic torque to tail joints. Verify that boid steering is still respected while the soft-body adds visual lag and sway.                                                                                                                                                                                                                                                                                                                                                                                       |
| **P5 – Lighting & Shaders**   | Normal-mapped lighting             | Develop a `fish_normal.shader` (CanvasItem shader) for the fish sprite. In the vertex shader, use the sprite’s normal map to slightly displace vertices for a “puffed” 3D look (e.g. multiply normal.y by an inflate factor for thickness). In fragment shader, compute lighting: sample the normal map (convert from \[0,1] to \[-1,+1] vector), then compute `N · LightDir`. Use that to blend between highlight color and backscatter color to tint the sprite texture. Add uniform parameters `u_LightDir`, `u_HighlightColor`, `u_LowlightColor`, `u_BackscatterColor`. A global **LightManager** (autoload) will update these uniforms for all fish each frame (simulating e.g. a moving light source or tinted water).                                                                                                                                                                                                                                       |
| **P6 – Pseudo-Depth**         | Depth scaling & bounds             | Give each fish a `depth` property (0 = front glass, `DEPTH_MAX` = back of tank, e.g. 5.5). Implement rules for depth movement: fish cohesion uses full 3D distance (x,y,z) so they school in 3D space. Add a weak centering force toward a preferred depth (species-specific, so some fish roam near bottom, others near surface). Constrain depth within \[0, DEPTH\_MAX] (reflect or turn around at boundaries). For rendering, set fish scale = lerp(min\_scale, max\_scale, (DEPTH\_MAX - depth)/DEPTH\_MAX). Also modulate color or opacity by depth to simulate murky water (farther = slightly dimmer/bluer). Ensure draw order respects depth: e.g. use `CanvasItem.z_index` or YSort such that lower depth (front) draws on top of higher depth (back).                                                                                                                                                                                                    |
| **P7 – Manager & Spawning**   | Entity management                  | Implement `TankManager.gd`: responsible for spawning fish instances, pooling/recycling fish objects if needed, and handling global behaviors (feeding events, etc.). Fish spawn count and parameters come from a tank config. The manager can emit signals (e.g. `fish_count_changed`) for UI. It also controls global shader uniforms (via LightManager) and can adjust boid parameters globally (e.g. if switching behavior modes). Ensure that fish removed from the scene properly free their physics joints to avoid leaks.                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **P8 – Debug & Tools**        | Debug visuals and editor tools     | Create a `DebugOverlay.tscn` (CanvasLayer) that displays metrics: current FPS, number of fish, average neighbors per boid, etc. Include toggle options to visualize boid vectors (draw lines for separation/cohesion directions for a selected fish) and normals (switch fish material to show their normal map output). In-editor, create gizmos or use existing Joint2D gizmos to visualize spring connections in the fish for tuning. Possibly integrate GUT (Godot Unit Test) overlay to run tests in-engine.                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **P9 – Optimization & Ports** | Final perf tweaks and native ports | Benchmark the simulation with 500, 800, 1000 fish. Profile CPU usage. If the boid steering or soft-body physics exceed frame budget (>16ms), consider porting the hot loops to C# or GDNative/GDExtension in C++/Rust for speed. For example, rewrite the neighbor search and force accumulation in a C++ module for a \~5-10× speedup in math-heavy code. If physics is the bottleneck, experiment with decreasing physics tick rate for joints or simplifying the fish rig (fewer joints), or even switching to a GPU-based animation for tails. The goal is to hit \~60 FPS for 1000 fish on target hardware. Also evaluate rendering: use `MultiMeshInstance2D` to draw fish in one draw call if the fillrate or draw call count is a problem (each fish could be a QuadMesh with the sprite texture). As an extreme path, test a GDExtension with **SIMD** (via Intel ISPC) to update multiple fish in parallel and see if it further improves CPU throughput. |

Each phase culminates in a review where new functionality is tested (automated and manual) and performance is measured. Only after passing tests and meeting the performance budget do we proceed to the next phase. This iterative approach ensures we catch issues early and keep the 60 FPS goal on track.

---

## 5 · Technical Design Details

### 5.1 Boid Engine (Steering Behavior)

* **Central Update Loop:** A single `Flock` or `School` object will iterate through all fish each physics frame to compute boid forces. This central loop (in GDScript or C#) has access to all fish states, making it easier to optimize globally than each fish running its own script. It computes the separation, alignment, cohesion vectors for each fish and sets the acceleration/steering for them accordingly.
* **Neighbor Search:** To avoid *O(n²)* checks, we use a **SpatialHash2D** (quadtree or grid). The space is divided into cells (e.g. 30×30 px); each fish is hashed to a cell. For each fish, we only check neighbors in the nearby cells (and their immediate neighbors), reducing the typical neighbor count dramatically. This keeps per-frame complexity roughly O(n) to O(n log n). In a Reddit demo, spatial subdivision (bin-lattice) was suggested as a crucial optimization for boids. Godot’s built-in broadphase can also be leveraged: by giving each fish an `Area2D` with a collision shape radius equal to the neighbor radius, Godot can automatically provide a list of overlaps each frame. This approach let one demo reach 700 fish at 30fps by tapping into the engine’s optimized collision detection. We will compare the custom spatial grid vs. Area2D to choose the best approach for our needs.
* **Steering Forces:** We use standard Boid rules: **Separation** (steer to avoid crowding neighbors), **Alignment** (steer toward average heading of neighbors), **Cohesion** (steer toward the center of neighbors). These vectors are weighted and summed for each fish. The weights (and neighbor radius) can be tuned per species via `FishParams`. We also add a **wander/jitter** component: a small random steering force that changes smoothly (using Perlin or Simplex noise over time) to ensure the school doesn’t appear too static or grid-like.
* **Velocity Control:** After computing acceleration, we integrate to update velocity. Clamp velocity to each species’ `max_speed`. Also limit the magnitude of steering (acceleration) to `max_force` to prevent unrealistic instant turns. This implicitly caps the turning rate for more realistic movement (fish will take a few frames to reverse direction, preventing jittery 180° flips).
* **Update Distribution:** To further improve performance at high fish counts, the boid update can be **staggered**: e.g. split fish into 2–3 groups and update each group on alternate frames. This effectively reduces update frequency per fish but with 3 groups the overall flock still updates fully every 3 frames. A Godot flocking experiment showed that using 3 update groups allowed a much larger swarm with only a slight loss in tightness of formation. We will implement this as an option (with configurable group count) to see if it benefits our use-case.
* **Threading Considerations:** Godot 4 supports multithreading via `Thread` class or concurrency APIs, but the physics and visuals are single-threaded by default. We might attempt to offload the boid calculations to a separate thread (or a thread per group) in C# or C++ if GDScript becomes a bottleneck. However, care must be taken because accessing physics space from multiple threads can cause race conditions (as noted by others who experienced missing neighbor readings when multithreading boids). An alternative is to use jobs that copy necessary data, compute in parallel, then synchronize results. This is an advanced optimization to be explored in P9 if needed.

### 5.2 Fish Soft-Body Animation

* **Structure:** Each fish’s body is a kinematic hierarchy or a set of rigid segments. We favor using Godot’s 2D physics joints for a realistic wobble: the head (root) could be a KinematicBody2D or Rigidbody2D controlled by boid velocity, and successive body parts (neck, torso, tail segments) are attached via `DampedSpringJoint2D`. These joints act like damped springs that try to maintain a set length. By configuring higher stiffness and damping near the head, and progressively lower stiffness toward the tail, the tail will lag behind the head’s motion and oscillate naturally, simulating the elastic spine of a fish. For example, if the head turns, the tail will whip and follow through a few frames later.
* **Tuning Parameters:** We expose parameters like `stiffness_head`, `stiffness_tail_base`, `stiffness_tail_tip`, and damping equivalents. We can initialize stiffness per joint with a quadratic falloff from head to tail (e.g. if head joint stiffness = X, tail tip stiffness = Y, interpolate in between). Damping should be enough to prevent uncontrolled oscillation but not so high that the motion becomes critically damped (lifeless). The Godot docs highlight that damping ∈ \[0,1] and a higher value brings the bodies in line faster – so tail joints might use lower damping (more oscillation) than head joints. Rest length of each spring is set to the designed segment length; the joint will try not to extend beyond a max length (like a semi-rigid spine).
* **Force Application:** The boid engine will provide a target velocity (and possibly a desired turning angle). To apply this to the soft-body fish, we have a few strategies to experiment with: (a) Directly set the velocity of the head body (if kinematic, move it; if rigid, apply a force or impulse) and let the joints drag the rest. (b) Apply a small steering force on each segment proportional to its distance from the head, to distribute the turn (mimicking how fish muscles propagate a turn along the body). (c) Use an AnimationPlayer or skeleton for the large-scale motion (rotate the whole fish toward direction) and let physics handle the residual wobble.
* **Procedural Animation Alternative:** If the full physics approach proves too costly for many fish, we have a fallback: use a simpler procedural or baked animation for the fish body. For instance, rig each fish sprite with a Skeleton2D (bones for head, body, tail) and play a pre-defined animation for tail wagging, while just rotating/translating the whole fish via boid steering. The animation speed can be synced to velocity (as done in some demos, by scaling animation playback rate with the fish’s speed). This would offload animation to the GPU (since Godot’s skeleton or shader will handle vertex deformation) at the cost of physical realism. We plan to try both and see which yields the best balance of realism and performance. In fact, a hybrid is possible: use a low-frequency spring simulation for large wobble and add a high-frequency sine wave in the shader for the small fin movements – combining realism with performance.
* **GPU Compute Option:** Godot 4 introduced compute shaders and the ability to manipulate particles/instances on the GPU. If we treat each fish’s tail as a set of points, one could write a compute shader to update those as a mass-spring system. This would be highly efficient for large numbers of fish, as proven by the particle-based fish example (moving thousands of fish with a shader). However, implementing a custom GPU physics might be complex. We keep it as a potential direction if CPU physics becomes a bottleneck.

### 5.3 Lighting Shader (2D Normal Mapping)

* **Goal:** Achieve a 3D-lit appearance on 2D sprites. Each fish sprite will have an accompanying **normal map** texture that encodes the 3D orientation of its surface (in tangent space). For example, the center of the fish’s side might be outward-facing (bright under direct light), while the edges curve away (getting rim lighting from behind).
* **Godot 2D Lights vs. Custom Shader:** Godot allows adding a Light2D node and simply assigning a normal map to the Sprite for basic lighting. However, we want fine control (especially for back-scatter light and possibly multiple light sources). So we opt for a custom CanvasItem shader on the fish. We’ll disable built-in 2D light and instead pass a global light direction uniform to our shader. This also avoids calculating lighting for each Light2D per fish, which could be expensive with many fish; instead, one shader pass per fish handles it globally.
* **Shader Implementation:** In the shader’s fragment function, we do:

  ```glsl
  // Pseudocode for fragment shader
  vec3 N = texture(u_NormalMap, UV).rgb * 2.0 - 1.0; // normal from map
  float NdL = max(0.0, dot(N, u_LightDir));         // diffuse term
  vec3 base_color = texture(TEXTURE, UV).rgb;       // sprite color
  // Blend between back-scatter and highlight based on N·L:
  vec3 lit_color = mix(u_BackscatterColor, u_HighlightColor, NdL);
  COLOR.rgb = base_color * lit_color + u_LowlightColor * base_color * (1.0 - NdL);
  COLOR.a = texture(TEXTURE, UV).a;
  ```

  Here, when the normal is facing away from light (NdL \~0), the back-scatter color (maybe a bluish glow) tints the fish, simulating light passing through or around edges. When facing the light (NdL \~1), the highlight color (warm light) dominates. The lowlight (ambient) is applied as a minimum global tint, ensuring no part of the fish is completely unlit. This is a simplified model but should give a sense of depth. We can adjust the exact formula based on visual feedback.
* **Vertex Deformation:** To enhance the 3D illusion, the vertex shader will use the normal map’s Y component to inflate the sprite slightly. E.g., for each vertex, sample the normal map at that vertex’s UV; use N.y (the upward/outward component) to offset the vertex along camera-eye axis (which in 2D is Z or a fake Z). Essentially, parts of the fish that bulge outward (like belly) will appear a bit closer. This might be subtle given 2D, but could be amplified by scaling. Another approach is to simply scale the sprite or parts of it based on orientation to simulate a slight rotation when turning. These need experimentation.
* **Multiple Lights and Environment:** We assume one main light source (like the top of the tank). If needed, we could incorporate a second light or a gradient (for example, slightly darker towards bottom of tank to simulate depth attenuation). Water caustics or moving light patterns could be another addition: e.g. scrolling a caustics texture multiplying the highlight. Those are stretch goals for visuals. The shader is written to be used by all fish materials; we’ll feed it uniforms globally. This way, changing lighting (e.g. day to night) is easy by adjusting `LightManager`’s uniforms.

### 5.4 Pseudo-Depth Mechanics

* **Coordinate System:** The tank is treated as a 3D box projected onto 2D. We maintain a `depth` (z) value for each fish in addition to its 2D position (x,y). The x and y correspond to horizontal and vertical positions in the tank as projected on screen (front view), while z is the distance from the front glass. The tank depth might be normalized to \[0,1] or in world units (e.g. 5.5 as given).
* **Movement in Depth:** Fish will have an additional boid-like behavior for the z-axis: they try to stay around a comfortable depth but avoid crowding in depth too. We treat depth cohesion similar to horizontal cohesion – i.e. fish have a tendency to stay with the school’s average depth. Separation in depth means they won’t all stack exactly on top of each other; if two fish are at almost the same x,y but very different z, that’s actually fine (they won’t collide visually as one will be smaller behind the other). However, to avoid weird visuals of fish completely overlapping in screen space, we could add a rule that if two fish project very close and have moderate z difference, they adjust slightly (this might be overkill; natural cohesion/separation might handle it by 3D distance). Essentially, all boid distance calculations can be done in 3D (x,y,z distance) so the school behaves volumetrically.
* **Depth Constraints:** The fish should not go out of the tank’s depth bounds. We implement an invisible “wall” at z=0 and z=DEPTH\_MAX. If a boid’s steering would take a fish beyond these, we project a force back into the volume (similar to how one handles boundaries in 2D, but now also for z). This could be a simple spring force or a flip of the velocity’s z component when hitting the limit.
* **Scaling and Rendering Order:** The apparent size of a fish is tied to its depth. A simple linear scale works: e.g. `min_scale = 0.5`, `max_scale = 1.0` for farthest to nearest. If the projection should mimic a camera perspective, we could use a more nonlinear scale (like inverse of (z+constant)), but since this is mostly for effect, linear or slightly eased scaling is fine. We will also modulate the sprite’s modulate color or opacity to fade with depth – this simulates **aerial perspective** (water haze) where distant objects are fainter. A light blue overlay could be mixed in for far fish. Rendering order is handled by setting each fish’s CanvasItem Z index = `-depth` (so a fish with depth 0 (front) has highest priority). Godot 4 can use `Sprite2D.z_index` and a **transposed** YSort (since YSort sorts by y coordinate normally, we might manually sort or use a custom draw order). We will verify that this correctly makes nearer fish draw over farther fish.
* **Collider Layers for Depth:** (Optional) If using 2D physics for neighbor detection, we might assign different collision layers for different depth “slices” to prevent fish far apart in z from being considered neighbors. However, since we do want them to still flock in z, a better approach is to just include depth in neighbor filtering by distance. We won’t physically prevent overlap in screen space, as it’s natural for one fish to pass behind another. The depth ordering will take care of visual correctness (one is rendered behind). In fact, slight overlaps make the scene feel more 3D as fish occlude each other appropriately.

### 5.5 Extensibility and Hooks

* **Fish Factory & Species Config:** A `FishFactory` class or method will handle spawning fish of a given species ID. Species data (in JSON or .tres) defines parameters like sprite frames (texture and normal map), size, max\_speed, boid weights, spring joint tuning, preferred depth, etc. The factory uses these to instantiate the fish scene, set up its parameters, and add to the tank. This design allows new species to be added simply by creating a data entry and corresponding sprite assets, with minimal code changes.
* **Behavior Plugins:** We anticipate future behaviors (e.g. predator-prey interactions, feeding frenzy when food is dropped, etc.). To support this, we can allow custom scripts to hook into the fish update loop. For example, any node that is a child of fish or a global singleton implementing `_fish_pre_update(delta, fish)` could inject forces or modify state before the boid rules apply. Alternatively, the TankManager could emit signals at certain times that external scripts listen to (e.g. `on_food_dropped` causes fish to break formation and seek food). The idea is to keep the core boid and physics system generic but not rigid, so designers or AI programmers can extend fish behavior without modifying the core code.
* **Hot-Reload & Tuning:** For rapid iteration, especially on art and environment, we plan to support reloading configuration at runtime. For instance, running the game with a `--hot-config` flag could enable reloading the JSON config files on the fly (by pressing a key or via an editor plugin). This way, parameters like spring stiffness or boid weight can be tweaked and immediately seen in-game. Similarly, shader uniforms for lighting could be exposed in a debug UI to allow artistic tuning of light color, intensity, backscatter amount, etc., during play.
* **Platform Considerations:** The project targets PC initially (desktop GL/Vulkan). We note that 500+ fish with physics might be heavy on mobile, so a future mobile port might switch to simpler animations or lower entity counts. The design with pluggable modules (e.g. replacing GDScript boids with a Rust module) means we can conditionally use different implementations depending on platform capabilities (for example, use a C++ fast path on PC, but stick to GDScript on Web export where GDNative might not be available). Keeping the systems decoupled and modular will ease such transitions.

### 5.6 Performance & Scalability Strategies

Performance is a first-class concern. Beyond the techniques built into the design (spatial hashing, group updates, etc.), we outline additional strategies to ensure we meet our FPS goals:

* **Native Code Hotspots:** Profiling may show certain functions (e.g. neighbor search, force accumulation, spring solving) consume a lot of time in GDScript. We will identify these and consider rewriting them in C# (leveraging Mono’s speed) or as a GDNative/GDExtension module in C++ or Rust. Using native code can dramatically speed up math-heavy operations – by an order of magnitude or more – thanks to lower-level optimizations and the ability to use SIMD. As one developer noted, offloading work to a C++ module allowed them to run intense computations “in its own bubble,” bypassing some Godot scripting overhead. Godot 4’s GDExtension makes it feasible to integrate such libraries without custom engine builds. Rust is a community-supported option with strong performance and memory safety, suitable for complex logic like boids. The key is to keep data exchange between engine and native module minimal (e.g. pass arrays of fish positions to native, get back arrays of forces), to avoid bottlenecks in the interface.
* **SIMD and Parallelism:** If using C++/Rust, we can utilize multithreading or SIMD. For instance, Intel’s ISPC or compiler intrinsics can update multiple fish in parallel in one thread, exploiting data-level parallelism (AVX instructions). If the CPU has multiple cores free, we could also split the flock into chunks and process them on separate threads (taking care to handle neighbors that straddle chunk boundaries). Godot’s jobs system or native threads with synchronization can be used. This will be explored if single-thread performance is insufficient.
* **GPU Instancing & Particles:** On the rendering side, drawing 1000 individual Sprite nodes incurs overhead. Using a **MultiMeshInstance2D** to draw all fish in one or few draw calls can save performance. We would create a single QuadMesh for a fish sprite, then have MultiMeshInstance2D place instances at all fish transforms each frame. However, updating a MultiMesh transform buffer for moving fish has a cost. The optimal scenario is to combine this with a GPU update: i.e. use a ParticlesMaterial or custom shader to animate those instances. The Godot docs on “Animating thousands of fish” show how a GPUParticles3D with a mesh can be controlled via a particle shader. We could adapt that approach in 2D: use a Particles2D node (or ParticlesMaterial on MultiMeshInstance2D) where each particle represents a fish, and write a shader that updates their position based on boid logic. The complexity is that boid logic itself is global; but perhaps a simplified shader-only noise movement could handle part of it. At minimum, GPU instancing will handle the drawing, and we ensure our fish spritesheet or normal map usage is compatible with that (may need to pass per-instance data like frame or color through custom data channels).
* **Level of Detail (LOD):** We might not need this for 1000 fish, but for completeness: if more fish are needed or performance is tighter on some hardware, we can introduce LOD. E.g., fish further away (very small on screen) could update at a lower frequency or use a simpler physics model (or even be billboards without soft-body simulation, just an animated sprite). We can dynamically reduce detail when the camera is zoomed out or the tank is very full. This is an extension of the group-update idea: effectively each fish has its own update schedule depending on importance.
* **Profiling and Budgeting:** Throughout development, we will use Godot’s profiler and frame monitor to track how much time each subsystem uses (physics, script, drawing). We also plan a custom headless benchmark mode (see CI in Section 6) where we spawn a large number of fish and log the average frame time. These data will guide which optimization path to pursue (e.g. if physics is the bottleneck, maybe reduce joint count or use a different approach; if script is bottleneck, move to C# or GDExt; if drawing is bottleneck, use MultiMesh or reduce texture size, etc.). The design remains flexible to change one component without large ripple effects – for example, swapping out the boid algorithm implementation or the fish animation method – because of the modular separation (boid outputs desired movement, fish body executes it).

The combination of these strategies, informed by research and community experience, gives us confidence that FishyX3 can achieve a high-performance simulation with rich, “fake-3D” visuals.

---

## 6 · Continuous Integration (CI)

To maintain code quality and performance targets, we set up a robust CI pipeline:

* **Style & Linting:** Every push triggers Godot’s built-in script validation in headless mode (`godot --headless --check-only`) to catch parse errors or style warnings. For C# code, we run `dotnet format` (or an analyzer like Roslyn) to enforce coding standards. Shader code can be validated by attempting a dummy compile (or using `gdshader` tool if available).
* **Unit Tests:** We use GUT (Godot Unit Test) for GDScript units. The tests are in `res://tests/` and can be run with a command line (`godot -s addons/gut/gut_cmdln.gd -gdir=res://tests`). These cover logic like the SpatialHash utility (e.g. ensuring neighbor queries return correct sets) and boid calculations (e.g. test that two agents far apart produce zero separation force). For any C# utility classes (e.g. math helpers or data loading), we integrate NUnit or XUnit tests that run with the .NET build (or possibly through the Mono assembly in Godot via an EditorPlugin). If we add Rust modules, `cargo test` will cover those in isolation. CI fails if any test fails.
* **Integration Tests:** We might include some Godot scene-based tests, e.g. using an automated script to instance a scene and verify something (like 10 fish spawn and swim without errors for 5 seconds). These can be done via headless Godot as well, or a lightweight custom test runner scene.
* **Performance Budget Check:** A unique aspect of our CI is a performance gate. We create a special scene `bench_1000_fish.tscn` that spawns 1000 fish with a deterministic pattern (maybe a fixed random seed for wander). When run in headless mode for (say) 10 seconds, it outputs the average frame time or FPS to the console or a log file. CI will parse this and if the average FPS is below 55 on our CI machine (which is standardized to a certain hardware or a lower bound spec), the build is flagged. While exact FPS in CI can vary, we mainly use this to catch performance regressions (if a commit drastically slows things down, it’ll be evident). Over time, as we optimize, we might tighten this threshold.
* **Continual Metrics:** We utilize Godot’s **engine.cfg** options to run low-resolution or simplified visuals during CI (since we only care about logic performance there). E.g., we can disable the normal-mapped shader or limit frames to logic only when running in test mode. This focuses the measurement on AI/physics, not rendering (rendering performance is measured manually on target hardware).
* **Build Artifacts:** The CI will produce export builds for at least one platform (say Windows) after all tests pass, so that testers or stakeholders can easily download and run the latest version. This ensures that the packaging (export settings, .pck files) stays working throughout development.

By automating these checks, we catch issues early and maintain confidence that adding new features (like more complex AI or visuals) doesn’t unknowingly break earlier functionality or push us over our frame budget.

---

## 7 · Example Header Comment Block

All code files will begin with a standard header for clarity and maintenance:

```gdscript
#============================================================
# File : scripts/boids/Boid.gd
# Node : Boid (class_name Boid)
# Key  : Core steering behavior for one fish
# Vars : MAX_SPEED (const), max_force (export), velocity
#============================================================
```

This block summarizes the file’s purpose, main class, and important script variables at a glance. It helps new contributors (or our future selves) quickly understand what each file is about without reading the entire content. We will include similar headers in C# and shader files (comment style adjusted accordingly). Consistent headers also assist in automated documentation generation if we choose to parse them into a reference guide.

---

## 8 · Minimal Code Skeletons

To illustrate the shape of the code, here are simplified skeletons for key components:

**GDScript Boid (simplified):**

```gdscript
# scripts/boids/Boid.gd
class_name Boid
extends Node2D

@export var max_speed := 150.0
@export var max_force := 30.0
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO

func _physics_process(delta):
    # Compute boid steering (acceleration) – placeholder
    _apply_boid_rules()
    # Update velocity with acceleration
    velocity += acceleration * delta
    # Limit speed
    if velocity.length() > max_speed:
        velocity = velocity.normalized() * max_speed
    # Move position
    position += velocity * delta
    # Reset acceleration for next frame
    acceleration = Vector2.ZERO
```

In reality, `_apply_boid_rules()` would likely live in a manager and set each Boid’s acceleration, but this shows the integration of steering forces, velocity, and movement. We clamp speed to avoid unbounded acceleration.

**C# Spring Solver (sketch):**

```csharp
// scripts/softbody/SpringSolver.cs
public partial class SpringSolver : Node
{
    [Export] public float Damping = 0.2f;
    // Hypothetical data structure for joints:
    private struct Joint { public Vector2 p1, p2, restLength; /*...*/ }

    public void Solve(Span<Joint> joints, float dt)
    {
        // Iterate joints and apply spring forces
        for(int i=0; i<joints.Length; i++)
        {
            // Compute vector between joint bodies
            Vector2 delta = joints[i].p2 - joints[i].p1;
            float dist = delta.Length();
            float stretch = dist - joints[i].restLength;
            // Hooke's law: force = -k * stretch (along delta)
            Vector2 force = -(joints[i].Stiffness) * stretch * delta.Normalized();
            // Apply damping (proportional to velocity difference, not shown here)
            // ...
            // Accumulate forces on the connected bodies (to be applied externally)
            joints[i].AccumulatedForceBody1 += force;
            joints[i].AccumulatedForceBody2 -= force;
        }
    }
}
```

This pseudo-code outlines how a custom solver might update spring forces. In practice, if using Godot’s built-in physics, we may not need to write this. But if we switch to a manual solver (for more control or performance via Burst or Rust), this is the kind of logic we’d implement. The solver would likely run in `_physics_process` after boid positions are updated, to settle the springs toward the new orientation.

These minimal examples will be expanded with proper integration, but they serve as starting templates.

---

## 9 · Milestone Acceptance Criteria

To verify progress, each milestone (phase) has specific criteria:

1. **M0: Project Initialized** – The repository builds and runs an empty scene without errors. CI is green (lint passes, dummy test passes). `main.tscn` exists but may just contain a placeholder node.
2. **M1: Data Loading** – Able to load fish species JSON and tank config JSON at runtime. Spawn 10 static fish (could be just sprites at this stage) using the loaded data (positions/sizes from config). Verify via a simple test that fish count matches config and species properties are applied.
3. **M2: Basic Movement** – Boid steering is functioning for simple sprites. When running, 20–50 fish move in a visually convincing flock (even if just dots or simple fish icons). Measure performance: 200 fish should run \~60fps without physics joints. If using GDScript boids, this is the first check on algorithm efficiency. Neighbors are correctly identified (we can log or use the debug overlay to ensure average neighbor counts are reasonable).
4. **M3: Soft-Body Integration** – The fish are now soft bodies that deform while moving. Criteria: a fish changes direction smoothly (no rigid instantaneous rotation) and tail exhibits a natural follow-through motion. If a fish suddenly stops (e.g. wander noise goes low), its tail should oscillate a bit before settling. This indicates the springs are working. Also, no instability (no explosion or NaN in physics). Up to 100 fish with soft-bodies should still run, possibly at lower FPS at this stage, but stable.
5. **M4: Lighting & Depth** – Normal mapping shader is applied to fish. We should see a lighting effect: as fish turn relative to the light direction, their shading changes (one side bright, the other darker with maybe rim lighting if backscatter is on). Depth scaling is in effect: fish moving “away” shrink and fade slightly. A UI slider or debug control can be used to move the light source direction and see the shader respond. All fish use the same global light (no per-fish anomalies). The scene with \~100 fish looks visually 3D-ish even though it’s 2D.
6. **M5: Performance Pass** – With all systems in place (flocking, physics, shader), test with 500 fish. Criteria: frame rate on a mid-tier GPU is \~60 FPS (with some tolerance). The debug overlay shows no single subsystem dominating the frame time excessively. If any subsystem is too slow, an optimization from P9 has been implemented (e.g. moving boids to C# or reducing joint count) to meet the target. The simulation remains stable (no physics crashes) and the fish still behave believably at this high count (the formation might loosen with grouped updates, which is acceptable). CI benchmark should pass the 55 FPS average mark.

These acceptance criteria ensure that by the end of each phase, the project not only adds features but maintains stability and performance. Only after M5 (500 fish at 60fps with all features) will we consider the project ready for further polish or additional features beyond the core simulation.

---

## 10 · Next Immediate Tasks (Week 1 Sprint)

To kick off development, the following tasks are prioritized in the first week:

* **Task 0-a:** *(Lead Developer)* – Initialize the Git repository and Godot project. Set up the basic folder structure as per Section 3. Commit an empty Godot project with a `main.tscn` that just has a Node2D and maybe a placeholder background rectangle (to represent the tank). Ensure the project runs in the editor.
* **Task 0-b:** *(DevOps Engineer)* – Create a GitHub Actions workflow for CI. Install Godot 4.4.1 headless, .NET SDK, and Rust toolchain on the runner. The workflow should: run Godot lint, build the C# project (`dotnet build` or MSBuild via Godot), and run any sample tests. Also prepare steps for future (like setting up a headless benchmark command, even if it’s a no-op for now). Cache Godot templates and NuGet packages to speed up subsequent runs.
* **Task 1-a:** *(Backend/Tools Developer)* – Design the JSON schema for fish species and tank. Define what attributes we need (e.g., `id`, `name`, `sprite_path`, `normal_path`, `max_speed`, `max_force`, `flock_weights` {sep,align,coh}, `spring_stiffness` profile, `preferred_depth`, etc.). Create `data/fish_schema.json` and a few sample entries (e.g., Goldfish, Guppy). Write a small script or use a schema validator to ensure the JSONs are well-formed. Optionally, write a generator that outputs a GDScript or C# file with constants for these (for intellisense and type safety).
* **Task 1-b:** *(Tech Artist)* – Create a placeholder fish sprite and its normal map. Even a simple oval shape will do for now. The normal map can be made with a tool like SpriteIlluminator or manually drawn (with brighter center and darker edges to simulate rounded belly). This will be used in Phase 4-5 for testing the shader. Also create a basic background texture (e.g., a gradient or tank image) for visual context.
* **Task 1-c:** *(Gameplay Programmer)* – Begin implementing the `SpatialHash2D` utility (if using one). Decide on grid size or quadtree structure. Functions needed: `update(fish_id, position)`, `query_range(position, radius) -> list of fish`. Write unit tests for this (e.g., add 3 points, query a radius that should get 2 of them, etc.). If using Godot’s physics instead, this task can be repurposed to setting up Area2D nodes on a test scene and verifying that overlaps are detected as expected.
* **Task 2-a:** *(AI Programmer)* – Draft the boid algorithm in code (could be GDScript initially for ease). Focus on one rule at a time: get separation working (e.g., make 5 test fish repel each other if too close), then alignment (have them match velocity vectors), then cohesion (come together). Use the debug overlay (simple printouts or lines drawn) to verify the vectors. We will refine these behaviors, but getting a basic motion happening is the goal.

*Note:* Each task is tagged with an owner role for clarity, but in a small team one person might take multiple roles. We will use our issue tracker to create these tasks and mark them for Week 1. Daily stand-ups will address any blockers (e.g., CI configuration issues or physics oddities). By the end of Week 1, we expect to have the project running with dummy fish and the beginnings of movement logic in place, ready to iterate on more advanced features.

---

*End of Enhanced Design Plan – Version 1.1 (2025-06-25)*

---

## Research & Recommendations Discussion

The above plan is crafted by integrating insights from various sources and prior art in the field of flocking simulation and 2D/3D hybrid rendering. This section provides a detailed commentary on key research findings and how they influenced the design:

### Realistic “Fake 3D” Fish Movement Strategies

Achieving realistic fish movement in a 2D engine requires simulating both the collective behavior of schools and the individual motion nuances of each fish. Classic boids algorithms (as introduced by Craig Reynolds) are a natural choice for schooling behavior. We confirmed through community examples that Godot’s GDScript can handle a few hundred boids, but performance optimizations are necessary for our target counts. In one Reddit demo, a developer managed **700 fish at 30+ FPS** by using a combination of engine features and algorithm tweaks. Notably, they attached an Area2D to each fish to let the physics engine handle neighbor detection, rather than manually iterating over every fish pair. This essentially uses Godot’s internal **broadphase collision detection** (likely a grid or quad-tree under the hood). We adopted a similar idea by planning either a custom spatial hash or leveraging Area2D overlaps. Additionally, that demo split the fish into three groups updated in interleaved frames, demonstrating a clever trade-off between fidelity and performance. We incorporated this concept as an optional mode; by updating, say, 1/3 of the fish each frame, the CPU cost is cut down significantly, at the cost of each fish updating at 20 FPS (which can be acceptable if done carefully, as the motion still looks continuous when staggered).

Another aspect of realism is how fish turn and move. Real fish don’t pivot instantly; they have inertia and bend their bodies. The soft-body approach in our design aims to address that. However, it’s worth noting that a purely physics-based wiggling tail might be more complex than needed. We learned that many simulations and games cheat by using **procedural animations** – essentially driving a sine wave for the tail and syncing it to movement speed, rather than simulating muscles. For instance, one could see in Godot’s documentation on animating fish that simply varying a shader or animation based on a `VELOCITY` value can make a convincing swimming effect. In our plan, we kept the physics route for authenticity, but also left room for switching to an animated skeleton if performance dictates. This flexibility is informed by the understanding that **CPU physics for many entities is expensive**, and GPUs are extremely fast at doing repetitive animations. The use of Skeleton2D or even a compute shader for springs was suggested in research. Godot 4’s support for compute and the example of **100k boids via GPU** (albeit in 3D) indicates that if we hit a wall, we can move calculations to the GPU. That said, GPU-driven boids in 2D would require writing a custom shader that updates positions and possibly doing texture feedback or shader storage buffers for positions, which is advanced. The simpler win might be using a MultiMesh with a particle shader as the docs outline, effectively turning our fish into GPU particles that follow rules we set. We’d lose some ease of interaction (GPU-driven fish are harder to hook events into, e.g., detecting collisions with CPU objects), so the plan is to try CPU methods first and only escalate to GPU if needed.

**Depth simulation** came up as a key point for fake 3D. What makes movement look 3D? One factor is perspective: objects get smaller as they go further. We implemented that via scaling. Another factor is layering: closer objects obscure farther ones. That is solved by draw order. A third factor is atmospheric distortion: farther things are fainter or tinted by the medium (water, in our case). The Pygame boids discussion explicitly mentioned making boids “shrink and shade as they go deeper” to fake depth. We cited this approach and included a fade to blue/gray for distant fish. These subtle cues can greatly enhance the perception of depth in a purely 2D scene.

One challenge is to ensure the fish still feel like a coherent school in 3D – meaning a group doesn’t accidentally all line up at different depths and look unrelated. By using 3D distance for cohesion/separation, we inherently encourage them to cluster in 3D space, which should preserve the schooling illusion in projection.

### Performance Considerations and Language Choices

Our research into Godot’s performance options made it clear that GDScript, while convenient, may not suffice for the scale we want. We saw from the community that GDScript boids top out a few hundred actors before frame rate falters (the Reddit example needed tricks to reach 700 in GDScript). Godot’s **Mono/C#** is substantially faster for heavy calculations, so moving the boid update there is a logical step if needed. We also considered using **Rust via GDExtension** for maximum performance. An article on integrating C++ with Godot remarks that you can drop down to lower-level code to “wring out as much performance as you can,” freeing you from some engine scripting overhead. It also notes that if one’s strength is in another language (like C++ or Rust), it’s viable to use that for heavy lifting in Godot. We took this to heart: our plan’s Phase 9 explicitly includes potentially porting CPU-intensive parts to native code. The mention of **ISPC and AVX** in the research is an eye-opener that even within native code, we can go further by utilizing vector instructions to update multiple fish in parallel. While implementing ISPC might be outside the initial scope, simply being aware of these techniques is valuable. It means we’ll structure data in arrays where possible (contiguous memory), making it easier to leverage such optimizations down the line. For example, instead of storing each fish’s properties as separate nodes with scattered data, we might maintain parallel arrays of positions, velocities, etc., which could be fed to a C++ routine or a SIMD function efficiently.

One recommendation from our findings is to “keep number crunching on the side that owns the data” to avoid marshalling overhead. For us, that means if the boid logic is in C#, maybe keep the relevant data in C# structures rather than constantly syncing GDScript <-> C#. Or if we go to Rust, possibly manage the state of fish in the Rust module. This influenced the plan by pushing toward a design where **TankManager** could be the owner of fish state in one place (instead of each fish individually holding state that is frequently accessed by others). We leaned toward a centralized update which also aligns well with possibly handing off that update to a different language backend.

### Visual Enhancements and Realism

In terms of visual realism, our research into 2D normal mapping taught us how effective it can be. The GDQuest tutorial demonstrates normal maps giving 2D art a 3D feel with proper lighting. We intend to use hand-drawn or software-generated normal maps for our fish sprites. One might ask: why not simply use 3D models if we’re simulating a 3D effect? The reason is performance and artistic style. 2D sprites with normal maps are much lighter to render (no heavy geometry or 3D physics), and they allow a stylized, possibly cartoon-like look that might be desired. Also, working with 2D allows using Godot’s rich 2D toolkit (TileMaps for background, etc.) and simplifies certain collisions (e.g., if we add food or obstacles, 2D collision shapes are easier to manage than full 3D physics for fish). So the “fake 3D” approach attempts to get the best of both worlds: the depth and lighting of 3D, with the simplicity and speed of 2D. Our shader approach with backscatter is somewhat custom; it’s inspired by how light behaves underwater – often you see a glow around the edges of fish when light is behind them, due to scattering in water. We didn’t find a ready-made Godot shader for this, so we plan to tweak our own. We’ll validate it visually and adjust as needed.

Another realism point is fish behavior nuances: e.g., fish might have slight up-and-down oscillation as they swim (other than tail wag). We can simulate that by adding a very low-frequency noise to their vertical position or by having them subtly bob (this could even be part of the wander component). We didn’t explicitly put that in the plan, but it’s an easy tweak once the basics are in.

If we consider environment, an advanced idea from research was adding **obstacle avoidance** – like if the tank has rocks or plants, fish should avoid them. The Reddit boids thread mentioned the next step being obstacle avoidance. We have the infrastructure to add that (just another force, similar to separation but for static obstacles). While not in the initial scope, our extensibility hooks would allow plugging in such behavior.

### Verification and Continuous Improvement

Our adoption of CI with performance benchmarking is a direct result of understanding how easily performance can degrade when adding features. By automating a performance test, we create a constant feedback loop to the developers to keep optimization in mind. In high-performance simulations, sometimes one extra loop or an inefficient memory access can reduce the fish count that can run smoothly. Having a tangible metric (FPS at X fish) tracked over time will guide us.

In summary, the research reinforced a few core strategies:

* **Optimize algorithms (spatial partitioning, reduce per-frame work)**: This is why we emphasize spatial hashing and optional frame-skipping for boids.
* **Leverage engine and hardware capabilities**: Use Godot’s built-ins (Area2D, Particles, MultiMesh) where possible since they are often optimized in C++. And plan for offloading to lower-level languages or GPU once we hit GDScript’s limits.
* **Maintain visual quality with clever tricks**: Normal mapping, scaling with depth, backscatter lighting – these give a rich look without the cost of true 3D rendering.
* **Stay flexible and data-driven**: Because we might need to swap out implementations (for performance) or tweak behaviors (for realism), the design uses data files and pluggable modules. This reduces hard-coding and allows trying different approaches (e.g., if the spring joints don’t look right, we can switch to an animated skeleton by just changing the fish scene and keeping the rest constant).

By implementing the plan with these principles, FishyX3 is poised to deliver a convincing aquarium simulation that runs efficiently. The combination of flocking AI and soft-body physics, enhanced by shader magic, will create an engaging visual where users can enjoy watching a large school of fish exhibiting lifelike movement—all without the need for a full 3D engine. The detailed design and research-backed choices give us a clear roadmap to follow and confidence in overcoming the technical challenges inherent in this project.

**Sources:**

* Reynolds, C. (1987). *Flocks, herds and schools: A distributed behavioral model.* (Original boids paper for foundational context).
* Reddit user **niceeffort1** – *Godot Fish Schooling demo insights* (use of Area2D and group updates).
* GDQuest – *Lighting with 2D Normal Maps* (techniques for normal mapped lighting in Godot).
* Godot Official Documentation – *Controlling thousands of fish with Particles* (GPU instancing approach).
* VileLasagna Blog – *Bringing C++ to Godot with GDExtension* (discussion on performance gains and integration of native code).
* Pygame Boids Discussion – (Confirmation of pseudo-3D effect via scaling and shading for depth).
