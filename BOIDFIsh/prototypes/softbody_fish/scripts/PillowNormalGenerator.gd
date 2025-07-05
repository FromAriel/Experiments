# gdlint:disable = class-variable-name,function-name
###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/PillowNormalGenerator.gd
# Key Classes      • PillowNormalGenerator – generates blurred silhouettes
# Key Functions    • update_polygon() – updates polygon points
# Editor Exports   • PN_size_IN: int – size of internal viewports
# Dependencies     • shaders/pillow_blur.gdshader
# Last Major Rev   • 24-05-05 – initial version
###############################################################
class_name PillowNormalGenerator
extends Node

const PN_BLUR_SHADER: Shader = preload("res://shaders/pillow_blur.gdshader")

@export var PN_size_IN: int = 256

var PN_sil_vp_RD: Viewport
var PN_blur_h_vp_RD: Viewport
var PN_blur_v_vp_RD: Viewport
var PN_polygon_RD: Polygon2D
var PN_blur_h_sprite_RD: Sprite2D
var PN_blur_v_sprite_RD: Sprite2D
var PN_blur_h_mat_RD: ShaderMaterial
var PN_blur_v_mat_RD: ShaderMaterial


func _ready() -> void:
    _setup_viewports()


func _setup_viewports() -> void:
    PN_sil_vp_RD = _create_viewport()
    add_child(PN_sil_vp_RD)
    PN_polygon_RD = Polygon2D.new()
    PN_polygon_RD.color = Color.WHITE
    PN_sil_vp_RD.add_child(PN_polygon_RD)

    PN_blur_h_vp_RD = _create_viewport()
    add_child(PN_blur_h_vp_RD)
    PN_blur_h_sprite_RD = Sprite2D.new()
    PN_blur_h_mat_RD = ShaderMaterial.new()
    PN_blur_h_mat_RD.shader = PN_BLUR_SHADER
    PN_blur_h_mat_RD.set_shader_parameter("direction", Vector2(1.0, 0.0))
    PN_blur_h_sprite_RD.material = PN_blur_h_mat_RD
    PN_blur_h_sprite_RD.texture = PN_sil_vp_RD.get_texture()
    PN_blur_h_vp_RD.add_child(PN_blur_h_sprite_RD)

    PN_blur_v_vp_RD = _create_viewport()
    add_child(PN_blur_v_vp_RD)
    PN_blur_v_sprite_RD = Sprite2D.new()
    PN_blur_v_mat_RD = ShaderMaterial.new()
    PN_blur_v_mat_RD.shader = PN_BLUR_SHADER
    PN_blur_v_mat_RD.set_shader_parameter("direction", Vector2(0.0, 1.0))
    PN_blur_v_sprite_RD.material = PN_blur_v_mat_RD
    PN_blur_v_sprite_RD.texture = PN_blur_h_vp_RD.get_texture()
    PN_blur_v_vp_RD.add_child(PN_blur_v_sprite_RD)


func _create_viewport() -> SubViewport:
    var vp := SubViewport.new()
    vp.disable_3d = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    vp.size = Vector2i(PN_size_IN, PN_size_IN)
    return vp


func update_polygon(points: Array[Vector2]) -> void:
    var poly: PackedVector2Array = PackedVector2Array()
    for p in points:
        poly.append(p + Vector2(PN_size_IN * 0.5, PN_size_IN * 0.5))
    PN_polygon_RD.polygon = poly


func get_texture() -> Texture2D:
    return PN_blur_v_vp_RD.get_texture()
