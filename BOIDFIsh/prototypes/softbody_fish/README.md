# SoftBody Fish Prototype

Experimental soft body fish based on a spring-mesh approach.
This folder contains a minimal Godot project for quick iteration.

The fish is scaled up 15× and centered on load. Drag the exposed
`HeadControl` and `TailControl` nodes in the editor or at runtime to
stretch the mesh. Additional cross-brace springs keep the body stable
while separate spring strength exports allow tuning of the head, tail
and body stiffness individually.
