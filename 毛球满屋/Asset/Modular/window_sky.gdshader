shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D wall_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D universe_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool mirror_uv = false;
uniform vec2 wall_uv_scale = vec2(1.0);
uniform vec4 glass_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D glass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float glass_strength : hint_range(0.0, 0.3) = 0.12;
uniform float glass_edge_strength : hint_range(0.0, 0.3) = 0.09;
void fragment() {
    vec2 wall_uv = vec2(mirror_uv ? 1.0-UV.x : UV.x, UV.y) * wall_uv_scale;
    vec4 wall = texture(wall_texture, wall_uv);
    vec2 screen_size = VIEWPORT_SIZE;
    vec2 image_size = vec2(textureSize(universe_texture,0));
    vec2 p = (SCREEN_UV - vec2(0.5,0.58)) * screen_size;
    float a = TIME * 0.006;
    p = mat2(vec2(cos(a),-sin(a)),vec2(sin(a),cos(a))) * p;
    float scale = 0.8 * 2.0 * length(screen_size * vec2(0.5,0.58)) / min(image_size.x,image_size.y);
    vec3 sky = texture(universe_texture, p / (image_size*scale) + vec2(0.5)).rgb;
    float opening = 1.0 - wall.a;
    // Reflection is fixed to the window, independent of the rotating sky.
    // Use unmirrored UVs so both panes share the same reflection direction.
    vec2 glass_uv = glass_region.xy + UV * glass_region.zw;
    vec4 glass = texture(glass_texture, glass_uv);
    vec2 texel = 1.5 / vec2(textureSize(wall_texture, 0));
    float edge = max(max(texture(wall_texture, wall_uv + vec2(texel.x,0.0)).a,
                         texture(wall_texture, wall_uv - vec2(texel.x,0.0)).a),
                     max(texture(wall_texture, wall_uv + vec2(0.0,texel.y)).a,
                         texture(wall_texture, wall_uv - vec2(0.0,texel.y)).a));
    float edge_accent = 1.0 - smoothstep(0.12, 0.45, wall_uv.y);
    // Generated artwork already has faint alpha: normalize before applying display opacity.
    float reflection_mask = clamp(glass.a / 0.22, 0.0, 1.0);
    float border_distance = min(min(glass_uv.x - 0.114, 0.886 - glass_uv.x), min(glass_uv.y - 0.12, 0.48 - glass_uv.y));
    float border_boost = 1.0 + 0.4 * (1.0 - smoothstep(0.0, 0.055, border_distance));
    float glass_alpha = clamp(reflection_mask * glass_strength * border_boost + edge * glass_edge_strength * edge_accent, 0.0, 0.22);
    sky = mix(sky, vec3(0.86, 0.83, 0.76), glass_alpha);
    ALBEDO = wall.rgb * wall.a;
    EMISSION = sky * opening;
    ROUGHNESS = 0.95;
}
