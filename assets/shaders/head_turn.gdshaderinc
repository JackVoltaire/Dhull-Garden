// A character's head with its face flattened, as a flattice flattens it in Blender, turned
// partway towards the camera and flattened along the camera's line of sight, as anime-style 3D
// games do, so a face keeps the shape it was drawn with from every side.
// Only how the head is drawn changes, not where it is, so animations and gameplay don't notice.
// The head's parts (the head, its hair, a face sheet) share its model space: its middle at the
// origin, up along +Y, the face towards +Z. Every shader that draws a part of a head, the face
// overlay included, turns it the same way, or the parts slide apart; parts that don't set
// head_turn (see HeadTurn) stay as they are.
//
// The camera is always the one drawing the viewport, even while a light draws its shadows, so a
// head casts the shadow of the shape it's drawn in.

// Fixed instance slots 8 and 10-12, apart from the character shader's (0-3) and the face's (4-7
// and 9), as a head carries all three.
// How far the head turns towards the camera, at most, in radians: sideways, as the camera goes
// round, and up or down, as it rises or sinks in front of the face.
instance uniform vec2 head_turn : instance_index(8) = vec2(0.0);
// How deep the head is drawn along the camera's line of sight, from 0 (flat) to 1 (as modeled).
instance uniform float head_depth : instance_index(10) = 1.0;
// How far the head is shaded like a ball rather than by its own facets, from 0 to 1, for big
// simple shapes of light and shade.
instance uniform float head_roundness : instance_index(11) = 0.0;
// How deep the front of the head is drawn, from its middle to its face, from 0 (flat) to 1 (as
// modeled): the flattice. A flatter face turns less round the head at an angle, so it keeps
// looking like a drawing on a flat face rather than one wrapped round a ball.
instance uniform float head_face_depth : instance_index(12) = 1.0;

// Whether this is part of a head that turns, rather than some other part.
bool is_head() {
	return head_turn != vec2(0.0) || head_depth != 1.0 || head_roundness != 0.0
			|| head_face_depth != 1.0;
}

// [vector] turned by [angle] radians about [axis], which is of length 1.
vec3 turned(vec3 vector, vec3 axis, float angle) {
	return vector * cos(angle) + cross(axis, vector) * sin(angle)
			+ axis * dot(axis, vector) * (1.0 - cos(angle));
}

// Flattens the face of a head part's [vertex], in its model space, then turns it and its
// [normal] towards the camera at [camera_world] and flattens the vertex along the line of sight.
// [model_matrix] is the part's.
void turn_head(inout vec3 vertex, inout vec3 normal, mat4 model_matrix, vec3 camera_world) {
	if (!is_head()) {
		return;
	}
	normal = normalize(mix(normal, normalize(vertex), head_roundness));
	// Only the front: the back of the head keeps its depth, so it's still round from the side.
	if (vertex.z > 0.0) {
		vertex.z *= head_face_depth;
	}
	vec3 camera = (inverse(model_matrix) * vec4(camera_world, 1.0)).xyz;
	// How far round from the face the camera is, and how high above it.
	float around = atan(camera.x, camera.z);
	float above = atan(camera.y, length(camera.xz));
	// The turn is strongest with the camera at the side and none with it straight in front, where
	// the face is already seen whole, or straight behind, where turning would twist the neck.
	float sideways = head_turn.x * sin(around);
	// The face only tips up or down towards a camera in front of it.
	float upward = head_turn.y * sin(above) * max(cos(around), 0.0);
	vertex = turned(turned(vertex, vec3(-1.0, 0.0, 0.0), upward), vec3(0.0, 1.0, 0.0), sideways);
	normal = turned(turned(normal, vec3(-1.0, 0.0, 0.0), upward), vec3(0.0, 1.0, 0.0), sideways);
	// The normal stays as it was through both flattenings, so the head is lit as its full shape.
	vec3 line_of_sight = normalize(camera);
	vertex -= line_of_sight * dot(vertex, line_of_sight) * (1.0 - head_depth);
}
