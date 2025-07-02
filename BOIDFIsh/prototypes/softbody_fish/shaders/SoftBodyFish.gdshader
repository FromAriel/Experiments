shader_type canvas_item;

uniform vec4 top_color : hint_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 bottom_color : hint_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform vec4 rim_color : hint_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float rim_size : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    float v = UV.y;
    vec4 base = mix(top_color, bottom_color, v);
    float rim = smoothstep(1.0 - rim_size, 1.0, v) + smoothstep(1.0 - rim_size, 1.0, 1.0 - v);
    COLOR = base + rim * rim_color;
}
