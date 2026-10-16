shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 region = vec4(0.0,0.0,1.0,1.0);
void fragment() {
 vec4 c=texture(art,region.xy+UV*region.zw);
 float light_mask=max(smoothstep(0.4,0.8,c.r)*smoothstep(0.08,0.3,c.r-c.b), smoothstep(0.55,0.85,min(c.r,c.g)));
 ALBEDO=c.rgb*(1.0-light_mask);
 EMISSION=c.rgb*light_mask;
 ALPHA=c.a;
 ROUGHNESS=1.0;
 SPECULAR=0.0;
}
