shader_type canvas_item;

uniform sampler2D distance_map;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 center_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform float stroke_width : hint_range(0.01, 1.0) = 0.2;
uniform float ring_spacing : hint_range(0.05, 0.5) = 0.25;
uniform bool rings = false;

float sample_blur(vec2 uv) {
    vec2 tex_size = vec2(textureSize(distance_map, 0));
    vec2 texel = 1.0 / tex_size;
    float sum = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            sum += texture(distance_map, uv + vec2(float(x), float(y)) * texel).r;
        }
    }
    return sum / 9.0;
}

void fragment() {
    float d = sample_blur(UV);
    if (rings) {
        float mod_val = fract(d / max(ring_spacing, 0.01));
        COLOR = mix(edge_color, center_color, mod_val) * d;
    } else {
        float t = smoothstep(1.0 - stroke_width, 1.0, d);
        COLOR = mix(edge_color, center_color, t) * d;
    }
}
