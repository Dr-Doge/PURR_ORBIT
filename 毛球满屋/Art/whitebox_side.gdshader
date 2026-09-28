shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D wall_texture : source_color, filter_linear, repeat_disable;
uniform float contrast : hint_range(0.0, 1.0) = 0.55;
uniform float brightness : hint_range(0.0, 1.0) = 0.65;
void fragment() {
 vec3 color = texture(wall_texture, UV).rgb;
 ALBEDO = mix(vec3(0.22), color, contrast) * brightness;
 ROUGHNESS = 0.95;
}
