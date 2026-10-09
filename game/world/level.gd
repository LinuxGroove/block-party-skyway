class_name Level
extends Node3D
## Base for islands and courses. Levels are code: a level's build() lays
## blocks and things with the helpers here, one unit to a grid square (x
## runs east, z south, y up), then finish() turns the repeated pieces into
## MultiMeshes.
##
## Levels build without a hero, so tests can check them. The play scene sets
## `hero` and listens to the signals below.
##
## The helpers for coins, gems, hearts and checkpoints leave them out of
## Speedrun by themselves, so a course is written once for both modes.

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
## A timed challenge's clock: a label and seconds left, or seconds < 0 to
## hide it.
signal countdown(label: String, seconds: float)
## Fell in water (or anything else that sends the hero back to the flag).
signal fell
## Leave for another level: an island through a Skyway gate.
signal travel(level_id: String, arrive: Dictionary)

## "adventure" or "speedrun".
var mode := "adventure"
var level_id := ""
## The world this level belongs to (see Worlds).
var world := ""
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
## Left empty, these come from the world's data: the music, the sky (see
## add_environment()) and the colour map for the grass and snow blocks.
var music := ""
var sky := {}
var block_palette := ""
## Gravity for the hero here (below 1 for the low gravity of space).
var gravity_scale := 1.0

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
## `sky` can set: top, horizon, bottom (colours), fog (colour), fog_density,
## sun_energy, sun_color, sun_angle (degrees above the horizon), ambient.
func add_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_res := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	# The islands float in the sky, so below the horizon is sky too.
	mat.sky_top_color = Color(sky.get("top", "3f8fe0"))
	mat.sky_horizon_color = Color(sky.get("horizon", "bfe3ff"))
	mat.ground_horizon_color = mat.sky_horizon_color
	mat.ground_bottom_color = Color(sky.get("bottom", "7cbcf0"))
	mat.ground_curve = 0.12
	mat.sun_angle_max = 20.0
	sky_res.sky_material = mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky_res
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = float(sky.get("ambient", 0.9))
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.fog_enabled = true
	e.fog_light_color = Color(sky.get("fog", "cfe9ff"))
	e.fog_density = float(sky.get("fog_density", 0.0035))
	e.fog_aerial_perspective = 0.4
	e.fog_sky_affect = 0.0
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-float(sky.get("sun_angle", 55.0)), -35, 0)
	sun.light_energy = float(sky.get("sun_energy", 1.0))
	sun.light_color = Color(sky.get("sun_color", "ffffff"))
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


## A star (see-through if found on an earlier visit).
func add_star(id: String, at: Vector3) -> Pickup:
	return add(Pickup.make("star", id, found_stars.has(id)), at) as Pickup


## A hidden gem. Not in Speedrun.
func add_gem(id: String, at: Vector3) -> Pickup:
	if is_speedrun():
		return null
	return add(Pickup.make("gem", id, found_gems.has(id)), at) as Pickup


## A coin. Not in Speedrun.
func add_coin(at: Vector3) -> void:
	if not is_speedrun():
		add(Pickup.make("coin"), at)


## `n` coins in a line from `from` to `to`, a little above.
func coin_line(from: Vector3, to: Vector3, n: int) -> void:
	for i in n:
		add_coin(from.lerp(to, float(i) / maxf(n - 1, 1)) + Vector3.UP * 0.1)


func coin_ring(center: Vector3, radius: float, n: int) -> void:
	for i in n:
		var a := TAU * i / n
		add_coin(center + Vector3(cos(a), 0.1, sin(a)) * radius)


## A heart, which gives one back. Not in Speedrun.
func add_heart(at: Vector3) -> void:
	if not is_speedrun():
		add(Pickup.make("heart"), at)


## A checkpoint flag; falling off comes back here. Not in Speedrun.
func add_checkpoint(at: Vector3, face: Vector3) -> Checkpoint:
	if is_speedrun():
		return null
	var c := Checkpoint.new()
	c.facing = face
	return add(c, at) as Checkpoint


## A sign; walk up to it to read it.
func add_sign(text: String, at: Vector3, face := Vector3.BACK) -> SignPost:
	var s := SignPost.new()
	s.text = text
	s.facing = face
	return add(s, at) as SignPost


