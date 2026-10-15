shader_type canvas_item;
uniform sampler2D remaining_mask : filter_linear, repeat_disable;
uniform sampler2D body_mask : filter_nearest, repeat_disable;
uniform vec4 region_in_body;
uniform float loosen = 1.0;
void fragment() {
 vec4 ink = texture(TEXTURE, UV) * COLOR;
 vec2 body_uv = region_in_body.xy + UV * region_in_body.zw;
 float valid = 0.0;
 if (body_uv.x >= 0.0 && body_uv.x <= 1.0 && body_uv.y >= 0.0 && body_uv.y <= 1.0) {
  valid = texture(body_mask, body_uv).r;
 }
 ink.a *= texture(remaining_mask, UV).r * valid * loosen;
 COLOR = ink;
}
