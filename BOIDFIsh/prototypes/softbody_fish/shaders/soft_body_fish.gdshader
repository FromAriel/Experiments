###############################################################
# BOIDFIsh/prototypes/softbody_fish/shaders/soft_body_fish.gdshader
# Key Classes      • (shader) – adds fake 3-D shading to fish body
# Key Functions    • fragment() – bulges centre using UV extents
# Critical Consts  • none
# Editor Exports   • top_color, bottom_color
# Dependencies     • SoftBodyFish.gd provides UV bounds
# Last Major Rev   • 24-05-?? – fake normal shading added
###############################################################

shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec2 uv_center = vec2(0.5, 0.5);
uniform vec2 uv_extents = vec2(1.0, 1.0);
uniform float bulge_y = 1.0;
uniform float bulge_x = 0.6;
uniform vec3 light_dir = vec3(0.0, -0.5, 0.8);

void fragment() {
    vec2 delta = (UV - uv_center) / uv_extents;
    float r = length(delta);
    float bulge = max(0.0, 1.0 - r);
    vec3 normal = normalize(vec3(delta.x * bulge_x, delta.y * bulge_y, bulge));
    float lighting = clamp(dot(normal, normalize(light_dir)), 0.0, 1.0);
    vec4 col = mix(bottom_color, top_color, clamp(delta.y * 0.5 + 0.5, 0.0, 1.0));
    float highlight = bulge * bulge;
    COLOR = vec4(col.rgb * lighting + vec3(highlight), col.a);
}
