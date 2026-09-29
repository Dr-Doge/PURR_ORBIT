shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D universe : source_color, filter_linear, repeat_disable;
uniform sampler2D wall_texture : source_color, filter_linear, repeat_disable;
uniform float orbit_angle = 0.0;
uniform vec2 canvas_size = vec2(1440.0, 900.0);
uniform vec4 rim_color : source_color = vec4(0.66,0.65,0.63,1.0);
uniform float rim_width = 2.0;
// Select only the three panes, then follow the painted inner edge, including
// its clipped corners and small irregularities. The generous luminance threshold
// removes JPEG noise inside the dark panes without imposing a rectangular border.
float pane_mask(vec2 uv) {
 vec2 pixel=uv*vec2(1024.0,572.0);
 bool column=(pixel.x>61.0 && pixel.x<285.0) || (pixel.x>355.0 && pixel.x<669.0) || (pixel.x>738.0 && pixel.x<966.0);
 if (!column || pixel.y<148.0 || pixel.y>298.0) { return 0.0; }
 bool interior=(pixel.x>69.0 && pixel.x<277.0) || (pixel.x>363.0 && pixel.x<661.0) || (pixel.x>746.0 && pixel.x<958.0);
 if (interior && pixel.y>158.0 && pixel.y<289.0) { return 1.0; }
 vec3 color=texture(wall_texture,uv).rgb;
 return 1.0-smoothstep(0.045,0.09,max(color.r,max(color.g,color.b)));
}
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
 float pane=pane_mask(wall_uv);
 float opening=pane;
 vec2 texel=1.0/wall_size;
 for (int i=0;i<8;i++) {
  float angle=float(i)*0.78539816339;
  opening=min(opening,pane_mask(wall_uv+vec2(cos(angle),sin(angle))*texel*rim_width));
 }
 float rim=max(pane-opening,0.0);
 // The inset lip stays matte and lit; only the sky emits light.
 ALBEDO=cabin*(1.0-pane)+rim_color.rgb*rim;
 EMISSION=sky*opening;
 ROUGHNESS=0.9;
}
