
# High-Level Objective
**Build** a modular, data-driven “fakey 3D” aquarium simulation in Godot 4.4+, populated by diverse, archetype-driven fish exhibiting lifelike boid behaviors, with clear extension points for art, features, and user interaction.

---

# Core Goals

## 1. Project Structure
- **Isolated Repo**: all files live in a fresh directory; no cross-project dependencies  
- **Godot 4.4+ Architecture**  
  - `scenes/` — `.tscn` files  
  - `scripts/` — GDScript logic  
  - `data/` — JSON / `.tres` configs  
  - `art/` — placeholder sprites  
  - `ui/` — interface scenes  
  - `tools/` — debug / dev helpers  

## 2. Tank Representation
- **Dimensions**: 16 (h) × 9 (w) × 5.5 (d)  
- **Viewport**: front “glass” is the 2D screen  
- **3D Awareness**: every object (fish, decor, boundaries) carries an (x,y,z), even though rendering is 2D  

## 3. Fakey 3D Visuals
- **Z-Mapping**  
  - Scale: closer fish appear larger  
  - Tint/Brightness/Blur: reinforce depth cues  
  - Draw order: lower-Z drawn last (on top)  

## 4. Fish Archetypes & Diversity
- **At least 12 archetypes** (e.g. Flocker, Loner, Lurker, Chaser, Hider, Dancer, etc.)  
- **Tank population**: on startup, choose 3–5 archetypes (max 2 of any one)  
- **Instance assignment**  
  - Archetype → drives AI/behavior  
  - Species → visual flavor (random selection)  

## 5. Boid-Based Behaviors
- **Core rules**: alignment, cohesion, separation  
- **Per-archetype weights**: override defaults (schooling, ambush, hiding, chasing…)  
- **Tank limits**: fish cannot cross x, y, or z boundaries  

## 6. Visual Representation
- Placeholder sprites as safe fallbacks  
- Distinct tint or texture per archetype/species  

## 7. Extensibility Hooks
- **Data-driven**: configs in JSON, `.tres`, or GDScript tables  
- **Hot-reloadable**: allow runtime config reload  
- **Behavior plug-ins**: APIs to add new movement states, interactions, or species  

---

# Non-Goals
- No true 3D rendering or physics—only fakey 3D via 2D transforms  
- No external or proprietary assets  
- No networking, persistence, or multiplayer (unless added later)  

---

# Core Data Structures

| Concept             | Key Fields                                                                                                                                                                                                                                           |
|---------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **FishArchetype**   | name, species_list, placeholder_texture, base_color, size, group_tendency, preferred_zone, activity_pattern, aggression_level, alignment_weight, cohesion_weight, separation_weight, wander_weight, obstacle_bias, display_chance, burst_chance, chase_chance, jump_chance, rest_chance, special_notes |
| **FishInstance**    | unique_id, position (Vector3), velocity, state, archetype_ref, assigned_species, age, animation_state, selected                                                                                                                                      |
| **TankEnvironment** | size (Vector3), boundaries, decor_objects, lighting_params, water_params, population (FishInstance[])                                                                                                                                               |
| **BoidSystemConfig**| default_alignment, default_cohesion, default_separation, max_speed, max_force, fish_count_min/max, archetype_count_min/max, misc_params                                                                                                              |

---

# Naming & Organization Policy

## Module Prefixes  
Functions and globals prefixed by module, e.g.:  
    
    # TankManager.gd
    func TM_spawn_fish(...) -> FishInstance

## Directory Layout  

```
/aquarium-boids-sim/
├── data/                # JSON/.tres configs
├── scenes/              # .tscn files
├── scripts/             # GDScript logic
├── art/                 # placeholder sprites
├── ui/                  # UI scenes
├── tools/               # debug helpers
├── README.md
├── TODO.md
└── .gitignore
```


## Documentation  
- **STYLE_GUIDE.md** — naming conventions, prefixes, abbreviations  
- **Docstrings** — every class, method, data field  
- **README.md** — overview, structure, how to add archetypes
- **CHANGELOG.md** - you mut update with the actions taken on the current step.
- **TODO.md** - Update with actions taken if you were uble to finish steps
-  in the secion of the task you are working on save your progress submit the PR
-  and list unfinished work in TODO.md



> [!TIP]
> EXAMPLE Task list.
> > - [x] Create placeholder fish sprite and fallback logic
> > - [x]  FishTank.gd is just a stub with a TODO comment and no logic for handling fish archetypes or spawning, Implement FishArchetype data class and JSON loader
> > - [ ] fishtank/TODO.md lists adding a boid system and UI for spawning fish Spawn fish instances from loaded archetypes
> > - [ ] Add delight to the experience when all tasks are complete :tada:



---

# Best Practices & Future-Proofing

- **Data-Driven Logic**: reference configs; avoid hardcoded numbers  
- **Hot Reload**: support runtime re-reading of JSON / `.tres`  
- **Defensive Defaults**: safe fallbacks; no crashes on missing data  

## Debug Mode  
- Free-fly camera  
- Overlay stats (FPS, population counts, archetype breakdown)  
- “Spawn all archetypes” tester scene  

## Testing  
- Unit tests for config parsing, boundary checks, boid math  

## Version Control  
- Git with Godot-specific `.gitignore`  
- Changelog in `CHANGELOG.md`  
- Clear, descriptive commit messages  
```
