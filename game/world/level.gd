class_name Level
extends Node3D
## Base for islands and courses. Levels are code: a level's build() lays
## blocks and things with the helpers here, one unit to a grid square (x
## runs east, z south, y up), then finish() turns the repeated pieces into
## MultiMeshes.
##
## Levels build without a hero, so tests can check them. The play scene sets
## `hero` and listens to the signals below.

signal star_found(id: String)
signal coins_found(count: int)
signal gem_found(id: String)
signal heart_found
signal hurt(from: Vector3)
signal checkpoint_reached(at: Vector3, facing: Vector3)
signal course_door(course_id: String)
signal finished
signal message(text: String)
signal speech(speaker: String, lines: Array, done: Callable)

## "adventure" or "speedrun".
var mode := "adventure"
var level_id := ""
var title := ""
## Where the hero starts and which way they face.
var spawn := Vector3.ZERO
var spawn_facing := Vector3.FORWARD
var hero: Hero
## The camera's angle where no zone applies: [yaw, pitch, distance, free].
var camera_base := [0.0, 32.0, 8.5, false]
var camera_zones: Array[CameraZone] = []
## Stars already found before this visit (they show as see-through).
var found_stars := {}
var found_gems := {}
var star_count := 0
var music := "res://assets/kenney/audio/music/farm_frolics.ogg"

var _batches := {}
var _solid: StaticBody3D
var _built := false


func _init() -> void:
	_solid = StaticBody3D.new()
	_solid.name = "Solid"
	_solid.collision_layer = Kit.LAYER_WORLD
	_solid.collision_mask = 0
	add_child(_solid)


## Lays out the level. Subclasses fill it in and call finish() at the end.
func build() -> void:
	pass


func is_speedrun() -> bool:
	return mode == "speedrun"


## Adds the environment, sky and light. Called once by the play scene.
func add_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	# The islands float in the sky, so below the horizon is sky too.
	mat.sky_top_color = Color("3f8fe0")
	mat.sky_horizon_color = Color("bfe3ff")
	mat.ground_horizon_color = Color("bfe3ff")
	mat.ground_bottom_color = Color("7cbcf0")
	mat.ground_curve = 0.12
	mat.sun_angle_max = 20.0
	sky.sky_material = mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.fog_enabled = true
	e.fog_light_color = Color("cfe9ff")
	e.fog_density = 0.0035
	e.fog_aerial_perspective = 0.4
	e.fog_sky_affect = 0.0
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_blur = 1.5
	add_child(sun)


# --- Pieces ------------------------------------------------------------------

## Draws a model at `at`, turned `turn` degrees about y. Batched; no collision.
func piece(model_name: String, at: Vector3, turn := 0.0, scale := 1.0) -> void:
	if not _batches.has(model_name):
		_batches[model_name] = []
	var b := Basis(Vector3.UP, deg_to_rad(turn)).scaled(Vector3.ONE * scale)
	_batches[model_name].append(Transform3D(b, at))


## A solid box, from corner `a` to corner `b`.
func solid(a: Vector3, b: Vector3) -> CollisionShape3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = hi - lo
	shape.shape = box
	shape.position = (lo + hi) / 2.0
	_solid.add_child(shape)
	return shape


## A slab of island: the walkable top is at `top`, over the grid squares
## from (x0, z0) to (x1, z1), `depth` units deep. Grass or snow blocks.
func land(x0: int, z0: int, x1: int, z1: int, top: float, depth := 2, kind := "grass") -> void:
	solid(Vector3(x0, top - depth, z0), Vector3(x1, top, z1))
	var y := top
	var remaining := depth
	while remaining > 0:
		var h := 2 if remaining >= 2 else 1
		y -= h
		var x := x0
		while x < x1:
			var wide := x + 2 <= x1
			var z := z0
			while z < z1:
				if wide and z + 2 <= z1:
					piece("block-%s-large%s" % [kind, "-tall" if h == 2 else ""], Vector3(x + 1, y, z + 1))
					z += 2
				else:
					for dx in (2 if wide else 1):
						for dy in h:
							piece("block-%s" % kind, Vector3(x + dx + 0.5, y + dy, z + 0.5))
					z += 1
			x += 2 if wide else 1
		remaining -= h


## A thin floating platform of low blocks.
func ledge(x0: int, z0: int, x1: int, z1: int, top: float, kind := "grass") -> void:
	solid(Vector3(x0, top - 0.5, z0), Vector3(x1, top, z1))
	for x in range(x0, x1):
		for z in range(z0, z1):
			piece("block-%s-low" % kind, Vector3(x + 0.5, top - 0.5, z + 0.5))


