###############################################################
# fishtank/fishy/fish_proto.gd
# Key Classes      • FishProto – build and visualize a soft-body fish
# Key Functions    • _FP_build_chain_IN() – create segments and joints
#                   • _physics_process() – apply demo torque
# Dependencies     • fish_proto_config.gd
# Last Major Rev   • 24-07-06 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name

class_name FishProto
extends Node2D

const FishProtoConfig = preload("res://fishy/fish_proto_config.gd")

@export var FP_config_IN: FishProtoConfig
@export var FP_apply_motion_IN: bool = true

var FP_segments_SH: Array[RigidBody2D] = []
var FP_time_UP: float = 0.0


func _ready() -> void:
    if FP_config_IN == null:
        FP_config_IN = FishProtoConfig.new()
    _FP_build_chain_IN()


func _physics_process(delta: float) -> void:
    FP_time_UP += delta
    if FP_apply_motion_IN:
        var torque := sin(FP_time_UP * 2.0) * 10.0
        for i in range(1, FP_segments_SH.size()):
            FP_segments_SH[i].apply_torque(torque)
    queue_redraw()


func _draw() -> void:
    for i in range(FP_segments_SH.size() - 1):
        var a: Vector2 = FP_segments_SH[i].global_position
        var b: Vector2 = FP_segments_SH[i + 1].global_position
        draw_line(a, b, Color(1, 1, 1, 0.3), 1.0)
        var vel := FP_segments_SH[i].linear_velocity
        draw_line(a, a + vel * 0.1, Color(0, 1, 0, 0.5), 2.0)


func _FP_build_chain_IN() -> void:
    var anchor := Node2D.new()
    anchor.name = "Anchor"
    add_child(anchor)

    var prev: RigidBody2D
    for i in range(1 + FP_config_IN.FPC_body_segments_IN + FP_config_IN.FPC_tail_segments_IN):
        var body := RigidBody2D.new()
        body.position = Vector2(-i * FP_config_IN.FPC_segment_spacing_IN, 0)
        var mass := FP_config_IN.FPC_body_mass_IN
        var tint := Color(0, 1, 0)
        var stiffness: float = lerp(
            FP_config_IN.FPC_head_stiffness_IN,
            FP_config_IN.FPC_tail_stiffness_IN,
            float(i) / max(FP_config_IN.FPC_body_segments_IN + FP_config_IN.FPC_tail_segments_IN, 1)
        )
        if i == 0:
            mass = FP_config_IN.FPC_head_mass_IN
            tint = Color(0.4, 0.6, 1.0)
        elif i >= FP_config_IN.FPC_body_segments_IN:
            mass = FP_config_IN.FPC_tail_mass_IN
            tint = Color(1.0, 0.5, 0.2)
        body.mass = mass
        var sprite := Sprite2D.new()
        sprite.texture = _FP_make_ellipse_IN(32, 16, Color.WHITE)
        sprite.modulate = tint
        body.add_child(sprite)
        add_child(body)
        FP_segments_SH.append(body)
        if prev != null:
            var joint := DampedSpringJoint2D.new()
            joint.node_a = prev.get_path()
            joint.node_b = body.get_path()
            joint.length = FP_config_IN.FPC_segment_spacing_IN
            joint.rest_length = FP_config_IN.FPC_segment_spacing_IN
            joint.stiffness = stiffness
            joint.damping = FP_config_IN.FPC_damping_IN
            add_child(joint)
        else:
            var pin := PinJoint2D.new()
            pin.node_a = anchor.get_path()
            pin.node_b = body.get_path()
            add_child(pin)
        prev = body


func _FP_make_ellipse_IN(w: int, h: int, color: Color) -> ImageTexture:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var rx := w / 2.0
    var ry := h / 2.0
    for y in range(h):
        for x in range(w):
            var dx: float = (x - rx + 0.5) / rx
            var dy: float = (y - ry + 0.5) / ry
            if dx * dx + dy * dy <= 1.0:
                img.set_pixel(x, y, color)
    return ImageTexture.create_from_image(img)
# gdlint:enable = class-variable-name,function-name,function-variable-name
