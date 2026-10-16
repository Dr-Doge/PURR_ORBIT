shader_type canvas_item;
uniform sampler2D remaining_mask : filter_linear, repeat_disable;
uniform float opacity=1.0;
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 // Source alpha once; configurable opacity is visual only, never remaining work.
 vec4 ink=texture(TEXTURE,UV)*vertex_tint;
 ink.a*=opacity*texture(remaining_mask,UV).r;
 COLOR=ink;
}
