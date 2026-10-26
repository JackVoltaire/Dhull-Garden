// The sky as a speckled mosaic of broken stained glass: long, thin shards of colored glass held
// in dark lead, running from the horizon up towards a broken-out hole at the top of the sky, as if
// the glass shattered from there. Some shards are cracked and a few are missing. Each shard takes
// its color from the sky gradient where it sits (top_color, horizon_color, ground_color, which
// SkyCycle sets by time of day), tinted towards the moodboard's reds, blues, purples and gold.
// Shards near the sun or moon glow, as if lit from behind.
shader_type sky;

uniform vec4 top_color : source_color = vec4(0.15, 0.09, 0.36, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.44, 0.31, 0.7, 1.0);
uniform vec4 ground_color : source_color = vec4(0.16, 0.1, 0.3, 1.0);
uniform vec4 lead_color : source_color = vec4(0.07, 0.04, 0.1, 1.0);
// Shards side by side around the horizon. Keep it a whole number, so they meet up all the way
// round.
uniform float shards_around : hint_range(8.0, 200.0, 1.0) = 56.0;
// How many times longer than wide a shard is.
uniform float shard_aspect : hint_range(1.0, 8.0) = 3.5;
// Width of the lead between shards, as a fraction of a shard's width.
uniform float lead_width : hint_range(0.0, 0.5) = 0.12;
// Radius, in degrees, of the hole at the top of the sky where the glass broke out.
uniform float impact_radius : hint_range(0.0, 45.0) = 12.0;
// Share of shards tinted towards an accent color, and how strongly.
uniform float accent_share : hint_range(0.0, 1.0) = 0.35;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.45;
// How much brighter or darker one shard can be than the next.
uniform float shard_variation : hint_range(0.0, 0.5) = 0.18;
// Share of shards broken out of the window, leaving dark holes.
uniform float missing_share : hint_range(0.0, 0.3) = 0.04;
// Share of the remaining shards with a crack through them.
uniform float cracked_share : hint_range(0.0, 1.0) = 0.3;
// How strongly the glass is flecked with lighter and darker specks, and how many there are
// across one radian of sky.
uniform float speckle_strength : hint_range(0.0, 1.0) = 0.35;
uniform float speckle_density : hint_range(10.0, 500.0) = 200.0;
// How much shards near the sun or moon brighten.
uniform float backlight : hint_range(0.0, 2.0) = 0.7;

const vec3 ACCENTS[4] = { vec3(0.85, 0.2, 0.35), vec3(0.2, 0.45, 0.95), vec3(0.6, 0.25, 0.9), vec3(1.0, 0.75, 0.25) };
// Softens the edges of lead and cracks, in radians, about a pixel at common resolutions.
const float EDGE_SOFTNESS = 0.003;

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float result = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 corner = vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		vec3 weight = mix(1.0 - f, f, corner);
		result += hash3(cell + corner).x * weight.x * weight.y * weight.z;
	}
	return result;
}

// Random numbers for a grid cell. Cells repeat every shards_around steps sideways, so the shards
// meet up where the azimuth wraps round.
vec3 cell_random(vec2 cell, float salt) {
	return hash3(vec3(mod(cell.x, shards_around), cell.y, salt));
}

// Finds the shard at a point of the shard grid: the cell of the nearest random point, one point
// per grid cell. The grid is square, but each grid unit spans `scale` radians of sky, so shards
// come out stretched. Returns how far the point is from the shard's edge, in radians of sky, so
// the lead stays the same width all round.
float shard_edge_distance(vec2 grid_point, vec2 scale, out vec2 shard_point, out vec2 shard_cell) {
	vec2 cell = floor(grid_point);
	vec2 to_nearest = vec2(8.0);
	float nearest = 64.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 neighbor = cell + vec2(float(x), float(y));
			vec2 to_point = neighbor + cell_random(neighbor, 0.0).xy - grid_point;
			float squared = dot(to_point, to_point);
			if (squared < nearest) {
				nearest = squared;
				to_nearest = to_point;
				shard_cell = neighbor;
			}
		}
	}
	shard_point = grid_point + to_nearest;

	// Each edge lies halfway between the shard's point and a neighbor's, square to the line
	// joining them. Its distance is measured in the grid, then converted to radians of sky along
	// the edge's normal.
	float edge = 8.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 neighbor = shard_cell + vec2(float(x), float(y));
			vec2 to_point = neighbor + cell_random(neighbor, 0.0).xy - grid_point;
			vec2 between = to_point - to_nearest;
			if (dot(between, between) > 0.00001) {
				vec2 normal = normalize(between);
				float grid_distance = dot(0.5 * (to_nearest + to_point), normal);
				edge = min(edge, grid_distance / length(normal / scale));
			}
		}
	}
	return edge;
}

