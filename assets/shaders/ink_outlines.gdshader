// Ink lines over the whole 3D view, drawn where one thing passes in front of another and where a
// surface folds sharply. Lines keep the same width on screen at any distance, unlike outlines
// grown around each model. Use it on a 2x2 QuadMesh that is never culled; it covers the screen
// by itself (see scenes/environment/ink_outlines.tscn). Characters get no lines, as House of
// Decay's have none: where the nearest surface is a character, marked by its roughness (see
// ps1_character.gdshader), nothing is drawn.
shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;
uniform vec4 ink : source_color = vec4(0.07, 0.04, 0.1, 1.0);
// Line width in pixels on a screen 1080 pixels tall; it scales with the resolution.
uniform float line_width : hint_range(0.5, 8.0) = 2.5;
// How much farther, relative to its distance, the surface behind an edge must be to draw a line.
uniform float silhouette_gap : hint_range(0.01, 1.0) = 0.1;
// How sharply, in degrees, a surface must fold to draw a line along the fold.
uniform float crease_angle : hint_range(1.0, 180.0) = 40.0;
// The roughness characters mark themselves with: ps1_character.gdshader's CHARACTER_ROUGHNESS.
uniform float character_roughness = 0.3;
// Lines fade out between these distances, in meters, like the environment's distance fog.
uniform float fade_start = 40.0;
uniform float fade_end = 300.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

bool is_character(vec2 uv) {
	return abs(texture(normal_texture, uv).a - character_roughness) < 0.05;
}

void fragment() {
	vec2 reach = line_width / 1080.0 * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
	vec2 neighbors[4] = { vec2(reach.x, 0.0), vec2(-reach.x, 0.0), vec2(0.0, reach.y), vec2(0.0, -reach.y) };

	// Depth is reversed: 1 at the near plane, 0 for the sky.
	float center_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 center_normal = texture(normal_texture, SCREEN_UV).xyz * 2.0 - 1.0;
	float nearest_depth = center_depth;
	vec2 nearest_uv = SCREEN_UV;
	float neighbor_depth_sum = 0.0;
	float fold = 0.0;
	for (int i = 0; i < 4; i++) {
		// Past the screen's edge, reuse the edge itself, so it doesn't read as a line.
		vec2 uv = clamp(SCREEN_UV + neighbors[i], vec2(0.0), vec2(1.0));
		float depth = texture(depth_texture, uv).r;
		neighbor_depth_sum += depth;
		if (depth > nearest_depth) {
			nearest_depth = depth;
			nearest_uv = uv;
		}
		// The sky has no normal to compare with.
		if (depth > 0.0 && center_depth > 0.0) {
			vec3 normal = texture(normal_texture, uv).xyz * 2.0 - 1.0;
			fold = max(fold, 1.0 - dot(center_normal, normal));
		}
	}

	// The depth buffer changes evenly across any flat surface, however steeply it's seen, so its
	// second difference stays at zero there and only jumps where one surface passes in front of
	// another.
	float gap = abs(neighbor_depth_sum - 4.0 * center_depth) / max(nearest_depth, 1e-6);
	float silhouette = smoothstep(silhouette_gap, silhouette_gap * 1.5, gap);
	float fold_limit = 1.0 - cos(radians(crease_angle));
	float crease = smoothstep(fold_limit, fold_limit * 1.5, fold);
	// A line belongs to the nearer surface; a character's edges and folds get none.
	if (is_character(nearest_uv)) {
		silhouette = 0.0;
	}
	if (is_character(SCREEN_UV)) {
		crease = 0.0;
	}

	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, nearest_depth, 1.0);
	float distance = -view.z / view.w;
	float fade = 1.0 - smoothstep(fade_start, fade_end, distance);

	ALBEDO = ink.rgb;
	ALPHA = max(silhouette, crease) * fade * ink.a;
}
