
# 🌊 “Virtual Wall Aquarium” — High-Level Design Document

> **Purpose** Deliver a gorgeous, maintenance-free display tank that lives entirely on a monitor.
> **Hook** All the depth, life and shimmer of a 960-gallon lobby show-piece — without the plumbing.

---

## 1. Vision & Experience

* **What guests see**
  A floor-to-ceiling screen filled with vibrant fish that weave in and out of the scene, scale convincingly with depth, glint under virtual lighting, and interact just enough to feel alive (schooling splits, lazy drifters, sudden darting).

* **What owners get**
  *Zero* wet maintenance. A single executable runs at a locked 60 FPS on any mid-range PC and mirrors to LED panels or a 4-k projector. Settings allow one-click swaps between “calm clinic,” “reef frenzy,” or “night-light” moods.

---

## 2. Signature Features

| Pillar                      | How We Hit It                                                                                                           |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Full 3-D flocking logic** | Each fish moves through real XYZ space (Reynolds boids + head/tail segment). Avoids “paper-flat” overlaps.              |
| **2-D fake-3-D rendering**  | Only `(x, y)`, depth ratio, yaw – plus sprite squash – reach the GPU. Lets us draw hundreds of fish cheaply.            |
| **Soft-body fish shader**   | Head & tail positions feed a custom shader that bends, tints and highlights the sprite on the fly; no baked animations. |
| **Depth cues**              | Automatic scale, brightness fall-off and subtle color shift make near fish pop and far fish recede.                     |
| **Species realism**         | Six archetypes (schooler, cruiser, glider, loner, bottom-dweller, custodian) tuned with real behaviour ranges.          |
| **Adaptive tank**           | Tank dimensions track window size; user slider scales “depth” 0 .5 × – 1 .5 × height.                                   |
| **Maintenance-mode logs**   | Toggle a dev overlay that draws spines, cell grids, and dumps CSVs for a chosen fish — only when the debug flag is on.  |

---

## 3. Visual & Audio Style

* **Art direction** – high-saturation “aquarium lighting,” crisp dark backdrop, gentle caustic overlay.
* **Sprites** – painterly but semi-real (think *Abzû* meets *Aquarium Live Wallpaper*).
* **Shader flourishes** – eye glint pass, rim-light that scales with depth, per-species hue variation.
* **Ambient loop** – low-pass filtered bubbling + soft room tone; optional kid-friendly voice IDs on click.

---

## 4. Fish Casting (Default Mix)

| Layer / Role       | Species Group                     | Qty (at 960 gal) | Behaviour Profile                                    |
| ------------------ | --------------------------------- | ---------------- | ---------------------------------------------------- |
| Glitter cloud      | Cardinal & Rummy-nose tetras      | 150              | Tight school, mid-speed, depth 0.3 – 0.7             |
| Mid accents        | Boesemani rainbows                | 20               | Constant cruisers, occasional burst, depth 0.2 – 0.6 |
| Graceful gliders   | Marble angelfish                  | 8                | Slow turns, mild territory, depth 0.4 – 0.8          |
| Showpiece drifters | Pearl gouramis                    | 10               | Surface skimmers, gentle yaw, depth 0.0 – 0.3        |
| Bottom parade      | Sterbai corys                     | 30               | Ground-hugging hops, shoal loosely, depth 0.9        |
| Custodians         | Bristlenose plecos + Amano shrimp | 6 + 200          | Mostly stick to décor; occasional wall shift         |

*(Quantities scale down automatically on smaller monitor windows.)*

---

## 5. Technical Blueprint (Bird’s-Eye)

```
 ┌────────────┐  fixed-Δt  ┌───────────────┐  per-frame  ┌───────────────┐
 │ BoidSim    │──────────►│ Snap-Buffer   │────────────►│ Renderer2D    │
 │  (Head▶Tail)│ fish[]    │  immutable    │             │  sprites + FX │
 └────────────┘            └───────────────┘             └───────────────┘
```

1. **BoidSim** (120 Hz) updates real 3-D positions, velocities, behaviours.
2. **Snap-Buffer** copies bare-bones state (head/tail, species id).
3. **Renderer2D** (60 Hz) projects to screen, feeds shader with:

   * `head_xy`, `tail_xy`, depth ratio
   * yaw Δ for squash, species palette id.

---

## 6. User-Facing Controls

| Setting       | Where                          | Range / Options |
| ------------- | ------------------------------ | --------------- |
| Fish count    | GameManager → **“Population”** | 50 – 600        |
| Depth scale   | “Tank Depth”                   | 0.5 – 1.5       |
| Preset themes | “Community / Reef / Night”     | Buttons         |
| Debug overlay | Hidden hotkey <kbd>F3</kbd>    | On / Off        |

All inspector properties nest under a single **GameManager** node for clarity.

---

## 7. Performance & Fallbacks

