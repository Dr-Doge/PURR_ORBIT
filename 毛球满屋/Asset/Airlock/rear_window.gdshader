shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D wall_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D universe_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
void fragment(){
 vec2 wall_uv=vec2(0.01754,0.02233)+UV*vec2(0.96491,0.94179);
 vec4 wall=texture(wall_texture,wall_uv);
 float window_region=step(0.20,UV.x)*step(UV.x,0.80)*step(0.10,UV.y)*step(UV.y,0.74);
 float opening=(1.0-wall.a)*window_region;
 vec2 image_size=vec2(textureSize(universe_texture,0));
 vec2 p=(SCREEN_UV-vec2(0.5,0.58))*VIEWPORT_SIZE;
 float a=TIME*0.006;
 p=mat2(vec2(cos(a),-sin(a)),vec2(sin(a),cos(a)))*p;
 float scale=0.8*2.0*length(VIEWPORT_SIZE*vec2(0.5,0.58))/min(image_size.x,image_size.y);
 ALBEDO=mix(vec3(0.24,0.22,0.20),wall.rgb,wall.a)*(1.0-opening);
 EMISSION=texture(universe_texture,p/(image_size*scale)+vec2(0.5)).rgb*opening;
 ROUGHNESS=0.95;
}
