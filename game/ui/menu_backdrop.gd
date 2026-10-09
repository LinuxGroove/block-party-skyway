class_name MenuBackdrop
extends Node3D
## Behind the menus: the island the player was last on (Sunny Isles at
## first), with the chosen astronaut waving at its start and the camera
## drifting slowly round.

var level: Level
var astronaut: RigCharacter
var _cam: Camera3D
var _angle := 0.4
var _hero := -1


func _ready() -> void:
	var id := str(Progress.island_spot.get("level", "sunny"))
	if not Worlds.is_built(Worlds.world_of(id)) or id != str(Worlds.get_def(Worlds.world_of(id)).island):
		id = "sunny"
	level = Levels.make(id)
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
	astronaut.position = level.spawn + level.spawn_facing * 3.0
	add_child(astronaut)
	astronaut.play_once("emote-yes")


func _process(delta: float) -> void:
	_angle += delta * 0.04
	_place_camera()
	if astronaut and not astronaut.busy():
		astronaut.play("idle")


func _place_camera() -> void:
	var focus := level.spawn + level.spawn_facing * 9.0 + Vector3(2, 0, 0)
	_cam.position = focus + Vector3(sin(_angle) * 26.0, 13.0, cos(_angle) * 26.0)
	_cam.look_at(focus + Vector3.UP * 1.0, Vector3.UP)
