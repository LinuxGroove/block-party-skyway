class_name CastleParts
extends RefCounted
## Sky Castle's building pieces: the Castle Kit's towers, walls, arches and
## stairs drawn at a scale, with solid boxes that match, plus banners,
## trees and the sea of clouds the castle floats over. Every level of the
## world builds with these, like Level's own land() and ledge().

## A tower storey, a wall's walkway and an arch's opening, at scale 1.
const STOREY := 1.01
const WALK := 1.18
const ARCH_OPEN := 0.73


## A square tower `size` across with its foot centred on `at`: `storeys`
## storeys, then a top. "walk" is a crenellated floor to stand on (low solid
## rims stop a walk off the edge), "roof" a pointed roof, "spire" a tall
## one, "dome" a rounded one, "" nothing. Returns the height you stand on:
## the floor of a "walk" top, else the top of the last storey. `edge` puts
## low solid rims round a "walk" top; `solid` false leaves the collision to
## the caller (for a tower with a secret in it).
static func tower(level: Level, at: Vector3, size: float, storeys: int, top := "walk", windows := true, edge := false, solid := true) -> float:
	var y := at.y
	for i in storeys:
		var model := "castle:tower-square-base" if i == 0 else ("castle:tower-square-mid-windows" if windows and i % 2 == 1 else "castle:tower-square-mid")
		level.piece(model, Vector3(at.x, y, at.z), 0.0, size)
		y += STOREY * size
	var floor_y := y
	match top:
		"walk":
			level.piece("castle:tower-square-top", Vector3(at.x, y, at.z), 0.0, size)
			floor_y = y + 0.17 * size
			if edge:
				rims(level, Vector3(at.x, floor_y, at.z), size, size, 0.13 * size)
		"roof":
			level.piece("castle:tower-square-roof", Vector3(at.x, y, at.z), 0.0, size)
		"spire":
			level.piece("castle:tower-square-top-roof-high", Vector3(at.x, y, at.z), 0.0, size)
		"dome":
			level.piece("castle:tower-square-top-roof-rounded", Vector3(at.x, y, at.z), 0.0, size)
	if solid:
		var h := size / 2.0
		level.solid(Vector3(at.x - h, at.y, at.z - h), Vector3(at.x + h, floor_y, at.z + h))
	return floor_y


## A round (hexagonal) tower about `size` across: a base, `mids` short
## storeys, and a roof ("roof", "spire" or "walk" for a wooden top to stand
## on). Returns the height of its top floor.
static func round_tower(level: Level, at: Vector3, size: float, mids: int, top := "roof") -> float:
	var y := at.y
	level.piece("castle:tower-hexagon-base", at, 0.0, size)
	y += 1.31 * size
	for i in mids:
		level.piece("castle:tower-hexagon-mid", Vector3(at.x, y, at.z), 0.0, size)
		y += 0.46 * size
	var floor_y := y
	match top:
		"roof":
			level.piece("castle:tower-hexagon-roof", Vector3(at.x, y, at.z), 0.0, size)
		"spire":
			level.piece("castle:tower-hexagon-roof-secondary", Vector3(at.x, y, at.z), 0.0, size)
		"walk":
			level.piece("castle:tower-hexagon-top", Vector3(at.x, y, at.z), 0.0, size)
			floor_y = y + 0.08 * size
	level.solid(Vector3(at.x - 0.43 * size, at.y, at.z - 0.39 * size), Vector3(at.x + 0.43 * size, floor_y, at.z + 0.39 * size))
	return floor_y


## Low solid rims round the edge of a `w` by `d` floor centred on `at`, so a
## careless step doesn't go over (a jump still does).
static func rims(level: Level, at: Vector3, w: float, d: float, thick := 0.3, high := 0.4) -> void:
	var hw := w / 2.0
	var hd := d / 2.0
	level.solid(Vector3(at.x - hw, at.y, at.z - hd), Vector3(at.x + hw, at.y + high, at.z - hd + thick))
	level.solid(Vector3(at.x - hw, at.y, at.z + hd - thick), Vector3(at.x + hw, at.y + high, at.z + hd))
	level.solid(Vector3(at.x - hw, at.y, at.z - hd), Vector3(at.x - hw + thick, at.y + high, at.z + hd))
	level.solid(Vector3(at.x + hw - thick, at.y, at.z - hd), Vector3(at.x + hw, at.y + high, at.z + hd))


