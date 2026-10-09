class_name Island
extends Level
## Base for a world's island in Adventure: the doors to its four courses and
## its boss, the Skyway gates to the worlds either side, a timed coin rush,
## and the count of what's still hidden.


func _init() -> void:
	super()
	camera_base = [0.0, 34.0, 10.0, true]


## Stars found in this world so far.
func world_stars() -> int:
	var n := 0
	for id in Worlds.star_ids(world):
		if found_stars.has(id):
			n += 1
	return n


## Stars and gems still hidden in this world (island, courses and boss).
func secrets_left() -> int:
	var n := 0
	for id in Worlds.star_ids(world):
		if not found_stars.has(id):
			n += 1
	for id in Worlds.gem_ids(world):
		if not found_gems.has(id):
			n += 1
	return n


## The door into one of this world's courses.
func add_course_door(course_id: String, at: Vector3, face := Vector3.BACK) -> CourseDoor:
	var door := CourseDoor.new()
	door.course_id = course_id
	door.facing = face
	return add(door, at) as CourseDoor


## The door to this world's boss, shut until enough stars are found.
func add_boss_door(at: Vector3, face := Vector3.BACK) -> BossDoor:
	var boss := Worlds.boss_def(world)
	var door := BossDoor.new()
	door.course_id = str(boss.id)
	door.need = int(boss.get("door", 5))
	door.facing = face
	return add(door, at) as BossDoor


## A Skyway gate to another world (usually the one before and the one after).
func add_skyway_gate(to_world: String, at: Vector3, face := Vector3.BACK) -> SkywayGate:
	var gate := SkywayGate.new()
	gate.to_world = to_world
	gate.facing = face
	return add(gate, at) as SkywayGate


## Gates to the worlds before and after this one, wherever they exist.
func add_skyway_gates(back_at: Vector3, back_face: Vector3, on_at: Vector3, on_face: Vector3) -> void:
	var before := Worlds.neighbour(world, -1)
	var after := Worlds.neighbour(world, 1)
	if before != "":
		add_skyway_gate(before, back_at, back_face)
	if after != "":
		add_skyway_gate(after, on_at, on_face)


## A timed coin rush: step on the button, then grab every silver coin at
## `spots` within `seconds` for the star `star_id`.
func add_silver_rush(star_id: String, button_at: Vector3, spots: Array, seconds := 30.0) -> SilverRush:
	var rush := SilverRush.new()
	rush.star_id = star_id
	rush.spots = spots
	rush.seconds = seconds
	rush.button_at = button_at
	return add(rush, Vector3.ZERO) as SilverRush
