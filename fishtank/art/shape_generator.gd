###############################################################
# fishtank/art/shape_generator.gd
# Key Classes      • ShapeGenerator – generates placeholder textures
# Key Functions    • SG_generate_shapes_IN() – writes ellipse and triangle images
# Dependencies     • None
# Last Major Rev   • 24-07-05 – ensure output dir exists, guard errors
###############################################################
# gdlint:disable = function-variable-name,function-name,loop-variable-name

class_name ShapeGenerator
extends Node

const SG_ART_DIR := "res://fishtank/art"


func SG_generate_shapes_IN() -> void:
    # Make sure the art directory exists (important on a fresh checkout / export).
    var SG_art_path := ProjectSettings.globalize_path(SG_ART_DIR)
    var SG_dir_err := DirAccess.make_dir_recursive_absolute(SG_art_path)
    if SG_dir_err != OK and SG_dir_err != ERR_ALREADY_EXISTS:
        push_error("ShapeGenerator: Cannot create directory %s (err %d)" % [SG_ART_DIR, SG_dir_err])
        return

    var SG_ellipse_image_UP := _SG_create_ellipse_IN(64, 32, Color.WHITE)
    SG_ellipse_image_UP.save_png("%s/ellipse_placeholder.png" % SG_ART_DIR)

    var SG_triangle_image_UP := _SG_create_triangle_IN(64, 64, Color.WHITE)
    SG_triangle_image_UP.save_png("%s/triangle_placeholder.png" % SG_ART_DIR)


func _SG_create_ellipse_IN(width: int, height: int, color: Color) -> Image:
    var SG_img_UP := Image.create(width, height, false, Image.FORMAT_RGBA8)
    SG_img_UP.fill(Color.TRANSPARENT)
    var SG_rx_UP := width / 2.0
    var SG_ry_UP := height / 2.0
    for SG_y_IN in range(height):
        for SG_x_IN in range(width):
            var SG_dx_UP: float = (SG_x_IN - SG_rx_UP + 0.5) / SG_rx_UP
            var SG_dy_UP: float = (SG_y_IN - SG_ry_UP + 0.5) / SG_ry_UP
            if SG_dx_UP * SG_dx_UP + SG_dy_UP * SG_dy_UP <= 1.0:
                SG_img_UP.set_pixel(SG_x_IN, SG_y_IN, color)
    return SG_img_UP


func _SG_create_triangle_IN(width: int, height: int, color: Color) -> Image:
    var SG_img_UP := Image.create(width, height, false, Image.FORMAT_RGBA8)
    SG_img_UP.fill(Color.TRANSPARENT)
    var SG_center_UP := width / 2.0
    for SG_y_IN in range(height):
        var SG_ratio_UP: float = float(SG_y_IN) / max(height - 1, 1)
        var SG_half_width_UP: float = (width * SG_ratio_UP) / 2.0
        for SG_x_IN in range(width):
            if abs(SG_x_IN - SG_center_UP) <= SG_half_width_UP:
                SG_img_UP.set_pixel(SG_x_IN, SG_y_IN, color)
    return SG_img_UP
# gdlint:enable = function-variable-name,function-name,loop-variable-name
