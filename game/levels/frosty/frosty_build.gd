class_name FrostyBuild
extends RefCounted
## Builders shared by Frosty Peaks' levels: Holiday Kit cabins with roofs
## you can stand on, giant presents to climb, and snowy scenery. Each works
## on a level before its finish(), through the level's own pieces and
## collision.

## The Holiday Kit's cabin pieces are one unit square; cabins draw them at
## twice that, so a storey is 2 m and a door fits the hero.
const CABIN := 2.0
## Roofs are squashed a little from the kit's steep pitch so they can be
## walked on: the ridge stands this far over the top of the walls.
const ROOF_SQUASH := 0.62
const RIDGE := 1.28 * ROOF_SQUASH * CABIN
const PRESENTS := ["present-a-cube", "present-b-cube", "present-a-round", "present-b-round"]
## How tall each present's box is (body and lid) in the kit's units; the
## bow stands 0.17 over it.
const PRESENT_BOX := [0.4, 0.3, 0.4, 0.3]


## Draws a model with a scale per axis (Level.piece() scales evenly).
static func put(level: Level, model_name: String, at: Vector3, turn: float, scale: Vector3) -> void:
	if not level._batches.has(model_name):
		level._batches[model_name] = []
	var b := Basis(Vector3.UP, deg_to_rad(turn)).scaled(scale)
	level._batches[model_name].append(Transform3D(b, at))


## A body for collision shapes that aren't boxes (roofs).
static func _body(level: Level) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Kit.LAYER_WORLD
	body.collision_mask = 0
	level.add_child(body)
	return body


## A log cabin `w` by `d` tiles (2 m each) with its south-west corner at
## (x, z) on ground `y`: walls with windows, a door in the middle of the
## side facing `door` (a grid direction), and a snowy roof whose ridge runs
## north to south. The walls and roof are solid; the roof's slopes can be
## walked on. `chimney` puts a chimney on the roof (scenery).
static func cabin(level: Level, x: float, z: float, w := 2, d := 2, y := 0.0, door := Vector3.BACK, chimney := true) -> void:
	var s := CABIN
	var x1 := x + w * s
	var z1 := z + d * s
	# Walls: one piece per tile on each side, turned to face out.
	var sides := [[Vector3.BACK, 0.0], [Vector3.RIGHT, 90.0], [Vector3.FORWARD, 180.0], [Vector3.LEFT, 270.0]]
	for side in sides:
		var dir: Vector3 = side[0]
		var turn: float = side[1]
		var n := w if dir.z != 0.0 else d
		for i in n:
			var cx: float
			var cz: float
			if dir.z != 0.0:
				cx = x + (i + 0.5) * s
				cz = z1 - 0.5 * s if dir.z > 0.0 else z + 0.5 * s
			else:
				cz = z + (i + 0.5) * s
				cx = x1 - 0.5 * s if dir.x > 0.0 else x + 0.5 * s
			var model := "holiday:cabin-wall"
			if dir == door and i == n / 2:
				model = "holiday:cabin-door-rotate"
			elif (i + int(turn / 90.0)) % 2 == 0:
				model = "holiday:cabin-window-a"
			elif dir == Vector3.BACK:
				model = "holiday:cabin-wall-wreath"
			level.piece(model, Vector3(cx, y, cz), turn, s)
	# Corner logs.
	var corners := [[Vector3(x, y, z1), 0.0], [Vector3(x1, y, z1), 90.0], [Vector3(x1, y, z), 180.0], [Vector3(x, y, z), 270.0]]
	for c in corners:
		var at: Vector3 = c[0]
		# The piece sits at a tile's south-west corner; step back to that tile's middle.
		var off := Vector3(0.5, 0, -0.5).rotated(Vector3.UP, deg_to_rad(c[1])) * s
		level.piece("holiday:cabin-corner-logs", at + off, c[1], s)
	var top := y + s
	level.solid(Vector3(x, y, z), Vector3(x1, top, z1))
	# The roof: two slopes meeting over the middle, a piece per tile.
	var mid := (x + x1) / 2.0
	var scale := Vector3(s, s * ROOF_SQUASH, s)
	for i in d:
		var cz := z + (i + 0.5) * s
		for j in w / 2:
			var model := "holiday:cabin-roof-snow"
			if chimney and i == d - 1 and j == 0:
				model = "holiday:cabin-roof-snow-chimney"
			put(level, model, Vector3(mid + (0.5 + j) * s, top, cz), 0.0, scale)
			put(level, "holiday:cabin-roof-snow", Vector3(mid - (0.5 + j) * s, top, cz), 180.0, scale)
	# Gable ends under the roof: one triangle across each end.
	var gable := Vector3(2.0 * s, s * ROOF_SQUASH, s)
	put(level, "holiday:cabin-wall-roof-center", Vector3(mid, top, z1 - 0.5 * s), 0.0, gable)
	put(level, "holiday:cabin-wall-roof-center", Vector3(mid, top, z + 0.5 * s), 180.0, gable)
	# Roof collision: a wedge with its ridge over the middle, out to the eaves.
	var shape := CollisionShape3D.new()
	var wedge := ConvexPolygonShape3D.new()
	var ex := 0.28 * s
	var ez := 0.2 * s
	wedge.points = PackedVector3Array([
		Vector3(x - ex, top, z - ez), Vector3(x1 + ex, top, z - ez),
		Vector3(x - ex, top, z1 + ez), Vector3(x1 + ex, top, z1 + ez),
		Vector3(mid, top + RIDGE, z - ez), Vector3(mid, top + RIDGE, z1 + ez)])
	shape.shape = wedge
	_body(level).add_child(shape)


