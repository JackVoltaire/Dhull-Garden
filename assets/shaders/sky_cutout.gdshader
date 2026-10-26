// A drawn cutout far out in the sky, like the sun or moon: always faces the camera and ignores
// light, fog and shadows. Frames sit side by side in the texture, as in cardboard_cutout, and
// play in steps. Center the QuadMesh on its middle.
shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, cull_disabled;

uniform sampler2D frames : source_color, filter_linear_mipmap;
uniform int frame_count : hint_range(1, 64) = 4;
uniform float fps : hint_range(0.0, 30.0) = 4.0;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;

varying flat float frame;

void vertex() {
	frame = mod(floor(TIME * fps), float(frame_count));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
			INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
			INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
			MODEL_MATRIX[3]);
}

void fragment() {
	vec4 color = texture(frames, vec2((UV.x + frame) / float(frame_count), UV.y));
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
}
