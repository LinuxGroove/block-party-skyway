class_name MenuBackdrop
extends Node3D
## Behind the menus: Sunny Isles, with the chosen astronaut waving at the
## start and the camera drifting slowly round.

var level: SunnyIsle
var astronaut: RigCharacter
var _cam: Camera3D
var _angle := 0.4
var _hero := -1


func _ready() -> void:
	level = Levels.make("sunny") as SunnyIsle
	level.found_stars = Progress.stars.duplicate()
	level.found_gems = Progress.gems.duplicate()
	add_child(level)
	level.build()
	level.add_environment()
	_cam = Camera3D.new()
	_cam.fov = 55.0
	add_child(_cam)
	_cam.current = true
	show_hero(GameConfig.hero_index())
	_place_camera()


## Swaps the astronaut standing at the start.
func show_hero(i: int) -> void:
	if i == _hero:
		return
	_hero = i
	if astronaut:
		astronaut.queue_free()
	astronaut = RigCharacter.create(GameConfig.hero_scene(i), 1.6)
	astronaut.position = Vector3(0, 0, 6)
	add_child(astronaut)
	astronaut.play_once("emote-yes")


func _process(delta: float) -> void:
	_angle += delta * 0.04
	_place_camera()
	if astronaut and not astronaut.busy():
		astronaut.play("idle")


func _place_camera() -> void:
	var focus := Vector3(2, 0, 0)
	_cam.position = focus + Vector3(sin(_angle) * 26.0, 13.0, cos(_angle) * 26.0)
	_cam.look_at(focus + Vector3.UP * 1.0, Vector3.UP)
