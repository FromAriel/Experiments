shader_type canvas_item;

///////////////////////////////////////////////////////////////
// BOIDFIsh/prototypes/softbody_fish/shaders/soft_body_fish.gdshader
// Key Functions    • fragment() – fake 3D lighting for soft-body fish
// Critical Consts  • none
// Editor Exports   • top_color, bottom_color
// Dependencies     • none
// Last Major Rev   • 24-05-05 – added fake normal lighting
///////////////////////////////////////////////////////////////

uniform vec4 top_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.2, 0.4, 0.6, 1.0);

uniform float x_roundness = 0.4; // front/back bulge intensity
uniform float y_roundness = 1.0; // top/bottom bulge intensity
uniform vec3 light_dir = vec3(-0.2, -0.3, 1.0);

void fragment() {
    vec2 local = UV * 2.0 - vec2(1.0);
    vec3 normal = normalize(vec3(local.x * x_roundness, local.y * y_roundness, 1.0));
    float light = max(dot(normal, normalize(light_dir)), 0.0);
    float rim = smoothstep(0.6, 1.0, 1.0 - length(local));
    vec4 col = mix(bottom_color, top_color, UV.y);
    col.rgb *= light * 0.8 + 0.2;
    COLOR = col + vec4(vec3(rim), 0.0);
}
