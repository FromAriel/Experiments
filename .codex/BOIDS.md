Here is your converted Git patch content as clean Markdown from the `.codex/BOIDS.md` file:

---

# Boid Swarm Algorithm

This document summarizes how the boid swarm implementation works in **Alone in Space**. The concepts and formulas here are generic and can be ported to other engines.

---

## Data Representation

Each boid is represented by a position and velocity stored in arrays. Key parameters controlling the behaviour include:

* `neighbor_radius` – radius within which other boids influence the current boid.
* `separation_distance` – minimum allowed distance to neighbors.
* `max_speed` – maximum speed a boid may reach.
* `max_force` – maximum steering force applied per frame.
* `grid_cell_size` – size of each spatial partition cell.
* `bounds_rect` – world rectangle used for wrapping around.

These parameters appear at the start of the `BoidSwarm.gd` script and define the behaviour weights:

```gdscript
@export var boid_profile: BoidProfile
@export var boid_count: int = 50
@export var neighbor_radius: float = 50.0
@export var separation_distance: float = 25.0
@export var max_speed: float = 100.0
@export var max_force: float = 20.0
@export var grid_cell_size: float = 100.0
@export var bounds_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1024, 768))
@export var boid_radius: float = 1.5
var cohesion_weight: float = 1.0
var alignment_weight: float = 1.0
var separation_weight: float = 1.5
```

---

## Spatial Partitioning

To efficiently find neighbors each frame, boids are inserted into a uniform grid:

```gdscript
func _update_grid() -> void:
    _grid.clear()
    for i in range(boid_count):
        var p: Vector2 = _positions[i]
        var cell := Vector2i(floor(p.x / grid_cell_size), floor(p.y / grid_cell_size))
        if not _grid.has(cell):
            _grid[cell] = []
        _grid[cell].append(i)
```

Neighbor lookup checks the current cell and the eight surrounding cells. This reduces the search cost compared to checking every boid.

---

## Core Behaviors

During each update the swarm computes **alignment**, **cohesion**, and **separation** for every boid. The code below shows the main loop and formulas (simplified for clarity):

```gdscript
for i in range(boid_count):
    var pos := _positions[i]
    var vel := _velocities[i]
    var separation := Vector2.ZERO
    var alignment := Vector2.ZERO
    var cohesion := Vector2.ZERO
    var count := 0

    var cell := Vector2i(floor(pos.x / grid_cell_size), floor(pos.y / grid_cell_size))
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var key := Vector2i(cell.x + dx, cell.y + dy)
            if _grid.has(key):
                for j in _grid[key]:
                    if j == i:
                        continue
                    var d := _positions[j] - pos
                    var dist := d.length()
                    if dist < neighbor_radius:
                        alignment += _velocities[j]
                        cohesion += _positions[j]
                        count += 1
                        if dist < separation_distance and dist > 0.0:
                            separation -= d / dist
    if count > 0:
        alignment = alignment / count
        alignment = alignment.normalized() * max_speed - vel
        alignment = alignment.limit_length(max_force)

        cohesion = (cohesion / count - pos)
        if cohesion != Vector2.ZERO:
            cohesion = cohesion.normalized() * max_speed - vel
            cohesion = cohesion.limit_length(max_force)

        separation = separation / count
        if separation != Vector2.ZERO:
            separation = separation.normalized() * max_speed - vel
            separation = separation.limit_length(max_force)

    var accel := alignment * align_w + cohesion * coh_w + separation * sep_w
    vel += accel * delta
    vel = vel.limit_length(max_speed)
    pos += vel * delta
```

### Alignment

Boids steer toward the average heading of nearby flockmates.

### Cohesion

Boids seek the center of mass of neighbors.

### Separation

Boids steer away from neighbors closer than `separation_distance`.

---

## Velocity and Position Update

The final acceleration is a weighted sum of the three behaviors:

```gdscript
vel += accel * delta
vel = vel.limit_length(max_speed)
pos += vel * delta
```

Boids are wrapped within the world bounds:

```gdscript
if pos.x < bounds_rect.position.x:
    pos.x = bounds_rect.end.x
elif pos.x > bounds_rect.end.x:
    pos.x = bounds_rect.position.x
if pos.y < bounds_rect.position.y:
    pos.y = bounds_rect.end.y
elif pos.y > bounds_rect.end.y:
    pos.y = bounds_rect.position.y
```

---

## Example Pseudocode

```pseudo
for each boid i:
    neighbors = find_neighbors(i)
    alignment = Vector2(0, 0)
    cohesion = Vector2(0, 0)
    separation = Vector2(0, 0)
    count = 0
    for each j in neighbors:
        if i == j: continue
        diff = position[j] - position[i]
        dist = length(diff)
        if dist < neighbor_radius:
            alignment += velocity[j]
            cohesion += position[j]
            count += 1
            if dist < separation_distance and dist > 0:
                separation -= diff / dist
    if count > 0:
        alignment = normalize(alignment / count) * max_speed - velocity[i]
        cohesion = normalize((cohesion / count) - position[i]) * max_speed - velocity[i]
        separation = normalize(separation / count) * max_speed - velocity[i]
    acceleration = alignment_weight * alignment
                  + cohesion_weight * cohesion
                  + separation_weight * separation
    velocity[i] = clamp_length(velocity[i] + acceleration * dt, max_speed)
    position[i] += velocity[i] * dt
    wrap_position_within_bounds()
```

---

## Conclusion

The boid swarm operates by computing local steering forces—alignment, cohesion, separation—based on nearby boids located via a simple grid. The forces are weighted and combined to update velocity and position each frame. Wrapping around the world bounds keeps the flock contained. The same formulas can be ported to other game engines or languages with minimal changes.


