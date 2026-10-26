// The stained-glass window the sky is drawn as. Shared by the sky and by the drawings that sit
// behind it, such as the sun and moon, so their view of the lead and the missing shards lines up
// exactly. The window is cut the same way everywhere from the constants below; change them here
// to reshape it.
//
// How it's cut: the sky is split into patches, and each patch is cut in two along a random
// straight line, each half in two again, and so on. The shards come out in many shapes and sizes,
// lying every which way, with straight edges that meet at sharp corners.

// Size, in degrees, of the patches the window is first split into.
const float GLASS_PATCH_SIZE = 16.0;
// How many times each patch is cut in two; each cut doubles the shards in it.
const int GLASS_CUTS = 3;
// Width of the lead between shards, in degrees.
const float GLASS_LEAD_WIDTH = 0.3;
// Share of shards missing from the window.
const float GLASS_MISSING_SHARE = 0.05;
// Softens the edges of the lead, in radians: about a pixel at common resolutions.
const float GLASS_EDGE_SOFTNESS = 0.003;

struct GlassShard {
	// Random numbers that tell shards apart.
	vec3 id;
	// The point's position in its patch, in flat coordinates that are radians near the middle.
	vec2 position;
	// The shard's middle and rough half-size, in the same coordinates.
	vec2 middle;
	float size;
	// Direction to the shard's middle.
	vec3 middle_direction;
	// Radians from the point to the nearest edge of the shard.
	float edge_distance;
	bool missing;
};

vec3 glass_hash(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

float glass_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float result = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 corner = vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		vec3 weight = mix(1.0 - f, f, corner);
		result += glass_hash(cell + corner).x * weight.x * weight.y * weight.z;
	}
	return result;
}

// Finds the patch around a direction: the nearest, by angle, of random points scattered over the
// sky, one per unit cell of a grid `density` cells across a radian. Returns the patch's middle
// and grid cell, and the angle from the direction to the patch's edge. Edges lie halfway between
// neighboring points along great circles, so they come out as straight lines on the sky.
float glass_patch(vec3 direction, float density, out vec3 patch_middle, out vec3 patch_cell) {
	vec3 p = direction * density;
	vec3 cell = floor(p);
	float nearest = -2.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = cell + vec3(float(x), float(y), float(z));
				vec3 point = neighbor + glass_hash(neighbor);
				// Only points near the sky's sphere count, so the patches stay evenly sized.
				if (abs(length(point) - density) < 0.75) {
					float closeness = dot(direction, normalize(point));
					if (closeness > nearest) {
						nearest = closeness;
						patch_middle = normalize(point);
						patch_cell = neighbor;
					}
				}
			}
		}
	}

	float edge = 8.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = cell + vec3(float(x), float(y), float(z));
				vec3 point = neighbor + glass_hash(neighbor);
				vec3 other = normalize(point);
				vec3 between = patch_middle - other;
				if (abs(length(point) - density) < 0.75 && dot(between, between) > 0.0000001) {
					edge = min(edge, dot(direction, normalize(between)));
				}
			}
		}
	}
	return edge;
}

// The shard of the window seen in a direction.
GlassShard glass_shard(vec3 direction) {
	GlassShard shard;
	vec3 patch_middle;
	vec3 patch_cell;
	shard.edge_distance = glass_patch(direction, 1.0 / radians(GLASS_PATCH_SIZE), patch_middle, patch_cell);

	// Flat coordinates around the patch's middle. Straight lines in them are great circles on the
	// sky, so the lead comes out straight.
	vec3 reference = abs(patch_middle.y) > 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 side = normalize(cross(patch_middle, reference));
	vec3 up = cross(side, patch_middle);
	shard.position = vec2(dot(direction, side), dot(direction, up)) / dot(direction, patch_middle);

	// Cut the patch in two, then the half this point is in, and so on. Each cut passes near the
	// middle of the piece it cuts, at a random angle.
	shard.id = patch_cell;
	shard.middle = vec2(0.0);
	shard.size = radians(GLASS_PATCH_SIZE) * 0.5;
	for (int cut = 0; cut < GLASS_CUTS; cut++) {
		vec3 random = glass_hash(shard.id + vec3(float(cut) * 13.7, 1.9, 4.3));
		float angle = random.x * PI;
		vec2 normal = vec2(cos(angle), sin(angle));
		vec2 through = shard.middle + normal * (random.y - 0.5) * shard.size;
		float distance_past = dot(shard.position - through, normal);
		float which_half = distance_past >= 0.0 ? 1.0 : -1.0;
		shard.edge_distance = min(shard.edge_distance, abs(distance_past));
		shard.id = glass_hash(shard.id + vec3(which_half * 3.1, float(cut) * 1.7, 0.37)) * 100.0;
		shard.middle = through + normal * which_half * shard.size * 0.5;
		shard.size *= 0.7;
	}
	shard.middle_direction = normalize(patch_middle + side * shard.middle.x + up * shard.middle.y);
	shard.missing = glass_hash(shard.id + 41.0).x < GLASS_MISSING_SHARE;
	return shard;
}

// How much of the window is black at a point of a shard: 1 on the lead and on missing shards,
// 0 on glass.
float glass_shard_blackness(GlassShard shard) {
	if (shard.missing) {
		return 1.0;
	}
	float half_lead = radians(GLASS_LEAD_WIDTH) * 0.5;
	return 1.0 - smoothstep(half_lead, half_lead + GLASS_EDGE_SOFTNESS, shard.edge_distance);
}

float glass_blackness(vec3 direction) {
	return glass_shard_blackness(glass_shard(direction));
}

// A drawing as seen through the black of the window: its dark ink lines turn white, everything
// else black.
vec3 glass_line_art(vec3 drawing_color) {
	// Judged on screen brightness, not the linear color, so mid tones like orange don't pass for
	// ink. Not named `brightness`: sky_cutout has a uniform by that name, which would win.
	vec3 on_screen = pow(max(drawing_color, vec3(0.0)), vec3(1.0 / 2.2));
	float luminance = dot(on_screen, vec3(0.3, 0.55, 0.15));
	// A little generous, as ink lines blur into their surroundings when a drawing is small.
	return vec3(1.0 - smoothstep(0.1, 0.18, luminance));
}