## A giant present: a box `size` wide (x and z) and `h` tall, its middle at
## `at` (on its foot), solid and drawn from the kit's presents. See gift().
static func present(level: Level, at: Vector3, size: float, h: float, kind := 0, turn := 0.0, bow := false) -> void:
	gift(level, at + Vector3(-size / 2.0, 0, -size / 2.0), at + Vector3(size / 2.0, h, size / 2.0), kind, turn, bow)


## A giant present filling the box from `lo` to `hi`, solid. Presents to
## stand on are drawn upside down, their bows hidden in whatever they stand
## on, so the top is flat; `bow` keeps the bow on top (it's scenery, and the
## hero walks through it). Kinds 2 and 3 are round, for scenery.
static func gift(level: Level, lo: Vector3, hi: Vector3, kind := 0, turn := 0.0, bow := false) -> void:
	var k := kind % PRESENTS.size()
	var model: String = "holiday:" + PRESENTS[k]
	var wide := 0.55 if k >= 2 else 0.45
	var size := hi - lo
	var foot := Vector3((lo.x + hi.x) / 2.0, lo.y, (lo.z + hi.z) / 2.0)
	var b := Basis(Vector3.UP, deg_to_rad(turn))
	if not bow:
		b = b * Basis(Vector3.RIGHT, PI)
		foot.y = hi.y
	b = b * Basis.from_scale(Vector3(size.x / wide, size.y / PRESENT_BOX[k], size.z / wide))
	if not level._batches.has(model):
		level._batches[model] = []
	level._batches[model].append(Transform3D(b, foot))
	level.solid(lo, hi)


static var _ice_mat: StandardMaterial3D


## A slippery slab of ice (Level.ice()) with a glassy sheet over the kit's
## blue blocks, so it reads as ice.
static func ice(level: Level, x0: int, z0: int, x1: int, z1: int, top: float, depth := 0.5) -> StaticBody3D:
	var body := level.ice(x0, z0, x1, z1, top, depth)
	var sheet := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(x1 - x0, z1 - z0)
	sheet.mesh = plane
	if _ice_mat == null:
		_ice_mat = StandardMaterial3D.new()
		_ice_mat.albedo_color = Color(0.74, 0.9, 1.0, 0.82)
		_ice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ice_mat.roughness = 0.08
		_ice_mat.metallic_specular = 1.0
		_ice_mat.rim_enabled = true
		_ice_mat.rim = 0.4
	sheet.material_override = _ice_mat
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheet.position = Vector3((x0 + x1) / 2.0, top + 0.012, (z0 + z1) / 2.0)
	level.add_child(sheet)
	return body
