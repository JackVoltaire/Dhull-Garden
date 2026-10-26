// The sky as a speckled mosaic of broken stained glass: irregular shards of colored glass in thin
// dark lead, lying every which way, a few of them missing. The cut of the window lives in
// stained_glass.gdshaderinc, shared with the drawings behind it. Each shard takes its color from
// the sky gradient where it sits (top_color, horizon_color, ground_color, which SkyCycle sets by
// time of day), tinted towards the moodboard's reds, blues, purples and gold, and is shaded
// inside like thick glass. Shards near the sun or moon glow, as if lit from behind.
shader_type sky;

#include "res://assets/shaders/stained_glass.gdshaderinc"

uniform vec4 top_color : source_color = vec4(0.15, 0.09, 0.36, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.44, 0.31, 0.7, 1.0);
uniform vec4 ground_color : source_color = vec4(0.16, 0.1, 0.3, 1.0);
// The lead between shards, and missing shards.
uniform vec4 lead_color : source_color = vec4(0.03, 0.02, 0.05, 1.0);
// Share of shards tinted towards an accent color, and how strongly.
uniform float accent_share : hint_range(0.0, 1.0) = 0.45;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.5;
// How much brighter or darker one shard can be than the next.
uniform float shard_variation : hint_range(0.0, 0.5) = 0.2;
// How much each shard brightens from one side to the other, and how strong the streaks in it are,
// like light caught in thick glass.
uniform float glass_shading : hint_range(0.0, 1.0) = 0.35;
uniform float glass_streaks : hint_range(0.0, 1.0) = 0.25;
// How strongly the glass is flecked with lighter and darker specks, and how many there are
// across one radian of sky.
uniform float speckle_strength : hint_range(0.0, 1.0) = 0.25;
uniform float speckle_density : hint_range(10.0, 500.0) = 200.0;
// How much shards near the sun or moon brighten.
uniform float backlight : hint_range(0.0, 2.0) = 0.7;

const vec3 ACCENTS[4] = { vec3(0.85, 0.2, 0.35), vec3(0.2, 0.45, 0.95), vec3(0.6, 0.25, 0.9), vec3(1.0, 0.75, 0.25) };

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
		GlassShard shard = glass_shard(EYEDIR);
		vec3 random = glass_hash(shard.id + 17.0);
		vec3 random2 = glass_hash(shard.id + 29.0);

		// One color per shard, from the gradient at its middle.
		vec3 color = gradient(shard.middle_direction.y);
		if (random.x < accent_share) {
			vec3 accent = ACCENTS[int(random.y * 4.0) % 4];
			// Keep the shard's brightness, so accents tint the sky's mood rather than replace it.
			float brightness = dot(color, vec3(0.3, 0.55, 0.15));
			float accent_brightness = dot(accent, vec3(0.3, 0.55, 0.15));
			color = mix(color, accent * brightness / accent_brightness, accent_strength);
		}
		color *= 1.0 + (random.z - 0.5) * 2.0 * shard_variation;
		if (LIGHT0_ENABLED) {
			float toward_light = max(dot(shard.middle_direction, LIGHT0_DIRECTION), 0.0);
			color *= 1.0 + pow(toward_light, 6.0) * backlight;
		}

		// Inside the shard, like thick glass: lighter towards one side, with soft streaks running
		// across it.
		vec2 light_way = vec2(cos(random2.x * TAU), sin(random2.x * TAU));
		vec2 from_middle = (shard.position - shard.middle) / shard.size;
		float shading = clamp(dot(from_middle, light_way), -1.0, 1.0) * glass_shading;
		vec2 streak_way = vec2(cos(random2.y * PI), sin(random2.y * PI));
		float streak_coordinate = dot(shard.position, streak_way) / shard.size;
		float streaks = glass_noise(vec3(streak_coordinate * 2.5, random2.z * 50.0, 0.0)) - 0.5;
		color *= 1.0 + shading + streaks * 2.0 * glass_streaks;

		// Specks in the glass.
		float speck = glass_noise(EYEDIR * speckle_density);
		color *= 1.0 + (smoothstep(0.75, 0.85, speck) - smoothstep(0.25, 0.15, speck)) * speckle_strength;

		COLOR = mix(color, lead_color.rgb, glass_shard_blackness(shard));
	}
}
