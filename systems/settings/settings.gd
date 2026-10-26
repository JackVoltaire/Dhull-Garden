extends Node
## Player preferences, registered as the [code]Settings[/code] autoload. Stored in [member path]
## separately from save games, so they apply to every slot, and applied at startup.
##
## Settings are named "section/key", like project settings. Every one must be listed in
## [constant DEFAULTS], which also fixes its type.

signal changed(setting: String, value: Variant)

const DEFAULTS := {
	"audio/master_volume": 1.0,
	"audio/music_volume": 0.8,
	"audio/sfx_volume": 1.0,
	"audio/ambience_volume": 1.0,
	"audio/ui_volume": 1.0,
	"display/fullscreen": false,
	"display/vsync": true,
	"controls/mouse_sensitivity": 1.0,
	"controls/invert_y": false,
	# Flips the seasons for players south of the equator.
	"game/southern_hemisphere": false,
	# Empty means the system language.
	"game/locale": "",
}
## Audio bus controlled by each volume setting. Buses are defined in default_bus_layout.tres.
const VOLUME_BUSES := {
	"audio/master_volume": &"Master",
	"audio/music_volume": &"Music",
	"audio/sfx_volume": &"SFX",
	"audio/ambience_volume": &"Ambience",
	"audio/ui_volume": &"UI",
}

var path := "user://settings.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(path)
	for setting: String in DEFAULTS:
		var value: Variant = get_value(setting)
		# Leave the window alone unless the player changed it, so it doesn't fight the
		# editor's embedded game view or the window settings in project.godot.
		if not setting.begins_with("display/") or value != DEFAULTS[setting]:
			_apply(setting, value)


func get_value(setting: String) -> Variant:
	var default: Variant = _get_default(setting)
	var value: Variant = _config.get_value(
		setting.get_slice("/", 0), setting.get_slice("/", 1), default
	)
	return value if typeof(value) == typeof(default) else default


func set_value(setting: String, value: Variant) -> void:
	var default: Variant = _get_default(setting)
	if typeof(default) == TYPE_FLOAT and typeof(value) == TYPE_INT:
		value = float(value)
	assert(typeof(value) == typeof(default), "Wrong type for setting '%s'." % setting)
	_config.set_value(setting.get_slice("/", 0), setting.get_slice("/", 1), value)
	_apply(setting, value)
	_config.save(path)
	changed.emit(setting, value)


func _get_default(setting: String) -> Variant:
	assert(DEFAULTS.has(setting), "Unknown setting '%s'." % setting)
	return DEFAULTS[setting]


func _apply(setting: String, value: Variant) -> void:
	if VOLUME_BUSES.has(setting):
		var bus := AudioServer.get_bus_index(VOLUME_BUSES[setting])
		if bus != -1:
			AudioServer.set_bus_volume_linear(bus, value)
		return
	match setting:
		"display/fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"display/vsync":
			if value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"game/locale":
			TranslationServer.set_locale(value if value != "" else OS.get_locale())
