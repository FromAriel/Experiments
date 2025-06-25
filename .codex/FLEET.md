🎯 Boids System Enhancement — Multi-Group AI Behavior
Task:
Edit the current Boids system to support 5 distinct groups, each with unique properties and behavior. The system must include dynamic avoidance and be optimized for performance.

🧠 Boid Groups Overview
Group 1: Scouts
Visual: Small, light triangle primitive

Behavior:

Fast, lightweight

Occasionally performs short bursts of speed

Movement is erratic and twitchy

Use Case: Recon units or fast harassment swarms

Group 2: Kamikaze
Visual: Arrowhead or spike

Behavior:

Aggressively targets the player’s current position

Often overshoots the target, course corrects, and charges again

Use Case: Suicide drones or berserker units

Group 3: Fighters
Visual: Medium-sized classic Boid

Behavior:

Standard flocking behavior (alignment, cohesion, separation)

Ideal for dogfighting and formation-based swarm combat

Use Case: Mainline AI fighters

Group 4: Guardians
Visual: Hexagon shape

Behavior:

Loosely orbits around Group 5 units

Defensive support role — not directly attacking, more patrol/escort pattern

Use Case: Escorts or shields for VIP targets

Group 5: Carriers
Visual: Large, heavy octagon shape

Behavior:

Slow-moving, keeps visual contact with player

Prefers to stay at maximum comfortable distance

Acts as a central command node or mothership

Use Case: Boss support, anchor for battle formations

⚠️ System Requirements
Collision Avoidance:

All Boids (regardless of group) must actively avoid crashing or overlapping with:

Other Boids in the same group

Boids in other groups

Environmental obstacles (if implemented)

Performance Optimization:

Maintain natural, fluid movement

Use efficient spatial partitioning (e.g., grid or quad-tree) for collision and neighbor detection

Ensure the system remains performant with hundreds of active Boids

✅ Goals Summary
Modular Boid behavior per group

Smooth inter-group interaction (e.g., G4 orbiting G5, G2 targeting player)

Dynamic yet believable aerial combat and positioning

Strong performance under swarm conditions
