class_name StationDeco
extends RefCounted
## Star Station's building pieces, shared by its island, courses and King
## Thud's throne room: the Space Station Kit's walls, rails, consoles and
## crates scaled up to the astronauts, panelled floors, and the space around
## the station (stars, a planet below and a moon).

## The kit is made for small figures: its walls are a metre tall.
const WALL_SCALE := 2.0


## A run of station wall from `a` to `b` (along x or z, standing on a.y),
## one piece every `scale` metres, picked in turn from `kinds`, its front
## facing `face`. Solid unless `solid` is false.
static func wall(level: Level, a: Vector3, b: Vector3, face: Vector3, kinds := ["wall", "wall-window"], scale := WALL_SCALE, solid := true) -> void:
	var along := b - a
	var n := maxi(int(roundf(along.length() / scale)), 1)
	var step := along / n
	var turn := rad_to_deg(atan2(face.x, face.z))
	for i in n:
		level.piece("station:" + str(kinds[i % kinds.size()]), a + step * (i + 0.5), turn, scale)
	if solid:
		var half := face.normalized() * 0.15 * scale
		level.solid(a - half, b + half + Vector3.UP * scale)


## A low rail along an edge, from `a` to `b` (along x or z). Just for looks.
static func rail(level: Level, a: Vector3, b: Vector3, scale := 1.6) -> void:
	var along := b - a
	var n := maxi(int(roundf(along.length() / scale)), 1)
	var step := along / n
	var turn := rad_to_deg(atan2(-along.z, along.x))
	for i in n:
		level.piece("station:rail", a + step * (i + 0.5), turn, scale)


## A kit model with a solid box under it, `size` wide and tall (its foot at
## `at`). A zero size leaves it see-through, like Level.deco().
static func prop(level: Level, model_name: String, at: Vector3, turn := 0.0, scale := 1.6, size := Vector3.ZERO) -> void:
	level.piece("station:" + model_name, at, turn, scale)
	if size != Vector3.ZERO:
		level.solid(at - Vector3(size.x, 0, size.z) / 2.0, at + Vector3(size.x / 2.0, size.y, size.z / 2.0))


## Panels laid flush on top of a stretch of floor (a land() top at `top`),
## every other square, so the big decks don't look bare.
static func panels(level: Level, x0: int, z0: int, x1: int, z1: int, top: float, model_name := "floor-panel") -> void:
	for x in range(x0, x1, 2):
		for z in range(z0, z1, 2):
			level.piece("station:" + model_name, Vector3(x + 1, top - 0.29, z + 1), 0.0, 1.0)


## A stack of cargo, solid: crates and canisters on top of each other.
static func cargo(level: Level, at: Vector3, high := 2) -> void:
	for i in high:
		var kind := "container-wide" if i % 2 == 0 else "container"
		level.piece("station:" + kind, at + Vector3.UP * (i * 1.05), 45.0 * i, 1.5)
	level.solid(at + Vector3(-0.45, 0, -0.45), at + Vector3(0.45, high * 1.05, 0.45))


## A lattice mast `high` metres tall with a glowing lamp on top, to give
## the decks some height. Solid at its foot.
static func beacon(level: Level, at: Vector3, high := 6, color := Color("ff4d6d")) -> void:
	for i in high:
		level.piece("station:structure", at + Vector3.UP * i, 45.0 * (i % 2), 1.0)
	level.solid(at + Vector3(-0.5, 0, -0.5), at + Vector3(0.5, high, 0.5))
	var lamp := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.28
	ball.height = 0.56
	lamp.mesh = ball
	lamp.material_override = glow(color)
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp.position = at + Vector3.UP * (high + 0.3)
	level.add_child(lamp)


## The stars, a planet far below and a moon, all around the level.
static func space(level: Level) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := BoxMesh.new()
	dot.size = Vector3.ONE * 0.9
	mm.mesh = dot
	mm.instance_count = 420
	for i in mm.instance_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1.0), rng.randf_range(-1, 1)).normalized()
		var s := rng.randf_range(0.5, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), dir * 330.0))
	var stars := MultiMeshInstance3D.new()
	stars.name = "Stars"
	stars.multimesh = mm
	stars.material_override = _glow(Color(1, 1, 1), true)
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(stars)
	_ball(level, Vector3(70, -250, -170), 120.0, Color("6f5bd6"), Color("2c2470"))
	_ball(level, Vector3(-190, 90, -230), 26.0, Color("d9dce8"), Color("50557a"))


static func _ball(level: Level, at: Vector3, radius: float, color: Color, dark: Color) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 48
	s.rings = 24
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = dark
	mat.emission_energy_multiplier = 0.6
	mat.disable_fog = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = at
	level.add_child(m)


## A material that glows: lasers, lights, stars.
static func _glow(color: Color, no_fog := false, alpha := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color, alpha)
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_fog = no_fog
	return mat


## A glowing material for things in the level (lasers, lamps, cores).
static func glow(color: Color, alpha := 1.0) -> StandardMaterial3D:
	return _glow(color, false, alpha)
