shader_type canvas_item;

uniform sampler2D heightmap;
uniform vec2 tex_size = vec2(64.0, 64.0);
uniform float height_scale = 8.0;
uniform vec3 light_dir = vec3(-0.2491, -0.4983, 0.8305);
uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

void fragment() {
    vec2 px = 1.0 / tex_size;
    float hx1 = texture(heightmap, UV + vec2(px.x, 0.0)).r;
    float hx0 = texture(heightmap, UV - vec2(px.x, 0.0)).r;
    float hy1 = texture(heightmap, UV + vec2(0.0, px.y)).r;
    float hy0 = texture(heightmap, UV - vec2(0.0, px.y)).r;
    vec3 normal = normalize(vec3((hx1 - hx0) * height_scale, (hy1 - hy0) * height_scale, 1.0));
    float diff = max(dot(normal, light_dir), 0.0);
    vec4 base = mix(bottom_color, top_color, UV.y);
    float rim = smoothstep(0.8, 1.0, 1.0 - length(UV * 2.0 - vec2(1.0)));
    vec3 lighting = base.rgb * (0.3 + 0.7 * diff) + rim;
    COLOR = vec4(lighting, base.a);
}
