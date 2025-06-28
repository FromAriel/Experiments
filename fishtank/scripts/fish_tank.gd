###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name
# fishtank/scripts/fish_tank.gd
# Key Classes      • FishTank – root controller for the aquarium
# Key Functions    • _ready() – initialize tank and debug overlay
#                   FT_apply_depth_IN() – apply pseudo-3D transform
# Dependencies     • archetype_loader.gd, tank_environment.gd
# Last Major Rev   • 24-06-30 – add debug overlay and depth logic
###############################################################

class_name FishTank
extends Node2D

@export var FT_environment_IN: TankEnvironment
var FT_overlay_label_UP: Label


func _ready() -> void:
    FT_overlay_label_UP = $DebugOverlay/DebugLabel
    if FT_environment_IN == null:
        FT_environment_IN = TankEnvironment.new()
    FT_environment_IN.TE_update_bounds_IN()
    var FT_loader_IN := ArchetypeLoader.new()
    var FT_archetypes_UP := FT_loader_IN.AL_load_archetypes_IN("res://data/archetypes.json")
    FT_overlay_label_UP.text = "Loaded %d archetypes" % FT_archetypes_UP.size()


func FT_apply_depth_IN(node: Node2D, depth: float) -> void:
    var FT_ratio_UP: float = clamp(depth / FT_environment_IN.TE_size_IN.z, 0.0, 1.0)
    var FT_scale_UP: float = lerp(1.0, 0.5, FT_ratio_UP)
    node.scale = Vector2.ONE * FT_scale_UP
    var FT_tint_UP: float = 1.0 - FT_ratio_UP * 0.5
    node.modulate = Color(FT_tint_UP, FT_tint_UP, FT_tint_UP)
# gdlint:enable = class-variable-name,function-name,function-variable-name
