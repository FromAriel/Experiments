shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec2 shape_aspect = vec2(1.0, 1.0);

void fragment() {
    vec2 local = (UV - vec2(0.5)) * 2.0 * shape_aspect;
    vec2 scaled = local * vec2(0.6, 1.0);
    float z = sqrt(max(0.0, 1.0 - dot(scaled, scaled)));
    vec3 normal = normalize(vec3(scaled, z));
    vec3 light_dir = normalize(vec3(-0.3, -0.4, 0.9));
    float diff = clamp(dot(normal, light_dir), 0.0, 1.0);
    float rim = smoothstep(0.8, 1.0, 1.0 - length(local));
    vec4 col = mix(bottom_color, top_color, UV.y);
    vec3 lit = col.rgb * diff + vec3(rim);
    COLOR = vec4(lit, col.a);
}
