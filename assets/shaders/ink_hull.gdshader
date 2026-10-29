// An ink outline grown around a character's part, for characters the screen-wide InkOutlines
// miss: a small Dhull in front of the ground makes too small a jump in depth for those lines.
// It draws the part's back faces in ink, pushed out by the same width on screen as InkOutlines'
// lines, so only a rim shows around the part, and each separate part gets its own.
//
// The low-poly parts are flat-shaded, so their normals split at every corner and pushing along
// them would crack the outline open. Instead each vertex is pushed straight out from the part's
// middle, outline_center, which suits the round, blobby parts. Use it as the next pass of the
// part's material.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 ink : source_color = vec4(0.07, 0.04, 0.1, 1.0);
// Outline width in pixels on a screen 1080 pixels tall, as InkOutlines' line_width.
uniform float line_width : hint_range(0.5, 8.0) = 2.5;
// The part's middle in its own space. Fixed instance slot 8, after the character and face
// shaders' slots on the same part.
instance uniform vec3 outline_center : instance_index(8) = vec3(0.0);

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 outward = (MODELVIEW_MATRIX * vec4(normalize(VERTEX - outline_center), 0.0)).xyz;
	vec2 push = (PROJECTION_MATRIX * vec4(outward, 0.0)).xy;
	if (length(push) > 0.0) {
		push = normalize(push) * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
	}
	// Clip space runs 2 across the screen; scaled by w, the push stays the same on screen at
	// any distance.
	clip.xy += push * line_width / 1080.0 * 2.0 * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink.rgb;
}
