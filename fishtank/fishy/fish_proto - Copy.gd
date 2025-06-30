###############################################################
# fishtank/fishy/fish_proto.gd
# Key Classes      • FishProto – soft-body fish prototyping scene
# Key Functions    • _FP_build_fish_IN() – construct segments and joints
#                   • _FP_apply_swim_IN() – idle torque motion
# Dependencies     • None
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name FishProto
extends Node2D

@export var FP_config_resource_IN: Resource

var FP_segments_UP: Array = []
var FP_joints_UP: Array = []
var FP_head_tex_UP: Texture2D
var FP_body_tex_UP: Texture2D
var FP_tail_tex_UP: Texture2D
var FP_time_UP: float = 0.0


func _ready() -> void:
    _FP_generate_textures_IN()
    _FP_build_fish_IN()
    set_process(true)
    queue_redraw()


func _process(delta: float) -> void:
    _FP_apply_swim_IN(delta)
    queue_redraw()


func _draw() -> void:
    for joint in FP_joints_UP:
        var a := get_node(joint.node_a) as RigidBody2D
        var b := get_node(joint.node_b) as RigidBody2D
        draw_line(a.position, b.position, Color(1, 0, 0))
        draw_circle(a.position, 2, Color(0, 1, 0))
        draw_circle(b.position, 2, Color(0, 1, 0))


func _FP_build_fish_IN() -> void:
    var masses: Array = []
    var stiff: Array = []
    var damp: Array = []
    if FP_config_resource_IN != null:
        masses = FP_config_resource_IN.get("masses")
        if masses == null:
            masses = []
        stiff = FP_config_resource_IN.get("stiffness")
        if stiff == null:
            stiff = []
        damp = FP_config_resource_IN.get("damping")
        if damp == null:
            damp = []
    var seg_length := 20.0
    for i in range(masses.size()):
        var seg := RigidBody2D.new()
        seg.name = "segment_%d" % i
        seg.position = Vector2(-i * seg_length, 0)
        seg.mass = masses[i]
        var sprite := Sprite2D.new()
        if i == 0:
            sprite.texture = FP_head_tex_UP
            sprite.modulate = Color.hex(0x69b3ffff)
        elif i < 5:
            sprite.texture = FP_body_tex_UP
            sprite.modulate = Color.hex(0x88ff88ff)
        else:
            sprite.texture = FP_tail_tex_UP
            sprite.modulate = Color.hex(0xffb56bff)
        seg.add_child(sprite)
        add_child(seg)
        FP_segments_UP.append(seg)
        if i > 0:
            var joint := DampedSpringJoint2D.new()
            joint.node_a = NodePath("segment_%d" % (i - 1))
            joint.node_b = NodePath(seg.name)
            joint.length = seg_length
            if i - 1 < stiff.size():
                joint.stiffness = stiff[i - 1]
            if i - 1 < damp.size():
                joint.damping = damp[i - 1]
            add_child(joint)
            FP_joints_UP.append(joint)
    var anchor := $Anchor as StaticBody2D
    var pin := PinJoint2D.new()
    pin.node_a = NodePath("segment_0")
    pin.node_b = NodePath(anchor.get_path())
    add_child(pin)


func _FP_create_ellipse_IN(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var rx := w / 2.0
    var ry := h / 2.0
    for y in range(h):
        for x in range(w):
            var dx := (x - rx + 0.5) / rx
            var dy := (y - ry + 0.5) / ry
            if dx * dx + dy * dy <= 1.0:
                img.set_pixel(x, y, Color.WHITE)
    return img


func _FP_create_triangle_IN(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var center := w / 2.0
    for y in range(h):
        var ratio = float(y) / max(h - 1, 1)
        var half_width = (w * ratio) / 2.0
        for x in range(w):
            if abs(x - center) <= half_width:
                img.set_pixel(x, y, Color.WHITE)
    return img


func _FP_generate_textures_IN() -> void:
    FP_head_tex_UP = ImageTexture.create_from_image(_FP_create_ellipse_IN(32, 20))
    FP_body_tex_UP = ImageTexture.create_from_image(_FP_create_ellipse_IN(24, 16))
    FP_tail_tex_UP = ImageTexture.create_from_image(_FP_create_triangle_IN(20, 20))


func _FP_apply_swim_IN(delta: float) -> void:
    FP_time_UP += delta
    var torque := sin(FP_time_UP * 2.0) * 5.0
    for i in range(5, FP_segments_UP.size()):
        var seg: RigidBody2D = FP_segments_UP[i]
        seg.apply_torque(torque * (i - 4))
# gdlint:enable
