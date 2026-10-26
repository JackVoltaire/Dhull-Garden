// A flat drawing standing in the 3D world like a cardboard cutout. The texture is a strip of
// frames side by side, with the feet at the bottom middle, and it plays as stepped
// frame-by-frame animation, usually 3 or 4 frames. Use it on a QuadMesh whose bottom edge sits
// at the origin (center_offset.y = half the height) and whose size matches one frame.
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D frames : source_color, filter_linear_mipmap;
uniform int frame_count : hint_range(1, 64) = 4;
// Frames per second. Low rates (3-8) read as drawn animation; 0 holds the first frame.
uniform float fps : hint_range(0.0, 30.0) = 8.0;
// Turn around the vertical axis to face the camera. Off, it stays put like a standee.
uniform bool billboard = true;
// Mirror some copies, picked by position, so repeats look less alike.
uniform bool random_flip = true;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
// How far the shadow caster sits behind the drawing, along the light. The shadow on the ground
// stays in place, but the drawing stops shadowing itself.
uniform float shadow_offset : hint_range(0.0, 1.0) = 0.3;

varying flat float frame;
varying flat float flip;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// Each copy starts on its own frame, so a field of them doesn't move in lockstep.
	vec3 origin = MODEL_MATRIX[3].xyz;
	float count = float(frame_count);
	frame = mod(floor(TIME * fps + hash(origin.xz) * count), count);
	flip = random_flip && hash(origin.xz + 7.31) < 0.5 ? 1.0 : 0.0;
	if (IN_SHADOW_PASS) {
		// Moving along the light's rays doesn't change where the shadow lands.
		bool orthogonal = PROJECTION_MATRIX[3][3] > 0.5;
		vec3 away = orthogonal ? -INV_VIEW_MATRIX[2].xyz : normalize(origin - INV_VIEW_MATRIX[3].xyz);
		origin += away * shadow_offset;
	}
	mat4 world = MODEL_MATRIX;
	if (billboard) {
		// Same as BaseMaterial3D's Y-billboard with Keep Scale. MAIN_CAM_INV_VIEW_MATRIX keeps
		// shadows matching what the camera sees.
		world = mat4(
				vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
				vec4(0.0, 1.0, 0.0, 0.0),
				vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		world = world * mat4(
				vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
				vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
				vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
	}
	world[3] = vec4(origin, 1.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	// Light the drawing like the ground it stands on, not like a wall facing the camera, so it
	// darkens with the island at night and in shade.
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec2 uv = UV;
	uv.x = mix(uv.x, 1.0 - uv.x, flip);
	uv.x = (uv.x + frame) / float(frame_count);
	vec4 color = texture(frames, uv) * tint;
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	// Also seen from behind (standees), keep the ground's normal rather than a flipped one.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
