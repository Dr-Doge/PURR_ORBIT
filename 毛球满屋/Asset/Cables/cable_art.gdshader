shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 region=vec4(0.0,0.0,1.0,1.0);
void fragment(){
 vec4 c=texture(art,region.xy+UV*region.zw);
 if(c.a<0.5) discard;
 ALBEDO=c.rgb; ROUGHNESS=1.0;
}
