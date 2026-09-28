shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D universe : source_color, filter_linear, repeat_disable;
uniform sampler2D wall_texture : source_color, filter_linear, repeat_disable;
uniform float orbit_angle = 0.0;
uniform vec2 canvas_size = vec2(1440.0, 900.0);
void fragment() {
 // Match the source aspect ratio to the projected back wall, cropping vertically.
 float visible_y=clamp((UV.y-0.717431)/0.282569,0.0,1.0);
 vec2 wall_size=vec2(textureSize(wall_texture,0));
 float span=(0.28*canvas_size.y)/(0.901*canvas_size.x)*(wall_size.x/wall_size.y);
 vec2 wall_uv=vec2(UV.x,0.39+(visible_y-0.5)*span);
 vec3 cabin=texture(wall_texture,wall_uv).rgb;
 // One continuous, aspect-correct image behind every window. Rotate in pixels
 // around the lower canvas centre, then convert into the source image's UVs.
 vec2 p = (SCREEN_UV - vec2(0.5,0.58)) * canvas_size;
 vec2 source_size = vec2(textureSize(universe, 0));
 float radius = length(canvas_size * vec2(0.5,0.58));
 float image_scale = 2.0 * radius / min(source_size.x, source_size.y);
 float c=cos(orbit_angle);
 float s=sin(orbit_angle);
 vec3 sky=texture(universe, mat2(vec2(c,-s),vec2(s,c))*p/(source_size*image_scale)+vec2(0.5)).rgb;
 bool column=(wall_uv.x>0.061 && wall_uv.x<0.277) || (wall_uv.x>0.349 && wall_uv.x<0.652) || (wall_uv.x>0.722 && wall_uv.x<0.941);
 bool window=column && wall_uv.y>0.262 && wall_uv.y<0.516;
 float opening=window ? 1.0-smoothstep(0.003,0.025,max(cabin.r,max(cabin.g,cabin.b))) : 0.0;
 ALBEDO=cabin*(1.0-opening);
 EMISSION=sky*opening;
 ROUGHNESS=0.9;
}
