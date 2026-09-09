shader_type canvas_item;
render_mode unshaded;

uniform sampler2D soil_mask : filter_nearest, repeat_disable;

void fragment() {
	vec4 soil = texture(TEXTURE, UV);
	soil.a *= texture(soil_mask, UV).r;
	COLOR = soil;
}
