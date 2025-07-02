shader_type canvas_item;

uniform vec4 color_top = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 color_bottom = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 rim_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float rim_width = 0.15;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = length(UV - center) * 2.0;
    float rim = smoothstep(1.0 - rim_width, 1.0, dist);
    vec4 base = mix(color_top, color_bottom, UV.y);
    COLOR = base + rim * rim_color;
}
