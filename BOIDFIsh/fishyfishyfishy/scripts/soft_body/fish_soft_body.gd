# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/soft_body/fish_soft_body.gd
# Key Classes      • FishSoftBody – spring-mass fish body
# Key Functions    • _physics_process() – integrates forces
# Critical Consts  • SB_ANCHORS_SH – base geometry points
# Editor Exports   • SB_head_stiffness_IN: float
# Dependencies     • tail_controller.gd
# Last Major Rev   • 24-05-21 – initial soft-body prototype
###############################################################

class_name FishSoftBody
extends Node2D

# ------------------------------------------------------------------ #
#  Inspector                                                         #
# ------------------------------------------------------------------ #
@export var SB_head_stiffness_IN: float = 10.0
@export var SB_body_stiffness_IN: float = 5.0
@export var SB_tail_stiffness_IN: float = 2.0
@export var SB_tension_strength_IN: float = 4.0
@export var SB_repulsor_strength_IN: float = 5.0
@export var SB_damping_IN: float = 0.2

# ------------------------------------------------------------------ #
#  Geometry & edges                                                  #
# ------------------------------------------------------------------ #
# Base anchor coordinates (local space)
const SB_ANCHORS_SH: Array[Vector2] = [
    Vector2(4, 5.5),  # 0 Head
    Vector2(6, 6.6),  # 1
    Vector2(9, 7.0),  # 2
    Vector2(12, 5.4),  # 3
    Vector2(14, 6.75),  # 4
    Vector2(15, 7.0),  # 5 Tail upper
    Vector2(15, 3.0),  # 6 Tail lower
    Vector2(14, 3.25),  # 7
    Vector2(12, 4.6),  # 8
    Vector2(9, 3.0),  # 9
    Vector2(6, 3.4),  #10
    Vector2(4, 4.5)  #11
]

const SB_EDGES_SH: Array[Vector2i] = [
    Vector2i(0, 1),
    Vector2i(1, 2),
    Vector2i(2, 3),
    Vector2i(3, 4),
    Vector2i(4, 5),
    Vector2i(5, 6),
    Vector2i(6, 7),
    Vector2i(7, 8),
    Vector2i(8, 9),
    Vector2i(9, 10),
    Vector2i(10, 11),
    Vector2i(11, 0),
    # diagonals for stiffness
    Vector2i(0, 2),
    Vector2i(2, 4),
    Vector2i(4, 6),
    Vector2i(6, 8),
    Vector2i(8, 10),
    Vector2i(10, 0)
]

# Each edge stores {i, j, rest, k}
var _SB_edges_data_SH: Array[Dictionary] = []

var _SB_points_UP: Array[Vector2] = []
var _SB_velocities_UP: Array[Vector2] = []
var _SB_spine_rest_dists_SH: Array[float] = []

@onready var _SB_polygon_RD: Polygon2D = $Polygon2D
@onready var _SB_tail_target_RD: Node2D = $TailController


# ------------------------------------------------------------------ #
#  Initialization                                                    #
# ------------------------------------------------------------------ #
func _ready() -> void:
    _SB_points_UP = []
    for p in SB_ANCHORS_SH:
        _SB_points_UP.append(p)
    _SB_velocities_UP.resize(_SB_points_UP.size())
    for i in _SB_velocities_UP.size():
        _SB_velocities_UP[i] = Vector2.ZERO

    _setup_edges()
    _cache_spine_dists()
    _update_polygon()


func _setup_edges() -> void:
    _SB_edges_data_SH.clear()
    for pair in SB_EDGES_SH:
        var e := {}
        e.i = pair[0]
        e.j = pair[1]
        e.rest = _SB_points_UP[e.i].distance_to(_SB_points_UP[e.j])
        e.k = _classify_stiffness(e.i, e.j)
        _SB_edges_data_SH.append(e)


func _classify_stiffness(a: int, b: int) -> float:
    var tail_indices := [4, 5, 6, 7]
    if a == 0 or b == 0 or a == 1 or b == 1:
        return SB_head_stiffness_IN
    if a in tail_indices or b in tail_indices:
        return SB_tail_stiffness_IN
    return SB_body_stiffness_IN


func _cache_spine_dists() -> void:
    var spine_line := _get_spine_segment()
    _SB_spine_rest_dists_SH.clear()
    for point in _SB_points_UP:
        var proj := _closest_point_on_segment(point, spine_line)
        _SB_spine_rest_dists_SH.append(point.distance_to(proj))


# ------------------------------------------------------------------ #
#  Physics step                                                      #
# ------------------------------------------------------------------ #
func _physics_process(delta: float) -> void:
    _apply_head_constraint()
    _apply_tail_guidance()
    _integrate_edges()
    _apply_internal_forces()
    _integrate_motion(delta)
    _update_polygon()


func _apply_head_constraint() -> void:
    _SB_points_UP[0] = Vector2.ZERO
    _SB_velocities_UP[0] = Vector2.ZERO


func _apply_tail_guidance() -> void:
    var target: Vector2 = _SB_tail_target_RD.position
    for idx in [4, 5, 6, 7]:
        var dir := target - _SB_points_UP[idx]
        var force := dir * SB_tail_stiffness_IN
        _SB_velocities_UP[idx] += force * get_process_delta_time()


func _integrate_edges() -> void:
    for e in _SB_edges_data_SH:
        var i: int = e.i
        var j: int = e.j
        var p1: Vector2 = _SB_points_UP[i]
        var p2: Vector2 = _SB_points_UP[j]
        var diff: Vector2 = p2 - p1
        var dist: float = diff.length()
        if dist == 0.0:
            continue
        var k: float = e.k
        var force: Vector2 = diff.normalized() * (dist - e.rest) * k
        _SB_velocities_UP[i] += force * get_process_delta_time()
        _SB_velocities_UP[j] -= force * get_process_delta_time()


func _apply_internal_forces() -> void:
    var spine_line := _get_spine_segment()
    for i in _SB_points_UP.size():
        if i == 0:
            continue
        var p: Vector2 = _SB_points_UP[i]
        var proj := _closest_point_on_segment(p, spine_line)
        var to_spine: Vector2 = proj - p
        _SB_velocities_UP[i] += to_spine * SB_tension_strength_IN * get_process_delta_time()
        var dist: float = to_spine.length()
        var rest: float = _SB_spine_rest_dists_SH[i]
        if dist < rest * 0.5:
            _SB_velocities_UP[i] -= (
                to_spine.normalized() * SB_repulsor_strength_IN * get_process_delta_time()
            )


func _integrate_motion(delta: float) -> void:
    for i in _SB_points_UP.size():
        if i == 0:
            continue
        _SB_velocities_UP[i] -= _SB_velocities_UP[i] * SB_damping_IN * delta
        _SB_points_UP[i] += _SB_velocities_UP[i] * delta


func _update_polygon() -> void:
    _SB_polygon_RD.polygon = _SB_points_UP


func _get_spine_segment() -> Dictionary:
    var head: Vector2 = _SB_points_UP[0]
    var tail_root: Vector2 = (_SB_points_UP[4] + _SB_points_UP[7]) * 0.5
    return {"a": head, "b": tail_root}


func _closest_point_on_segment(p: Vector2, seg: Dictionary) -> Vector2:
    var a: Vector2 = seg.a
    var b: Vector2 = seg.b
    var ab: Vector2 = b - a
    var t: float = 0.0
    var denom: float = ab.length_squared()
    if denom > 0.0:
        t = clamp((p - a).dot(ab) / denom, 0.0, 1.0)
    return a + ab * t
