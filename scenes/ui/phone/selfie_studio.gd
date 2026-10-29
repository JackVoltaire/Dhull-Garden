class_name SelfieStudio
extends SubViewport
## Takes the selfie a Dhull posts with: the Dhull, posed in the mood it posted in, with the thing
## the post is about held up beside it, against a background in the post's tone. Each selfie is
## taken once and kept for as long as the game runs.

## The drawing held up beside the Dhull for each topic.
@export var props: Dictionary[FeedPost.Topic, Mesh] = {}
## The background behind a post that feels good, low or angry.
@export var backdrops: Dictionary[DhullPosting.Tone, Color] = {}

## Selfies taken so far, by post id.
var _taken: Dictionary[StringName, Texture2D] = {}
var _busy := false

@onready var _dhull: Dhull = $Dhull
@onready var _prop: MeshInstance3D = $Prop
@onready var _backdrop: Environment = ($Backdrop as WorldEnvironment).environment


## The selfie for [param post] by [param record], taken now if it hasn't been yet.
func selfie(post: FeedPost, record: DhullRecord) -> Texture2D:
	if _taken.has(post.id):
		return _taken[post.id]
	while _busy:
		await RenderingServer.frame_post_draw
	_busy = true
	_dhull.genome = record.genome
	_dhull.coloring = record.coloring
	_dhull.mood = post.mood
	_dhull.activity = (
		DhullState.Activity.SLEEPING
		if post.topic == FeedPost.Topic.NAPPING
		else DhullState.Activity.STANDING
	)
	_prop.mesh = props.get(post.topic)
	_backdrop.background_color = backdrops.get(DhullPosting.tone_of(post.mood), Color.BLACK)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	# Two frames: one for the Dhull to take its pose, one to draw it.
	await RenderingServer.frame_post_draw
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var picture := ImageTexture.create_from_image(get_texture().get_image())
	_taken[post.id] = picture
	_busy = false
	return picture
