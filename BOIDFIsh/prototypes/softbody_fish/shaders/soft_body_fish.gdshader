shader_type canvas_item;

uniform sampler2D heightmap : hint_default_black;
uniform float normal_strength = 2.0;
uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

void fragment() {
    vec2 texel = 1.0 / vec2(textureSize(heightmap, 0));
    float center = texture(heightmap, UV).r;
    float right = texture(heightmap, UV + vec2(texel.x, 0.0)).r;
    float left = texture(heightmap, UV - vec2(texel.x, 0.0)).r;
    float up = texture(heightmap, UV - vec2(0.0, texel.y)).r;
    float down = texture(heightmap, UV + vec2(0.0, texel.y)).r;
    vec3 n = normalize(vec3((right - left) * normal_strength, (down - up) * normal_strength, 1.0));
    vec3 light = vec3(0.0, 0.0, 1.0);
    float diff = max(dot(n, light), 0.0);
    vec4 col = mix(bottom_color, top_color, UV.y);
    float rim = smoothstep(0.8, 1.0, 1.0 - length(UV * 2.0 - vec2(1.0)));
    COLOR = vec4(col.rgb * diff, col.a) + vec4(vec3(rim), 0.0);
}
