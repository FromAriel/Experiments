shader_type canvas_item;

uniform vec2 body_radius = vec2(1.0, 0.6);
uniform float bulge_power = 2.0;
uniform vec3 light_dir = vec3(0.2, -0.7, 1.0);

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

void fragment() {
    vec2 norm_uv = (UV - vec2(0.5)) / body_radius;
    float dist = length(norm_uv);
    float height = pow(max(1.0 - dist, 0.0), bulge_power);

    vec3 normal = normalize(vec3(norm_uv, height));
    float shade = clamp(dot(normal, normalize(light_dir)), 0.0, 1.0);
    float rim = smoothstep(0.85, 1.0, height);

    vec4 col = mix(bottom_color, top_color, UV.y);
    COLOR = col * (0.6 + 0.4 * shade) + vec4(vec3(rim), 0.0);
}
