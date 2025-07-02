shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.9, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_width = 0.25;

void fragment() {
    float t = UV.y;
    vec4 base = mix(top_color, bottom_color, t);
    float rim = smoothstep(1.0 - rim_width, 1.0, length(UV - vec2(0.5)));
    COLOR = mix(base, rim_color, rim);
}
