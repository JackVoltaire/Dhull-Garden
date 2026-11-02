class_name LullaTalk
extends RefCounted
## What Lulla says each time the dreamer talks to her, and when she nods off, apart from her
## scene so it can be tested. She nods off on some lines, mid-sentence, and dozes until she's
## talked to again; then she wakes with a start and says a waking line instead of mumbling.

## Whether she's dozing.
var dozing := false

## Translation keys: what she says when the dreamer first meets her; her mumbling afterwards and
## what she says when woken, a line each time, in turn; and the lines she nods off on.
var _first_meeting: PackedStringArray
var _mumbling: PackedStringArray
var _waking: PackedStringArray
var _nodding_off: PackedStringArray
var _next_mumble := 0
var _next_waking := 0


func _init(
	first_meeting: PackedStringArray,
	mumbling: PackedStringArray,
	waking: PackedStringArray,
	nodding_off: PackedStringArray
) -> void:
	_first_meeting = first_meeting
	_mumbling = mumbling
	_waking = waking
	_nodding_off = nodding_off


## What she says when the dreamer talks to her: the first meeting if they haven't [param met]
## yet; a waking line if she's dozing, which wakes her; else her next mumble.
func next_lines(met: bool) -> PackedStringArray:
	if not met:
		return _first_meeting
	if dozing:
		dozing = false
		var waking_line := _waking[_next_waking]
		_next_waking = (_next_waking + 1) % _waking.size()
		return PackedStringArray([waking_line])
	var mumble := _mumbling[_next_mumble]
	_next_mumble = (_next_mumble + 1) % _mumbling.size()
	return PackedStringArray([mumble])


## Whether she nods off on [param line] as she says it. If she does, she's dozing from then on.
func nods_off_on(line: String) -> bool:
	var nods_off := line in _nodding_off
	if nods_off:
		dozing = true
	return nods_off