## A run of crenellated wall from `a` to `b`, straight along x or z with its
## foot at a.y, drawn `scale` thick. Solid up to its walkway, with a low
## solid parapet down the sides in `rim_sides` (-1 is the left of a to b, 1
## the right). Returns the walkway's height.
static func wall(level: Level, a: Vector3, b: Vector3, scale := 2.0, rim_sides := [-1.0, 1.0]) -> float:
	var along := Vector3(b.x - a.x, 0, b.z - a.z)
	var length := along.length()
	var dir := along / maxf(length, 0.001)
	var across := Vector3(-dir.z, 0, dir.x)
	var n := maxi(1, roundi(length / scale))
	var step := length / n
	# The kit's wall runs along z.
	var turn := rad_to_deg(atan2(dir.x, dir.z))
	for i in n:
		level.piece("castle:wall", a + dir * step * (i + 0.5), turn, scale)
	var top := a.y + WALK * scale
	var h := across * scale / 2.0
	var lo := a - h
	var hi := b + h
	level.solid(Vector3(minf(lo.x, hi.x), a.y, minf(lo.z, hi.z)), Vector3(maxf(lo.x, hi.x), top, maxf(lo.z, hi.z)))
	for side in rim_sides:
		var s := float(side)
		var edge: Vector3 = across * s * scale * 0.44
		var p0: Vector3 = a + edge - across * 0.06 * scale
		var p1: Vector3 = b + edge + across * 0.06 * scale
		level.solid(Vector3(minf(p0.x, p1.x), top, minf(p0.z, p1.z)), Vector3(maxf(p0.x, p1.x), top + 0.4, maxf(p0.z, p1.z)))
	return top


## An open arch (the kit's archway block) `size` across with its foot centred
## on `at`: four solid corner posts, open on every side. Its top has no
## collision: it's out of reach, and the camera looks through it at a hero
## who has just run under it. Returns the height of its top.
static func arch(level: Level, at: Vector3, size: float) -> float:
	level.piece("castle:tower-square-arch", at, 0.0, size)
	var h := size * 0.465
	var post := size * 0.05
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := at + Vector3(sx * (h - post / 2.0), 0, sz * (h - post / 2.0))
			level.solid(c + Vector3(-post / 2.0, 0, -post / 2.0), c + Vector3(post / 2.0, ARCH_OPEN * size, post / 2.0))
	return at.y + STOREY * size


## A tower a wall walk runs through: a solid base storey up to `floor_at`,
## an open arch on top of it (the way through, on every side) and a roof.
static func arch_tower(level: Level, floor_at: Vector3, size: float, roof := "castle:tower-square-top-roof-high") -> void:
	var foot := floor_at - Vector3.UP * STOREY * size
	level.piece("castle:tower-square-base", foot, 0.0, size)
	var h := size / 2.0
	level.solid(Vector3(foot.x - h, foot.y, foot.z - h), Vector3(foot.x + h, floor_at.y, foot.z + h))
	var top := arch(level, floor_at, size)
	if roof != "":
		level.piece(roof, Vector3(floor_at.x, top, floor_at.z), 0.0, size)
	_footing(level, foot, Vector3(1, 0, 1))


## A wall (see wall()) standing on a narrow footing of stone that hangs in
## the sky. Returns the walkway's height.
static func rampart(level: Level, a: Vector3, b: Vector3, scale := 3.0, rim_sides := [-1.0, 1.0]) -> float:
	var top := wall(level, a, b, scale, rim_sides)
	var along := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
	var across := Vector3(absf(along.z), 0, absf(along.x))
	var lo := Vector3(minf(a.x, b.x), a.y, minf(a.z, b.z)) - across
	var hi := Vector3(maxf(a.x, b.x), a.y, maxf(a.z, b.z)) + across
	level.land(roundi(lo.x), roundi(lo.z), roundi(hi.x), roundi(hi.z), a.y, 3, "snow")
	return top


## A square bastion of stone `size` metres across with its top centred on
## `center`, and little turrets with pointed roofs on the corners listed in
## `corners` (Vector2(1, -1) is the north-east one).
static func bastion(level: Level, center: Vector3, size: int, corners: Array = [], depth := 4) -> void:
	var h := size / 2
	var cx := roundi(center.x)
	var cz := roundi(center.z)
	level.land(cx - h, cz - h, cx + h, cz + h, center.y, depth, "snow")
	for c in corners:
		var corner: Vector2 = c
		var at := Vector3(cx + corner.x * (h - 0.6), center.y, cz + corner.y * (h - 0.6))
		tower(level, at, 1.2, 2, "roof")


## Stone under a tower's foot, 2 m across, so it doesn't float on nothing.
static func _footing(level: Level, foot: Vector3, half: Vector3) -> void:
	var lo := foot - half
	var hi := foot + half
	level.land(roundi(lo.x), roundi(lo.z), roundi(hi.x), roundi(hi.z), foot.y, 3, "snow")


