class_name Islander
extends Node3D
## One of the Sky Isles' Cube Pets. Press Talk nearby to hear what they have
## to say; some of them want something.

var level: Level
var model_name := "animal-penguin"
var islander_name := ""
var lines: Array = []
var facing := Vector3.BACK
var model_scale := 0.42
## Called instead of the plain lines when set, for islanders with requests.
var on_talk := Callable()

var rig: RigCharacter


static func make(p_model: String, p_name: String, p_lines: Array, p_scale := 0.42) -> Islander:
	var i := Islander.new()
	i.model_name = p_model
	i.islander_name = p_name
	i.lines = p_lines
	i.model_scale = p_scale
	return i


func _ready() -> void:
	add_to_group("talker")
	rig = RigCharacter.create(Kit.scene(model_name), model_scale)
	rig.rotation.y = atan2(facing.x, facing.z)
	add_child(rig)
	if level:
		level.solid(global_position + Vector3(-0.35, 0, -0.35), global_position + Vector3(0.35, 0.8, 0.35))


func can_talk() -> bool:
	return true


func talk_range() -> float:
	return 1.6


func talk_text() -> String:
	return "Talk to %s" % islander_name


func talk() -> void:
	rig.play_once("gesture-positive")
	if on_talk.is_valid():
		on_talk.call()
	else:
		level.speak(islander_name, lines)


func cheer() -> void:
	rig.play_once("dance")
