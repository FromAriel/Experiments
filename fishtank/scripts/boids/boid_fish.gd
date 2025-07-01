###############################################################
# fishtank/scripts/boids/boid_fish.gd
# Key Classes      • BoidFish – minimal boid entity
# Dependencies     • fish_archetype.gd, tank_environment.gd
# Last Major Rev   • 24-07-05 – auto-spawn placeholder sprite, null-safety
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name

class_name BoidFish
extends Node2D

# --------------------------------------------------------------
# Enums
# --------------------------------------------------------------
enum FishBehavior { SCHOOL, DART, IDLE, CHASE }

enum MovementMode { NORMAL, FLIP_TURN_ENABLED }

const TankEnvironment = preload("res://scripts/data/tank_environment.gd")

# --------------------------------------------------------------
# Exports
# --------------------------------------------------------------
@export var BF_depth_lerp_speed_IN: float = 1.0

# --------------------------------------------------------------
# Vars
# --------------------------------------------------------------
var BF_position_UP: Vector3 = Vector3.ZERO
var BF_velocity_UP: Vector3 = Vector3.ZERO
var BF_archetype_IN: FishArchetype
var BF_group_id_SH: int = 0
var BF_isolated_timer_UP: float = 0.0
var BF_environment_IN: TankEnvironment
var BF_behavior_SH: int = FishBehavior.SCHOOL
var BF_target_depth_SH: float = 0.0
var BF_wander_phase_UP: float = 0.0
var BF_flip_timer_UP: float = 0.0
var BF_flip_applied_SH: bool = false
var BF_flip_duration_IN: float = 0.4
var BF_z_angle_UP: float = 0.0
var BF_z_steer_target_UP: float = 0.0
var BF_z_last_angle_UP: float = 0.0
var BF_z_flip_applied_SH: bool = false
var BF_rot_target_UP: float = 0.0
var BF_pitch_UP: float = 0.0
var BF_head_pos_UP: Vector3 = Vector3.ZERO
var BF_tail_pos_UP: Vector3 = Vector3.ZERO


func _ready() -> void:
    set_process(true)
    _BF_ensure_visual_IN()
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    BF_wander_phase_UP = rng.randf_range(0.0, TAU)
    BF_target_depth_SH = BF_position_UP.z
    BF_head_pos_UP = BF_position_UP
    BF_tail_pos_UP = BF_position_UP
    if BF_archetype_IN != null:
        BF_behavior_SH = BF_archetype_IN.FA_behavior_IN


func _process(delta: float) -> void:
    if BF_flip_timer_UP > 0.0:
        _BF_update_flip_turn_IN(delta)
    elif BF_velocity_UP != Vector3.ZERO:
        var turn_speed: float = 5.0
        if BF_archetype_IN != null:
            turn_speed = BF_archetype_IN.FA_turn_speed_IN
        rotation = lerp_angle(rotation, BF_rot_target_UP, turn_speed * delta)

    if BF_environment_IN != null:
        _BF_apply_depth_IN()

    var squash_intensity = abs(BF_pitch_UP) / PI
    var sx = 1.0
    var sy = 1.0
    if BF_archetype_IN != null:
        sx = lerp(1.0, BF_archetype_IN.FA_z_deform_min_x_IN, squash_intensity)
        sy = lerp(1.0, BF_archetype_IN.FA_z_deform_max_y_IN, squash_intensity)
    scale = Vector2(scale.x * sx, scale.y * sy)
    var sprite: Sprite2D = get_node_or_null("Sprite2D")
    if BF_archetype_IN != null:
        if squash_intensity > BF_archetype_IN.FA_z_flip_threshold_IN and not BF_z_flip_applied_SH:
            if sign(BF_z_angle_UP) != sign(BF_z_last_angle_UP):
                if sprite:
                    sprite.flip_h = not sprite.flip_h
                BF_z_flip_applied_SH = true
        else:
            BF_z_flip_applied_SH = false
    BF_z_last_angle_UP = BF_z_angle_UP


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
    var BF_ratio_UP: float = clamp(
        (BF_environment_IN.TE_size_IN.z - BF_position_UP.z) / BF_environment_IN.TE_size_IN.z,
        0.0,
        1.0,
    )

    # Scale
    var BF_scale_UP: float = lerp(0.5, 1.0, BF_ratio_UP)
    scale = Vector2.ONE * BF_scale_UP

    # Tint / opacity
    var BF_col := modulate
    BF_col.a = lerp(0.4, 1.0, BF_ratio_UP)
    modulate = BF_col


func _BF_start_flip_turn_IN(duration: float) -> void:
    BF_flip_duration_IN = duration
    BF_flip_timer_UP = duration
    BF_flip_applied_SH = false


func _BF_update_flip_turn_IN(delta: float) -> void:
    BF_flip_timer_UP = max(BF_flip_timer_UP - delta, 0.0)
    var half := BF_flip_duration_IN * 0.5
    var sprite: Sprite2D = get_node_or_null("Sprite2D")
    var sx := 1.0
    var sy := 1.0
    if BF_flip_timer_UP > half:
        var t := 1.0 - (BF_flip_timer_UP - half) / half
        sx = lerp(1.0, 0.6, t)
        sy = lerp(1.0, 1.4, t)
    else:
        if not BF_flip_applied_SH:
            BF_flip_applied_SH = true
            if sprite:
                sprite.flip_h = not sprite.flip_h
            BF_velocity_UP = -BF_velocity_UP
        var t2 := 1.0 - BF_flip_timer_UP / half
        sx = lerp(0.6, 1.0, t2)
        sy = lerp(1.4, 1.0, t2)
    if sprite:
        sprite.scale = Vector2(sx, sy)
    if BF_flip_timer_UP == 0.0 and sprite:
        sprite.scale = Vector2.ONE
