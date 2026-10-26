extends Node
## Music with crossfades and fire-and-forget sound effects, registered as the [code]Audio[/code]
## autoload. Sounds go to the buses in default_bus_layout.tres, whose volumes the player sets
## in [code]Settings[/code]. Sounds placed in the world belong in scenes as
## AudioStreamPlayer3D or AudioStreamPlayer2D nodes on the SFX or Ambience bus.

const SFX_PLAYER_COUNT := 12

var _music_players: Array[AudioStreamPlayer] = []
var _music_index := 0
var _music_tween: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0


func _ready() -> void:
	# Keep playing while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in 2:
		_music_players.append(_add_player(&"Music"))
	for _i in SFX_PLAYER_COUNT:
		_sfx_players.append(_add_player(&"SFX"))


## Fades from the current music to [param stream]. Does nothing if it's already playing.
func play_music(stream: AudioStream, fade_seconds := 1.0) -> void:
	var current := _music_players[_music_index]
	if current.stream == stream and current.playing:
		return
	_music_index = 1 - _music_index
	var next := _music_players[_music_index]
	next.stream = stream
	next.volume_linear = 0.0
	next.play()
	_restart_music_tween()
	_music_tween.tween_property(next, "volume_linear", 1.0, fade_seconds)
	_music_tween.tween_property(current, "volume_linear", 0.0, fade_seconds)
	_music_tween.chain().tween_callback(current.stop)


func stop_music(fade_seconds := 1.0) -> void:
	var current := _music_players[_music_index]
	_restart_music_tween()
	_music_tween.tween_property(current, "volume_linear", 0.0, fade_seconds)
	_music_tween.chain().tween_callback(current.stop)


## Plays a one-off sound, such as a menu click on the [code]&"UI"[/code] bus. When all players
## are busy, the oldest sound is cut off.
func play_sfx(stream: AudioStream, bus := &"SFX", volume_db := 0.0, pitch_scale := 1.0) -> void:
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _restart_music_tween() -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()


func _add_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player
