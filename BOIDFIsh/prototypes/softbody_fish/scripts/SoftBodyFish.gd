###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/SoftBodyFish.gd
# Key Classes      • SoftBodyFish – basic soft-body fish prototype
# Key Functions    • _physics_process() – per-frame spring update
# Critical Consts  • SB_COORDS_UP – initial node layout
# Editor Exports   • SB_spring_strength_IN: float
# Dependencies     • none
# Last Major Rev   • 25-07-02 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,class-definitions-order
class_name SoftBodyFish
extends Node2D

const SB_COORDS_UP := [
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
    Vector2(4, 4.5)
]

@export var SB_spring_strength_IN: float = 60.0
@export var SB_radial_strength_IN: float = 20.0
@export_range(0.0, 1.0, 0.01) var SB_damping_IN: float = 0.9
@export var SB_gravity_IN: float = 0.0
@export var SB_wobble_amp_IN: float = 0.5
@export var SB_wobble_speed_IN: float = 2.0

var SB_nodes_UP := []
var SB_vels_UP := []
var SB_rest_UP := []
var SB_poly_node: Polygon2D
var SB_time_UP: float = 0.0

# Future expansion: head/tail controls
var SB_head_ctrl_UP: Vector2 = Vector2.ZERO
var SB_tail_ctrl_UP: Vector2 = Vector2.ZERO


func _ready() -> void:
    SB_rest_UP = SB_COORDS_UP.duplicate()
    for coord in SB_rest_UP:
        SB_nodes_UP.append(coord)
        SB_vels_UP.append(Vector2.ZERO)
    SB_poly_node = Polygon2D.new()
    SB_poly_node.material = load("res://shaders/SoftBodyFishShader.tres")
    add_child(SB_poly_node)
    _update_polygon()


func _physics_process(delta: float) -> void:
    SB_time_UP += delta
    var n: int = SB_nodes_UP.size()
    for i in n:
        var pos: Vector2 = SB_nodes_UP[i]
        var prev: Vector2 = SB_nodes_UP[(i - 1 + n) % n]
        var next: Vector2 = SB_nodes_UP[(i + 1) % n]
        var rest: Vector2 = SB_rest_UP[i]
        var spring: Vector2 = (next - pos) + (prev - pos)
        spring *= SB_spring_strength_IN
        var wobble_offset: Vector2 = (
            Vector2(
                sin(SB_time_UP * SB_wobble_speed_IN + float(i)),
                cos(SB_time_UP * SB_wobble_speed_IN + float(i))
            )
            * SB_wobble_amp_IN
        )
        var radial: Vector2 = (rest + wobble_offset - pos) * SB_radial_strength_IN
        var accel: Vector2 = spring + radial
        accel.y += SB_gravity_IN
        SB_vels_UP[i] += accel * delta
        SB_vels_UP[i] *= SB_damping_IN
        SB_nodes_UP[i] += SB_vels_UP[i] * delta
    _update_polygon()


func _update_polygon() -> void:
    if SB_poly_node:
        SB_poly_node.polygon = PackedVector2Array(SB_nodes_UP)
