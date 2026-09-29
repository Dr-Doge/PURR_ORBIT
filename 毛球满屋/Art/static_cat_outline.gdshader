shader_type canvas_item;
render_mode unshaded;
uniform float pulse = 1.0;
void fragment() {
 float center = texture(TEXTURE,UV).a;
 float outer = 0.0;
 float inner = 0.0;
 for (int i=0; i<8; i++) {
  float angle = float(i)*0.78539816339;
  vec2 axis = vec2(cos(angle),sin(angle))*TEXTURE_PIXEL_SIZE;
  outer = max(outer,texture(TEXTURE,UV+axis*5.6).a);
  inner = max(inner,texture(TEXTURE,UV+axis*2.0).a);
 }
 bool fine_edge = inner>0.35;
 float alpha = (center>0.35 || outer<0.35) ? 0.0 : (fine_edge ? 0.85 : pulse);
 COLOR = vec4(fine_edge ? vec3(0.18,0.14,0.13) : vec3(0.55,0.88,1.0),alpha);
}