## Stone stairs from `foot` climbing `rise` towards `dir` (a grid direction),
## about `width` wide: a slope to walk up, drawn with the kit's steps.
## Returns where they come out at the top.
static func stairs(level: Level, foot: Vector3, dir: Vector3, rise: float, width := 2.0) -> Vector3:
	var k := rise / 0.67
	var run := 0.82 * k
	var piece_w := 0.24 * k
	var n := maxi(1, ceili(width / piece_w - 0.05))
	var across := Vector3(-dir.z, 0, dir.x)
	var turn := rad_to_deg(atan2(dir.x, dir.z))
	for i in n:
		var off := (i - (n - 1) / 2.0) * piece_w
		level.piece("castle:stairs-stone", foot + dir * run / 2.0 + across * off, turn, k)
	var w := n * piece_w
	var body := StaticBody3D.new()
	body.collision_layer = Kit.LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var wedge := ConvexPolygonShape3D.new()
	var hw := w / 2.0
	# Built climbing towards -z, then turned to `dir`.
	wedge.points = PackedVector3Array([
		Vector3(-hw, 0, 0), Vector3(hw, 0, 0), Vector3(-hw, 0, -run), Vector3(hw, 0, -run),
		Vector3(-hw, rise, -run), Vector3(hw, rise, -run)])
	shape.shape = wedge
	body.add_child(shape)
	body.basis = Basis(Vector3.UP, atan2(-dir.x, -dir.z))
	body.position = foot
	level.add_child(body)
	return foot + dir * run + Vector3.UP * rise


## A long banner hanging flat against a wall that faces `face`, its top at
## `top`.
static func banner(level: Level, top: Vector3, face: Vector3, long := true, scale := 2.0) -> void:
	var model := "castle:flag-banner-long" if long else "castle:flag-banner-short"
	var tall := (2.17 if long else 0.78) * scale
	level.piece(model, top - Vector3.UP * tall + face * 0.05, rad_to_deg(atan2(face.x, face.z)) - 90.0, scale)


## A pennant on a short pole, on top of a tower.
static func pennant(level: Level, at: Vector3, turn := 0.0, scale := 2.0) -> void:
	level.piece("castle:flag-pennant", at, turn, scale)


## One of the kit's trees, with a trunk to bump into.
static func tree(level: Level, at: Vector3, large := true, scale := 2.0) -> void:
	level.piece("castle:tree-large" if large else "castle:tree-small", at, fmod(absf(at.x * 37.0 + at.z * 11.0), 360.0), scale)
	level.solid(at + Vector3(-0.12, 0, -0.12) * scale, at + Vector3(0.12, 0.9, 0.12) * scale)


## A pile of rocks to bump into.
static func rocks(level: Level, at: Vector3, large := true, scale := 1.5) -> void:
	var turn := fmod(absf(at.x * 53.0 + at.z * 17.0), 360.0)
	level.piece("castle:rocks-large" if large else "castle:rocks-small", at, turn, scale)
	var r := (0.45 if large else 0.38) * scale
	level.solid(at + Vector3(-r, 0, -r), at + Vector3(r, 0.45 * scale, r))


## A siege engine for scenery (solid): "catapult", "ballista", "ram",
## "trebuchet" or "tower", facing `face` (its working end).
static func siege(level: Level, kind: String, at: Vector3, face: Vector3, scale := 1.4) -> void:
	# The kit's siege engines face +x.
	level.piece("castle:siege-" + kind, at, rad_to_deg(atan2(-face.z, face.x)), scale)
	var size: Vector3 = {"catapult": Vector3(1.4, 1.0, 1.0), "ballista": Vector3(1.0, 0.8, 1.0), "ram": Vector3(1.8, 1.0, 0.9),
		"trebuchet": Vector3(1.4, 1.6, 1.0), "tower": Vector3(0.9, 2.6, 0.9)}.get(kind, Vector3.ONE) * scale
	var h := (Basis(Vector3.UP, atan2(-face.z, face.x)) * Vector3(size.x, 0, size.z)).abs() / 2.0
	level.solid(at - Vector3(h.x, 0, h.z), at + Vector3(h.x, size.y, h.z))


## A sea of clouds below the island: soft puffs in a ring from `inner` to
## `outer` metres round `center`, between y `low` and `high`.
static func cloud_sea(level: Level, center: Vector3, inner: float, outer: float, low := -16.0, high := -9.0, count := 60, seed_value := 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	mm.mesh = sphere
	var xfs: Array[Transform3D] = []
	for i in count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf_range(inner * inner, outer * outer))
		var c := center + Vector3(cos(a) * r, rng.randf_range(low, high), sin(a) * r)
		var big := rng.randf_range(2.5, 5.0)
		for j in rng.randi_range(3, 5):
			var p := c + Vector3(rng.randf_range(-1.2, 1.2) * big, rng.randf_range(-0.2, 0.3) * big, rng.randf_range(-1.0, 1.0) * big)
			var s := big * rng.randf_range(0.6, 1.0)
			xfs.append(Transform3D(Basis().scaled(Vector3(s, s * 0.55, s)), p))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "CloudSea"
	mmi.multimesh = mm
	mmi.material_override = CastleCloud.cloud_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(mmi)
