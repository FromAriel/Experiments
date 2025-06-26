shader_type canvas_item;

uniform vec2 u_light_dir = vec2(0.0, -1.0);
uniform sampler2D normal_tex : hint_normal;
uniform vec4 u_highlight = vec4(1.0);
uniform vec4 u_lowlight = vec4(0.2, 0.3, 0.4, 1.0);
uniform vec4 u_backscatter = vec4(1.0, 0.3, 0.2, 1.0);
uniform float u_puff_intensity = 0.0;

void vertex() {
    vec3 n = texture(normal_tex, UV).rgb * 2.0 - 1.0;
    if (u_puff_intensity > 0.0) {
        VERTEX += n.xy * u_puff_intensity;
    }
}

void fragment() {
    vec4 albedo = texture(TEXTURE, UV);
    vec3 n = normalize(texture(normal_tex, UV).rgb * 2.0 - 1.0);
    vec3 l = normalize(vec3(u_light_dir, 0.0));
    float ndotl = dot(n, l);
    float diffuse = max(ndotl, 0.0);
    vec4 color = mix(albedo, u_highlight, diffuse * diffuse);
    color = mix(color, u_lowlight, pow(1.0 - diffuse, 2.0));
    if (ndotl < 0.0) {
        color = mix(color, u_backscatter, -ndotl);
    }
    COLOR = color;
}
