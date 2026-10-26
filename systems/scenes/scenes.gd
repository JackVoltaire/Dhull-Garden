extends CanvasLayer
## Changes scenes behind a fade, registered as the [code]Scenes[/code] autoload. The next scene
## loads on a background thread while the screen fades out.
##
## To hand data to the next scene, pass [param params] to [method change_scene]: if the new
## scene's root has a [code]setup(params: Dictionary)[/code] method, it's called before the
## scene enters the tree, so the data is there by the time [code]_ready()[/code] runs.

signal scene_changed(scene: Node)

const FADE_SECONDS := 0.3

## True while a change is in progress. Further changes are ignored until it finishes.
var is_changing := false

var _fade := ColorRect.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


## Fades out, switches to the scene at [param path] and fades back in. Await it to continue
## once the new scene is visible.
func change_scene(path: String, params := {}) -> void:
	if is_changing:
		push_warning("Ignoring change to '%s' while another scene change is running." % path)
		return
	is_changing = true
	# Block clicks on the old scene while it fades out.
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	ResourceLoader.load_threaded_request(path)
	await _fade_to(1.0)

	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	if packed == null:
		push_error("Couldn't load scene '%s'." % path)
	else:
		var scene := packed.instantiate()
		if scene.has_method("setup"):
			scene.setup(params)
		get_tree().change_scene_to_node(scene)
		await get_tree().scene_changed

	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing = false
	if packed:
		scene_changed.emit(get_tree().current_scene)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
