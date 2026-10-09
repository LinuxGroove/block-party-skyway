class_name BossDoor
extends CourseDoor
## The door to a world's boss: it stays shut until enough of the world's
## stars are found (the world data's boss "door"), then leads to the arena.

## Stars in this world it takes to open.
var need := 5


func _ready() -> void:
	super()
	var star := Kit.model("star", 1.6)
	star.position = Vector3.UP * 3.5
	add_child(star)


func _flag_model() -> String:
	return "spike-block"


func is_open() -> bool:
	return _found() >= need


func _found() -> int:
	var n := 0
	for id in Worlds.star_ids(level.world):
		if level.found_stars.has(id):
			n += 1
	return n


func talk_text() -> String:
	if is_open():
		return "Face %s" % Worlds.boss_def(level.world).get("name", "the boss")
	return "Shut: %d of %d stars" % [_found(), need]


func talk() -> void:
	if not is_open():
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/error_004.ogg", -4.0)
		level.say("The door won't budge. Find %d stars in %s to open it." % [need, Worlds.world_name(level.world)])
		return
	super()
