###############################################################
# fishtank/scripts/boids/boid_fish.gd
# Key Classes      • BoidFish – minimal boid entity
# Dependencies     • fish_archetype.gd, tank_environment.gd
# Last Major Rev   • 24-07-05 – auto-spawn placeholder sprite, null-safety
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name

class_name BoidFish
extends Node2D

enum FishBehavior { SCHOOL, DART, IDLE, CHASE }

const TankEnvironment = preload("res://scripts/data/tank_environment.gd")

var BF_velocity_UP: Vector2 = Vector2.ZERO
var BF_archetype_IN: FishArchetype
var BF_group_id_SH: int = 0
var BF_isolated_timer_UP: float = 0.0
var BF_depth_UP: float = 0.0
var BF_environment_IN: TankEnvironment
var BF_behavior_SH: int = FishBehavior.SCHOOL
var BF_target_depth_SH: float = 0.0
var BF_wander_phase_UP: float = 0.0
var BF_depth_lerp_speed_IN: float = 1.5


func _ready() -> void:
    set_process(true)
    _BF_ensure_visual_IN()


func _process(delta: float) -> void:
    if BF_velocity_UP != Vector2.ZERO:
        var turn_speed := 5.0
        if BF_archetype_IN != null:
            turn_speed = BF_archetype_IN.FA_turn_speed_IN
        rotation = lerp_angle(rotation, BF_velocity_UP.angle(), turn_speed * delta)

    if BF_environment_IN != null:
        _BF_apply_depth_IN()

    var anim := get_node_or_null("AnimationPlayer") as AnimationPlayer
    if anim != null and BF_environment_IN != null:
        var cfg_speed := 200.0
        if BF_archetype_IN != null:
            cfg_speed = BF_archetype_IN.FA_burst_speed_IN
        anim.speed_scale = BF_velocity_UP.length() / max(cfg_speed, 1.0)


# --------------------------------------------------------------
# Helpers
# --------------------------------------------------------------
func _BF_ensure_visual_IN() -> void:
    # Add a simple Sprite2D if the scene file didn't include one,
    # preventing null texture crashes and giving us something to see.
    if get_node_or_null("Sprite2D") != null:
        return  # already has a sprite

    var sprite := Sprite2D.new()
    sprite.name = "Sprite2D"
    sprite.centered = true
    var tex_path := "res://art/ellipse_placeholder.png"
    if ResourceLoader.exists(tex_path):
        sprite.texture = load(tex_path)
    add_child(sprite)


func _BF_apply_depth_IN() -> void:
    var BF_ratio_UP: float = clamp(BF_depth_UP / BF_environment_IN.TE_size_IN.z, 0.0, 1.0)
    scale = Vector2.ONE * lerp(1.0, 0.5, BF_ratio_UP)
    modulate = Color(
        1.0 - BF_ratio_UP * 0.5,
        1.0 - BF_ratio_UP * 0.5,
        1.0 - BF_ratio_UP * 0.5,
        lerp(1.0, 0.4, BF_ratio_UP),
    )
