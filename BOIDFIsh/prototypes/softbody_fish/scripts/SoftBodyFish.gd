# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/SoftBodyFish.gd
# Key Classes      • SoftBodyFish – simple soft-body fish demo
# Key Functions    • _physics_step() – per-node spring physics
# Critical Consts  • FB_COORDS – initial node positions
# Editor Exports   • FB_spring_strength_IN: float
# Dependencies     • shaders/soft_body_fish.gdshader
# Last Major Rev   • 24-04-30 – initial prototype
###############################################################
# gdlint:disable = class-variable-name,function-name
class_name SoftBodyFish
extends Node2D

const FB_COORDS: Array[Vector2] = [
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
    Vector2(4, 5.5)
]
const FB_SCALE: float = 15.0
const FB_HEAD_IDX: int = 0
const FB_TAIL_IDXS: Array[int] = [5, 6]
const FB_DIAGONALS: Array = [[2, 9], [3, 8]]

@export var FB_spring_strength_IN: float = 10.0
@export var FB_head_strength_IN: float = 12.0
@export var FB_tail_strength_IN: float = 8.0
@export var FB_diag_strength_IN: float = 10.0
@export var FB_radial_strength_IN: float = 5.0
@export_range(0.5, 1.0, 0.01) var FB_damping_IN: float = 0.9
@export var FB_gravity_IN: float = 0.0
@export var FB_wobble_amp_IN: float = 0.4
@export var FB_breath_amp_IN: float = 0.2
@export var FB_gizmo_radius_IN: float = 20.0
@export_range(0.1, 0.8, 0.05) var FB_handle_frac_IN: float = 0.4
@export_range(8, 64, 1) var FB_tessellation_steps_IN: int = 32
@onready var FB_head_node_RD: Node2D = $HeadControl
@onready var FB_tail_node_RD: Node2D = $TailControl

var FB_nodes_UP: Array[Vector2] = []
var FB_node_vels_UP: Array[Vector2] = []
var FB_rest_nodes_SH: Array[Vector2] = []
var FB_head_ctrl_UP: Vector2 = Vector2.ZERO
var FB_tail_ctrl_UP: Vector2 = Vector2.ZERO
var FB_head_drag_UP: bool = false
var FB_tail_drag_UP: bool = false
var _mat: ShaderMaterial
var FB_curve_UP: Curve2D = Curve2D.new()
var FB_poly_cache_UP: PackedVector2Array = PackedVector2Array()
var FB_uv_cache_UP: PackedVector2Array = PackedVector2Array()
var FB_last_valid_SH: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
    _init_nodes()
    position = get_viewport_rect().size * 0.5
    _mat = ShaderMaterial.new()
    _mat.shader = load("res://shaders/soft_body_fish.gdshader")
    material = _mat
    set_process_input(true)


func _init_nodes() -> void:
    FB_nodes_UP.clear()
    FB_node_vels_UP.clear()
    FB_rest_nodes_SH.clear()
    var scaled: Array[Vector2] = []
    for pt in FB_COORDS:
        scaled.append(pt * FB_SCALE)
    var centroid: Vector2 = Vector2.ZERO
    for i in range(scaled.size() - 1):
        centroid += scaled[i]
    centroid /= scaled.size() - 1
    for p in scaled:
        var adj: Vector2 = p - centroid
        FB_nodes_UP.append(adj)
        FB_node_vels_UP.append(Vector2.ZERO)
        FB_rest_nodes_SH.append(adj)
    FB_head_node_RD.position = FB_rest_nodes_SH[FB_HEAD_IDX]
    FB_tail_node_RD.position = (
        (FB_rest_nodes_SH[FB_TAIL_IDXS[0]] + FB_rest_nodes_SH[FB_TAIL_IDXS[1]]) * 0.5
    )


func _process(delta: float) -> void:
    _physics_step(delta)
    FB_head_node_RD.position = FB_nodes_UP[FB_HEAD_IDX]
    FB_tail_node_RD.position = (FB_nodes_UP[FB_TAIL_IDXS[0]] + FB_nodes_UP[FB_TAIL_IDXS[1]]) * 0.5
    queue_redraw()


