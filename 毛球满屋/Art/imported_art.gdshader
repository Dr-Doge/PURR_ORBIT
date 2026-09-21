shader_type canvas_item;
render_mode unshaded;
void fragment() {
 vec4 pixel = texture(TEXTURE,UV);
 float low = min(pixel.r,min(pixel.g,pixel.b));
 float high = max(pixel.r,max(pixel.g,pixel.b));
 // The supplied PNGs contain an opaque grey checkerboard, rather than alpha.
 float checker = smoothstep(0.72,0.80,low)*(1.0-smoothstep(0.035,0.075,high-low));
 COLOR.a *= 1.0-checker;
}
