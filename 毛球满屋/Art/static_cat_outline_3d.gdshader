shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_never;
uniform sampler2D frame_texture : source_color, filter_nearest, repeat_disable;
uniform float pulse = 1.0;
uniform float thin_width = 2.0;
void fragment() {
 float center = texture(frame_texture, UV).a;
 float outer = 0.0;
 float inner = 0.0;
 vec2 texel = 1.0 / vec2(textureSize(frame_texture, 0));
 for (int i=0; i<8; i++) {
  float angle = float(i)*0.78539816339;
  vec2 axis = vec2(cos(angle),sin(angle))*texel;
  outer = max(outer, texture(frame_texture, UV+axis*5.6).a);
  inner = max(inner, texture(frame_texture, UV+axis*thin_width).a);
 }
 if (center>0.35 || outer<0.35) { discard; }
 bool fine_edge = thin_width>0.0 && inner>0.35;
 ALBEDO = fine_edge ? vec3(0.18,0.14,0.13) : vec3(0.55,0.88,1.0);
 ALPHA = fine_edge ? 0.85 : clamp(pulse,0.0,1.0);
}
