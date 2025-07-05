# SoftBody Fish Prototype

Experimental soft body fish based on a spring-mesh approach.
This folder contains a minimal Godot project for quick iteration.

The `soft_body_fish.gdshader` simulates a rounded body by faking 3‑D
lighting from the UVs. The shader uses adjustable `body_radius`,
`bulge_power` and `light_dir` uniforms so the highlights follow the
deforming polygon.
