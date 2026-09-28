shader_type spatial;
render_mode cull_disabled, specular_disabled, shadows_disabled;
uniform sampler2D frame_texture : source_color, filter_linear, repeat_disable;
uniform bool mirrored = false;
void fragment() {
 // Bounds of the current 1254px PNG, including the full foot and metal bevels.
 vec2 uv=vec2(mix(0.421,0.579,mirrored ? 1.0-UV.x : UV.x),mix(0.024,0.973,UV.y));
 vec3 color=texture(frame_texture,uv).rgb;
 if(max(color.r,max(color.g,color.b))<0.06) discard;
 float foot_shade=1.0-0.12*smoothstep(0.94,1.0,UV.y);
 float luminance=dot(color,vec3(0.2126,0.7152,0.0722));
 vec3 warm_metal=mix(color,vec3(luminance)*vec3(1.06,1.0,0.90),0.7);
 ALBEDO=warm_metal*0.86*foot_shade;
 ROUGHNESS=0.9;
}
