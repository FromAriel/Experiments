extends Object
class_name ShapeGenerator
## Creates simple placeholder textures entirely in memory.

static func generate_ellipse_texture(
        width: int,
        height: int,
        fill_color: Color = Color(1, 1, 1, 1)
) -> Texture2D:
    var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))                                                # Transparent background.

    var center: Vector2 = Vector2(width * 0.5, height * 0.5)
    var radius: Vector2 = Vector2(width * 0.5, height * 2)

    for y: int in range(height):
        for x: int in range(width):
            var rel: Vector2 = Vector2(x, y) - center
            var norm: Vector2 = Vector2(rel.x / radius.x, rel.y / radius.y)
            if norm.length_squared() <= 1.0:
                img.set_pixel(x, y, fill_color)
            else:
                pass                                                       # Keep pixel transparent.

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
