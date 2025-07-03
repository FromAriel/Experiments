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

const FB_HEAD_INDICES: Array[int] = [4, 5, 6, 7]
const FB_TAIL_INDICES: Array[int] = [0, 1, 10, 11]
const FB_CROSS_BRACES: Array[Vector2i] = [Vector2i(2, 9), Vector2i(3, 8)]

@export var FB_spring_strength_IN: float = 10.0
@export var FB_head_spring_strength_IN: float = 10.0
@export var FB_tail_spring_strength_IN: float = 10.0
@export var FB_radial_strength_IN: float = 5.0
@export_range(0.5, 1.0, 0.01) var FB_damping_IN: float = 0.9
@export var FB_gravity_IN: float = 0.0
@export var FB_wobble_amp_IN: float = 0.4
@export var FB_breath_amp_IN: float = 0.2
@export var FB_cross_strength_IN: float = 10.0

var FB_nodes_UP: Array[Vector2] = []
var FB_node_vels_UP: Array[Vector2] = []
var FB_rest_nodes_SH: Array[Vector2] = []
var FB_head_ctrl_UP: Vector2 = Vector2.ZERO
var FB_tail_ctrl_UP: Vector2 = Vector2.ZERO
var FB_mat_UP: ShaderMaterial
var FB_cross_rest_SH: Dictionary = {}
var FB_drag_head_UP: bool = false
var FB_drag_tail_UP: bool = false
@onready var FB_head_node_SH: Node2D = $HeadControl
@onready var FB_tail_node_SH: Node2D = $TailControl


func _ready() -> void:
    _init_nodes()
    FB_mat_UP = ShaderMaterial.new()
    FB_mat_UP.shader = load("res://shaders/soft_body_fish.gdshader")
    material = FB_mat_UP
    scale = Vector2.ONE * 15.0
    position = get_viewport_rect().size * 0.5
    FB_head_node_SH.position = (FB_nodes_UP[5] + FB_nodes_UP[6]) * 0.5
    FB_tail_node_SH.position = (FB_nodes_UP[0] + FB_nodes_UP[11]) * 0.5


func _init_nodes() -> void:
    FB_nodes_UP.clear()
    FB_node_vels_UP.clear()
    FB_rest_nodes_SH.clear()
    FB_cross_rest_SH.clear()
    for pt in FB_COORDS:
        FB_nodes_UP.append(pt)
        FB_node_vels_UP.append(Vector2.ZERO)
        FB_rest_nodes_SH.append(pt)
    for pair in FB_CROSS_BRACES:
        FB_cross_rest_SH[pair] = FB_rest_nodes_SH[pair.y] - FB_rest_nodes_SH[pair.x]


func _process(delta: float) -> void:
    _physics_step(delta)
    queue_redraw()


func _physics_step(delta: float) -> void:
    var count: int = FB_nodes_UP.size()
    var time_now: float = Time.get_ticks_msec() / 1000.0

    for i in count:
        var prev: Vector2 = FB_nodes_UP[(i - 1 + count) % count]
        var next: Vector2 = FB_nodes_UP[(i + 1) % count]
        var base: Vector2 = FB_rest_nodes_SH[i]
        var wob: float = sin(time_now * 0.8 + float(i)) * FB_wobble_amp_IN
        var breath: float = sin(time_now + float(i) * 0.1) * FB_breath_amp_IN
        var target: Vector2 = base + Vector2(0, wob + breath)

        var spring_strength: float = FB_spring_strength_IN
        if FB_HEAD_INDICES.has(i):
            spring_strength = FB_head_spring_strength_IN
        elif FB_TAIL_INDICES.has(i):
            spring_strength = FB_tail_spring_strength_IN

        var spring: Vector2 = ((prev + next) * 0.5 - FB_nodes_UP[i]) * spring_strength
        var radial: Vector2 = (target - FB_nodes_UP[i]) * FB_radial_strength_IN
        var grav: Vector2 = Vector2.DOWN * FB_gravity_IN
        FB_node_vels_UP[i] += (spring + radial + grav) * delta

    for pair in FB_CROSS_BRACES:
        var diff: Vector2 = (FB_nodes_UP[pair.y] - FB_nodes_UP[pair.x]) - FB_cross_rest_SH[pair]
        var impulse: Vector2 = diff * FB_cross_strength_IN * delta * 0.5
        FB_node_vels_UP[pair.x] += impulse
        FB_node_vels_UP[pair.y] -= impulse

    if FB_drag_head_UP:
        var pos: Vector2 = to_local(get_viewport().get_mouse_position())
        FB_nodes_UP[5] = pos
        FB_nodes_UP[6] = pos
        FB_head_node_SH.position = pos
    if FB_drag_tail_UP:
        var pos: Vector2 = to_local(get_viewport().get_mouse_position())
        FB_nodes_UP[0] = pos
        FB_nodes_UP[11] = pos
        FB_tail_node_SH.position = pos

    for i in count:
        var vel: Vector2 = FB_node_vels_UP[i]
        vel *= FB_damping_IN
        FB_nodes_UP[i] += vel * delta
        FB_node_vels_UP[i] = vel


func _draw() -> void:
    var points: PackedVector2Array = PackedVector2Array(FB_nodes_UP)
    var uvs: PackedVector2Array = PackedVector2Array()
    for p in FB_nodes_UP:
        uvs.append(p * 0.05 + Vector2(0.5, 0.5))
    draw_polygon(points, [], uvs)
    draw_circle(FB_head_node_SH.position, 0.2, Color.WHITE)
    draw_circle(FB_tail_node_SH.position, 0.2, Color.WHITE)


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var mp: Vector2 = to_local(event.position)
                if mp.distance_to(FB_head_node_SH.position) < 0.5:
                    FB_drag_head_UP = true
                    Input.set_default_cursor_shape(Input.CURSOR_DRAG)
                elif mp.distance_to(FB_tail_node_SH.position) < 0.5:
                    FB_drag_tail_UP = true
                    Input.set_default_cursor_shape(Input.CURSOR_DRAG)
            else:
                FB_drag_head_UP = false
                FB_drag_tail_UP = false
                Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    elif event is InputEventMouseMotion:
        var mp: Vector2 = to_local(event.position)
        if not FB_drag_head_UP and not FB_drag_tail_UP:
            if (
                mp.distance_to(FB_head_node_SH.position) < 0.5
                or mp.distance_to(FB_tail_node_SH.position) < 0.5
            ):
                Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
            else:
                Input.set_default_cursor_shape(Input.CURSOR_ARROW)
