// A Dhull's face, drawn over its head as an overlay (GeometryInstance3D.material_overlay): a pair
// of eyes and a mouth, each picked from a strip of drawings, like Wind Waker's swappable face
// textures. The drawings are imported small and shown with hard pixels, so they read as crunchy
// painted textures, like a PS1 character's. They're projected straight onto the front (+Z) of the head, so the head needs no
// special UVs. Each Dhull picks its own drawings through the instance uniforms eye_frame and
// mouth_frame (see DhullFace for the order); a mouth_frame below 0 shows no mouth. The eye strip
// has a row per iris color, and eye_color picks the row (see DhullGenome.EyeColor). A gloomy
// Dhull gets anime-style blue lines down its forehead, behind the eyes, while gloom is above 0.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_back, shadows_disabled;

uniform sampler2D eyes : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2D mouths : source_color, filter_nearest_mipmap, repeat_disable;
uniform int eye_frames = 10;
uniform int eye_colors = 6;
uniform int mouth_frames = 2;
// Where the eyes and the mouth sit on the front of the head, in meters from the head's middle,
// and how wide and tall each drawing is.
uniform vec2 eyes_center = vec2(0.0, -0.025);
uniform vec2 eyes_size = vec2(0.44, 0.275);
uniform vec2 mouth_center = vec2(0.0, -0.155);
uniform vec2 mouth_size = vec2(0.17, 0.085);
// The gloomy lines: their color, where on the forehead they hang and how big the patch is.
uniform vec4 gloom_color : source_color = vec4(0.36, 0.42, 0.95, 1.0);
uniform vec2 gloom_center = vec2(0.0, 0.09);
uniform vec2 gloom_size = vec2(0.4, 0.26);
// How big one of the face drawings' pixels is on the head, in meters, so the gloom is drawn in
// pixels as crunchy as theirs: the eye drawings' width over their width in pixels.
uniform float face_pixel = 0.006875;
// Fixed instance slots 4-7, apart from the character shader's on the same head.
instance uniform int eye_frame : instance_index(4) = 0;
instance uniform int mouth_frame : instance_index(5) = 0;
instance uniform int eye_color : instance_index(6) = 0;
instance uniform float gloom : instance_index(7) = 0.0;

// A 4x4 ordered dither, for shading in pixels the way the eye bags are.
const float BAYER[16] = float[](
		0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

varying vec3 head_position;
varying float facing_forward;

void vertex() {
	head_position = VERTEX;
	facing_forward = NORMAL.z;
	// Lift the face a hair off the head, so it draws over it without flickering. Outward from the
	// head's middle rather than along each face's normal: the head is flat-shaded, and pushing each
	// facet along its own normal would open cracks between them.
	VERTEX += normalize(VERTEX) * 0.002;
}

// A drawing from a strip of frames side by side, in one of its rows.
vec4 feature(sampler2D strip, int frame, int frames, int row, int rows, vec2 center, vec2 size) {
	vec2 uv = (head_position.xy - center) / size + 0.5;
	uv.y = 1.0 - uv.y;
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	vec2 strip_uv = vec2(
			(clamp(uv.x, 0.0, 1.0) + float(frame)) / float(frames),
			(clamp(uv.y, 0.0, 0.999) + float(row)) / float(rows));
	return texture(strip, strip_uv) * inside.x * inside.y;
}

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// Lines down the forehead, every third pixel column, each reaching its own way down from the
// top, over a dithered blue shade that's thickest at the top.
vec4 gloom_lines() {
	vec2 pixel = floor(head_position.xy / face_pixel);
	vec2 uv = (pixel * face_pixel - gloom_center) / gloom_size + 0.5;
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	if (gloom <= 0.0 || inside.x * inside.y == 0.0) {
		return vec4(0.0);
	}
	float reach = 0.45 + 0.5 * hash(pixel.x);
	bool on_line = mod(pixel.x, 3.0) == 0.0 && uv.y > 1.0 - reach;
	int bayer_index = int(mod(pixel.y, 4.0)) * 4 + int(mod(pixel.x, 4.0));
	bool shaded = (BAYER[bayer_index] + 0.5) / 16.0 < uv.y * 0.6 * gloom;
	if (on_line) {
		return vec4(gloom_color.rgb, 1.0);
	}
	return shaded ? vec4(gloom_color.rgb * 0.6, 1.0) : vec4(0.0);
}

void fragment() {
	vec4 eye = feature(eyes, eye_frame, eye_frames, eye_color, eye_colors, eyes_center, eyes_size);
	vec4 mouth = mouth_frame < 0
			? vec4(0.0)
			: feature(mouths, mouth_frame, mouth_frames, 0, 1, mouth_center, mouth_size);
	vec4 face = mix(mouth, eye, eye.a);
	vec4 glum = gloom_lines();
	ALBEDO = mix(glum.rgb, face.rgb, face.a);
	// Only on the front of the head, not projected through to the back.
	ALPHA = (face.a + glum.a * (1.0 - face.a)) * step(0.0, facing_forward);
}
