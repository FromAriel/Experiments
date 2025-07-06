# LIVEdie

A minimal Godot 4 project prepared for mobile devices.

This folder contains the starting structure:

- `project.godot` – project settings targeting mobile devices.
- `main.tscn` – empty scene placeholder.
- `scripts/` – for GDScript files.
- `assets/` – for art and other resources.
- `scenes/dial_spinner.tscn` – circular quantity spinner.

## Running on mobile

1. Open the project in Godot 4.
2. Install Android or iOS export templates via **Project > Install Android Build Template** (for Android) or the equivalent for iOS.
3. Add an export preset under **Project > Export** and configure it for your device.
4. Build and deploy to your phone or tablet using the export window.

The project defaults to portrait orientation and touch input, so it should run on mobile without additional tweaks.
