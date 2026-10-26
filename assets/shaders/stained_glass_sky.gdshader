// The sky as a speckled mosaic of broken stained glass: long, thin shards of colored glass held
// in dark lead, lying every which way, with smaller pieces in the gaps. Some shards are cracked,
// a few are missing, and the glass has broken out of a hole at the top of the sky. Each shard
// takes its color from the sky gradient where it sits (top_color, horizon_color, ground_color,
// which SkyCycle sets by time of day), tinted towards the moodboard's reds, blues, purples and
// gold. Shards near the sun or moon glow, as if lit from behind.
//
// How the shards are cut: the sky is split into clusters, each a handful of shards lying the same
// way. A cluster is cut into long strips with slightly tapering sides, and each strip into
// lengths with slanted ends. Where a cluster's edge clips its strips, small pieces are left.
shader_type sky;

uniform vec4 top_color : source_color = vec4(0.15, 0.09, 0.36, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.44, 0.31, 0.7, 1.0);
uniform vec4 ground_color : source_color = vec4(0.16, 0.1, 0.3, 1.0);
uniform vec4 lead_color : source_color = vec4(0.07, 0.04, 0.1, 1.0);
// Size, in degrees, of a cluster of shards that lie the same way.
uniform float cluster_size : hint_range(3.0, 40.0) = 11.0;
// Width of a shard, in degrees, and how many times longer than wide it is.
uniform float shard_width : hint_range(0.5, 10.0) = 2.6;
uniform float shard_aspect : hint_range(1.0, 10.0) = 4.0;
// How far, in degrees, a shard's sides can lean off parallel, so shards taper.
uniform float shard_taper : hint_range(0.0, 15.0) = 9.0;
// How far, in degrees, a shard's ends can slant off square, so shards come to points.
uniform float end_slant : hint_range(0.0, 70.0) = 40.0;
// Width of the lead between shards, in degrees.
uniform float lead_width : hint_range(0.0, 3.0) = 0.45;
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
uniform float cracked_share : hint_range(0.0, 1.0) = 0.25;
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

