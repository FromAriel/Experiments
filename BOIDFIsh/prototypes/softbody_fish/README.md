# SoftBody Fish Prototype

Experimental soft body fish based on a spring-mesh approach.
This folder contains a minimal Godot project for quick iteration.

The fish scales up 15× and centers itself when the scene runs. Head and tail
control nodes can be dragged in play mode; the springs will snap the mesh back
when released. Use the exported variables on the `SoftBodyFish` node to tweak
head and tail stiffness separately or adjust the added cross-brace strength.
