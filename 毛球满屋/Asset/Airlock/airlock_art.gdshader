shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 region=vec4(0.0,0.0,1.0,1.0);
uniform float lamp_emission=0.0;
uniform bool mirror=false;
uniform bool flip_y=false;
uniform bool fill_leaf=false;
uniform sampler2D frame_mask : filter_linear;
uniform vec4 opening_bounds;
uniform vec4 frame_region=vec4(0.0031897927,0.0119617225,0.994417863,0.975279107);
uniform bool sliding=false;
uniform bool clip_ready=false;
uniform mat4 portal_inverse;
uniform float portal_half_width=1.52;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 if(sliding && clip_ready){
 vec2 p=(portal_inverse*vec4(world_pos,1.0)).xy;
 if(p.x<opening_bounds.x || p.y<opening_bounds.y || p.x>opening_bounds.z || p.y>opening_bounds.w) discard;
 vec2 fuv=vec2(p.x/3.7754125+0.5,0.5-(p.y-2.065929)/4.131858);
 if(texture(frame_mask,frame_region.xy+fuv*frame_region.zw).a>=0.5) discard;
 }
 vec2 uv=vec2(mirror?1.0-UV.x:UV.x,flip_y?1.0-UV.y:UV.y);
 vec4 c=texture(art,region.xy+uv*region.zw);
 if(c.a<0.5){ if(fill_leaf) c=texture(art,region.xy+vec2(0.5,0.6)*region.zw); else discard; }
 float glow=lamp_emission*smoothstep(0.4,0.8,c.r)*smoothstep(0.08,0.3,c.r-c.b);
 ALBEDO=c.rgb*(1.0-glow); EMISSION=c.rgb*glow; ROUGHNESS=0.95;
}
