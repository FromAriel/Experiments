shader_type canvas_item;

uniform sampler2D base_texture : hint_default_black;
uniform vec2 blur_direction = vec2(1.0, 0.0);
uniform vec2 tex_size = vec2(64.0, 64.0);

void fragment() {
    vec2 texel = blur_direction / tex_size;
    vec4 col = texture(base_texture, UV) * 0.227027;
    col += texture(base_texture, UV + texel * 1.384615) * 0.316216;
    col += texture(base_texture, UV - texel * 1.384615) * 0.316216;
    col += texture(base_texture, UV + texel * 3.230769) * 0.070270;
    col += texture(base_texture, UV - texel * 3.230769) * 0.070270;
    COLOR = col;
}
