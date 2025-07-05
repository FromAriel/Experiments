shader_type canvas_item;

uniform sampler2D mask_tex : hint_default_white;
uniform float stroke_width : hint_range(0.01, 0.5) = 0.15;
uniform bool rings = false;
uniform vec4 edge_color : source_color = vec4(0.1, 0.4, 0.8, 1.0);
uniform vec4 center_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float ring_frequency : hint_range(1.0, 20.0) = 6.0;
uniform float ring_fade : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    vec2 uv = UV;
    vec2 texel = 1.0 / vec2(textureSize(mask_tex, 0));
    float sum = 0.0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            sum += texture(mask_tex, uv + vec2(float(x), float(y)) * texel).r;
        }
    }
    float dist = sum / 25.0;
    float d = smoothstep(0.0, stroke_width, dist);
    vec4 col = mix(edge_color, center_color, d);
    if (rings) {
        float t = fract(dist * ring_frequency);
        float ring = smoothstep(0.0, ring_fade, t) * (1.0 - smoothstep(1.0 - ring_fade, 1.0, t));
        col.rgb = mix(col.rgb, vec3(1.0), ring);
    }
    COLOR = col * dist;
}
