shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec2 uv_center = vec2(0.5, 0.5);
uniform vec2 uv_size = vec2(1.0, 1.0);
uniform float bulge_y = 1.0;
uniform float bulge_x = 0.5;
uniform vec3 light_dir = normalize(vec3(-0.3, -0.5, 1.0));

void fragment() {
    vec2 local = (UV - uv_center) / (uv_size * 0.5);
    local = clamp(local, vec2(-1.0), vec2(1.0));
    vec2 ellip = vec2(local.x * bulge_x, local.y * bulge_y);
    float radial = clamp(1.0 - dot(ellip, ellip), 0.0, 1.0);
    vec3 normal = normalize(vec3(ellip, sqrt(radial)));
    float diff = max(dot(normal, light_dir), 0.0);
    float rim = pow(1.0 - radial, 2.0);
    vec4 col = mix(bottom_color, top_color, UV.y);
    COLOR = col * (0.4 + 0.6 * diff) + vec4(vec3(rim), 0.0);
}
