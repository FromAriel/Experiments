shader_type canvas_item;

uniform sampler2D src_tex;
uniform vec2 tex_size = vec2(64.0, 64.0);

void fragment() {
    vec2 px = 1.0 / tex_size;
    vec4 c = texture(src_tex, UV) * 4.0;
    c += texture(src_tex, UV + vec2(px.x, 0.0)) * 2.0;
    c += texture(src_tex, UV - vec2(px.x, 0.0)) * 2.0;
    c += texture(src_tex, UV + vec2(0.0, px.y)) * 2.0;
    c += texture(src_tex, UV - vec2(0.0, px.y)) * 2.0;
    c += texture(src_tex, UV + px) * 1.0;
    c += texture(src_tex, UV - px) * 1.0;
    c += texture(src_tex, UV + vec2(px.x, -px.y)) * 1.0;
    c += texture(src_tex, UV + vec2(-px.x, px.y)) * 1.0;
    COLOR = c / 16.0;
}
