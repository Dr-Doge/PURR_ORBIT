shader_type canvas_item;
render_mode unshaded;

// Preserve the original pixel-art bezel while opening its opaque screen fill.
// Dimensions describe UI_Image_Mobile.png (512 x 984), not the game window.
void fragment() {
	vec4 artwork = texture(TEXTURE, UV) * COLOR;
	vec2 pixel = UV * vec2(512.0, 984.0);
	vec2 center = vec2(258.0, 492.0);
	vec2 half_size = vec2(210.0, 452.0);
	float radius = 24.0;
	vec2 q = abs(pixel - center) - (half_size - vec2(radius));
	float distance_to_screen = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	if (distance_to_screen < 0.0) artwork.a = 0.0;
	COLOR = artwork;
}
