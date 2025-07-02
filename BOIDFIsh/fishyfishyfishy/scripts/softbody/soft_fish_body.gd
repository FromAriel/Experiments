# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/softbody/soft_fish_body.gd
# Key Classes      • SoftFishBody – 2-D soft-body fish prototype
# Key Functions    • _physics_process() – spring solver
# Critical Consts  • SB_ANCHOR_POINTS_SH – base shape
# Editor Exports   • head_stiffness, body_stiffness, tail_stiffness
# Dependencies     • tail_controller.gd
# Last Major Rev   • 24-04-2024 – initial creation
###############################################################

extends Node2D
class_name SoftFishBody

# ------------------------------------------------------------------ #
#  Exported tuning parameters                                        #
# ------------------------------------------------------------------ #
@export var SB_head_stiffness_IN: float = 300.0
@export var SB_body_stiffness_IN: float = 120.0
@export var SB_tail_stiffness_IN: float = 80.0
@export var SB_tension_strength_IN: float = 10.0
@export var SB_repulsor_strength_IN: float = 20.0
@export var SB_damping_IN: float = 0.9

# ------------------------------------------------------------------ #
#  Internal state                                                     #
# ------------------------------------------------------------------ #
var SB_anchor_points_SH: Array[Vector2] = []
var SB_particles_SH: Array[Vector2] = []
var SB_velocities_SH: Array[Vector2] = []
var SB_edges_SH: Array[Vector2i] = []
var SB_rest_lengths_SH: Array[float] = []

var SB_polygon_node_RD: Polygon2D
var SB_tail_controller_RD: Node2D

# ------------------------------------------------------------------ #
#  Helper constants                                                   #
# ------------------------------------------------------------------ #
const SB_INDICES_TAIL_SH: Array[int] = [4, 5, 6, 7]
const SB_SPINE_THRESH_SH: float = 1.0


# ------------------------------------------------------------------ #
#  Lifecycle                                                          #
# ------------------------------------------------------------------ #
func _ready() -> void:
    SB_polygon_node_RD = Polygon2D.new()
    add_child(SB_polygon_node_RD)
    SB_tail_controller_RD = get_node_or_null("TailController")
    _init_particles()
    _init_edges()
    _cache_rest_lengths()


func _physics_process(delta: float) -> void:
    _apply_springs()
    _apply_tension()
    _apply_repulsor()
    _integrate(delta)
    _update_polygon()


# ------------------------------------------------------------------ #
#  Initialization helpers                                             #
# ------------------------------------------------------------------ #
func _init_particles() -> void:
    SB_anchor_points_SH = [
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
    for p in SB_anchor_points_SH:
        SB_particles_SH.append(p)
        SB_velocities_SH.append(Vector2.ZERO)


func _init_edges() -> void:
    for i in range(SB_particles_SH.size() - 1):
        SB_edges_SH.append(Vector2i(i, i + 1))
    # close loop
    SB_edges_SH.append(Vector2i(SB_particles_SH.size() - 1, 0))
    # simple diagonals for extra stiffness
    SB_edges_SH.append(Vector2i(0, 2))
    SB_edges_SH.append(Vector2i(2, 4))
    SB_edges_SH.append(Vector2i(4, 7))
    SB_edges_SH.append(Vector2i(7, 9))
    SB_edges_SH.append(Vector2i(9, 11))


func _cache_rest_lengths() -> void:
    for edge in SB_edges_SH:
        var a: Vector2 = SB_particles_SH[edge.x]
        var b: Vector2 = SB_particles_SH[edge.y]
        SB_rest_lengths_SH.append(a.distance_to(b))


# ------------------------------------------------------------------ #
#  Physics helpers                                                    #
# ------------------------------------------------------------------ #
func _apply_springs() -> void:
    for i in range(SB_edges_SH.size()):
        var edge: Vector2i = SB_edges_SH[i]
        var a_idx: int = edge.x
        var b_idx: int = edge.y
        var pos_a: Vector2 = SB_particles_SH[a_idx]
        var pos_b: Vector2 = SB_particles_SH[b_idx]
        var delta: Vector2 = pos_b - pos_a
        var dist: float = delta.length()
        if dist == 0:
            continue
        var rest: float = SB_rest_lengths_SH[i]
        var dir: Vector2 = delta / dist
        var stiffness: float = _get_stiffness_for_edge(edge)
        var force: Vector2 = dir * (dist - rest) * stiffness
        SB_velocities_SH[a_idx] += force * -0.5
        SB_velocities_SH[b_idx] += force * 0.5


func _apply_tension() -> void:
    var spine_start: Vector2 = SB_particles_SH[0]
    var spine_end: Vector2 = (SB_particles_SH[4] + SB_particles_SH[7]) * 0.5
    for i in range(SB_particles_SH.size()):
        if i == 0:
            continue
        var pos: Vector2 = SB_particles_SH[i]
        var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(pos, spine_start, spine_end)
        var to_spine: Vector2 = nearest - pos
        SB_velocities_SH[i] += to_spine * SB_tension_strength_IN * 0.01


func _apply_repulsor() -> void:
    var spine_start: Vector2 = SB_particles_SH[0]
    var spine_end: Vector2 = (SB_particles_SH[4] + SB_particles_SH[7]) * 0.5
    for i in range(SB_particles_SH.size()):
        var pos: Vector2 = SB_particles_SH[i]
        var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(pos, spine_start, spine_end)
        var dist: float = pos.distance_to(nearest)
        if dist < SB_SPINE_THRESH_SH:
            var to_spine: Vector2 = (
                Geometry2D.get_closest_point_to_segment(pos, spine_start, spine_end) - pos
            )
            if to_spine.length() > 0:
                SB_velocities_SH[i] -= (
                    to_spine.normalized() * SB_repulsor_strength_IN * (SB_SPINE_THRESH_SH - dist)
                )


func _integrate(delta: float) -> void:
    for i in range(SB_particles_SH.size()):
        if i == 0:
            SB_particles_SH[i] = Vector2.ZERO
            continue
        SB_velocities_SH[i] *= pow(SB_damping_IN, delta * 60.0)
        SB_particles_SH[i] += SB_velocities_SH[i] * delta
    # tail target springs
    if SB_tail_controller_RD:
        for i in SB_INDICES_TAIL_SH:
            var to_target: Vector2 = SB_tail_controller_RD.position - SB_particles_SH[i]
            SB_velocities_SH[i] += to_target * SB_tail_stiffness_IN * 0.001


func _update_polygon() -> void:
    var poly: PackedVector2Array = PackedVector2Array()
    for p in SB_particles_SH:
        poly.append(p)
    SB_polygon_node_RD.polygon = poly


func _get_stiffness_for_edge(edge: Vector2i) -> float:
    if edge.x <= 1 or edge.y <= 1:
        return SB_head_stiffness_IN * 0.001
    if edge.x >= 4 and edge.y >= 4:
        return SB_tail_stiffness_IN * 0.001
    return SB_body_stiffness_IN * 0.001
