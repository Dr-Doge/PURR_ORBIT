shader_type canvas_item;
uniform sampler2D remaining_mask : filter_linear, repeat_disable;
uniform sampler2D body_mask : filter_nearest, repeat_disable;
uniform sampler2D coat_map : source_color, filter_linear, repeat_disable;
uniform vec4 region_in_body;
uniform bool match_coat = false;
uniform bool preserve_outline = false;
uniform float loosen = 1.0;
void fragment() {
 vec4 ink=texture(TEXTURE,UV)*COLOR;
 vec2 body_uv=region_in_body.xy+UV*region_in_body.zw;
 float valid=0.0;
 if (all(greaterThanEqual(body_uv,vec2(0.0))) && all(lessThanEqual(body_uv,vec2(1.0)))) {
  valid=texture(body_mask,body_uv).r;
  vec4 coat=texture(coat_map,body_uv);
  if (match_coat && coat.a>0.2) {
   float light=dot(ink.rgb,vec3(0.299,0.587,0.114));
   if (!(preserve_outline && light<0.18)) {
    // Keep hairlock relief, but not the atlas's incompatible grey/white pigment.
    float relief=clamp(1.0+(light-0.65)*0.16,0.92,1.04);
    ink.rgb=coat.rgb*relief;
   }
  }
 }
 ink.a*=texture(remaining_mask,UV).r*valid*loosen;
 COLOR=ink;
}
