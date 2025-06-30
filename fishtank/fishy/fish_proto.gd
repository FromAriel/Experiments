###############################################################
# fishtank/fishy/fish_proto.gd
# Key Classes      • FishProto – soft-body fish testbed
# Key Functions    • _FP_build_segments_IN() – create rigid bodies & joints
#                   • _FP_create_ellipse_tex_IN() – generate placeholder texture
# Dependencies     • fish_proto_config.gd
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name FishProto
extends Node2D

@export var FP_segment_spacing_IN: float = 20.0
@export var FP_body_segments_IN: int = 4
@export var FP_tail_segments_IN: int = 6
@export var FP_config_IN: FishProtoConfig

var FP_segments_UP: Array[RigidBody2D] = []
var FP_time_UP: float = 0.0


func _ready() -> void:
    if FP_config_IN == null:
        FP_config_IN = preload("res://fishy/default_config.tres")
    _FP_build_segments_IN()
    set_process(true)


func _process(delta: float) -> void:
    FP_time_UP += delta
    # Simple idle motion: oscillate torque on tail
    for i in range(FP_body_segments_IN, FP_segments_UP.size()):
        var seg := FP_segments_UP[i]
        seg.apply_torque(sin(FP_time_UP * 2.0 + i) * 5.0)


func _FP_build_segments_IN() -> void:
    var anchor := StaticBody2D.new()
    anchor.name = "Anchor"
    add_child(anchor)

    var head := _FP_create_segment_IN(FP_config_IN.FC_head_mass_IN, Color(0.5, 0.5, 1.0), 1.4)
    FP_segments_UP.append(head)
    head.position = Vector2.ZERO
    add_child(head)
    var pin := PinJoint2D.new()
    pin.node_a = anchor.get_path()
    pin.node_b = head.get_path()
    add_child(pin)

    var prev := head
    for i in range(FP_body_segments_IN):
        var body := _FP_create_segment_IN(FP_config_IN.FC_body_mass_IN, Color(0.5, 1.0, 0.5), 1.1)
        body.position = Vector2(-FP_segment_spacing_IN * (i + 1), 0)
        add_child(body)
        FP_segments_UP.append(body)
        var spring := DampedSpringJoint2D.new()
        spring.node_a = prev.get_path()
        spring.node_b = body.get_path()
        spring.length = FP_segment_spacing_IN
        var t: float = float(i) / max(FP_body_segments_IN + FP_tail_segments_IN, 1)
        spring.stiffness = lerp(
            FP_config_IN.FC_head_stiffness_IN, FP_config_IN.FC_tail_stiffness_IN, t
        )
        spring.damping = lerp(FP_config_IN.FC_head_damping_IN, FP_config_IN.FC_tail_damping_IN, t)
        add_child(spring)
        prev = body

    for i in range(FP_tail_segments_IN):
        var tail := _FP_create_segment_IN(FP_config_IN.FC_tail_mass_IN, Color(1.0, 0.7, 0.3), 0.8)
        tail.position = Vector2(-FP_segment_spacing_IN * (FP_body_segments_IN + i + 1), 0)
        add_child(tail)
        FP_segments_UP.append(tail)
        var spring_t := DampedSpringJoint2D.new()
        spring_t.node_a = prev.get_path()
        spring_t.node_b = tail.get_path()
        spring_t.length = FP_segment_spacing_IN
        var t2: float = (
            float(FP_body_segments_IN + i) / max(FP_body_segments_IN + FP_tail_segments_IN, 1)
        )
        spring_t.stiffness = lerp(
            FP_config_IN.FC_head_stiffness_IN, FP_config_IN.FC_tail_stiffness_IN, t2
        )
        spring_t.damping = lerp(
            FP_config_IN.FC_head_damping_IN, FP_config_IN.FC_tail_damping_IN, t2
        )
        add_child(spring_t)
        prev = tail


func _FP_create_segment_IN(mass: float, tint: Color, scale: float) -> RigidBody2D:
    var body := RigidBody2D.new()
    body.mass = mass
    var sprite := Sprite2D.new()
    sprite.centered = true
    sprite.texture = _FP_create_ellipse_tex_IN(32, 16, Color.WHITE)
    sprite.modulate = tint
    sprite.scale = Vector2.ONE * scale
    body.add_child(sprite)
    return body


func _FP_create_ellipse_tex_IN(width: int, height: int, color: Color) -> ImageTexture:
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var rx := width / 2.0
    var ry := height / 2.0
    for y in range(height):
        for x in range(width):
            var dx: float = (x - rx + 0.5) / rx
            var dy: float = (y - ry + 0.5) / ry
            if dx * dx + dy * dy <= 1.0:
                img.set_pixel(x, y, color)
    var tex := ImageTexture.create_from_image(img)
    return tex
# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
