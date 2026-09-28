shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D floor_texture : source_color, filter_linear, repeat_disable;
uniform float half_width=4.3636365;
varying vec3 room_position;
void vertex() {
 room_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
 float side_distance=max(0.0,half_width-abs(room_position.x));
 float back_distance=max(0.0,room_position.z+6.91743);
 // Restrained contact darkening stays on the perimeter's metal trim.
 float seam=exp(-min(side_distance,back_distance)/0.10)*0.16;
 float feet=exp(-pow((room_position.z+3.4)/0.18,2.0))
           +exp(-pow((room_position.z-0.9)/0.18,2.0));
 float contact=feet*exp(-pow(side_distance/0.30,2.0))*0.22;
 ALBEDO=texture(floor_texture,UV).rgb*(1.0-seam-contact);
 ROUGHNESS=0.95;
}
