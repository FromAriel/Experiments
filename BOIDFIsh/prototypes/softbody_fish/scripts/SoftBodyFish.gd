# gdlint:disable = class-variable-name,function-name
###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/SoftBodyFish.gd
# Key Classes      • SoftBodyFish – simple soft-body fish demo
# Key Functions    • _physics_step() – per-node spring physics
# Critical Consts  • FB_COORDS – initial node positions
# Editor Exports   • FB_body_spring_strength_IN: float
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

const HEAD_INDICES: PackedInt32Array = PackedInt32Array([0, 1, 11, 12])
const TAIL_INDICES: PackedInt32Array = PackedInt32Array([4, 5, 6, 7])
const CROSS_PAIRS: Array = [[2, 9], [3, 8]]

@export var FB_body_spring_strength_IN: float = 10.0
@export var FB_head_spring_strength_IN: float = 12.0
@export var FB_tail_spring_strength_IN: float = 12.0
@export var FB_display_scale_IN: float = 15.0
@export var FB_radial_strength_IN: float = 5.0
@export_range(0.5, 1.0, 0.01) var FB_damping_IN: float = 0.9
@export var FB_gravity_IN: float = 0.0
@export var FB_wobble_amp_IN: float = 0.4
@export var FB_breath_amp_IN: float = 0.2

var FB_nodes_UP: Array[Vector2] = []
var FB_node_vels_UP: Array[Vector2] = []
var FB_rest_nodes_SH: Array[Vector2] = []
var FB_head_ctrl_UP: Vector2 = Vector2.ZERO
var FB_tail_ctrl_UP: Vector2 = Vector2.ZERO
var _mat: ShaderMaterial
var _dragging_head: bool = false
var _dragging_tail: bool = false

@onready var head_control: Node2D = $HeadControl
@onready var tail_control: Node2D = $TailControl


func _ready() -> void:
    _init_nodes()
    position = get_viewport_rect().size * 0.5
    _mat = ShaderMaterial.new()
    _mat.shader = load("res://shaders/soft_body_fish.gdshader")
    material = _mat
    head_control.position = FB_nodes_UP[0]
    tail_control.position = FB_nodes_UP[5]


func _init_nodes() -> void:
    FB_nodes_UP.clear()
    FB_node_vels_UP.clear()
    FB_rest_nodes_SH.clear()
    for pt in FB_COORDS:
        var p: Vector2 = pt * FB_display_scale_IN
        FB_nodes_UP.append(p)
        FB_node_vels_UP.append(Vector2.ZERO)
        FB_rest_nodes_SH.append(p)


func _process(delta: float) -> void:
    _update_cursor()
    _physics_step(delta)
    queue_redraw()


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if head_control.global_position.distance_to(event.position) < 10.0:
                _dragging_head = true
            elif tail_control.global_position.distance_to(event.position) < 10.0:
                _dragging_tail = true
        else:
            _dragging_head = false
            _dragging_tail = false
    elif event is InputEventMouseMotion:
        if _dragging_head:
            head_control.position += event.relative
        elif _dragging_tail:
            tail_control.position += event.relative


func _update_cursor() -> void:
    var mouse_pos: Vector2 = get_global_mouse_position()
    var cursor := Input.CURSOR_ARROW
    if head_control.global_position.distance_to(mouse_pos) < 10.0:
        cursor = Input.CURSOR_POINTING_HAND
    elif tail_control.global_position.distance_to(mouse_pos) < 10.0:
        cursor = Input.CURSOR_POINTING_HAND
    Input.set_default_cursor_shape(cursor)


func _physics_step(delta: float) -> void:
    var count: int = FB_nodes_UP.size()
    var time_now: float = Time.get_ticks_msec() / 1000.0
    for i in count:
        var prev: Vector2 = FB_nodes_UP[(i - 1 + count) % count]
        var next: Vector2 = FB_nodes_UP[(i + 1) % count]
        var pos: Vector2 = FB_nodes_UP[i]
        var vel: Vector2 = FB_node_vels_UP[i]
        var base: Vector2 = FB_rest_nodes_SH[i]
        if i in HEAD_INDICES:
            base = head_control.position
        elif i in TAIL_INDICES:
            base = tail_control.position
        var wob: float = sin(time_now * 0.8 + float(i)) * FB_wobble_amp_IN
        var breath: float = sin(time_now + float(i) * 0.1) * FB_breath_amp_IN
        var target: Vector2 = base + Vector2(0, wob + breath)

        var spring_strength: float = FB_body_spring_strength_IN
        if i in HEAD_INDICES:
            spring_strength = FB_head_spring_strength_IN
        elif i in TAIL_INDICES:
            spring_strength = FB_tail_spring_strength_IN

        var spring: Vector2 = ((prev + next) * 0.5 - pos) * spring_strength * delta
        var radial: Vector2 = (target - pos) * FB_radial_strength_IN * delta
        var grav: Vector2 = Vector2.DOWN * FB_gravity_IN * delta
        vel += spring + radial + grav
        vel *= FB_damping_IN
        pos += vel * delta
        FB_nodes_UP[i] = pos
        FB_node_vels_UP[i] = vel

    for pair in CROSS_PAIRS:
        var a: int = pair[0]
        var b: int = pair[1]
        var pa: Vector2 = FB_nodes_UP[a]
        var pb: Vector2 = FB_nodes_UP[b]
        var mid: Vector2 = (pa + pb) * 0.5
        FB_node_vels_UP[a] += (mid - pa) * FB_body_spring_strength_IN * delta
        FB_node_vels_UP[b] += (mid - pb) * FB_body_spring_strength_IN * delta


func _draw() -> void:
    var points: PackedVector2Array = PackedVector2Array(FB_nodes_UP)
    var uvs: PackedVector2Array = PackedVector2Array()
    for p in FB_nodes_UP:
        uvs.append(p * 0.05 + Vector2(0.5, 0.5))
    draw_polygon(points, [], uvs)
