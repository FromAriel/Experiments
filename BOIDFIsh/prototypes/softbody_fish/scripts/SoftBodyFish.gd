# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# prototypes/softbody_fish/scripts/SoftBodyFish.gd
# Key Classes      • SoftBodyFish – simple soft-body fish prototype
# Key Functions    • _physics_process() – spring update loop
# Critical Consts  • SBF_BASE_POINTS_SH – initial node layout
# Editor Exports   • sbf_spring_strength_SH, sbf_radial_strength_SH
# Dependencies     • none
# Last Major Rev   • 24-04-27 – initial version
###############################################################
class_name SoftBodyFish
extends Node2D

# ------------------------------------------------------------------ #
#  Constants                                                         #
# ------------------------------------------------------------------ #
const SBF_BASE_POINTS_SH: Array[Vector2] = [
    Vector2(4, 5.5),
    Vector2(6, 6.6),
    Vector2(9, 7.0),
    Vector2(12, 5.4),
    Vector2(14, 6.75),
    Vector2(15, 7.0),
    Vector2(15, 3.0),
    Vector2(14, 3.25),
    Vector2(12, 4.6),
    Vector2(9, 3.0),
    Vector2(6, 3.4),
    Vector2(4, 4.5),
]

const SBF_NUM_NODES_SH: int = SBF_BASE_POINTS_SH.size()

# ------------------------------------------------------------------ #
#  Inspector parameters                                              #
# ------------------------------------------------------------------ #
@export var sbf_scale_SH: float = 10.0
@export var sbf_spring_strength_SH: float = 40.0
@export var sbf_radial_strength_SH: float = 20.0
@export var sbf_damping_SH: float = 0.8
@export var sbf_gravity_SH: float = 9.8
@export var sbf_wobble_amp_SH: float = 0.5
@export var sbf_wobble_speed_SH: float = 1.5

# ------------------------------------------------------------------ #
#  Runtime state                                                     #
# ------------------------------------------------------------------ #
var sbf_nodes_UP: Array[Vector2] = []
var sbf_vels_UP: Array[Vector2] = []
var sbf_polygon_POLY: Polygon2D

# Stub placeholders for future head/tail control.
var sbf_head_ctrl_LC: Vector2 = Vector2.ZERO
var sbf_tail_ctrl_LC: Vector2 = Vector2.ZERO


# ------------------------------------------------------------------ #
func _ready() -> void:
    _init_nodes()
    sbf_polygon_POLY = Polygon2D.new()
    add_child(sbf_polygon_POLY)
    sbf_polygon_POLY.material = load("res://shaders/SoftBodyFish.shader")
    _build_polygon()


func _init_nodes() -> void:
    sbf_nodes_UP.resize(SBF_NUM_NODES_SH)
    sbf_vels_UP.resize(SBF_NUM_NODES_SH)
    for i in range(SBF_NUM_NODES_SH):
        sbf_nodes_UP[i] = SBF_BASE_POINTS_SH[i] * sbf_scale_SH
        sbf_vels_UP[i] = Vector2.ZERO


func _physics_process(delta: float) -> void:
    _physics_step(delta)
    _build_polygon()


func _physics_step(delta: float) -> void:
    for i in range(SBF_NUM_NODES_SH):
        var pos := sbf_nodes_UP[i]
        var prev := sbf_nodes_UP[(i - 1 + SBF_NUM_NODES_SH) % SBF_NUM_NODES_SH]
        var next := sbf_nodes_UP[(i + 1) % SBF_NUM_NODES_SH]

        var target := SBF_BASE_POINTS_SH[i] * sbf_scale_SH
        target.x += (
            sin(OS.get_ticks_msec() / 1000.0 * sbf_wobble_speed_SH + float(i)) * sbf_wobble_amp_SH
        )

        var spring := ((prev + next) * 0.5 - pos) * sbf_spring_strength_SH
        var radial := (target - pos) * sbf_radial_strength_SH
        var grav := Vector2(0, sbf_gravity_SH)

        var vel := sbf_vels_UP[i]
        vel += (spring + radial + grav) * delta
        vel *= sbf_damping_SH
        pos += vel * delta

        sbf_vels_UP[i] = vel
        sbf_nodes_UP[i] = pos


func _build_polygon() -> void:
    var poly := PackedVector2Array(sbf_nodes_UP)
    sbf_polygon_POLY.polygon = poly
