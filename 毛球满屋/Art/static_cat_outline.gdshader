shader_type canvas_item;
render_mode unshaded;
uniform float pulse = 1.0;
uniform vec4 edge_color : source_color = vec4(0.55,0.88,1.0,1.0);
void fragment() {
 float center = texture(TEXTURE,UV).a;
 float outer = 0.0;
 for (int i=0; i<8; i++) {
  float angle = float(i)*0.78539816339;
  vec2 delta = vec2(cos(angle),sin(angle))*TEXTURE_PIXEL_SIZE*18.0;
  outer = max(outer,texture(TEXTURE,UV+delta).a);
 }
 COLOR = vec4(edge_color.rgb,outer*(1.0-center)*pulse*edge_color.a);
}
