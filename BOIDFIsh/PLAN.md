
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


######################### ################################# ############################### 
######################### ################################# ############################### 

# 12 Fish Reference data


| Ecological niche                 | Species (common → latin)                                                              | Qty                           | Size range                   | Why they work here                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------- | ---------------------------- | -------------------------------------------------------------------------------- |
| **Schooling “glitter”**          | Cardinal tetra *Paracheirodon axelrodi*<br>Rummy-nose tetra *Hemigrammus rhodostomus* | 120 – 150 total (60/60 split) | 1.5 ″                        | Huge shimmer cloud, tight schooling keeps them visually cohesive & stress-free.  |
| **Mid-water accent**             | Boesemani rainbowfish *Melanotaenia boesemani*                                        | 18–24                         | 4 ″                          | Flashy color shift, active but peaceful; draw the eye without bullying.          |
| **Graceful “gliders”**           | Marble angelfish *Pterophyllum scalare* (captive-bred)                                | 6–8                           | 6 ″ body (fin height \~10 ″) | Tall bodies fill vertical space; large tank volume limits territorial squabbles. |
| **Lazy cruisers / centerpieces** | Pearl gourami *Trichopodus leerii*                                                    | 10–12                         | 4–5 ″                        | Calm surface dwellers; sparkling throats under office lights.                    |
| **Bottom custodians**            | Sterbai corydoras *Corydoras sterbai*                                                 | 25–30                         | 2.5 ″                        | Constant “catfish parade,” sifts leftover food, extremely peaceful.              |
| **Algae patrol**                 | Bristlenose pleco *Ancistrus cf. cirrhosus*                                           | 6                             | 4–5 ″                        | Stay small, stick to glass & décor; don’t uproot plants.                         |
| **Detritus crew**                | Amano shrimp *Caridina multidentata*                                                  | 200+                          | 1.5 ″                        | Safe with the species above; superb filament-algae eaters.                       |

4. Fish Casting (Default Mix)
Layer / Role	Species Group	Qty (at 960 gal)	Behaviour Profile
Glitter cloud	Cardinal & Rummy-nose tetras	150	Tight school, mid-speed, depth 0.3 – 0.7
Mid accents	Boesemani rainbows	20	Constant cruisers, occasional burst, depth 0.2 – 0.6
Graceful gliders	Marble angelfish	8	Slow turns, mild territory, depth 0.4 – 0.8
Showpiece drifters	Pearl gouramis	10	Surface skimmers, gentle yaw, depth 0.0 – 0.3
Bottom parade	Sterbai corys	30	Ground-hugging hops, shoal loosely, depth 0.9
Custodians	Bristlenose plecos + Amano shrimp	6 + 200	Mostly stick to décor; occasional wall shift

(Quantities scale down automatically on smaller monitor windows.)

| Archetype (example)                       | Approx % of population | Primary states                 | Extra quirks                                                   |
| ----------------------------------------- | ---------------------- | ------------------------------ | -------------------------------------------------------------- |
| **Tiny schoolers** (tetras, rasboras)     | 40-60 %                | School, wander, dart           | React quickly to predators; tight cohesion.                    |
| **Mid-size drifters** (goldfish, angels)  | 15-25 %                | Cruise, peck, idle             | Large personal space; occasional group loitering near plants.  |
| **Lazy cruisers** (gourami, discus)       | 5-10 %                 | Slow roam, hover               | Prefer mid-depth “comfort zone”; rarely sprint.                |
| **Bottom feeders** (corys, loaches)       | 10-15 %                | Floor-hug, nibble, sudden dash | Bound to z ≈ bottom ± 20 cm; occasional vertical dart.         |
| **Territorial / aggressive** (male betta) | 1-2 singular fish      | Patrol, chase, flare           | Exclude same species within “bubble”; chase schoolers briefly. |

### Expanded “Resident Cast” -– husbandry quick-sheet

