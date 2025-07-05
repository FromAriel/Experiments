shader_type canvas_item;

uniform sampler2D source_texture : hint_default_black;
uniform vec2 direction = vec2(1.0, 0.0);

void fragment() {
    vec2 texel = 1.0 / vec2(textureSize(source_texture, 0));
    vec2 off = direction * texel;
    vec4 c = texture(source_texture, UV) * 0.227027;
    c += texture(source_texture, UV + off * 1.384615) * 0.316216;
    c += texture(source_texture, UV - off * 1.384615) * 0.316216;
    c += texture(source_texture, UV + off * 3.230769) * 0.070270;
    c += texture(source_texture, UV - off * 3.230769) * 0.070270;
    COLOR = c;
}
