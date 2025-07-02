# ===============================================================
#  File:  res://scripts/soft_body/fish_soft_body.gd
#  Desc:  Stand-alone soft-body fish using spring physics.
# ===============================================================
# gdlint:disable = class-variable-name,function-name,class-definitions-order
class_name FishSoftBody
extends Node2D

# ------------------------------------------------------------------ #
#  Editor Exports                                                    #
# ------------------------------------------------------------------ #
@export var FSB_head_stiffness_IN: float = 600.0
@export var FSB_body_stiffness_IN: float = 200.0
@export var FSB_tail_stiffness_IN: float = 80.0
@export var FSB_tension_strength_IN: float = 4.0
@export var FSB_repulsor_strength_IN: float = 6.0
@export var FSB_damping_IN: float = 0.98

# ------------------------------------------------------------------ #
#  Geometry & Runtime State                                          #
# ------------------------------------------------------------------ #
const FSB_ANCHOR_COORDS_SH: PackedVector2Array = PackedVector2Array(
    [
        Vector2(4.0, 5.5),
        Vector2(6.0, 6.6),
        Vector2(9.0, 7.0),
        Vector2(12.0, 5.4),
        Vector2(14.0, 6.75),
        Vector2(15.0, 7.0),
        Vector2(15.0, 3.0),
        Vector2(14.0, 3.25),
        Vector2(12.0, 4.6),
        Vector2(9.0, 3.0),
        Vector2(6.0, 3.4),
        Vector2(4.0, 4.5)
    ]
)

const FSB_EDGES_DEF_SH := [
    {"a": 0, "b": 1, "type": "head"},
    {"a": 1, "b": 2, "type": "body"},
    {"a": 2, "b": 3, "type": "body"},
    {"a": 3, "b": 4, "type": "body"},
    {"a": 4, "b": 5, "type": "tail"},
    {"a": 5, "b": 6, "type": "tail"},
    {"a": 6, "b": 7, "type": "tail"},
    {"a": 7, "b": 8, "type": "body"},
    {"a": 8, "b": 9, "type": "body"},
    {"a": 9, "b": 10, "type": "body"},
    {"a": 10, "b": 11, "type": "body"},
    {"a": 11, "b": 0, "type": "head"},
    {"a": 2, "b": 9, "type": "body"},
    {"a": 3, "b": 8, "type": "body"},
    {"a": 4, "b": 7, "type": "tail"}
]

const FSB_TAIL_INDICES_SH := PackedInt32Array([4, 5, 6, 7])

var FSB_positions_UP: Array[Vector2] = []
var FSB_velocities_UP: Array[Vector2] = []
var FSB_rest_spine_dist_UP: Array[float] = []
var FSB_edges_UP: Array = []
var FSB_tail_rest_len_UP: Array[float] = []

@onready var FSB_polygon_RD: Polygon2D = $Polygon2D
@onready var FSB_tail_controller_RD: TailController = $TailController


func _ready() -> void:
    FSB_positions_UP.assign(FSB_ANCHOR_COORDS_SH)
    FSB_velocities_UP.resize(FSB_positions_UP.size())
    FSB_velocities_UP.fill(Vector2.ZERO)
    _FSB_compute_spine_rest_dist()
    _FSB_build_edges()
    _FSB_cache_tail_lengths()
    _FSB_update_polygon()


func _physics_process(delta: float) -> void:
    _FSB_solve_springs(delta)
    _FSB_apply_tension_and_repulsor(delta)
    _FSB_apply_tail_springs(delta)
    _FSB_integrate(delta)
    _FSB_update_polygon()


func _FSB_compute_spine_rest_dist() -> void:
    var spine_head := FSB_positions_UP[0]
    var spine_tail := (FSB_positions_UP[4] + FSB_positions_UP[7]) * 0.5
    FSB_rest_spine_dist_UP.clear()
    for p in FSB_positions_UP:
        var closest := Geometry2D.get_closest_point_to_segment(p, spine_head, spine_tail)
        FSB_rest_spine_dist_UP.append(p.distance_to(closest))