| Niche / role                         | Star species ( common → latin )                                                             | Adult size in\&nbsp.; cm                      | Temp °F (°C)                                | pH                         | Group size                                     | Swim zone                    | Temperament                     | Why they fit here                                                                                                                  |
| ------------------------------------ | ------------------------------------------------------------------------------------------- | --------------------------------------------- | ------------------------------------------- | -------------------------- | ---------------------------------------------- | ---------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Glitter cloud – schooling tetras** | • Cardinal tetra *Paracheirodon axelrodi*  <br>• Rummy-nose tetra *Hemigrammus rhodostomus* | 1.3-1.6 ″ (3-4 cm) <br>1.8-2.2 ″ (4.5-5.5 cm) | 73-81 °F (23-27 °C) <br>75-82 °F (24-28 °C) | 4.5-6.5 (soft) <br>6.2-7.0 | ≥ 12 each (really +25 for tight “ball”)        | mid (0.3-0.7 z)              | Peaceful, rapid schooling turns | Dense shimmering “bait-ball” contrasts with larger fish. ([animaldiversity.org][1], [thesprucepets.com][2], [en.wikipedia.org][3]) |
| **Mid-water accents – rainbows**     | Boesemani rainbow *Melanotaenia boesemani*                                                  | 4-4.5 ″ (10-12 cm)                            | 74-80 °F (23-27 °C)                         | 7.0-8.0                    | 8 + (harem ratio 1 ♂ : 2 ♀)                    | mid / upper (0.2-0.6 z)      | Very active, non-nippy          | Sunset color-shift draws the eye without bullying. ([reddit.com][4])                                                               |
| **Graceful gliders – angels**        | Marble angelfish *Pterophyllum scalare* (captive line)                                      | body 6 ″ (15 cm) – fins to 10 ″ (25 cm)       | 78-84 °F (26-29 °C)                         | 6.5-7.5                    | kept in 6-8 juveniles to dilute pair squabbles | mid / high (0.4-0.8 z)       | Semi-territorial during spawn   | Tall, slow “sail” adds vertical movement; volume tamps aggression.                                                                 |
| **Show-piece drifters**              | Pearl gourami *Trichopodus leerii*                                                          | 4-5 ″ (10-12 cm)                              | 76-82 °F (24-28 °C)                         | 6.0-8.0                    | 1 ♂ : 3 ♀ groups, 8-10 total                   | top third (0.0-0.3 z)        | Calm, air-breather              | Iridescent throat “pearls”; occupies still surface corners. ([thesprucepets.com][5])                                               |
| **Bottom parade**                    | Sterbai cory *Corydoras sterbai*                                                            | 2.3-2.7 ″ (6-7 cm)                            | 75-82 °F (24-28 °C)                         | 6.0-7.5                    | 10 + (true shoaler)                            | substrate (0.9 z)            | Totally peaceful                | Continuous “catfish parade” aerates sand & cleans scraps.                                                                          |
| **Algae patrol**                     | Bristlenose pleco *Ancistrus cf. cirrhosus*                                                 | 4-5.9 ″ (11-15 cm)                            | 73-80 °F (23-27 °C)                         | 6.5-7.5                    | 1 per 20–25 gal (6 in 960 gal≈right)           | glass / décor                | Reclusive; mild to fish         | Devours film algae, won’t uproot plants. ([en.aqua-fish.net][6])                                                                   |
| **Detritus crew**                    | Amano shrimp *Caridina multidentata*                                                        | 1.2-2.0 ″ (3-5 cm)                            | 70-78 °F (21-26 °C)                         | 6.5-8.0                    | 10 + per 15 gal (200 here)                     | everywhere but open midwater | Non-aggressive                  | Peerless filament-algae & bio-film grazers. ([aquariumcarebasics.com][7])                                                          |

---

### Behaviour presets ­– ready for the simulator

| Archetype                                   | Pop. share | Default states           | Depth window      | Speed    | Schooling rule            |
| ------------------------------------------- | ---------- | ------------------------ | ----------------- | -------- | ------------------------- |
| **Tiny schoolers** (tetras/rasboras)        | 45 %       | *school* → wander → dart | 0.25-0.70         | moderate | **tight, mix-friendly**   |
| **Mid-size drifters** (rainbows, angels)    | 20 %       | cruise → burst           | 0.20-0.65         | fast     | same-species loose shoal  |
| **Lazy cruisers** (gouramis)                | 8 %        | hover → slow roam        | 0.05-0.35         | slow     | pair / solitary           |
| **Bottom feeders** (cories, loaches)        | 12 %       | floor-hug → nibble       | 0.85-1.00         | moderate | shoal of 6 +              |
| **Custodians** (pleco, shrimp)              | 12 %       | cling → scrape           | substrate & décor | slow     | solitary / swarm (shrimp) |
| **Occasional aggressor** (e.g. betta sp.)\* | < 1 %      | patrol → flare           | 0.10-0.40         | bursty   | solitary territory        |

