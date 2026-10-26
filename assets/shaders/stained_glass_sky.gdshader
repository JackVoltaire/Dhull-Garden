// The sky as a speckled mosaic of broken stained glass: shards of colored glass held in dark lead,
// some cracked and a few missing. Each shard takes its color from the sky gradient where it sits
// (top_color, horizon_color, ground_color, which SkyCycle sets by time of day), tinted towards
// the moodboard's reds, blues, purples and gold. Shards near the sun or moon glow, as if lit from
// behind.
shader_type sky;

uniform vec4 top_color : source_color = vec4(0.15, 0.09, 0.36, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.44, 0.31, 0.7, 1.0);
uniform vec4 ground_color : source_color = vec4(0.16, 0.1, 0.3, 1.0);
uniform vec4 lead_color : source_color = vec4(0.07, 0.04, 0.1, 1.0);
// Shards across one radian of sky; higher makes smaller shards.
uniform float shard_density : hint_range(2.0, 40.0) = 7.0;
// Width of the lead between shards, as a fraction of a shard.
uniform float lead_width : hint_range(0.0, 0.3) = 0.07;
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

// Finds the shard around p: the nearest of the random points scattered one per unit cell, which
// identifies the shard by its point and cell. Returns how far p is from the shard's edge, so the
// lead between shards comes out straight and even, with sharp corners.
float shard_edge_distance(vec3 p, out vec3 shard_point, out vec3 shard_cell) {
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
					shard_cell = neighbor;
				}
			}
		}
	}
	shard_point = p + to_nearest;

	// Each edge lies halfway between the shard's point and a neighbor's, square to the line
	// joining them.
	float edge = 8.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = shard_cell + vec3(float(x), float(y), float(z));
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

vec3 gradient(vec3 direction) {
	if (direction.y >= 0.0) {
		return mix(horizon_color.rgb, top_color.rgb, smoothstep(0.0, 0.7, direction.y));
	}
	return mix(horizon_color.rgb, ground_color.rgb, smoothstep(0.0, 0.25, -direction.y));
}

void sky() {
	// Ambient light and reflections only need the overall colors, not the mosaic.
	if (AT_CUBEMAP_PASS) {
		COLOR = gradient(EYEDIR);
	} else {
		vec3 shard_point;
		vec3 shard_cell;
		vec3 p = EYEDIR * shard_density;
		float edge_distance = shard_edge_distance(p, shard_point, shard_cell);
		vec3 random = hash3(shard_cell + 17.0);
		vec3 random2 = hash3(shard_cell + 41.0);

		// One flat color per shard, from the gradient at its middle.
		vec3 shard_direction = normalize(shard_point);
		vec3 color = gradient(shard_direction);
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

		// A broken-out shard: a dark hole with the odd glint.
		if (random2.x < missing_share) {
			color = lead_color.rgb * 1.6 + vec3(step(0.93, speck)) * 0.5;
		}

		// A crack: a thin line across the shard, through its middle, at a random angle.
		float crack = 0.0;
		if (random2.y < cracked_share && random2.x >= missing_share) {
			vec3 across = normalize(cross(shard_direction, normalize(random2 - 0.5)));
			float wobble = (value_noise(p * 6.0) - 0.5) * 0.08;
			crack = 1.0 - smoothstep(0.012, 0.03, abs(dot(p - shard_point, across) + wobble));
		}

		float lead = 1.0 - smoothstep(lead_width * 0.5, lead_width * 0.5 + 0.02, edge_distance);
		COLOR = mix(color, lead_color.rgb, max(lead, crack * 0.85));
	}
}
