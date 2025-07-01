# gdlint:disable = function-name,class-definitions-order
extends Object
class_name ShapeGenerator
## Creates simple placeholder textures entirely in memory. Supports
## ellipses, circles, triangles and partial ellipse segments for debug art.

enum TriangleVariant { ISOSCELES, SCALENE, RIGHT, OBTUSE }


static func generate_ellipse_texture(
    width: int, height: int, fill_color: Color = Color(1, 1, 1, 1)
) -> Texture2D:
    var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))  # Transparent background.

    var center: Vector2 = Vector2(width * 0.5, height * 0.5)
    var radius: Vector2 = Vector2(width * 0.5, height * 2)

    for y: int in range(height):
        for x: int in range(width):
            var rel: Vector2 = Vector2(x, y) - center
            var norm: Vector2 = Vector2(rel.x / radius.x, rel.y / radius.y)
            if norm.length_squared() <= 1.0:
                img.set_pixel(x, y, fill_color)
            else:
                pass  # Keep pixel transparent.

    var tex: ImageTexture = ImageTexture.create_from_image(img)

    # Optional debug PNG dump.
    if Engine.has_singleton("GameManager"):
        var gm: GameManager = Engine.get_singleton("GameManager")
        if gm.GM_debug_enabled_SH and gm.GM_dump_placeholders_SH:
            var path: String = "user://ellipse_%dx%d.png" % [width, height]
            img.save_png(path)
        else:
            pass
    else:
        pass

    return tex


static func generate_circle_texture(
    diameter: int, fill_color: Color = Color(1, 1, 1, 1)
) -> Texture2D:
    return generate_ellipse_texture(diameter, diameter, fill_color)


static func generate_triangle_texture(
    width: int,
    height: int,
    fill_color: Color = Color(1, 1, 1, 1),
    variant: TriangleVariant = TriangleVariant.ISOSCELES
) -> Texture2D:
    var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)

    var points: PackedVector2Array
    match variant:
        TriangleVariant.RIGHT:
            points = PackedVector2Array(
                [
                    Vector2(0, 0),
                    Vector2(0, height - 1),
                    Vector2(width - 1, height - 1),
                ]
            )
        TriangleVariant.SCALENE:
            points = PackedVector2Array(
                [
                    Vector2(width * 0.1, 0),
                    Vector2(width - 1, height * 0.75),
                    Vector2(width * 0.25, height - 1),
                ]
            )
        TriangleVariant.OBTUSE:
            points = PackedVector2Array(
                [
                    Vector2(width * 0.5, 0),
                    Vector2(0, height - 1),
                    Vector2(width * 0.9, height - 1),
                ]
            )
        _:
            points = PackedVector2Array(
                [
                    Vector2(width * 0.5, 0),
                    Vector2(0, height - 1),
                    Vector2(width - 1, height - 1),
                ]
            )

    for y in range(height):
        for x in range(width):
            var p: Vector2 = Vector2(x + 0.5, y + 0.5)
            if Geometry2D.is_point_in_polygon(p, points):
                img.set_pixel(x, y, fill_color)

    var tex: ImageTexture = ImageTexture.create_from_image(img)

    if Engine.has_singleton("GameManager"):
        var gm: GameManager = Engine.get_singleton("GameManager")
        if gm.GM_debug_enabled_SH and gm.GM_dump_placeholders_SH:
            var tpath: String = "user://triangle_%dx%d.png" % [width, height]
            img.save_png(tpath)

    return tex


static func generate_bottom_ellipse_segment_texture(
    width: int, height: int, thickness: int = 2, fill_color: Color = Color(1, 1, 1, 1)
) -> Texture2D:
    var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)

    var center: Vector2 = Vector2(width * 0.5, height * 0.5)
    var outer: Vector2 = Vector2(width * 0.5, height * 0.5)
    var inner: Vector2 = Vector2(outer.x - thickness, outer.y - thickness)

    for y in range(int(height / 2), height):
        for x in range(width):
            var rel: Vector2 = Vector2(x + 0.5, y + 0.5) - center
            var norm_o: Vector2 = Vector2(rel.x / outer.x, rel.y / outer.y)
            var norm_i: Vector2 = Vector2(rel.x / max(inner.x, 1), rel.y / max(inner.y, 1))
            var in_outer = norm_o.length_squared() <= 1.0
            var in_inner = norm_i.length_squared() <= 1.0
            if in_outer and not in_inner:
                img.set_pixel(x, y, fill_color)

    var tex: ImageTexture = ImageTexture.create_from_image(img)

    if Engine.has_singleton("GameManager"):
        var gm: GameManager = Engine.get_singleton("GameManager")
        if gm.GM_debug_enabled_SH and gm.GM_dump_placeholders_SH:
            var epath: String = "user://ellipse_segment_%dx%d.png" % [width, height]
            img.save_png(epath)

    return tex
