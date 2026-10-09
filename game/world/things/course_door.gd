class_name CourseDoor
extends Node3D
## A stone arch with a door into a course. Stand in front of it and press
## Talk to go in.

var level: Level
var course_id := ""
var facing := Vector3.BACK

var _door: Node3D


func _ready() -> void:
	add_to_group("talker")
	var turn := atan2(facing.x, facing.z)
	var side := facing.cross(Vector3.UP).normalized()
	# The arch: two stone pillars and a lintel, from the kit's blocks.
	for s in [-1.2, 1.2]:
		var pillar := Kit.model("block-snow-narrow", 1.0)
		pillar.position = side * s
		pillar.scale = Vector3(0.7, 2.6, 0.7)
		add_child(pillar)
	var top := Kit.model("block-snow-long", 1.0)
	top.position = Vector3.UP * 2.6
	top.rotation.y = turn + PI / 2.0
	top.scale = Vector3(1.0, 0.5, 1.4)
	add_child(top)
	_door = Kit.model("door-rotate-large", 1.9)
	_door.rotation.y = turn
	add_child(_door)
	var sign := Kit.model("flag", 1.4)
	sign.position = side * 1.9 + facing * 0.3
	add_child(sign)
	if level:
		level.solid(global_position + side * 1.2 + Vector3(-0.3, 0, -0.3), global_position + side * 1.2 + Vector3(0.3, 2.6, 0.3))
		level.solid(global_position - side * 1.2 + Vector3(-0.3, 0, -0.3), global_position - side * 1.2 + Vector3(0.3, 2.6, 0.3))


func can_talk() -> bool:
	return level.hero != null and level.hero.is_on_floor()


func talk_range() -> float:
	return 1.8


func talk_text() -> String:
	return "Go in: %s" % Courses.title(course_id)


func talk() -> void:
	var anim := _door.find_children("*", "AnimationPlayer", true, false)
	if not anim.is_empty():
		anim[0].play("open")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/open_001.ogg", -2.0)
	level.enter_course(course_id)
