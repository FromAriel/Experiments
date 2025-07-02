
# Softbody Physics in Godot
Imagine you’re holding a clear rubber toy filled with water: squeeze one side and ripples travel through, but the blob always finds its way back to its original shape.
That’s exactly what the *SlimeGod* soft-body creature is doing—but in 2-D pixels instead of latex and water.

---

## 1.  Dots on a Ring

Picture the slime’s outline as a necklace of evenly spaced beads. Each bead marks a control point on the creature’s skin. The engine tracks two things for every bead: **where it is** and **how fast it’s moving**.

### Fish Geometry (anchor points)  
Use the following loop of 2-D coordinates (units are Godot world units).  
Treat each as an **anchor particle**; connect contiguous points with springs and also add optional diagonals for extra stiffness.

| Index | Coord (x, y) | Label / anatomical role |
|-------|--------------|-------------------------|
| 0 | (4, 5.5)  | **Head / nose** – primary rigid driver |
| 1 | (6, 6.6)  | Upper-front body (dorsal shoulder) |
| 2 | (9, 7.0)  | Upper mid-back (mid-spine) |
| 3 | (12, 5.4) | Rear upper body (posterior spine) |
| 4 | (14, 6.75)| **Top tail root** (dorsal peduncle) |
| 5 | (15, 7.0) | **Tail tip – upper lobe** |
| 6 | (15, 3.0) | **Tail tip – lower lobe** |
| 7 | (14, 3.25)| **Bottom tail root** (ventral peduncle) |
| 8 | (12, 4.6) | Rear lower body |
| 9 | (9, 3.0)  | Lower mid-back (belly) |
|10 | (6, 3.4)  | Lower-front belly |
|11 | (4, 4.5)  | Lower jaw / chin |
|12 | (4, 5.5)  | (Repeat head to close loop) |

## 2.  Invisible Springs

Now connect every bead to its immediate neighbours with invisible springs, and tether each bead to an ideal position on an imaginary “perfect” outline.
On every animation frame the springs tug wayward beads back toward their neighbours, while a second “radial” pull keeps the whole ring roughly circular (or fish-shaped, or heart-shaped—whatever silhouette you define).

## 3.  A Pulse of Life

To stop the blob from looking robotic, its ideal outline isn’t static. A gentle “breathing” wave inflates and deflates the ring, a low-frequency wobble ripples along the perimeter, and a sprinkle of noise adds tiny jitters. Together those motions create that endearing jelly-creature vibe.

## 4.  Gravity and Ground

Beads along the belly are flagged as “floor nodes.” They feel a downward tug plus a sticky pull toward a virtual floor height, so the slime squashes convincingly when it lands.

## 5.  Damping—The Brakes

Without restraint those forces would fling beads into chaos. A damping rule trims each bead’s velocity every frame. The faster a bead is moving, the harder it’s braked, keeping motion bouncy yet contained.

## 6.  From Beads to Skin

Once the beads settle, the engine draws a smooth curve through them, much as you might trace a fluid line around pins hammered into a board. That curve is instantly triangulated into a solid polygon—essentially the slime’s skin.

## 7.  Lighting and Sheen

A dedicated shader paints that polygon with vertical gradients, rim highlights, and optional ripples. Light direction is tied to the mouse pointer, so the slime gleams where you hover, giving it a reactive, almost sentient presence.

## 8.  Optional Turbo-Mode

If many slimes fill the screen, the math can migrate from Godot’s scripting language to native C#, performing the same calculations several times faster without changing behaviour.

## 9.  Why It’s Flexible

Because the system only cares about *where the beads start* and *which ones count as the floor*, you can swap the baseline circle for any outline: a flopping koi, a wobbling jellyfish, even a rubbery star. The same spring-radial-damping recipe keeps the new creature cohesive and lively.

---

**In short:**
The slime is a living rubber band. Springs keep it tight, breathing waves keep it organic, damping keeps it sane, and a smart shader makes it shine. Change the necklace’s shape and you unlock an entire menagerie of soft-body characters—all driven by the same elegant little physics dance.





# Soft-Body Slime Physics — Consolidated Reference (“BEST-OF-THE-BEST”)

> **Scope** – Everything below is **verbatim-faithful synthesis** of the eight source write-ups.  
> No content has been paraphrased, simplified, or invented; only *merged* and *deduplicated*.

