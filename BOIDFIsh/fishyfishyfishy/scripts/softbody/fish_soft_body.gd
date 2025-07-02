# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# scripts/softbody/fish_soft_body.gd
# Key Classes      • FishSoftBody – soft-body fish simulation
# Key Functions    • _physics_process() – main solver loop
# Critical Consts  • FSB_BASE_POINTS – template geometry
# Editor Exports   • head_stiffness: float
#                  • body_stiffness: float
#                  • tail_stiffness: float
#                  • tension_strength: float
# Dependencies     • tail_controller.gd
# Last Major Rev   • 24-??-?? – initial creation
###############################################################
class_name FishSoftBody
extends Node2D

# ------------------------------------------------------------------
#  Exported tunables
# ------------------------------------------------------------------
@export var FSB_head_stiffness_IN: float = 200.0
@export var FSB_body_stiffness_IN: float = 80.0
@export var FSB_tail_stiffness_IN: float = 40.0
@export var FSB_tension_strength_IN: float = 10.0
@export var FSB_repulsor_strength_IN: float = 20.0
@export var FSB_damping_IN: float = 0.9

# ------------------------------------------------------------------
#  Constants
# ------------------------------------------------------------------
const FSB_BASE_POINTS := [
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

const FSB_EDGES := [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
    [9, 10],
    [10, 11],
    [11, 0],
    [1, 11],
    [2, 10],
    [3, 9],
    [4, 8],
    [5, 7]
]

# ------------------------------------------------------------------
#  Runtime state
# ------------------------------------------------------------------
var FSB_particles_UP: Array = []
var FSB_edges_UP: Array = []
var FSB_thickness_UP: Array = []
var FSB_tail_node_UP: Node2D
@onready var FSB_polygon_UP: Polygon2D = get_node("Polygon2D")


func _ready() -> void:
    _fsb_init_particles()
    _fsb_init_edges()
    FSB_tail_node_UP = get_node("TailTarget") as Node2D
    _fsb_record_thickness()


func _physics_process(delta: float) -> void:
    _fsb_drive_head()
    _fsb_apply_springs(delta)
    _fsb_apply_tail_springs(delta)
    _fsb_apply_tension_and_pressure(delta)
    _fsb_integrate(delta)
    _fsb_update_polygon()


# ------------------------------------------------------------------
#  Initialization helpers
# ------------------------------------------------------------------
func _fsb_init_particles() -> void:
    FSB_particles_UP.clear()
    for p in FSB_BASE_POINTS:
        FSB_particles_UP.append({"pos": p, "vel": Vector2.ZERO})


func _fsb_init_edges() -> void:
    FSB_edges_UP.clear()
    for pair in FSB_EDGES:
        var rest := FSB_BASE_POINTS[pair[0]].distance_to(FSB_BASE_POINTS[pair[1]])
        var k := FSB_body_stiffness_IN
        if 0 in pair or 1 in pair or 11 in pair:
            k = FSB_head_stiffness_IN
        elif pair[0] >= 4 and pair[0] <= 7 and pair[1] >= 4 and pair[1] <= 7:
            k = FSB_tail_stiffness_IN
        FSB_edges_UP.append({"a": pair[0], "b": pair[1], "rest": rest, "k": k})


func _fsb_record_thickness() -> void:
    FSB_thickness_UP.clear()
    var spine_start := FSB_BASE_POINTS[0]
    var spine_end := (FSB_BASE_POINTS[4] + FSB_BASE_POINTS[7]) * 0.5
    for p in FSB_BASE_POINTS:
        var closest := Geometry2D.get_closest_point_to_segment(p, spine_start, spine_end)
        FSB_thickness_UP.append(p.distance_to(closest))


# ------------------------------------------------------------------
#  Solver steps
# ------------------------------------------------------------------
func _fsb_drive_head() -> void:
    var head := FSB_particles_UP[0]
    head.pos = global_position
    head.vel = Vector2.ZERO
    FSB_particles_UP[0] = head


func _fsb_apply_springs(delta: float) -> void:
    for edge in FSB_edges_UP:
        var a := edge.a
        var b := edge.b
        var pa := FSB_particles_UP[a]
        var pb := FSB_particles_UP[b]
        var delta_pos := pb.pos - pa.pos
        var dist := delta_pos.length()
        if dist == 0:
            continue
        var force := delta_pos.normalized() * (dist - edge.rest) * edge.k
        pa.vel += force * delta
        pb.vel -= force * delta
        FSB_particles_UP[a] = pa
        FSB_particles_UP[b] = pb


func _fsb_apply_tail_springs(delta: float) -> void:
    var target_pos := FSB_tail_node_UP.global_position
    for i in range(4, 8):
        var p := FSB_particles_UP[i]
        var dir := target_pos - p.pos
        p.vel += dir * FSB_tail_stiffness_IN * delta
        FSB_particles_UP[i] = p


func _fsb_apply_tension_and_pressure(delta: float) -> void:
    var spine_start := FSB_particles_UP[0].pos
    var spine_end := (FSB_particles_UP[4].pos + FSB_particles_UP[7].pos) * 0.5
    for i in range(1, FSB_particles_UP.size()):
        var p := FSB_particles_UP[i]
        var closest := Geometry2D.get_closest_point_to_segment(p.pos, spine_start, spine_end)
        var to_spine := closest - p.pos
        p.vel += to_spine * FSB_tension_strength_IN * delta
        var dist := abs(to_spine.length())
        var min_thick := FSB_thickness_UP[i] * 0.7
        if dist < min_thick:
            var push_dir := -to_spine.normalized()
            p.vel += push_dir * (min_thick - dist) * FSB_repulsor_strength_IN * delta
        FSB_particles_UP[i] = p


func _fsb_integrate(delta: float) -> void:
    for i in range(1, FSB_particles_UP.size()):
        var p := FSB_particles_UP[i]
        p.vel *= pow(FSB_damping_IN, delta)
        p.pos += p.vel * delta
        FSB_particles_UP[i] = p


func _fsb_update_polygon() -> void:
    var poly := PackedVector2Array()
    for p in FSB_particles_UP:
        poly.append(p.pos)
    FSB_polygon_UP.polygon = poly