| Tier               | Target HW         | Strategy                                |
| ------------------ | ----------------- | --------------------------------------- |
| **High** (default) | GTX 1660, Ryzen 5 | 120 Hz sim, soft-body shader, 400 fish  |
| **Medium**         | Integrated GPU    | 90 Hz sim, sprite-only deform, 250 fish |
| **Low**            | Small kiosks      | 60 Hz sim, cull distant fish, 150 fish  |

The engine auto-detects dropped frames and steps down one tier; user may override.

---

## 8. Roadmap Milestones

1. **MVP loop** – single goldfish archetype, placeholder ellipse sprite, depth scale OK.
2. **Species library** – six archetypes, parameter CSV, random variant tint.
3. **Shader deformation** – head-tail input, squash & rim light.
4. **Behaviour richness** – flock splitting, wall grazing, bottom patrol.
5. **Theme presets + UI** – “clinic calm,” “tropical party,” “after-hours dim.”
6. **Release 1.0** – installer, idle-safety watchdog, kiosk mode.

---

## 9. Success Criteria

* 60 FPS sustained with 400 fish on a 1080p office PC.
* Casual viewer can’t tell sprites from a lightweight 3-D model.
* Facility staff perform zero intervention beyond occasional software update.
* Kids stop in the hallway and point — mission accomplished.

---

**“A screen-clean aquarium, forever crystal-clear.”**
# Fish Tank Boid Simulation — **Full Technical Spec v 0.3.1**

> **Scope** A real-time “wall display” aquarium that simulates **250 – 400** fish in full 3-D boid space, then renders them as 2-D sprites with depth scaling, yaw squash and optional soft-body mesh.
> **Engine** Godot 4.x (GDScript).
> **Targets** 60 FPS on mid-range PCs (≈ Ryzen 5 / GTX 1660).

---

## 0. Document Map

| §  | Title                                  |
| -- | -------------------------------------- |
| 1  | Architecture Overview                  |
| 2  | File & Node Layout                     |
| 3  | Naming Convention                      |
| 4  | Core Data Structures                   |
| 5  | Runtime Parameters & Defaults          |
| 6  | Simulation Details                     |
| 7  | Rendering Pipeline                     |
| 8  | Placeholder Art Generation *(updated)* |
| 9  | Debug & Developer Flags                |
| 10 | Performance Budgets                    |
| 11 | Future-Facing Hooks                    |

---

## 1 Architecture Overview

```
Main.tscn
└── GameManager            ← holds global settings & debug flags
    ├── FishBoidSim        ← pure-logic world (fixed Δt)
    │    └── BoidFish …    ← head & tail in 3-D, behaviour state
    └── FishRenderer       ← per-frame 2-D draw from sim snapshot
```

* **Hard separation** — no rendering code inside the simulation layer.
* **Head + Tail model** — each fish stores two Vec3 positions; orientation and yaw derive deterministically from that segment.
* **Fixed-timestep** integrator (e.g. 120 Hz) decoupled from display FPS (60 Hz).

---

## 2 File & Node Layout

| Path                                     | Purpose                                            |
| ---------------------------------------- | -------------------------------------------------- |
| `scripts/boids/boid_system.gd`           | `FB` prefix. Creates fish, spatial grid, steering. |
| `scripts/boids/boid_fish.gd`             | `BF` prefix. Holds state, per-frame update hooks.  |
| `scripts/data/fish_archetype.gdresource` | `FA` prefix. Tweakable species presets.            |
| `scripts/render/fish_renderer.gd`        | `FR` prefix. Converts 3-D → sprite instance.       |
| `scripts/tools/shape_generator.gd`       | `SG` prefix. Generates in-memory textures.         |
| `scripts/core/game_manager.gd`           | `GM` prefix. Singleton for settings / debug.       |

*All scripts obey the naming scheme described next.*

---

## 3 Naming Convention (💡 *“3-part handle” rule*)

```
<2-letter Script Prefix>_<snake_case_var>_<2-letter Context Tag>
```

* **Prefix** — top-level owner script (`BF`, `FB`, `GM`, …).
* **Var name** — regular Godot style (`head_pos`, `max_speed`, …).
* **Context tag** — two-letter hint:

  * `SH` shared / constant in script
  * `UP` updated each frame
  * `IN` inspector export
  * `TM`, `RD`, `AI` etc. for major function scopes

*Example* `BF_head_pos_UP` → “BoidFish / head position / updated each frame”.

---

## 4 Core Data Structures