## A course's finish flag.
func add_flag(at: Vector3, face := Vector3.FORWARD) -> FinishFlag:
	var f := FinishFlag.new()
	f.facing = face
	return add(f, at) as FinishFlag


## An islander to talk to. Set on_talk on the result for one with a request.
func add_islander(model_name: String, who: String, lines: Array, at: Vector3, face := Vector3.BACK, scale := 0.42) -> Islander:
	var i := Islander.make(model_name, who, lines, scale)
	i.facing = face
	return add(i, at) as Islander


## A slippery slab of ice over the grid squares from (x0, z0) to (x1, z1).
## The hero slides about on it (see Hero.ICE_GRIP).
func ice(x0: int, z0: int, x1: int, z1: int, top: float, depth := 1.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Kit.LAYER_WORLD
	body.collision_mask = 0
	body.set_meta("ice", true)
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(x1 - x0, depth, z1 - z0)
	shape.shape = box
	shape.position = Vector3((x0 + x1) / 2.0, top - depth / 2.0, (z0 + z1) / 2.0)
	body.add_child(shape)
	for x in range(x0, x1):
		for z in range(z0, z1):
			piece("block-moving-blue", Vector3(x + 0.5, top - 0.5, z + 0.5))
	return body


## A sheet of water (or soda, or lava: any colour) at height `y` between
## two corners. Falling in sends the hero back to the last flag, like
## falling off the island.
func water(x0: float, z0: float, x1: float, z1: float, y: float, color := Color(0.25, 0.6, 0.95, 0.75)) -> Area3D:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(x1 - x0, z1 - z0)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.15
	mat.metallic_specular = 0.8
	mesh.material_override = mat
	mesh.position = Vector3((x0 + x1) / 2.0, y, (z0 + z1) / 2.0)
	add_child(mesh)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Kit.LAYER_HERO
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(x1 - x0, 4.0, z1 - z0)
	shape.shape = box
	shape.position = Vector3((x0 + x1) / 2.0, y - 2.0 - 0.45, (z0 + z1) / 2.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_water)
	return area


func _on_water(body: Node3D) -> void:
	if body == hero:
		fall_off()


## Sends the hero back to the last flag, as if they'd fallen off.
func fall_off() -> void:
	fell.emit()


## Where the hero arrives for `arrive` (from Play.open), as
## {"position": Vector3, "facing": Vector3}, or {} for the level's start.
## Things in the "arrival" group with a matching `arrive_id` (course
## doors, the boss door, Skyway gates) are arrival points.
func arrival(arrive: Dictionary) -> Dictionary:
	if arrive.has("position"):
		return arrive
	var id := str(arrive.get("door", ""))
	if id == "":
		return {}
	for n in get_tree().get_nodes_in_group("arrival") if is_inside_tree() else []:
		if is_ancestor_of(n) and str(n.arrive_id) == id:
			var face: Vector3 = n.facing
			return {"position": (n as Node3D).global_position + face * 1.7 + Vector3.UP * 0.1, "facing": face}
	return {}


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
		var recolour: Material = null
		if block_palette != "" and str(model_name).begins_with("block-"):
			recolour = _palette_material()
		for entry in Kit.meshes(model_name):
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = entry[0]
			mm.instance_count = xfs.size()
			var local: Transform3D = entry[1]
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i] * local)
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Batch_" + model_name.replace(":", "_")
			mmi.multimesh = mm
			if recolour:
				mmi.material_override = recolour
			add_child(mmi)
	_batches.clear()
	_built = true
	_keep_active(self)


var _palette_mat: Material


## The kit's block material with this world's colour map.
func _palette_material() -> Material:
	if _palette_mat == null:
		var base: Material = null
		for entry in Kit.meshes("block-grass"):
			base = (entry[0] as Mesh).surface_get_material(0)
		var mat: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
		mat.albedo_texture = load(block_palette)
		_palette_mat = mat
	return _palette_mat


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


## Leaves for another level (a Skyway gate to another world's island).
func travel_to(id: String, arrive := {}) -> void:
	travel.emit(id, arrive)


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
