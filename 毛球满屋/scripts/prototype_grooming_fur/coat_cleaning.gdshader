shader_type canvas_item;
uniform sampler2D remaining_mask : filter_linear, repeat_disable;
uniform sampler2D body_mask : filter_nearest, repeat_disable;
uniform sampler2D coat_map : source_color, filter_linear, repeat_disable;
uniform vec4 region_in_body;
uniform float patch_angle = 0.0;
uniform bool match_coat = false;
uniform bool complete_sprite = false;
uniform bool preserve_outline = false;
uniform float loosen = 1.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
void fragment() {
 // Fragment COLOR already includes the texture in Godot; sampling it twice
 // squares source alpha and damages semi-transparent hair edges.
 vec4 ink=texture(TEXTURE,UV)*vertex_tint;
 vec2 offset=(UV-vec2(0.5))*region_in_body.zw;
 // Rotate in logical pixels before converting back to body UV (non-square cat).
 vec2 body_pixels=vec2(textureSize(coat_map,0));
 offset*=body_pixels;
 float c=cos(patch_angle),s=sin(patch_angle);
 offset=vec2(c*offset.x-s*offset.y,s*offset.x+c*offset.y)/body_pixels;
 vec2 body_uv=region_in_body.xy+region_in_body.zw*0.5+offset;
 float valid=preserve_outline ? 1.0 : 0.0;
 if (all(greaterThanEqual(body_uv,vec2(0.0))) && all(lessThanEqual(body_uv,vec2(1.0)))) {
  valid=texture(body_mask,body_uv).r;
  vec4 coat=texture(coat_map,body_uv);
  if (match_coat && coat.a>0.2) {
   float light=dot(ink.rgb,vec3(0.299,0.587,0.114));
   if (!(preserve_outline && light<0.18)) {
    // Keep hairlock relief, but not the atlas's incompatible grey/white pigment.
    float relief=clamp(0.87+(light-0.65)*0.28,0.74,0.94);
    ink.rgb=coat.rgb*relief;
   }
  }
 }
 if (complete_sprite) { valid=1.0; }
 ink.a*=texture(remaining_mask,UV).r*valid*loosen;
 COLOR=ink;
}
