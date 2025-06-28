# Fakey 3D Fish Tank

This directory houses a modular aquarium simulation scaffold built with Godot 4.4.
It is organized for extensibility and data-driven development.

## Directory Layout
- `data/` – JSON and resource files describing archetypes and tank settings
- `scenes/` – Scene files (`.tscn`)
- `scripts/` – GDScript logic stubs
- `scripts/data/` – Resource classes like `FishArchetype`
- `scripts/data/archetype_loader.gd` – JSON parser with fallback art
- `art/` – Placeholder sprites and textures
- `ui/` – Interface scenes
- `tools/` – Debug and development helpers
- `FishTank.sln` and `FishTank.csproj` – C# project files for Mono builds
Both `ui/` and `tools/` are created empty for now and ready for new scenes and editor utilities.

## Adding New Archetypes
1. Create an entry in `data/archetypes.json`.
2. Provide any required placeholder art in `art/`.
3. Extend scripts to support custom behavior.
