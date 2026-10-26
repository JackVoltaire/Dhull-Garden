// A flat drawing in the 3D world, like a cardboard cutout: tree tops, clouds. The texture is a
// strip of frames side by side, played as stepped frame-by-frame animation, usually 3 or 4
// frames. Use it on a QuadMesh whose size matches one frame's shape.
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D frames : source_color, filter_linear_mipmap;
uniform int frame_count : hint_range(1, 64) = 4;
// Frames per second. Low rates (3-8) read as drawn animation; 0 holds the first frame.
uniform float fps : hint_range(0.0, 30.0) = 4.0;
// Separate drawings in the strip, one after another, each frame_count frames long. Each copy
// picks one by position.
uniform int variants : hint_range(1, 16) = 1;
// Off: stays put like a standee. Upright: turns around the vertical axis to face the camera;
// center the mesh on its bottom edge. Full: always faces the camera, for things that float;
// center the mesh on its middle.
uniform int billboard : hint_enum("Off", "Upright", "Full") = 2;
// Mirror some copies, picked by position, so repeats look less alike.
uniform bool random_flip = true;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
// How far the shadow caster sits behind the drawing, along the light, in mesh units; about
// half the mesh's width. The shadow on the ground stays in place, but the drawing stops
// shadowing itself.
uniform float shadow_offset : hint_range(0.0, 10.0) = 0.5;

varying flat float frame;
varying flat float flip;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// Each copy starts on its own frame, so a group of them doesn't move in lockstep.
	vec3 origin = MODEL_MATRIX[3].xyz;
	float count = float(frame_count);
	float variant = floor(hash(origin.xz + 3.17) * float(variants));
	frame = variant * count + mod(floor(TIME * fps + hash(origin.xz) * count), count);
	flip = random_flip && hash(origin.xz + 7.31) < 0.5 ? 1.0 : 0.0;
	vec3 scale = vec3(
			length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	if (IN_SHADOW_PASS) {
		// Moving along the light's rays doesn't change where the shadow lands.
		bool orthogonal = PROJECTION_MATRIX[3][3] > 0.5;
		vec3 away = orthogonal ? -INV_VIEW_MATRIX[2].xyz : normalize(origin - INV_VIEW_MATRIX[3].xyz);
		origin += away * shadow_offset * scale.x;
	}
	mat4 world = MODEL_MATRIX;
	vec3 up = vec3(0.0, 1.0, 0.0);
	if (billboard == 1) {
		// Like BaseMaterial3D's Y-billboard. MAIN_CAM_INV_VIEW_MATRIX keeps the shadow pass
		// facing the camera too, so shadows match what the camera sees.
		world = mat4(
				vec4(normalize(cross(up, MAIN_CAM_INV_VIEW_MATRIX[2].xyz)) * scale.x, 0.0),
				vec4(up * scale.y, 0.0),
				vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, up)) * scale.z, 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
	} else if (billboard == 2) {
		// In the shadow pass, face the light instead, so the whole drawing casts a shadow even
		// with the sun overhead.
		mat4 facing = IN_SHADOW_PASS ? INV_VIEW_MATRIX : MAIN_CAM_INV_VIEW_MATRIX;
		world = mat4(
				vec4(normalize(facing[0].xyz) * scale.x, 0.0),
				vec4(normalize(facing[1].xyz) * scale.y, 0.0),
				vec4(normalize(facing[2].xyz) * scale.z, 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
	}
	world[3] = vec4(origin, 1.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	// Light the drawing as if it faced the sky, not the camera, so it's lit like the ground
	// around it and darkens with the island at night and in shade.
	NORMAL = normalize(inverse(mat3(world)) * up);
}

void fragment() {
	vec2 uv = UV;
	uv.x = mix(uv.x, 1.0 - uv.x, flip);
	uv.x = (uv.x + frame) / float(frame_count * variants);
	vec4 color = texture(frames, uv) * tint;
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	// Also seen from behind (standees), keep the sky-facing normal rather than a flipped one.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
