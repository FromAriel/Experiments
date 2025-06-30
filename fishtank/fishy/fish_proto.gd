###############################################################
# fishtank/fishy/fish_proto.gd
# Key Classes      • FishProto – standalone soft-body fish sandbox
# Key Functions    • _ready() – build fish segments and joints
#                   • _process() – refresh debug drawing
#                   • _physics_process() – idle swim torque
# Dependencies     • FishProtoConfig
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name FishProto
extends Node2D

@export var FP_config_IN: FishProtoConfig

var FP_segments_UP: Array[RigidBody2D] = []
var FP_shape_texture_UP: Texture2D
var FP_time_UP: float = 0.0


func _ready() -> void:
    if FP_config_IN == null:
        FP_config_IN = load("res://fishy/default_proto_config.tres")
    FP_shape_texture_UP = _FP_create_shape_IN(32, 16)
    _FP_build_segments_IN()
    _FP_create_anchor_IN()


func _process(_delta: float) -> void:
    queue_redraw()


func _physics_process(delta: float) -> void:
    FP_time_UP += delta
    var FP_torque_UP: float = sin(FP_time_UP * 3.0) * 5.0
    for FP_i_IN in range(1, FP_segments_UP.size()):
        var FP_ratio_UP: float = 1.0 - float(FP_i_IN) / FP_segments_UP.size()
        FP_segments_UP[FP_i_IN].apply_torque(FP_torque_UP * FP_ratio_UP)


func _draw() -> void:
    for FP_i_IN in range(1, FP_segments_UP.size()):
        var FP_a_UP := FP_segments_UP[FP_i_IN - 1].global_position
        var FP_b_UP := FP_segments_UP[FP_i_IN].global_position
        draw_line(to_local(FP_a_UP), to_local(FP_b_UP), Color(0.8, 0.8, 0.8))
    for FP_seg_IN in FP_segments_UP:
        var FP_v_UP: Vector2 = FP_seg_IN.linear_velocity
        var FP_start_UP := to_local(FP_seg_IN.global_position)
        var FP_end_UP := to_local(FP_seg_IN.global_position + FP_v_UP * 0.1)
        draw_line(FP_start_UP, FP_end_UP, Color.RED)


func _FP_build_segments_IN() -> void:
    var FP_count_UP: int = FP_config_IN.FP_segment_masses_IN.size()
    for FP_i_IN in range(FP_count_UP):
        var FP_seg_UP := RigidBody2D.new()
        FP_seg_UP.name = "Segment_%d" % FP_i_IN
        FP_seg_UP.position = Vector2(-FP_i_IN * 20.0, 0)
        FP_seg_UP.mass = FP_config_IN.FP_segment_masses_IN[FP_i_IN]
        var FP_sprite_UP := Sprite2D.new()
        FP_sprite_UP.texture = FP_shape_texture_UP
        var FP_color_UP: Color = _FP_color_for_index_IN(FP_i_IN)
        FP_sprite_UP.modulate = FP_color_UP
        FP_sprite_UP.scale = _FP_scale_for_index_IN(FP_i_IN)
        FP_seg_UP.add_child(FP_sprite_UP)
        add_child(FP_seg_UP)
        FP_segments_UP.append(FP_seg_UP)
        if FP_i_IN > 0:
            var FP_joint_UP := DampedSpringJoint2D.new()
            FP_joint_UP.node_a = FP_segments_UP[FP_i_IN - 1].get_path()
            FP_joint_UP.node_b = FP_seg_UP.get_path()
            FP_joint_UP.rest_length = 20.0
            FP_joint_UP.stiffness = FP_config_IN.FP_stiffness_IN[FP_i_IN - 1]
            FP_joint_UP.damping = FP_config_IN.FP_damping_IN[FP_i_IN - 1]
            add_child(FP_joint_UP)


func _FP_create_anchor_IN() -> void:
    if FP_segments_UP.is_empty():
        return
    var FP_anchor_UP := StaticBody2D.new()
    FP_anchor_UP.name = "Anchor"
    add_child(FP_anchor_UP)
    var FP_pin_UP := PinJoint2D.new()
    FP_pin_UP.node_a = FP_anchor_UP.get_path()
    FP_pin_UP.node_b = FP_segments_UP[0].get_path()
    add_child(FP_pin_UP)


func _FP_color_for_index_IN(i: int) -> Color:
    if i == 0:
        return Color(0.4, 0.6, 1.0)
    if i <= 3:
        return Color(0.4, 1.0, 0.4)
    return Color(1.0, 0.6, 0.2)


func _FP_scale_for_index_IN(i: int) -> Vector2:
    if i == 0:
        return Vector2(1.3, 1.3)
    if i <= 3:
        return Vector2(1.0, 1.0)
    return Vector2(0.8, 0.8)


func _FP_create_shape_IN(width: int, height: int) -> ImageTexture:
    var FP_img_UP := Image.create(width, height, false, Image.FORMAT_RGBA8)
    FP_img_UP.fill(Color.TRANSPARENT)
    var FP_rx_UP := width / 2.0
    var FP_ry_UP := height / 2.0
    for FP_y_IN in range(height):
        for FP_x_IN in range(width):
            var FP_dx_UP: float = (FP_x_IN - FP_rx_UP + 0.5) / FP_rx_UP
            var FP_dy_UP: float = (FP_y_IN - FP_ry_UP + 0.5) / FP_ry_UP
            if FP_dx_UP * FP_dx_UP + FP_dy_UP * FP_dy_UP <= 1.0:
                FP_img_UP.set_pixel(FP_x_IN, FP_y_IN, Color.WHITE)
    var FP_tex_UP := ImageTexture.create_from_image(FP_img_UP)
    return FP_tex_UP
# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