\*Not present in current cast but reserved for “challenge mode” presets.

---



Refrences

[1]: https://animaldiversity.org/accounts/Paracheirodon_axelrodi/?utm_source=chatgpt.com "ADW: Paracheirodon axelrodi: INFORMATION - Animal Diversity Web"
[2]: https://www.thesprucepets.com/cardinal-tetra-1378417?utm_source=chatgpt.com "Explore the Vibrant World of Cardinal Tetras"
[3]: https://en.wikipedia.org/wiki/Rummy-nose_tetra?utm_source=chatgpt.com "Rummy-nose tetra"
[4]: https://www.reddit.com/r/Aquariums/comments/x7gcio/tankmates_for_rainbowfish/?utm_source=chatgpt.com "Tankmates for rainbowfish? : r/Aquariums - Reddit"
[5]: https://www.thesprucepets.com/pearl-gourami-1381025?utm_source=chatgpt.com "Pearl Gourami Fish Species Profile"
[6]: https://en.aqua-fish.net/fish/bristlenose-catfish?utm_source=chatgpt.com "Bristlenose Catfish (Ancistrus cirrhosus) - Aqua-Fish.Net"
[7]: https://www.aquariumcarebasics.com/freshwater-shrimp/amano-shrimp/?utm_source=chatgpt.com "Amano Shrimp Care, Feeding, Algae Eating, Size, Lifespan - Video"

Here’s a little “starter library” of well-written, evergreen pages (plus two classic calculators) that experienced aquarists point newcomers toward when they’re planning a **large, mixed-community freshwater display**.  Skim them in roughly the order shown and you’ll have a solid, 360-degree view of stocking, aquascaping, biotope logic and long-term husbandry.

| What you’ll learn                   | Why it’s useful for a big show-tank                                                                                                          | Reference                                                                   |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Theme & layout fundamentals**     | Gives you eight proven layout “blueprints” (Dutch garden, Jungle, Island, Iwagumi, etc.) and shows how fish choice flows from the hardscape. | “Aquascaping 101 – Freshwater Aquarium Themes”  ([aqueon.com][1])           |
| **Step-by-step build walk-through** | 180 cm/210 gal planted tank diary with gear picks, livestock roll-out schedule and water-change maths – great sense of scale.                | PlantedTank forum build thread  ([tfhmagazine.com][2])                      |
| **Stock-list brainstorming**        | Community brainstorm around a 120 gal footprint; pros/cons of combining rainbows, angelfish, large tetras & bottom crews.                    | FishForums “120 g ideas”  ([reddit.com][3])                                 |
| **Biotope thinking**                | Explains how to mix fish that *see* the same water chemistry (& décor) in the wild; showcases Amazon, Rift-Lake, SE-Asia sets.               | Practical Fishkeeping “Create a biotope”  ([aqadvisor.com][4])              |
| **Compatibility quick-rules**       | Aqueon’s inch-per-gallon myth-busting table + aggression hierarchy & surface-area logic. Short and beginner-friendly.                        | Aqueon “Fish Compatibility”  ([aqueon.com][1])                              |
| **Detailed stocking guide**         | Long-form article that dives into oxygen demand, growth rate, schooling density and “territory bubbles” – moves beyond rules-of-thumb.       | Aquarium Co-op stocking guide  ([aqadvisor.com][5])                         |
| **Big-fish reference list**         | Profiles 15 species that *stay nice* in 150 gal+, including size, temperament, and swimming zone – handy for feature fish.                   | BuildYourAquarium “Large freshwater fish”  ([aquariumindustries.com.au][6]) |
| **Stocking *calculator***           | Plug tank dimensions & filtration, get a load-index based on adult size, waste output & aggression (helpful sanity check).                   | AqAdvisor (classic web tool)  ([aqadvisor.com][7])                          |
| **Surface-area & O₂ science**       | Why depth matters less than footprint once you pass \~50 cm; how current & temperature shift capacity.                                       | Wikipedia “Fishkeeping” stocking section  ([en.wikipedia.org][8])           |
| **Free PDF handbook**               | 40-page primer from a bricks-and-mortar shop: cycling, plant choices, fish charts, maintenance matrix. Good to keep offline.                 | Elmer’s Freshwater Aquarium Handbook (PDF)  ([elmersaquarium.com][9])       |