vec2 rotate(vec2 v, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// Finds the cluster around p: the nearest of the random points scattered one per unit cell.
// Returns how far p is from the cluster's edge, in the same units as p.
float nearest_cluster(vec3 p, out vec3 cluster_point, out vec3 cluster_cell) {
	vec3 cell = floor(p);
	vec3 to_nearest = vec3(8.0);
	float nearest = 64.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = cell + vec3(float(x), float(y), float(z));
				vec3 to_point = neighbor + hash3(neighbor) - p;
				float squared = dot(to_point, to_point);
				if (squared < nearest) {
					nearest = squared;
					to_nearest = to_point;
					cluster_cell = neighbor;
				}
			}
		}
	}
	cluster_point = p + to_nearest;

	// Each edge lies halfway between the cluster's point and a neighbor's, square to the line
	// joining them.
	float edge = 8.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = cluster_cell + vec3(float(x), float(y), float(z));
				vec3 to_point = neighbor + hash3(neighbor) - p;
				vec3 between = to_point - to_nearest;
				if (dot(between, between) > 0.00001) {
					edge = min(edge, dot(0.5 * (to_nearest + to_point), normalize(between)));
				}
			}
		}
	}
	return edge;
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
		float cluster_density = 1.0 / radians(cluster_size);
		vec3 cluster_point;
		vec3 cluster_cell;
		float cluster_edge = nearest_cluster(EYEDIR * cluster_density, cluster_point, cluster_cell)
				/ cluster_density;

		// Flat coordinates around the cluster's middle, in radians near the middle. Straight lines
		// in them are great circles on the sky, so the lead comes out straight.
		vec3 middle = normalize(cluster_point);
		vec3 reference = abs(middle.y) > 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
		vec3 side = normalize(cross(middle, reference));
		vec3 up = cross(side, middle);
		vec2 plane = vec2(dot(EYEDIR, side), dot(EYEDIR, up)) / dot(EYEDIR, middle);

		// The way this cluster's shards lie.
		vec3 cluster_random = hash3(cluster_cell + 5.0);
		vec2 lengthwise = rotate(vec2(1.0, 0.0), cluster_random.x * PI);
		vec2 crosswise = vec2(-lengthwise.y, lengthwise.x);

		// Strips: the sides are lines across the cluster, roughly a shard apart and leaning a
		// little off parallel. The strip is the one whose lower side this point is past.
		float width = radians(shard_width);
		float first = floor(dot(plane, crosswise) / width) - 2.0;
		float strip = first;
		float below = 8.0;
		float above = 8.0;
		for (int i = 0; i <= 4; i++) {
			float k = first + float(i);
			vec3 random = hash3(cluster_cell + vec3(k * 7.13, 0.0, 11.0));
			vec2 normal = rotate(crosswise, (random.x - 0.5) * 2.0 * radians(shard_taper));
			float distance_past = dot(plane, normal) - (k + (random.y - 0.5) * 0.6) * width;
			if (distance_past >= 0.0) {
				strip = k;
				below = distance_past;
			} else if (-distance_past < above) {
				above = -distance_past;
			}
		}

		// Lengths: cuts across the strip, a few shard widths apart and slanted.
		vec3 strip_random = hash3(cluster_cell + vec3(strip * 7.13, 0.0, 23.0));
		float piece_length = width * shard_aspect * (0.6 + 0.8 * strip_random.x);
		float phase = strip_random.y;
		float along = dot(plane, lengthwise);
		float first_cut = floor(along / piece_length + phase) - 1.0;
		float piece = first_cut;
		float behind = 8.0;
		float ahead = 8.0;
		for (int i = 0; i <= 2; i++) {
			float j = first_cut + float(i);
			vec3 random = hash3(cluster_cell + vec3(strip * 7.13, j * 3.71, 37.0));
			vec2 normal = rotate(lengthwise, (random.x - 0.5) * 2.0 * radians(end_slant));
			float distance_past = dot(plane, normal) - (j - phase) * piece_length;
			if (distance_past >= 0.0) {
				piece = j;
				behind = distance_past;
			} else if (-distance_past < ahead) {
				ahead = -distance_past;
			}
		}
		float edge_distance = min(cluster_edge, min(min(below, above), min(behind, ahead)));

		vec3 shard_id = cluster_cell + vec3(strip * 7.13, piece * 3.71, 0.0);
		vec3 random = hash3(shard_id + 17.0);
		vec3 random2 = hash3(shard_id + 41.0);

		// One plane color per shard, from the gradient at its middle.
		vec2 plane_middle = crosswise * (strip + 0.5) * width + lengthwise * (piece + 0.5 - phase) * piece_length;
		vec3 shard_direction = normalize(middle + side * plane_middle.x + up * plane_middle.y);
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

		// A broken-out shard, in the hole at the top or anywhere at random: dark, with the odd
		// glint. The hole goes by cluster, so its rim is jagged.
		bool in_impact = middle.y > cos(radians(impact_radius));
		bool missing = in_impact || random2.x < missing_share;
		if (missing) {
			color = lead_color.rgb * 1.6 + vec3(step(0.93, speck)) * 0.5;
		}

		// A crack: a thin, wavering line across the shard, through its middle, at a random angle.
		float crack = 0.0;
		if (!missing && random2.y < cracked_share) {
			vec2 across = normalize(random2.xz - 0.5);
			float wobble = (value_noise(EYEDIR * 60.0) - 0.5) * 0.006;
			float distance_to_crack = abs(dot(plane - plane_middle, across) + wobble);
			crack = 1.0 - smoothstep(0.001, 0.001 + EDGE_SOFTNESS, distance_to_crack);
		}

		float half_lead = radians(lead_width) * 0.5;
		float lead = 1.0 - smoothstep(half_lead, half_lead + EDGE_SOFTNESS, edge_distance);
		// The hole has no lead inside it, only round its rim.
		if (in_impact) {
			lead = 0.0;
		}
		COLOR = mix(color, lead_color.rgb, max(lead, crack * 0.85));
	}
}
