shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

uniform sampler2D heightmap : hint_default_black;
uniform vec2 heightmap_size = vec2(64.0, 64.0);

void fragment() {
    vec2 texel = 1.0 / heightmap_size;
    float c = texture(heightmap, UV).r;
    float r = texture(heightmap, UV + vec2(texel.x, 0.0)).r;
    float u = texture(heightmap, UV + vec2(0.0, texel.y)).r;
    vec3 normal = normalize(vec3((c - r) * 2.0, (c - u) * 2.0, 1.0));
    vec3 light_dir = normalize(vec3(-0.3, -0.5, 1.0));
    float lit = clamp(dot(normal, light_dir), 0.0, 1.0);
    float rim = smoothstep(0.8, 1.0, 1.0 - length(UV * 2.0 - vec2(1.0)));
    vec4 col = mix(bottom_color, top_color, UV.y);
    col.rgb *= mix(0.5, 1.2, lit);
    COLOR = col + vec4(vec3(rim), 0.0);
}
