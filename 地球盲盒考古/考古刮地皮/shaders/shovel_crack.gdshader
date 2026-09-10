shader_type canvas_item;
uniform sampler2D crack_art : source_color;
uniform vec2 world_size = vec2(1096.0,822.0);
uniform vec2 center;
uniform float radius = 72.0;
uniform float progress : hint_range(0.0,1.0) = 0.0;
void fragment() {
	vec2 offset = UV*world_size-center;
	vec2 local_uv = offset/(2.0*radius)+vec2(0.5);
	float stencil = texture(TEXTURE,UV).r;
	// Crop the image's blank margins so its crack footprint fills the dig circle.
	vec2 art_uv = local_uv*vec2(0.70,0.70)+vec2(0.15,0.14);
	vec4 art = texture(crack_art,clamp(art_uv,vec2(0.0),vec2(1.0)));
	// The supplied black decal has a baked light checkerboard: key only its background.
	art.a *= 1.0-smoothstep(0.18,0.65,max(art.r,max(art.g,art.b)));
	COLOR=vec4(art.rgb,art.a*stencil*progress*step(length(offset),radius));
}
