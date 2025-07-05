###############################################################
# BOIDFIsh/prototypes/softbody_fish/shaders/heightmap_blur.gdshader
# Key Functions    • fragment() – single-pass Gaussian blur
# Last Major Rev   • 24-05-06 – initial version
###############################################################

shader_type canvas_item;

uniform sampler2D source_tex;
uniform vec2 inv_size = vec2(0.01, 0.01);

void fragment() {
    vec2 uv = UV;
    vec4 col = texture(source_tex, uv) * 0.227027;
    col += texture(source_tex, uv + vec2(inv_size.x, 0.0)) * 0.316216;
    col += texture(source_tex, uv - vec2(inv_size.x, 0.0)) * 0.316216;
    col += texture(source_tex, uv + vec2(0.0, inv_size.y)) * 0.316216;
    col += texture(source_tex, uv - vec2(0.0, inv_size.y)) * 0.316216;
    col += texture(source_tex, uv + vec2(inv_size.x * 2.0, 0.0)) * 0.070270;
    col += texture(source_tex, uv - vec2(inv_size.x * 2.0, 0.0)) * 0.070270;
    col += texture(source_tex, uv + vec2(0.0, inv_size.y * 2.0)) * 0.070270;
    col += texture(source_tex, uv - vec2(0.0, inv_size.y * 2.0)) * 0.070270;
    COLOR = col;
}
