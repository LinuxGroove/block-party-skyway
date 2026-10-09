class_name PirateBuild
extends RefCounted
## Building helpers for Pirate Cove's levels: docks of plank platforms on
## posts, and ships (or any big Pirate Kit model) to stand on, with
## collision made from the model's own hull, so decks, rails, stairs and
## masts are exactly where they look.
##
##   PirateBuild.dock(self, Vector3(0, 0, -3), Vector3(0, 0, -13))
##   PirateBuild.ship(self, "pirate:ship-pirate-large", Vector3(0, -1.5, -20), 90.0, 1.35)

## The sea's surface.
const SEA := -0.6
const SEA_COLOR := Color(0.13, 0.56, 0.84, 0.9)


## The sea all round: falling in sends the hero back to the last flag.
static func sea(level: Level) -> void:
	level.water(-160, -160, 160, 160, SEA, SEA_COLOR)


## A dock from `a` to `b` (a straight line along x or z, in whole 2.5 m
## pieces), its walkway at a.y and 2.5 m wide.
static func dock(level: Level, a: Vector3, b: Vector3) -> void:
	var along := b - a
	along.y = 0.0
	var n := maxi(1, int(roundf(along.length() / 2.5)))
	var dir := along.normalized()
	var side := dir.cross(Vector3.UP)
	var turn := 90.0 if absf(dir.x) > 0.5 else 0.0
	for i in n:
		var at := a + dir * (2.5 * i + 1.25)
		level.piece("pirate:structure-platform", Vector3(at.x, a.y - 0.9, at.z), turn)
	var end := a + dir * (2.5 * n)
	level.solid(a - side * 1.25 + Vector3.DOWN * 0.3, end + side * 1.25)


## Adds `model` at `at`, turned `turn` degrees about y and scaled, with
## collision from its main mesh (sails and flags left out, and hidden when
## `sails` is false, for a clear view of the deck). With `solid` false it's
## only scenery, for a level that lays its own boxes. Returns the model.
static func ship(level: Level, model: String, at: Vector3, turn := 0.0, scale := 1.0, sails := true, solid := true) -> Node3D:
	var n := Kit.model(model)
	n.position = at
	n.rotation_degrees.y = turn
	n.scale = Vector3.ONE * scale
	level.add_child(n)
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(turn)).scaled(Vector3.ONE * scale), at)
	var body: StaticBody3D = null
	if solid:
		body = StaticBody3D.new()
		body.collision_layer = Kit.LAYER_WORLD
		body.collision_mask = 0
		level.add_child(body)
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var part := str(mi.name)
		if part.begins_with("sail") or part.begins_with("flag") or part.begins_with("grass"):
			if not sails and not part.begins_with("grass"):
				mi.visible = false
			continue
		if body == null:
			continue
		var local := _local(n, mi)
		var faces := mi.mesh.get_faces()
		for i in faces.size():
			faces[i] = xf * (local * faces[i])
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
	return n


## Where a mesh sits inside a model, without the model's own transform.
static func _local(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p: Node = n
	while p != null and p != root:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t
