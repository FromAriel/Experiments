# SoftBody Fish Prototype

Experimental soft body fish based on a spring-mesh approach.
This folder contains a minimal Godot project for quick iteration.

## Shading

`shaders/soft_body_fish.gdshader` fakes 3‑D lighting by bulging the fish's UVs
along custom X/Y radii. The center appears brighter while the edges fall off,
giving the polygon a rounded body even as its vertices deform.
