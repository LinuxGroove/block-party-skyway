class_name StarCourse
extends Level
## Base for the Star Road's eight courses: the night sky over a sea of
## clouds, glowing stars and rainbows, rainbow paths, and the start and
## finish every course shares. Each course mixes the kits and hazards of
## several worlds.

## Where the clouds gather below the course, and how far they spread.
var cloud_center := Vector3(0, 0, -40)
var cloud_spread := 80.0


func _init() -> void:
	super()
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func add_environment() -> void:
	super()
	var s := StarSky.new()
	s.center = cloud_center
	s.spread = cloud_spread
	add_child(s)


## The start pad, from (x0, z0) to (x1, z1), with a sign by the spawn.
func start_pad(x0: int, z0: int, x1: int, z1: int, text: String) -> void:
	land(x0, z0, x1, z1, 0, 3)
	add_sign(text, spawn + Vector3(-2, 0, -1))
	deco("arrows", spawn + spawn_facing * 6.5, rad_to_deg(atan2(-spawn_facing.x, -spawn_facing.z)), 2.0)
	for s in [-1.0, 1.0]:
		var side: Vector3 = spawn_facing.cross(Vector3.UP) * s
		add(StarGlow.make(1.0), spawn + side * 2.6 + Vector3.UP * 1.6 - spawn_facing * 1.0)


## The finish: the flag under a rainbow, with stars either side.
func goal(at: Vector3, face: Vector3) -> void:
	add_flag(at, face)
	var side := face.cross(Vector3.UP)
	add(StarRainbow.make(3.4, rad_to_deg(atan2(face.x, face.z)), 0.22), at - face * 0.6)
	for s in [-1.0, 1.0]:
		add(StarGlow.make(1.3), at + side * s * 3.6 + Vector3.UP * 2.2)


## A wooden deck (a dock, a gangway, a ship's deck): the kit's platforms
## over the squares from (x0, z0) to (x1, z1), with the top at `top`.
func deck(x0: int, z0: int, x1: int, z1: int, top: float) -> void:
	solid(Vector3(x0, top - 0.4, z0), Vector3(x1, top, z1))
	for x in range(x0, x1):
		for z in range(z0, z1):
			piece("platform", Vector3(x + 0.5, top - 0.2, z + 0.5))


## A glowing star hanging in the sky (scenery).
func glow(at: Vector3, size := 1.6, color := Color("ffd84a")) -> void:
	add(StarGlow.make(size, color), at)


## A rainbow path from `from` to `to`, walked on like any floor.
func rainbow_path(from: Vector3, to: Vector3, width := 2.4) -> StarBridge:
	return add(StarBridge.make(to - from, width), from) as StarBridge
