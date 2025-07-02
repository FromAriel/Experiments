# gdlint:disable = class-variable-name,function-name,class-definitions-order
# ===============================================================
#  File:  res://scripts/SoftBodyFish.gd
#  Desc:  Simple soft-body fish using spring physics.
# ===============================================================

extends Node2D
class_name SoftBodyFish

# ------------------------------------------------------------------ #
#  Inspector                                                         #
# ------------------------------------------------------------------ #
@export_range(0.1, 20.0, 0.1, "suffix:×") var FB_spring_strength_SH: float = 5.0
@export_range(0.0, 1.0, 0.01) var FB_damping_SH: float = 0.1
@export_range(0.0, 10.0, 0.1) var FB_radial_strength_SH: float = 1.0
@export_range(0.0, 50.0, 0.1) var FB_gravity_SH: float = 0.0
@export_range(0.0, 2.0, 0.01) var FB_wobble_amp_SH: float = 0.2
@export_range(0.1, 10.0, 0.1) var FB_wobble_freq_SH: float = 1.0

# ------------------------------------------------------------------ #
#  Runtime state                                                     #
# ------------------------------------------------------------------ #
var FB_nodes_UP: Array[Vector2] = []
var FB_velocities_UP: Array[Vector2] = []
var FB_polygon: Polygon2D

# Future head / tail control points
var FB_head_ctrl_UP: Vector2 = Vector2.ZERO
var FB_tail_ctrl_UP: Vector2 = Vector2.ZERO

# Target coordinates from SOFTBODYFISHPLAN.md
const FB_TARGETS_RD: Array[Vector2] = [
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
    Vector2(4.0, 4.5),
]


# ------------------------------------------------------------------ #
#  Lifecycle                                                         #
# ------------------------------------------------------------------ #
func _ready() -> void:
    FB_polygon = Polygon2D.new()
    var mat := ShaderMaterial.new()
    mat.shader = load("res://shaders/SoftBodyFish.gdshader")
    FB_polygon.material = mat
    add_child(FB_polygon)

    _FB_init_nodes()
    _FB_update_polygon()


func _physics_process(delta: float) -> void:
    _FB_apply_physics(delta)
    _FB_update_polygon()


# ------------------------------------------------------------------ #
#  Internal Helpers                                                  #
# ------------------------------------------------------------------ #
func _FB_init_nodes() -> void:
    for coord in FB_TARGETS_RD:
        FB_nodes_UP.append(coord)
        FB_velocities_UP.append(Vector2.ZERO)


func _FB_apply_physics(delta: float) -> void:
    var count: int = FB_nodes_UP.size()
    for i in range(count):
        var target: Vector2 = FB_TARGETS_RD[i]
        var pos: Vector2 = FB_nodes_UP[i]
        var vel: Vector2 = FB_velocities_UP[i]

        var prev: Vector2 = FB_nodes_UP[(i - 1 + count) % count]
        var next: Vector2 = FB_nodes_UP[(i + 1) % count]

        var force: Vector2 = (target - pos) * FB_spring_strength_SH
        force += (prev - pos) * 0.5 * FB_spring_strength_SH
        force += (next - pos) * 0.5 * FB_spring_strength_SH

        var radial: Vector2 = (target - pos).normalized() * FB_radial_strength_SH
        force += radial
        force += Vector2(0, FB_gravity_SH)

        vel += force * delta
        vel *= 1.0 - FB_damping_SH

        FB_nodes_UP[i] = pos + vel * delta
        FB_velocities_UP[i] = vel

        var phase: float = Time.get_ticks_msec() / 1000.0 * FB_wobble_freq_SH
        var wobble: float = FB_wobble_amp_SH * sin(phase + float(i))
        FB_nodes_UP[i].y += wobble


func _FB_update_polygon() -> void:
    FB_polygon.polygon = FB_nodes_UP

    var uvs: Array[Vector2] = []
    var min_y: float = FB_nodes_UP[0].y
    var max_y: float = FB_nodes_UP[0].y
    for p in FB_nodes_UP:
        min_y = min(min_y, p.y)
        max_y = max(max_y, p.y)
    var height: float = max(max_y - min_y, 0.001)
    for p in FB_nodes_UP:
        uvs.append(Vector2(0.0, (p.y - min_y) / height))
    FB_polygon.uv = uvs