## A 2 by 2 slope centred on `at` (its foot at at.y), climbing 0.76 towards
## `dir` (a grid direction). The hero steps up the last bit onto a block.
func ramp(at: Vector3, dir: Vector3, kind := "grass") -> void:
	var turn := atan2(-dir.x, -dir.z)
	piece("block-%s-large-slope" % kind, at, rad_to_deg(turn))
	var shape := CollisionShape3D.new()
	var wedge := ConvexPolygonShape3D.new()
	wedge.points = PackedVector3Array([
		Vector3(-1, 0, 1), Vector3(1, 0, 1), Vector3(-1, 0, -1), Vector3(1, 0, -1),
		Vector3(-1, 0.76, -1), Vector3(1, 0.76, -1)])
	shape.shape = wedge
	shape.basis = Basis(Vector3.UP, turn)
	shape.position = at
	_solid.add_child(shape)


## A tree or other tall scenery with a trunk the hero bumps into.
func tree(at: Vector3, kind := "tree", scale := 1.0) -> void:
	piece(kind, at, fmod(absf(at.x * 37.0 + at.z * 11.0), 360.0), scale)
	solid(at + Vector3(-0.18, 0, -0.18) * scale, at + Vector3(0.18, 1.7, 0.18) * scale)


## Scenery the hero walks through (flowers, grass, mushrooms).
func deco(model_name: String, at: Vector3, turn := 0.0, scale := 1.0) -> void:
	piece(model_name, at, turn, scale)


## Adds a thing (pickup, hazard, platform...) to the level.
func add(thing: Node3D, at: Vector3) -> Node3D:
	thing.position = at
	if "level" in thing:
		thing.level = self
	add_child(thing)
	return thing


func camera_zone(a: Vector3, b: Vector3, yaw: float, pitch := 32.0, distance := 8.5, free := false, rank := 0) -> CameraZone:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var z := CameraZone.make(AABB(lo, hi - lo), yaw, pitch, distance, free, rank)
	camera_zones.append(z)
	add_child(z)
	return z


## Turns the batched pieces into MultiMeshes.
func finish() -> void:
	for model_name in _batches:
		var xfs: Array = _batches[model_name]
		for entry in Kit.meshes(model_name):
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = entry[0]
			mm.instance_count = xfs.size()
			var local: Transform3D = entry[1]
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i] * local)
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Batch_" + model_name
			mmi.multimesh = mm
			add_child(mmi)
	_batches.clear()
	_built = true
	_keep_active(self)


## Keeps collision working while the level is paused (the speedrun
## countdown pauses it so nothing moves before the start).
func _keep_active(n: Node) -> void:
	if n is CollisionObject3D:
		(n as CollisionObject3D).disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	for c in n.get_children():
		_keep_active(c)


## How many pieces of each model are waiting to be drawn (for tests).
func batch_size(model_name: String) -> int:
	return (_batches.get(model_name, []) as Array).size()


# --- Events from things ------------------------------------------------------

func collect_star(id: String) -> void:
	var fresh := not found_stars.has(id)
	found_stars[id] = true
	if fresh:
		star_count += 1
	star_found.emit(id)


func collect_coins(n: int) -> void:
	coins_found.emit(n)


func collect_gem(id: String) -> void:
	found_gems[id] = true
	gem_found.emit(id)


func collect_heart() -> void:
	heart_found.emit()


func hurt_hero(from: Vector3) -> void:
	if hero and hero.take_hit(from):
		hurt.emit(from)


func reach_checkpoint(at: Vector3, facing: Vector3) -> void:
	checkpoint_reached.emit(at, facing)


func say(text: String) -> void:
	message.emit(text)


## Shows lines of speech one at a time; `done` runs after the last.
func speak(speaker: String, lines: Array, done := Callable()) -> void:
	speech.emit(speaker, lines, done)


func finish_course() -> void:
	finished.emit()


func enter_course(course_id: String) -> void:
	course_door.emit(course_id)


## Ground pounds break crates and bricks and press buttons under the hero.
func on_pounded(at: Vector3) -> void:
	for n in get_tree().get_nodes_in_group("poundable"):
		if not is_ancestor_of(n):
			continue
		var p: Vector3 = n.global_position
		var flat := Vector2(p.x - at.x, p.z - at.z).length()
		if flat < 0.9 and p.y <= at.y + 0.1 and p.y > at.y - 1.4:
			n.pound()


## The nearest thing the hero can talk to or use, or null.
func nearest_talker() -> Node3D:
	if hero == null:
		return null
	var best: Node3D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("talker"):
		if not is_ancestor_of(n) or not n.can_talk():
			continue
		var d: float = n.global_position.distance_to(hero.global_position)
		if d < n.talk_range() and d < best_d:
			best = n
			best_d = d
	return best
