// Pastel water with hard-edged, jagged lines drawn on it that scroll with the flow.
// Used for both waterfalls (flow down the quad) and streams (flow along the plane).
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform vec4 water_color : source_color = vec4(0.2, 0.72, 0.92, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.46, 0.78, 1.0);
uniform vec4 line_color : source_color = vec4(0.92, 0.97, 1.0, 1.0);
// Direction the water flows in UV space. (0, 1) runs down a QuadMesh.
uniform vec2 flow = vec2(0.0, 1.0);
uniform float speed = 0.6;
// Repeats of the pattern across the mesh. Match the mesh's proportions to keep lines even.
uniform vec2 uv_scale = vec2(1.0, 5.0);
// Number of line lanes across one pattern repeat.
uniform float lanes = 3.0;
// How far each line zigzags sideways, as a fraction of its lane.
uniform float jaggedness = 0.8;
uniform float zigzags_per_repeat = 2.5;
// Line thickness as a fraction of its lane.
uniform float line_width = 0.2;
// Share of each line that's drawn; the rest are gaps between dashes.
uniform float dash_fill = 0.7;
uniform float dash_length = 0.9;
// Above 0, the lines give off light, and above about 1 the environment's glow makes them shine.
uniform float line_glow : hint_range(0.0, 4.0) = 1.5;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// Triangle wave from -1 to 1: straight runs with sharp corners, which reads as jagged.
float zigzag(float x) {
	return abs(fract(x) * 2.0 - 1.0) * 2.0 - 1.0;
}

void fragment() {
	vec2 along_dir = normalize(flow);
	vec2 across_dir = vec2(-along_dir.y, along_dir.x);
	vec2 uv = UV * uv_scale;
	float along = dot(uv, along_dir) - TIME * speed;
	float across = dot(uv, across_dir) * lanes;

	float lane = floor(across);
	float lane_seed = hash(lane + 1.0);
	float wobble = zigzag(along * zigzags_per_repeat * (0.7 + 0.6 * lane_seed) + lane_seed * 10.0);
	float center = 0.5 + 0.5 * jaggedness * wobble;
	float on_line = 1.0 - step(line_width * 0.5, abs(fract(across) - center));
	float on_dash = step(fract(along / dash_length + lane_seed * 3.0), dash_fill);

	vec3 base = mix(deep_color.rgb, water_color.rgb, step(0.5, lane_seed));
	ALBEDO = mix(base, line_color.rgb, on_line * on_dash);
	EMISSION = line_color.rgb * on_line * on_dash * line_glow;
}
