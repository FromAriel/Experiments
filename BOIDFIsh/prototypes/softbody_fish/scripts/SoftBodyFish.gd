# gdlint:disable = class-variable-name,function-name
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

const FB_SCALE: float = 15.0

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

const FB_DRAG_RADIUS: float = 20.0

@export var FB_spring_strength_IN: float = 10.0
@export var FB_head_anchor_strength_IN: float = 20.0
@export var FB_tail_anchor_strength_IN: float = 20.0
@export var FB_radial_strength_IN: float = 5.0
@export_range(0.5, 1.0, 0.01) var FB_damping_IN: float = 0.9
@export var FB_gravity_IN: float = 0.0
@export var FB_wobble_amp_IN: float = 0.4
@export var FB_breath_amp_IN: float = 0.2

@export var FB_head_control_IN: Node2D
@export var FB_tail_control_IN: Node2D

var FB_nodes_UP: Array[Vector2] = []
var FB_node_vels_UP: Array[Vector2] = []
var FB_rest_nodes_SH: Array[Vector2] = []
var FB_head_ctrl_UP: Vector2 = Vector2.ZERO
var FB_tail_ctrl_UP: Vector2 = Vector2.ZERO
var _mat: ShaderMaterial
var _drag_node: Node2D


func _ready() -> void:
    _init_nodes()
    _mat = ShaderMaterial.new()
    _mat.shader = load("res://shaders/soft_body_fish.gdshader")
    material = _mat
    position = get_viewport_rect().size * 0.5
    if FB_head_control_IN:
        FB_head_control_IN.position = _calc_head_pos()
    if FB_tail_control_IN:
        FB_tail_control_IN.position = _calc_tail_pos()


func _init_nodes() -> void:
    FB_nodes_UP.clear()
    FB_node_vels_UP.clear()
    FB_rest_nodes_SH.clear()
    for pt in FB_COORDS:
        var scaled: Vector2 = pt * FB_SCALE
        FB_nodes_UP.append(scaled)
        FB_node_vels_UP.append(Vector2.ZERO)
        FB_rest_nodes_SH.append(scaled)


func _calc_head_pos() -> Vector2:
    return (FB_rest_nodes_SH[5] + FB_rest_nodes_SH[6]) * 0.5


func _calc_tail_pos() -> Vector2:
    return (FB_rest_nodes_SH[0] + FB_rest_nodes_SH[11]) * 0.5


func _process(delta: float) -> void:
    _physics_step(delta)
    queue_redraw()
    _update_cursor()


func _input(event: InputEvent) -> void:
    if not FB_head_control_IN or not FB_tail_control_IN:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        var local_pos: Vector2 = to_local(mb.position)
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                if FB_head_control_IN.position.distance_to(local_pos) <= FB_DRAG_RADIUS:
                    _drag_node = FB_head_control_IN
                elif FB_tail_control_IN.position.distance_to(local_pos) <= FB_DRAG_RADIUS:
                    _drag_node = FB_tail_control_IN
            else:
                _drag_node = null
    elif event is InputEventMouseMotion and _drag_node:
        var mm := event as InputEventMouseMotion
        _drag_node.position = to_local(mm.position)


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

        var spring: Vector2 = ((prev + next) * 0.5 - pos) * FB_spring_strength_IN * delta
        var radial: Vector2 = (target - pos) * FB_radial_strength_IN * delta
        var grav: Vector2 = Vector2.DOWN * FB_gravity_IN * delta
        if FB_head_control_IN and i in [5, 6]:
            vel += (FB_head_control_IN.position - pos) * FB_head_anchor_strength_IN * delta
        if FB_tail_control_IN and i in [0, 11]:
            vel += (FB_tail_control_IN.position - pos) * FB_tail_anchor_strength_IN * delta
        vel += spring + radial + grav
        vel *= FB_damping_IN
        pos += vel * delta
        FB_nodes_UP[i] = pos
        FB_node_vels_UP[i] = vel

    _apply_diag_spring(2, 9, delta)
    _apply_diag_spring(3, 8, delta)


func _apply_diag_spring(a: int, b: int, delta: float) -> void:
    var pos_a: Vector2 = FB_nodes_UP[a]
    var pos_b: Vector2 = FB_nodes_UP[b]
    var diff: Vector2 = pos_b - pos_a
    var spring: Vector2 = diff * FB_spring_strength_IN * delta
    FB_node_vels_UP[a] += spring
    FB_node_vels_UP[b] -= spring


func _update_cursor() -> void:
    if not FB_head_control_IN or not FB_tail_control_IN:
        return
    var mpos: Vector2 = to_local(get_viewport().get_mouse_position())
    if (
        FB_head_control_IN.position.distance_to(mpos) <= FB_DRAG_RADIUS
        or FB_tail_control_IN.position.distance_to(mpos) <= FB_DRAG_RADIUS
    ):
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    else:
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _draw() -> void:
    var points: PackedVector2Array = PackedVector2Array(FB_nodes_UP)
    var uvs: PackedVector2Array = PackedVector2Array()
    for p in FB_nodes_UP:
        uvs.append(p * 0.05 + Vector2(0.5, 0.5))
    draw_polygon(points, [], uvs)