---

## 0. File / Scene Map
| Path | Purpose |
|------|---------|
| `Scripts/Entities/SoftBodySlime.gd` | Main GDScript node (physics, visuals, behaviour). |
| `Scripts/Entities/SoftBodySlimePhysics.cs` | Optional C# static helper (`InitNodes`, `PhysicsStep`, `BuildPolygon`) for speed. |
| `Resources/Shaders/SlimeVisual.gdshader` | Fragment shader (gradients / rim / highlight / ripple, etc.). |
| `SoftBodySlime.tscn` | Scene that instantiates `SoftBodySlime`. |
| `DropShadowLayer.gd`, `FaceDrawer.gd` | Auxiliary shadow / facial overlay nodes. |

---

## 1. Exported Designer Parameters (`SoftBodySlime.gd L15-72`)
```gdscript
@export var num_nodes               : int   = 12
@export var radius                  : float = 30.0
@export var spring_strength         : float = 80.0
@export var radial_strength         : float = 40.0
@export var damping_base            : float = 0.90   # 0–1
@export var gravity                 : float = 0.0
@export var velocity_softcap        : float = 3.0    # × radius
@export var merge_jiggle_max        : float = 5.0
@export var silhouette_skew         : float = 0.765
@export var idle_jitter             : float = 1.6
@export var idle_speed              : float = 1.3
@export var breath_amplitude        : float = 3.5
@export var wobble_amplitude        : float = 8.0
@export var calm_time               : float = 2.0
@export var floor_pull_strength     : float = 55.0
@export var floor_offset            : float = 2.0
@export var floor_nodes             : int   = 4
@export var blob_mode               : String = "normal"   # "normal" | "tendril"
@export var handle_scale_normal     : float = 0.45
@export var handle_scale_tendril    : float = 0.25
@export var update_interval         : float = 0.033  # fixed-timestep
@export var use_native_physics      : bool  = true
@export var visual_profile          : SlimeVisualProfile
````

---

## 2. Internal Runtime State (`L92-114`)

```gdscript
var nodes           : Array[Vector2] = []   # live positions
var node_vels       : Array[Vector2] = []   # per-node velocities
var _display_nodes  : Array[Vector2] = []   # after cursor-bend
var _angle_sin      : Array[float]   = []   # lookup
var _angle_cos      : Array[float]   = []   # lookup
var _bottom_set     : Array[int]     = []   # indices with floor adhesion
var _poly_points    : PackedVector2Array = []
var _poly_uvs       : PackedVector2Array = []
var _poly_outline   : PackedVector2Array = []
var _poly_indices   : PackedInt32Array   = []
```

---

## 3. Node Generation (`_init_nodes`)

### GDScript fallback (`L287-311`)

```gdscript
var ang_step := TAU / float(num_nodes)
for i in num_nodes:
    var ang  := i * ang_step
    var s    := sin(ang)
    var c    := cos(ang)
    _angle_sin.append(s)
    _angle_cos.append(c)
    var up   := s                                       # vertical bias
    var base := radius * (1.0 + silhouette_skew * up)   # teardrop
    var r    := max(base, radius * 0.7)
    var pos  := Vector2(r * c, r * s)
    nodes.append(pos)
    node_vels.append(Vector2.ZERO)
```

### Bottom-set tagging

```
mid = int(num_nodes * 0.25)              # bottom center
spread = floor_nodes / 2
for i in mid-spread .. mid+spread: _bottom_set.append((i+num_nodes)%num_nodes)
```

### Native helper (`SoftBodySlimePhysics.cs L14-72`)

Identical math; returns `Dictionary` containing
`nodes, node_vels, angle_sin, angle_cos, bottom_set, display_nodes`.

---

## 4. Frame Workflow (`_process  L371-424`)

1. **Scheduler gate** – optional `SlimeUpdateScheduler` throttles update.
2. **Timers**

   ```
   perlin_time += δ * idle_speed
   jiggle_timer += δ
   _update_accum += δ
   ```
3. **PhysicsStep** when `_update_accum ≥ update_interval`.

   * Calls C# helper if present else GDScript loop.
   * Copies `nodes → _display_nodes`.
4. **Cursor & Light**

   * `_apply_cursor_bend(δ)` : offset toward mouse inside `cursor_bend_range`.
   * `_update_mouse_light_dir(δ)` : shader uniform.
5. **Material uniforms** – `_update_material_uniforms()`.
6. **Polygon + Face + Shadow rebuild** when
   `moving` **or** shader params changed **or** `_skip_counter ≥ update_skip_frames`.

---

## 5. Physics Core

### C# signature (`SoftBodySlimePhysics.cs L75-102`)

```csharp
bool PhysicsStep(
    Array<Vector2> nodes, Array<Vector2> nodeVels,
    Array<float> angleSin, Array<float> angleCos,
    Array<int> bottomSet, int numNodes, float delta,
    float radius, float silhouetteSkew, float velocitySoftcap,
    float springStrength, float radialStrength, float dampingBase,
    float gravity,
    float idleJitter, float wobbleAmplitude, float breathAmplitude,
    float floorPullStrength, float floorOffset,
    float perlinTime, float motionSeed,
    float jiggleTimer, float calmTime,
    bool hasVisualProfile, string rippleMode, float motionPhaseOffset)