vec3 direction_from(float azimuth, float elevation) {
	return vec3(cos(elevation) * cos(azimuth), sin(elevation), cos(elevation) * sin(azimuth));
}

vec3 gradient(float height) {
	if (height >= 0.0) {
		return mix(horizon_color.rgb, top_color.rgb, smoothstep(0.0, 0.7, height));
	}
	return mix(horizon_color.rgb, ground_color.rgb, smoothstep(0.0, 0.25, -height));
}

void sky() {
	// Ambient light and reflections only need the overall colors, not the mosaic.
	if (AT_CUBEMAP_PASS) {
		COLOR = gradient(EYEDIR.y);
	} else {
		float azimuth = atan(EYEDIR.z, EYEDIR.x);
		float elevation = asin(clamp(EYEDIR.y, -1.0, 1.0));
		float shard_width = TAU / shards_around;
		// Circles of equal elevation shrink towards the top of the sky, and the shards with them.
		vec2 scale = vec2(shard_width * max(cos(elevation), 0.01), shard_width * shard_aspect);
		vec2 grid_point = vec2(azimuth, elevation) / vec2(shard_width, shard_width * shard_aspect);
		vec2 shard_point;
		vec2 shard_cell;
		float edge_distance = shard_edge_distance(grid_point, scale, shard_point, shard_cell);
		vec3 random = cell_random(shard_cell, 17.0);
		vec3 random2 = cell_random(shard_cell, 41.0);

		// One flat color per shard, from the gradient at its middle.
		float shard_elevation = shard_point.y * shard_width * shard_aspect;
		vec3 shard_direction = direction_from(shard_point.x * shard_width, shard_elevation);
		vec3 color = gradient(shard_direction.y);
		if (random.x < accent_share) {
			vec3 accent = ACCENTS[int(random.y * 4.0) % 4];
			// Keep the shard's brightness, so accents tint the sky's mood rather than replace it.
			float brightness = dot(color, vec3(0.3, 0.55, 0.15));
			float accent_brightness = dot(accent, vec3(0.3, 0.55, 0.15));
			color = mix(color, accent * brightness / accent_brightness, accent_strength);
		}
		color *= 1.0 + (random.z - 0.5) * 2.0 * shard_variation;
		if (LIGHT0_ENABLED) {
			float toward_light = max(dot(shard_direction, LIGHT0_DIRECTION), 0.0);
			color *= 1.0 + pow(toward_light, 6.0) * backlight;
		}

		// Specks in the glass.
		float speck = value_noise(EYEDIR * speckle_density);
		color *= 1.0 + (smoothstep(0.75, 0.85, speck) - smoothstep(0.25, 0.15, speck)) * speckle_strength;

		// A broken-out shard, round the hole at the top or anywhere at random: dark, with the odd
		// glint.
		bool in_impact = shard_elevation > radians(90.0 - impact_radius);
		bool missing = in_impact || random2.x < missing_share;
		if (missing) {
			color = lead_color.rgb * 1.6 + vec3(step(0.93, speck)) * 0.5;
		}

		// A crack: a thin, wavering line across the shard, through its middle, at a random angle.
		float crack = 0.0;
		if (!missing && random2.y < cracked_share) {
			vec2 across = normalize(random2.xz - 0.5);
			float wobble = (value_noise(EYEDIR * 60.0) - 0.5) * 0.006;
			float distance_to_crack = abs(dot((grid_point - shard_point) * scale, across) + wobble);
			crack = 1.0 - smoothstep(0.001, 0.001 + EDGE_SOFTNESS, distance_to_crack);
		}

		float half_lead = lead_width * 0.5 * shard_width;
		float lead = 1.0 - smoothstep(half_lead, half_lead + EDGE_SOFTNESS, edge_distance);
		// The hole has no lead inside it, only round its rim.
		if (in_impact) {
			lead = 0.0;
		}
		COLOR = mix(color, lead_color.rgb, max(lead, crack * 0.85));
	}
}