### How to use this bundle

1. **Pick a theme first** (nature, river-bank, Amazon blackwater, etc.) – the aquascaping article helps here.
2. **Run rough numbers** in AqAdvisor to see if your dream list is remotely feasible.
3. **Cross-check temperament** with the Aqueon & Aquarium Co-op guides; drop anything that scores “semi-aggressive” unless you’re dedicating a whole zone.
4. **Look at real builds** the forum/Reddit diaries show filtration shortcuts, light spreads and aquascape tricks that photos alone hide.
5. **Refine into a biotope-ish mix** so water chemistry & décor all work for *everyone* – the Practical Fishkeeping piece is gold here.
6. **Document it** – the PDF has ready-made log sheets; they’re boring now but priceless when you’re troubleshooting a year in.

Happy designing – and enjoy falling down the rabbit hole of gigantic glass boxes!

[1]: https://www.aqueon.com/articles/fish-compatibility?utm_source=chatgpt.com "Fish Compatibility: How to Build a Peaceful Community Fish Tank"
[2]: https://www.tfhmagazine.com/articles/aquarium-basics/fish-selection-stocking-guide?utm_source=chatgpt.com "Aquarium Stocking | Tropical Fish Hobbyist Magazine"
[3]: https://www.reddit.com/r/Aquariums/comments/e2bakc/1_inch_of_fish_per_gallon_isnt_that_ridiculous/?utm_source=chatgpt.com "1 inch of fish per gallon? Isn't that ridiculous? : r/Aquariums - Reddit"
[4]: https://aqadvisor.com/?utm_source=chatgpt.com "AqAdvisor - Intelligent Freshwater Tropical Fish Aquarium Stocking ..."
[5]: https://aqadvisor.com/AqAdvisor.php?AlreadySelected=200909300094%3A6%3A%3A%2C201002031336%3A12%3A%3A%2C200909300196%3A6%3A%3A%2C200909300117%3A6%3A%3A%2C200909300114%3A3%3A%3A%2C200909300175%3A6%3A%3A%2C200909300153%3A6%3A%3A&AqJuvMode=1&AqLengthUnit=cm&AqSearchMode=simple&AqSortType=sname&AqSpeciesWindowSize=long&AqTempUnit=F&AqVolUnit=L&AquFilterString=oto&AquListBoxChooser=Oto+%28Otocinclus+vittatus%29&AquListBoxFilter=Choose&AquListBoxFilter2=Choose&AquListBoxTank=Choose&AquTankDepth=45.72&AquTankHeight=50.8&AquTankLength=165.1&AquTankName=&AquTextBoxQuantity=&AquTextBoxRemoveQuantity=&AquTextFilterRate=0&AquTextFilterRate2=0&FilterMode=Display+all+species&FilterQuantity=0&FormSubmit=SortSName&utm_source=chatgpt.com "Intelligent Freshwater Tropical Fish Aquarium Stocking ... - AqAdvisor"
[6]: https://www.aquariumindustries.com.au/wp-content/uploads/2015/03/Freshwater-Fish-Compatibility-Chart.pdf?utm_source=chatgpt.com "[PDF] Aquarium Industries Freshwater Fish Compatibility Chart"
[7]: https://aqadvisor.com/AqAdvisorMarine.php?utm_source=chatgpt.com "Intelligent Saltwater Aquarium Stocking Calculator and ... - AqAdvisor"
[8]: https://en.wikipedia.org/wiki/Fishkeeping?utm_source=chatgpt.com "Fishkeeping"
[9]: https://www.elmersaquarium.com/pdf-files/FW%20Handbook.pdf?utm_source=chatgpt.com "[PDF] Freshwater Aquarium Handbook"


7 · Fish archetype table (authoring data)
Field	Meaning
Base size (body_len, body_depth)	
Mass, max speed front/back	
Turn responsiveness (z_steer_weight)	
Deformation limits (min_scale_x, max_scale_y, flip_threshold)	
Radii (r_sep, r_align, r_coh)	
Colour tint & depth fade curve	
Behaviour flags (schooling, bottom-dweller, aggressive, etc.)	

Rough plan: 6 archetypes × ~5 variants each → ≤ 30 json assets.



