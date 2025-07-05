shader_type canvas_item;

uniform sampler2D distance_map;
uniform vec4 edge_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 center_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform float stroke_width : hint_range(0.01, 1.0) = 0.25;
uniform float ring_spacing : hint_range(0.0, 20.0) = 0.0;
uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

void fragment() {
    vec2 px = 1.0 / vec2(textureSize(distance_map, 0));
    float d = texture(distance_map, UV).r * 4.0;
    d += texture(distance_map, UV + vec2(1.0, 0.0) * px).r;
    d += texture(distance_map, UV + vec2(-1.0, 0.0) * px).r;
    d += texture(distance_map, UV + vec2(0.0, 1.0) * px).r;
    d += texture(distance_map, UV + vec2(0.0, -1.0) * px).r;
    d += texture(distance_map, UV + vec2(1.0, 1.0) * px).r;
    d += texture(distance_map, UV + vec2(-1.0, -1.0) * px).r;
    d += texture(distance_map, UV + vec2(1.0, -1.0) * px).r;
    d += texture(distance_map, UV + vec2(-1.0, 1.0) * px).r;
    d /= 12.0;
    d = clamp(d, 0.0, 1.0);
    if (ring_spacing > 0.0) {
        d = fract(d * ring_spacing);
    }
    float t = smoothstep(0.0, stroke_width, d);
    vec4 stroke_col = mix(edge_color, center_color, t);

    vec4 body_col = mix(bottom_color, top_color, UV.y);
    float rim = smoothstep(0.8, 1.0, 1.0 - length(UV * 2.0 - vec2(1.0)));
    COLOR = body_col * stroke_col + vec4(vec3(rim), 0.0);
}
