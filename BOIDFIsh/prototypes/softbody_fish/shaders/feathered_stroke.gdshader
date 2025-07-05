shader_type canvas_item;

uniform sampler2D distance_map : hint_white;
uniform vec4 edge_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 center_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform float stroke_width : hint_range(0.01, 1.0) = 0.25;
uniform float ring_spacing : hint_range(0.01, 1.0) = 0.0;
uniform bool use_rings = false;

void fragment() {
    float d = texture(distance_map, UV).r;
    float grad = smoothstep(0.0, stroke_width, d);
    vec4 col = mix(edge_color, center_color, grad);
    if (use_rings && ring_spacing > 0.0001) {
        float ring = fract(d / ring_spacing);
        col = mix(edge_color, center_color, ring);
    }
    COLOR = col;
}
