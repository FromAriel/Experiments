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
    Vector2(4.00, 5.50),
    Vector2(4.75, 6.05),
    Vector2(6.00, 6.60),
    Vector2(7.50, 7.00),
    Vector2(9.00, 7.00),
    Vector2(10.50, 5.60),
    Vector2(12.00, 5.40),
    Vector2(13.50, 5.825),
    Vector2(14.00, 6.75),
    Vector2(14.50, 7.375),
    Vector2(16.75, 7.50),
    Vector2(15.75, 6.875),
    Vector2(16.05, 6.050),
    Vector2(15.30, 5.375),
    Vector2(14.50, 5.00),
    Vector2(15.30, 4.625),
    Vector2(16.05, 3.950),
    Vector2(15.75, 3.125),
    Vector2(16.75, 2.50),
    Vector2(14.50, 2.625),
    Vector2(14.00, 3.250),
    Vector2(13.50, 4.175),
    Vector2(12.00, 4.60),
    Vector2(10.50, 4.40),
    Vector2(9.00, 3.70),
    Vector2(7.50, 3.50),
    Vector2(6.00, 3.55),
    Vector2(4.75, 3.95),
    Vector2(3.85, 4.81),
    Vector2(3.70, 5.12),
    Vector2(4.00, 5.50)  # duplicated first vertex – will be ignored when triangulating
]
const FB_SCALE: float = 15.0
const FB_HEAD_IDX: int = 0
const FB_TAIL_IDXS: Array[int] = [5, 6]
const FB_DIAGONALS: Array = [[2, 9], [3, 8]]

@export var FB_spring_strength_IN: float = 8.0
@export var FB_head_strength_IN: float = 9.5
@export var FB_tail_strength_IN: float = 6.5
@export var FB_diag_strength_IN: float = 8.0
@export var FB_radial_strength_IN: float = 4.0
@export_range(0.5, 1.0, 0.01) var FB_damping_IN: float = 0.9
@export var FB_gravity_IN: float = 0.0
@export var FB_wobble_amp_IN: float = 0.4
@export var FB_breath_amp_IN: float = 0.2
@export var FB_gizmo_radius_IN: float = 20.0
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

# Pre-computed triangle indices.  Never empty unless initial triangulation failed.
var _tri_indices: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
    _init_nodes()
    position = get_viewport_rect().size * 0.5
    _mat = ShaderMaterial.new()
    _mat.shader = load("res://shaders/soft_body_fish.gdshader")
    material = _mat
    _precompute_triangles()
    set_process_input(true)


func _precompute_triangles() -> void:
    # Use the rest‐pose without the duplicate closing point; the vertex order
    # never changes afterwards, so these indices stay valid forever.
    var pts: PackedVector2Array = PackedVector2Array()
    for i in range(FB_COORDS.size() - 1):  # skip last duplicate
        pts.append(FB_COORDS[i] * FB_SCALE)
    _tri_indices = Geometry2D.triangulate_polygon(pts)
    if _tri_indices.is_empty():
        push_warning(
            "SoftBodyFish: initial triangulation failed – falling back to poly-line rendering."
        )
    # Note: we keep _tri_indices even if it is empty; the draw code below
    # checks the size to decide whether to use draw_polygon or draw_polyline.


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


func _draw() -> void:
    var points: PackedVector2Array = PackedVector2Array(FB_nodes_UP)
    var uvs: PackedVector2Array = PackedVector2Array()
    for p in FB_nodes_UP:
        uvs.append(p * 0.05 + Vector2(0.5, 0.5))
    if _tri_indices.is_empty():
        # Fallback if initial triangulation failed
        draw_polyline(points, Color.WHITE, 2.0, true)
    else:
        RenderingServer.canvas_item_add_triangle_array(
            get_canvas_item(), _tri_indices, points, PackedColorArray(), uvs
        )
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