| Struct / Node                | Key Fields (camel is inside snake case for brevity)                                                                                                                               |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`FishArchetype`** (`FA_…`) | `size_vec3_IN`, `max_speed_IN`, `wander_weight_IN`, `flock_type_IN`, `depth_pref_IN`, deform params (`z_steer_weight_IN`, `deform_min_x_IN`, `deform_max_y_IN`, `flip_thresh_IN`) |
| **`BoidFish`** (`BF_…`)      | `head_pos_UP: Vector3`, `tail_pos_UP: Vector3`, `velocity_UP`, `accel_UP`, `archetype_IN`, `species_id_SH:int`, behaviour timers, `z_angle_UP/target_UP`                          |
| **`BoidSystem`** (`FB_…`)    | Fish array, 3-D spatial hash (`Dictionary<Vector3i, Array[int]>`), tank bounds, random generator                                                                                  |
| **`GameManager`** (`GM_…`)   | All user-exposed settings & debug toggles (see §9)                                                                                                                                |

---

## 5 Runtime Parameters & Defaults

| Item                   | Default                                                                       | Range / Notes                                                                    |
| ---------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Tank size** (pixels) | `width = window_w`, `height = window_h`, `depth = height * GM_depth_scale_IN` | `GM_depth_scale_IN` ∈ \[**0.5**, 1.5]                                            |
| **Fish count**         | 300                                                                           | Slider 50 – 600                                                                  |
| **Species**            | 6 archetypes × 3–5 variants each                                              | Example sets: schooling tetra, goldfish, gourami, cory catfish, angelfish, betta |
| **Fixed sim Δt**       | 1 / 120 s                                                                     | Clamp ≤ 1 / 60 on low-end                                                        |
| **Render FPS**         | 60 Hz (engine default)                                                        | vsync on                                                                         |

---

## 6 Simulation Details

* **Steering forces** — classic Reynolds (separation, alignment, cohesion) in *full 3-D*.
* **Head/tail update**

  1. Integrate **head** by velocity.
  2. Constrain **tail** to fixed segment length (simple spring).
  3. Compute **orientation** = normalized (`head – tail`).
* **Wall avoidance** — soft repulsion + hard clamp as in earlier spec.
* **Behaviour blends** — flock types: `SCHOOL`, `SHOAL`, `LONER`, `BOTTOM_DWELLER`, `CRUISER`.

  * Species-match weight > other species, but tolerance factor tunable.
* **Z-axis depth bias** — archetype may prefer strata (e.g. bottom dwellers gravitate to depth ≈ 0.8 × max).

---

## 7 Rendering Pipeline (2-D facade)

1. **Snapshot** sim state → array of `{head, tail, species_id}`.
2. For each fish:

   * **Project** `(x, y)` = `head.xy`.
   * **Depth ratio** = `head.z / tank_depth`.
   * **Scale** = `lerp(scale_front, scale_back, depth_ratio)`.
   * **Yaw angle** from `atan2(velocity.y, velocity.x)`.
   * **Squash / stretch** per §6 deform rules and archetype parameters.
   * **Tint & brightness** fade with depth (optional cold-blue far, warm-bright near).
3. Submit to Godot `CanvasItem` or `MultiMeshInstance2D` for batching.

(*Soft-body mesh hook — future work: feed head/tail into a custom shader/mesh deformer.*)

---

## 8 Placeholder Art Generation — **Update**

* `ShapeGenerator.gd` builds ellipse / triangle **in-memory only** by default.
* Debug gate:

```gdscript
if GM_debug_enabled_SH and GM_dump_placeholders_SH:
    img.save_png("res://art/ellipse_%dx%d.png" % [w, h])
```

*No binaries land in Git unless the developer explicitly flips `GM_dump_placeholders_SH`.*

---

## 9 Debug & Developer Flags  *(exposed on `GameManager`)*

| Flag                      | Default   | Effect                                        |
| ------------------------- | --------- | --------------------------------------------- |
| `GM_debug_enabled_SH`     | **false** | Master switch.                                |
| `GM_draw_spines_SH`       | false     | Draw head-tail lines in 2-D.                  |
| `GM_log_fish_SH`          | false     | CSV dump of one fish’s 3-D state (perf test). |
| `GM_dump_placeholders_SH` | false     | Saves placeholder PNGs as §8 describes.       |
| `GM_show_grid_SH`         | false     | Renders 3-D spatial hash cells in overlay.    |

All debug code is stripped from release builds via `if` guards.

---

## 10 Performance Budgets

| Stage           | Goal              | Notes                                                           |
| --------------- | ----------------- | --------------------------------------------------------------- |
| **Steering**    | ≤ 2 ms @ 400 fish | Spatial hash reduces neighbor lookups to O(N + avg\_neighbors). |
| **Integration** | ≤ 1 ms            | Head & tail spring is constant-time.                            |
| **Render prep** | ≤ 1 ms            | Uses pooled arrays; no allocations during play.                 |
| **GPU draw**    | ≤ 0.5 ms          | `MultiMesh` or `CanvasItem` batching.                           |

---

## 11 Future Hooks

* Soft-body spline / shader mesh based on head-tail segment.
* Environment triggers (bubbles, food, light gradient).
* User interactivity (mouse poke → local disturbance).
* JSON-driven archetype library & workshop.

---

### ✅ Spec Locked (v 0.3.1)


