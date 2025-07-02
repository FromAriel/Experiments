# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/softbody/fish_soft_body.gd
# Key Classes      • FishSoftBody – soft-body / rigid-body hybrid fish
# Key Functions    • _physics_process() – integrate spring-mass system
# Critical Consts  • SB_ANCHOR_POINTS_SH – base geometry
# Editor Exports   • SB_head_stiffness_IN: float – Range(0..1000)
# Dependencies     • tail_controller.gd
# Last Major Rev   • 24-XX-XX – initial creation
###############################################################

extends Node2D
class_name FishSoftBody

# ------------------------------------------------------------------ #
#  Exported physics parameters                                        #
# ------------------------------------------------------------------ #
@export var SB_head_stiffness_IN: float = 600.0
@export var SB_body_stiffness_IN: float = 300.0
@export var SB_tail_stiffness_IN: float = 150.0
@export var SB_tension_strength_IN: float = 20.0
@export var SB_repulsor_strength_IN: float = 40.0
@export var SB_damping_IN: float = 2.0

# ------------------------------------------------------------------ #
#  Internal constants                                                 #
# ------------------------------------------------------------------ #
# Anchor geometry points in local space (closed loop).
const SB_ANCHOR_POINTS_SH: Array[Vector2] = [
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

# ------------------------------------------------------------------ #
#  Runtime data                                                       #
# ------------------------------------------------------------------ #
var SB_positions_UP: Array[Vector2] = []
var SB_velocities_UP: Array[Vector2] = []
var SB_edges_UP: Array[Vector2i] = []
var SB_rest_lengths_UP: Array[float] = []
var SB_rest_thickness_UP: Array[float] = []

var SB_polygon_RD: Polygon2D
var SB_tail_target_RD: Node2D


# ------------------------------------------------------------------ #
#  Construction                                                       #
# ------------------------------------------------------------------ #
func _ready() -> void:
    SB_polygon_RD = $Polygon2D
    SB_tail_target_RD = $TailController
    _init_particles()
    _init_edges()
    _cache_rest_thickness()
    set_physics_process(true)


# ------------------------------------------------------------------ #
#  Initialization helpers                                             #
# ------------------------------------------------------------------ #
func _init_particles() -> void:
    SB_positions_UP.clear()
    SB_velocities_UP.clear()
    for p in SB_ANCHOR_POINTS_SH:
        SB_positions_UP.append(p)
        SB_velocities_UP.append(Vector2.ZERO)


func _init_edges() -> void:
    SB_edges_UP.clear()
    SB_rest_lengths_UP.clear()
    var count: int = SB_ANCHOR_POINTS_SH.size()
    for i in count:
        var j: int = (i + 1) % count
        _add_edge(i, j)
    # Tail loop
    _add_edge(4, 7)
    _add_edge(4, 5)
    _add_edge(7, 6)
    _add_edge(5, 6)
    # Optional diagonals for stability
    _add_edge(0, 2)
    _add_edge(2, 4)
    _add_edge(7, 9)
    _add_edge(9, 11)
    _add_edge(11, 1)


func _add_edge(a: int, b: int) -> void:
    var edge := Vector2i(a, b)
    SB_edges_UP.append(edge)
    var rest_len := SB_positions_UP[a].distance_to(SB_positions_UP[b])
    SB_rest_lengths_UP.append(rest_len)


func _cache_rest_thickness() -> void:
    SB_rest_thickness_UP.resize(SB_positions_UP.size())
    var spine_start: Vector2 = SB_positions_UP[0]
    var spine_end: Vector2 = (SB_positions_UP[4] + SB_positions_UP[7]) * 0.5
    var spine_vec: Vector2 = spine_end - spine_start
    var spine_len: float = spine_vec.length()
    var spine_dir: Vector2 = spine_vec / spine_len
    for i in SB_positions_UP.size():
        var p: Vector2 = SB_positions_UP[i]
        var t: float = clamp((p - spine_start).dot(spine_dir) / spine_len, 0.0, 1.0)
        var proj: Vector2 = spine_start + spine_dir * t * spine_len
        SB_rest_thickness_UP[i] = p.distance_to(proj)


# ------------------------------------------------------------------ #
#  Physics update                                                     #
# ------------------------------------------------------------------ #
func _physics_process(delta: float) -> void:
    SB_positions_UP[0] = Vector2.ZERO
    SB_velocities_UP[0] = Vector2.ZERO

    var tail_target: Vector2 = SB_tail_target_RD.position
    # Apply spring forces
    for idx in SB_edges_UP.size():
        var edge := SB_edges_UP[idx]
        var i: int = edge.x
        var j: int = edge.y
        var pos_i: Vector2 = SB_positions_UP[i]
        var pos_j: Vector2 = SB_positions_UP[j]
        var delta_vec: Vector2 = pos_i - pos_j
        var dist: float = delta_vec.length()
        var rest: float = SB_rest_lengths_UP[idx]
        var dir: Vector2 = delta_vec.normalized()
        var k: float = _edge_stiffness(i, j)
        var force_mag: float = -k * (dist - rest)
        var force: Vector2 = dir * force_mag
        if i != 0:
            SB_velocities_UP[i] += force * delta
        if j != 0:
            SB_velocities_UP[j] -= force * delta

    # Tail control springs
    _apply_tail_force(4, tail_target, SB_tail_stiffness_IN, delta)
    _apply_tail_force(5, tail_target, SB_tail_stiffness_IN, delta)
    _apply_tail_force(6, tail_target, SB_tail_stiffness_IN, delta)
    _apply_tail_force(7, tail_target, SB_tail_stiffness_IN, delta)

    # Inward tension & repulsor
    var spine_start: Vector2 = SB_positions_UP[0]
    var spine_end: Vector2 = (SB_positions_UP[4] + SB_positions_UP[7]) * 0.5
    var spine_vec: Vector2 = spine_end - spine_start
    var spine_len: float = spine_vec.length()
    var spine_dir: Vector2 = spine_vec / spine_len
    for i in SB_positions_UP.size():
        if i == 0:
            continue
        var pos: Vector2 = SB_positions_UP[i]
        var t: float = clamp((pos - spine_start).dot(spine_dir) / spine_len, 0.0, 1.0)
        var proj: Vector2 = spine_start + spine_dir * t * spine_len
        var offset: Vector2 = proj - pos
        SB_velocities_UP[i] += offset * SB_tension_strength_IN * delta
        var rest_thick: float = SB_rest_thickness_UP[i]
        var cur_len: float = offset.length()
        if cur_len < rest_thick * 0.9:
            var outward: Vector2 = -offset.normalized()
            SB_velocities_UP[i] += (
                outward * SB_repulsor_strength_IN * (rest_thick - cur_len) * delta
            )

    # Damping and integrate
    for i in SB_positions_UP.size():
        SB_velocities_UP[i] *= exp(-SB_damping_IN * delta)
        SB_positions_UP[i] += SB_velocities_UP[i] * delta

    _update_polygon()


func _edge_stiffness(i: int, j: int) -> float:
    if i <= 2 or j <= 2:
        return SB_head_stiffness_IN
    if i >= 4 and j >= 4:
        return SB_tail_stiffness_IN
    return SB_body_stiffness_IN


func _apply_tail_force(idx: int, target: Vector2, k: float, delta: float) -> void:
    var pos: Vector2 = SB_positions_UP[idx]
    var delta_vec: Vector2 = pos - target
    var dist: float = delta_vec.length()
    var dir: Vector2 = delta_vec.normalized()
    var rest: float = SB_rest_thickness_UP[0]  # Use head thickness as rest
    var force: Vector2 = dir * (-k * (dist - rest))
    SB_velocities_UP[idx] += force * delta


func _update_polygon() -> void:
    var poly: PackedVector2Array = PackedVector2Array()
    for p in SB_positions_UP:
        poly.push_back(p)
    poly.push_back(SB_positions_UP[0])
    SB_polygon_RD.polygon = poly
