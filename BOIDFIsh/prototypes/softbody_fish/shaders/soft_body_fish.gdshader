###############################################################
# BOIDFIsh/prototypes/softbody_fish/shaders/soft_body_fish.gdshader
# Key Functions    • fragment() – lit with dynamic pillow normal map
# Dependencies     • heightmap_blur.gdshader
# Last Major Rev   • 24-05-06 – added pillow shading
###############################################################

shader_type canvas_item;

uniform sampler2D heightmap_tx;
uniform vec2 heightmap_texel = vec2(0.01, 0.01);
uniform float height_scale = 4.0;
uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

vec3 fb_compute_normal(vec2 uv) {
    float hx1 = texture(heightmap_tx, uv + vec2(heightmap_texel.x, 0.0)).r;
    float hx0 = texture(heightmap_tx, uv - vec2(heightmap_texel.x, 0.0)).r;
    float hy1 = texture(heightmap_tx, uv + vec2(0.0, heightmap_texel.y)).r;
    float hy0 = texture(heightmap_tx, uv - vec2(0.0, heightmap_texel.y)).r;
    vec2 grad = vec2(hx1 - hx0, hy1 - hy0) * height_scale;
    return normalize(vec3(grad, 1.0));
}

void fragment() {
    vec3 n = fb_compute_normal(UV);
    vec3 light = normalize(vec3(-0.5, -0.5, 1.0));
    float diff = clamp(dot(n, light), 0.0, 1.0);
    float rim = pow(1.0 - diff, 2.0);
    vec4 col = mix(bottom_color, top_color, UV.y);
    col.rgb *= diff * 0.8 + 0.2;
    col.rgb += rim * 0.3;
    COLOR = col;
}
