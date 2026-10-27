// A Dhull's face, drawn over its head as an overlay (GeometryInstance3D.material_overlay): a pair
// of eyes and a mouth, each picked from a strip of drawings, like Wind Waker's swappable face
// textures. The drawings are imported small and shown with hard pixels, so they read as crunchy
// painted textures, like a PS1 character's. They're projected straight onto the front (+Z) of the head, so the head needs no
// special UVs. Each Dhull picks its own drawings through the instance uniforms eye_frame and
// mouth_frame (see DhullFace for the order); a mouth_frame below 0 shows no mouth.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_back, shadows_disabled;

uniform sampler2D eyes : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2D mouths : source_color, filter_nearest_mipmap, repeat_disable;
uniform int eye_frames = 10;
uniform int mouth_frames = 2;
// Where the eyes and the mouth sit on the front of the head, in meters from the head's middle,
// and how wide and tall each drawing is.
uniform vec2 eyes_center = vec2(0.0, -0.025);
uniform vec2 eyes_size = vec2(0.44, 0.275);
uniform vec2 mouth_center = vec2(0.0, -0.155);
uniform vec2 mouth_size = vec2(0.17, 0.085);
// Fixed instance slots 4-5, apart from the clay's (clay.gdshader) on the same head.
instance uniform int eye_frame : instance_index(4) = 0;
instance uniform int mouth_frame : instance_index(5) = 0;

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

vec4 feature(sampler2D strip, int frame, int frames, vec2 center, vec2 size) {
	vec2 uv = (head_position.xy - center) / size + 0.5;
	uv.y = 1.0 - uv.y;
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	vec2 strip_uv = vec2((clamp(uv.x, 0.0, 1.0) + float(frame)) / float(frames), clamp(uv.y, 0.0, 1.0));
	return texture(strip, strip_uv) * inside.x * inside.y;
}

void fragment() {
	vec4 eye = feature(eyes, eye_frame, eye_frames, eyes_center, eyes_size);
	vec4 mouth = mouth_frame < 0 ? vec4(0.0) : feature(mouths, mouth_frame, mouth_frames, mouth_center, mouth_size);
	vec4 face = mix(mouth, eye, eye.a);
	ALBEDO = face.rgb;
	// Only on the front of the head, not projected through to the back.
	ALPHA = face.a * step(0.0, facing_forward);
}