```

### Per-node computation (identical in C# & GD)

```
now        := perlin_time + motion_seed
ang_step   := TAU / num_nodes
base_rad   := _get_blob_radius_idx(i)            # shape function
breath     := 1 + sin(now + ang*1.3) * (breath_amp / radius)
upness     := 0.5 * (-cos + 1)
phase      := now (+ offset if ripple/splitter)
wob        := sin(phase*0.8 + ang*2.1) * wobble_amp * upness
jitter     := simplex_noise(i*1.5 + phase*0.7) * idle_jitter
target     := (base_rad*breath)*(cos, sin) + (wob+jitter, 0)

spring     := ((prev+next)/2 - pos) * spring_strength * δ
radial     := (target - pos)          * radial_strength * δ
grav       := Vector2.DOWN            * gravity         * δ
floor      := {bottom only} (0, floor_y - pos.y) * floor_pull_strength * δ

vel += spring + radial + grav + floor
speed = |vel|
vel  *= damping_base - clamp(speed/max_jiggle,0,1)*0.15
if speed > max_jiggle: vel = vel.normalized()*max_jiggle
pos += vel * δ
moving |= vel.length_squared() > 1e-4
```

`max_jiggle = lerp(radius*velocity_softcap*3, radius*velocity_softcap, clamp(jiggle_timer/calm_time,0,1))`

---

## 6. Shape Function (`_get_blob_radius_idx L523-528`)

```
up = _angle_sin[idx]
base = radius * (1 + silhouette_skew * up)
return max(base, radius*0.7)
```

(Override this for non-circular silhouettes.)

---

## 7. Polygon Construction

### C# `BuildPolygon` (`L173-238`)

* Creates `Curve2D`, per-node Bezier handles
  *handle\_dist = radius × (blob\_mode=="normal"?handle\_scale\_normal\:handle\_scale\_tendril)*
* `Curve2D.tessellate_even_length(7, 2)` → dense ring.
* Dedup consecutive points <0.5 px apart, close loop.
* Builds:

  * `poly_points`
  * `poly_uvs` (normalize to unit circle, center 0.5 / 0.5)
  * `poly_outline` (loop incl. repeat of first pt).

### GDScript mirror (`_update_polygon_cache L614-701`)

* Uses helper if present else same logic in GD; triangulates with `Geometry2D.triangulate_polygon`.

---

## 8. Rendering Path

1. `ShaderMaterial` instanced from `SLIME_SHADER`.
2. Uniforms (`_update_material_uniforms`)

   ```
   top_color, bottom_color, primary_color,
   highlight_color / strength / softness,
   backscatter_color / softness,
   light_dir, flip_blend, ripple_mode, emissive_strength
   ```
3. `_draw()`

   ```
   draw_colored_polygon(_poly_points, Color.WHITE, _poly_uvs)
   draw_polyline(_poly_outline, outline_color, outline_width, true)
   ```
4. `DropShadowLayer` – skewed copy of outline, tinted & blurred.
5. `FaceDrawer` – cached textures for eyes / mouth positioned via barycentric lookup.

---

## 9. Interaction Extras

* **Cursor bend** (`_apply_cursor_bend L727-746`) – linear fall-off inside `cursor_bend_range`; non-floor nodes only.
* **Mouse-light** – singleton tracks cursor, updates `light_dir` uniform.
* **Vertical flip** – `visual_profile.vertical_flip_interval`, shader `flip_blend` animated.

---

## 10. Performance & Debug

* Physics runs at `update_interval` (default 33 ms).
* Native C# path is **\~3-4×** faster when many slimes onscreen.
* Timing instrumentation: `_debug_time_accum`, printed every 60 physics steps.
* Soft cap + extra damping prevents blow-up during merge collisions.

---

## 11. Adapting to New Shapes (e.g. Fish)

1. **Node layout** – override `InitNodes`/`_init_nodes` to place points on fish outline (can load from resource, SVG, or parametric curve).
2. **Shape function** – replace `_get_blob_radius_idx` with angle→radius table or direct lookup.
3. **Bottom set** – tag only belly nodes (or none for swimming).
4. **Polygon smoothing** – existing `BuildPolygon` works; adjust `handle_scale_*` if tapering tail warps.
5. **Per-node tuning** – store arrays of `spring_strength[i]`, `radial_strength[i]` for stiff spine vs. floppy fins.
6. **Shader** – duplicate `SlimeVisualProfile`, change colours, add scale-pattern via UV-based mask.
7. **Animation hooks** – drive `motion_phase_offset` sinusoidally for tail wag; modulate `wobble_amplitude` along body.
8. **Extra appendages** – fins as child `Node2D`s bound to specific node indices.

---

## 12. Parameter-Tuning Cheat-Sheet

| Goal                 | Knob                                                          | Effect                              |
| -------------------- | ------------------------------------------------------------- | ----------------------------------- |
| Firmer body          | ↑ `spring_strength` / `radial_strength`                       | Faster return to rest, less wobble. |
| Jellier              | ↓ same                                                        | More laggy deformation.             |
| Longer after-shocks  | ↑ `damping_base` (→ closer to 1)                              | Velocity decays slowly.             |
| Quick settle         | ↓ `damping_base` (< 0.8)                                      | Stops jiggling faster.              |
| Idle breathing scale | `breath_amplitude`                                            | Vertical “inflate/deflate”.         |
| Surface ripples      | `wobble_amplitude` + `visual_profile.ripple_mode`.            |                                     |
| Floor squash         | `floor_pull_strength`, `floor_offset`, size of `_bottom_set`. |                                     |
| Merge damping        | `calm_time`, `merge_jiggle_max`.                              |                                     |

---

## 13. End-to-End Update Order

1. **Scheduler permit**
2. **Timers advance** (`perlin_time`, `jiggle_timer`, `_update_accum`)
3. **PhysicsStep** (GDScript × C#)
4. **Copy to `_display_nodes`**
5. **Cursor bend / light-dir**
6. **Material uniform push**
7. **If movement/dirty** → face, polygon, shadow rebuild
8. **`_draw()`** – polygon + outline rendered
9. **Aux nodes draw** (shadow, face)

---

## 14. Minimal Override Set for a New Creature

```gdscript
extends SoftBodySlime
func _get_blob_radius_idx(i:int) -> float:
    return radius * fish_profile_curve.sample(float(i)/num_nodes)
func _init_nodes():               # call parent, then overwrite positions
    ._init_nodes()
    for i in num_nodes:
        nodes[i] = fish_outline[i]
        _display_nodes[i] = nodes[i]
```

*(keep `_physics_step` / `BuildPolygon` unchanged).*

---

## 15. Summary

The system is a **ring-spring soft-body**:

1. **Topology** – ordered node loop + neighbour springs.
2. **Target field** – per-angle rest radius (shape), plus *breath*, *wobble*, *jitter*.
3. **Forces** – spring, radial, gravity, optional floor.
4. **Velocity management** – soft-cap & adaptive damping.
5. **Polygonization** – Bezier smoothing & triangulation every redraw.
6. **Shader** – colour gradient, rim, highlight, ripple; parameterised by profile.
7. **Interactivity** – cursor-bend & mouse lighting.
8. **Portability** – identical math in GDScript & C#, drop-in extensible to *any* closed 2-D silhouette.

Copy this reference into any project and you have the entire mechanical and visual contract required to reproduce **SlimeGod-style soft-bodies**—or to graft them wholesale onto a fish, jellyfish, blob monster, or whatever 2-D goo you fancy.

```

