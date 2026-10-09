class_name SignPost
extends Node3D
## A wooden sign. Press Talk to read it.

var level: Level
var text := ""
var facing := Vector3.BACK


func _ready() -> void:
	add_to_group("talker")
	var m := Kit.model("sign", 1.6)
	m.rotation.y = atan2(facing.x, facing.z)
	add_child(m)


func can_talk() -> bool:
	return true


func talk_range() -> float:
	return 1.4


func talk_text() -> String:
	return "Read"


func talk() -> void:
	level.speak("Sign", [text])
