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
    _FT_update_environment_bounds_IN()
    var FT_loader_IN := ArchetypeLoader.new()
    var FT_archetypes_UP := FT_loader_IN.AL_load_archetypes_IN("res://data/archetypes.json")
    var FT_boid_system_UP: BoidSystem = $BoidSystem
    if FT_boid_system_UP.BS_config_IN == null:
        FT_boid_system_UP.BS_config_IN = BoidSystemConfig.new()
    FT_boid_system_UP.BS_spawn_population_IN(FT_archetypes_UP)
    FT_overlay_label_UP.text = "Loaded %d archetypes" % FT_archetypes_UP.size()


func FT_apply_depth_IN(node: Node2D, depth: float) -> void:
    var FT_ratio_UP: float = clamp(depth / FT_environment_IN.TE_size_IN.z, 0.0, 1.0)
    var FT_scale_UP: float = lerp(1.0, 0.5, FT_ratio_UP)
    node.scale = Vector2.ONE * FT_scale_UP
    var FT_tint_UP: float = 1.0 - FT_ratio_UP * 0.5
    node.modulate = Color(FT_tint_UP, FT_tint_UP, FT_tint_UP)


func _FT_update_environment_bounds_IN() -> void:
    var FT_tank_UP: Area2D = get_node_or_null("Tank")
    if FT_tank_UP and FT_tank_UP.has_node("CollisionShape2D"):
        var FT_shape_UP := FT_tank_UP.get_node("CollisionShape2D").shape
        if FT_shape_UP is RectangleShape2D:
            var FT_size_UP: Vector2 = FT_shape_UP.size * FT_tank_UP.scale
            var FT_origin_UP: Vector2 = FT_tank_UP.position - FT_size_UP / 2.0
            FT_environment_IN.TE_size_IN = Vector3(
                FT_size_UP.x, FT_size_UP.y, FT_environment_IN.TE_size_IN.z
            )
            FT_environment_IN.TE_boundaries_SH = AABB(
                Vector3(FT_origin_UP.x, FT_origin_UP.y, -FT_environment_IN.TE_size_IN.z / 2.0),
                FT_environment_IN.TE_size_IN
            )
            return

    var FT_rect_UP: Rect2 = get_viewport_rect()
    FT_environment_IN.TE_size_IN = Vector3(
        FT_rect_UP.size.x, FT_rect_UP.size.y, FT_environment_IN.TE_size_IN.z
    )
    FT_environment_IN.TE_boundaries_SH = AABB(
        Vector3(
            FT_rect_UP.position.x, FT_rect_UP.position.y, -FT_environment_IN.TE_size_IN.z / 2.0
        ),
        FT_environment_IN.TE_size_IN
    )
# gdlint:enable = class-variable-name,function-name,function-variable-name