func _physics_step(delta: float) -> void:
    var count: int = FB_nodes_UP.size()
    var time_now: float = Time.get_ticks_msec() / 1000.0
    for i in count:
        var prev: Vector2 = FB_nodes_UP[(i - 1 + count) % count]
        var next: Vector2 = FB_nodes_UP[(i + 1) % count]
        var pos: Vector2 = FB_nodes_UP[i]
        var vel: Vector2 = FB_node_vels_UP[i]
        var base: Vector2 = FB_rest_nodes_SH[i]
        var wob: float = sin(time_now * 0.8 + float(i)) * FB_wobble_amp_IN
        var breath: float = sin(time_now + float(i) * 0.1) * FB_breath_amp_IN
        var target: Vector2 = base + Vector2(0, wob + breath)
        var strength: float = FB_spring_strength_IN
        if i == FB_HEAD_IDX:
            strength = FB_head_strength_IN
        elif FB_TAIL_IDXS.has(i):
            strength = FB_tail_strength_IN
        var spring: Vector2 = ((prev + next) * 0.5 - pos) * strength * delta
        var radial: Vector2 = (target - pos) * FB_radial_strength_IN * delta
        var grav: Vector2 = Vector2.DOWN * FB_gravity_IN * delta
        vel += spring + radial + grav
        vel *= FB_damping_IN
        pos += vel * delta
        FB_nodes_UP[i] = pos
        FB_node_vels_UP[i] = vel

    for pair in FB_DIAGONALS:
        var a: int = pair[0]
        var b: int = pair[1]
        var diff: Vector2 = FB_nodes_UP[b] - FB_nodes_UP[a]
        var rest_diff: Vector2 = FB_rest_nodes_SH[b] - FB_rest_nodes_SH[a]
        var force: Vector2 = (diff - rest_diff) * FB_diag_strength_IN * delta
        FB_node_vels_UP[a] += force
        FB_node_vels_UP[b] -= force


func _FB_update_polygon_IN() -> void:
    FB_curve_UP.clear_points()
    var count: int = FB_nodes_UP.size()
    for i in count:
        var prev: Vector2 = FB_nodes_UP[(i - 1 + count) % count]
        var next: Vector2 = FB_nodes_UP[(i + 1) % count]
        var pos: Vector2 = FB_nodes_UP[i]
        var in_handle: Vector2 = (prev - pos) * FB_handle_frac_IN
        var out_handle: Vector2 = (next - pos) * FB_handle_frac_IN
        FB_curve_UP.add_point(pos, in_handle, out_handle)
    FB_curve_UP.closed = true

    var pts: PackedVector2Array = FB_curve_UP.tessellate(FB_tessellation_steps_IN)
    var check := Geometry2D.triangulate_polygon(pts)
    if check.size() > 0:
        FB_poly_cache_UP = pts
        FB_uv_cache_UP.resize(pts.size())
        for i in pts.size():
            FB_uv_cache_UP[i] = pts[i] * 0.05 + Vector2(0.5, 0.5)
        FB_last_valid_SH = FB_poly_cache_UP
    elif FB_last_valid_SH.size() > 0:
        FB_poly_cache_UP = FB_last_valid_SH
        FB_uv_cache_UP.resize(FB_poly_cache_UP.size())
        for i in FB_poly_cache_UP.size():
            FB_uv_cache_UP[i] = FB_poly_cache_UP[i] * 0.05 + Vector2(0.5, 0.5)


func _draw() -> void:
    _FB_update_polygon_IN()
    if FB_poly_cache_UP.size() > 2:
        draw_polygon(FB_poly_cache_UP, [], FB_uv_cache_UP)
    draw_circle(FB_head_node_RD.position, FB_gizmo_radius_IN, Color.RED)
    draw_circle(FB_tail_node_RD.position, FB_gizmo_radius_IN, Color.GREEN)


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var local_pos: Vector2 = to_local(event.position)
        if event.pressed:
            if FB_head_node_RD.position.distance_to(local_pos) <= FB_gizmo_radius_IN:
                FB_head_drag_UP = true
            elif FB_tail_node_RD.position.distance_to(local_pos) <= FB_gizmo_radius_IN:
                FB_tail_drag_UP = true
        else:
            FB_head_drag_UP = false
            FB_tail_drag_UP = false
    elif event is InputEventMouseMotion:
        var local_pos: Vector2 = to_local(event.position)
        if FB_head_drag_UP:
            FB_head_node_RD.position = local_pos
            FB_nodes_UP[FB_HEAD_IDX] = local_pos
            FB_node_vels_UP[FB_HEAD_IDX] = Vector2.ZERO
        elif FB_tail_drag_UP:
            for idx in FB_TAIL_IDXS:
                FB_nodes_UP[idx] = local_pos
                FB_node_vels_UP[idx] = Vector2.ZERO
            FB_tail_node_RD.position = local_pos

    var hover_pos: Vector2 = to_local(get_viewport().get_mouse_position())
    if (
        FB_head_node_RD.position.distance_to(hover_pos) <= FB_gizmo_radius_IN
        or FB_tail_node_RD.position.distance_to(hover_pos) <= FB_gizmo_radius_IN
    ):
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    else:
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)