func _FSB_build_edges() -> void:
    FSB_edges_UP.clear()
    for e in FSB_EDGES_DEF_SH:
        var a: int = e["a"]
        var b: int = e["b"]
        var rest := FSB_positions_UP[a].distance_to(FSB_positions_UP[b])
        var k := FSB_body_stiffness_IN
        match e["type"]:
            "head":
                k = FSB_head_stiffness_IN
            "tail":
                k = FSB_tail_stiffness_IN
        FSB_edges_UP.append({"a": a, "b": b, "rest": rest, "k": k})


func _FSB_cache_tail_lengths() -> void:
    FSB_tail_rest_len_UP.resize(FSB_TAIL_INDICES_SH.size())
    var target_pos := FSB_tail_controller_RD.position
    for i in FSB_TAIL_INDICES_SH.size():
        var idx: int = FSB_TAIL_INDICES_SH[i]
        FSB_tail_rest_len_UP[i] = FSB_positions_UP[idx].distance_to(target_pos)


func _FSB_solve_springs(delta: float) -> void:
    var forces: Array[Vector2] = []
    forces.resize(FSB_positions_UP.size())
    forces.fill(Vector2.ZERO)
    for e in FSB_edges_UP:
        var a: int = e["a"]
        var b: int = e["b"]
        var delta_vec := FSB_positions_UP[b] - FSB_positions_UP[a]
        var length := delta_vec.length()
        if length == 0.0:
            continue
        var dir := delta_vec / length
        var f := dir * (length - e["rest"]) * e["k"]
        forces[a] += f
        forces[b] -= f
    for i in FSB_positions_UP.size():
        if i == 0:
            continue
        FSB_velocities_UP[i] += forces[i] * delta


func _FSB_apply_tension_and_repulsor(delta: float) -> void:
    var spine_head := FSB_positions_UP[0]
    var spine_tail := (FSB_positions_UP[4] + FSB_positions_UP[7]) * 0.5
    for i in FSB_positions_UP.size():
        if i == 0:
            continue
        var pos := FSB_positions_UP[i]
        var closest := Geometry2D.get_closest_point_to_segment(pos, spine_head, spine_tail)
        var to_spine := closest - pos
        FSB_velocities_UP[i] += to_spine * FSB_tension_strength_IN * delta
        var rest_dist := FSB_rest_spine_dist_UP[i]
        var current_dist := to_spine.length()
        if current_dist < rest_dist * 0.9 and current_dist > 0.0:
            var push := (
                -to_spine.normalized() * (rest_dist * 0.9 - current_dist) * FSB_repulsor_strength_IN
            )
            FSB_velocities_UP[i] += push * delta


func _FSB_apply_tail_springs(delta: float) -> void:
    var target := FSB_tail_controller_RD.position
    for i in FSB_TAIL_INDICES_SH.size():
        var idx: int = FSB_TAIL_INDICES_SH[i]
        var diff := target - FSB_positions_UP[idx]
        var length := diff.length()
        if length == 0.0:
            continue
        var rest := FSB_tail_rest_len_UP[i]
        var f := diff / length * (length - rest) * FSB_tail_stiffness_IN
        FSB_velocities_UP[idx] += f * delta


func _FSB_integrate(delta: float) -> void:
    for i in FSB_positions_UP.size():
        if i == 0:
            FSB_positions_UP[0] = Vector2.ZERO
            FSB_velocities_UP[0] = Vector2.ZERO
            continue
        FSB_velocities_UP[i] *= FSB_damping_IN
        FSB_positions_UP[i] += FSB_velocities_UP[i] * delta


func _FSB_update_polygon() -> void:
    var poly := PackedVector2Array(FSB_positions_UP)
    FSB_polygon_RD.polygon = poly
