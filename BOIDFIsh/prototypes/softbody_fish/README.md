# SoftBody Fish Prototype

Experimental soft body fish based on a spring-mesh approach.
This folder contains a minimal Godot project for quick iteration.

## Feathered Stroke Demo

The scene now includes a viewport-based silhouette capture that feeds a
`feathered_ring_fish.gdshader`. The shader blends from an edge colour to a
centre colour using a blurred distance map so the fish has a soft border or
optional concentric rings. Parameters such as stroke width and ring frequency
are exposed in the inspector for live tweaking.
