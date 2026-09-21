shader_type canvas_item;
render_mode unshaded;
uniform sampler2D window_mask : filter_linear, repeat_disable;
uniform sampler2D universe : source_color, filter_linear, repeat_disable;
uniform float orbit_angle = 0.0;
uniform vec2 orbit_center = vec2(0.5, 0.68);
void fragment() {
 vec4 cabin = texture(TEXTURE, UV);
 // Mask stays registered to the cabin. Only the sky's sampling coordinates rotate.
 float opening = smoothstep(0.1, 0.9, texture(window_mask, UV).r);
 // Center below the middle of the entire scene, with enough overscan for a full turn.
 vec2 point = (UV - orbit_center) * vec2(1.0, 1536.0/2752.0) * 0.75;
 float c = cos(orbit_angle);
 float s = sin(orbit_angle);
 vec2 sky_uv = mat2(vec2(c,-s),vec2(s,c))*point + vec2(0.5);
 vec3 sky = texture(universe,sky_uv).rgb;
 COLOR = vec4(mix(cabin.rgb,sky,opening),1.0);
}
