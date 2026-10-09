class_name SpookyProps
extends RefCounted
## Spooky Hollow's scenery, shared by its island, courses and the Night
## Keeper's arena: lamp posts that really light up, gravestones, crypts and
## pines the hero bumps into, iron fences, pumpkins and a murky swamp.
##
## The Graveyard Kit's pieces are small next to the astronauts, so most go
## in at about twice their size.

const LAMP_COLOR := Color("ffb45a")
const SWAMP := Color(0.17, 0.42, 0.28, 0.9)
## How far behind its origin an iron fence piece stands, at size 1.
const IRON_BACK := 0.33
const STONES := ["grave:gravestone-round", "grave:gravestone-cross", "grave:gravestone-bevel", "grave:gravestone-roof", "grave:gravestone-decorative", "grave:gravestone-wide"]


## A lamp post with a warm light. `kind` is "single", "double" or "all".
static func lamp(level: Level, at: Vector3, kind := "double", turn := 0.0, energy := 1.8, reach := 8.0) -> OmniLight3D:
	level.piece("grave:lightpost-" + kind, at, turn, 2.2)
	level.solid(at + Vector3(-0.15, 0, -0.15), at + Vector3(0.15, 2.7, 0.15))
	var light := OmniLight3D.new()
	light.light_color = LAMP_COLOR
	light.light_energy = energy
	light.omni_range = reach
	light.position = at + Vector3.UP * 2.3
	level.add_child(light)
	return light


## A glow with no post (a fire basket, candles, a window).
static func glow(level: Level, at: Vector3, energy := 1.4, reach := 5.0, color := LAMP_COLOR) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.position = at
	level.add_child(light)
	return light


## A gravestone the hero bumps into. `kind` picks one of STONES (or names
## a model).
static func stone(level: Level, at: Vector3, kind: Variant = 0, turn := 0.0, scale := 1.8) -> void:
	var model: String = STONES[int(kind) % STONES.size()] if kind is int else str(kind)
	level.piece(model, at, turn, scale)
	var wide := 0.42 if model.ends_with("wide") else 0.24
	var half := Vector3(wide, 0, 0.14).rotated(Vector3.UP, deg_to_rad(turn)).abs() * scale
	level.solid(at - Vector3(half.x, 0, half.z), at + Vector3(half.x, 0.55 * scale, half.z))


## A row of gravestones from `from` to `to`, `n` of them, all facing `turn`.
static func stone_row(level: Level, from: Vector3, to: Vector3, n: int, turn := 0.0, seed := 0) -> void:
	for i in n:
		var at := from.lerp(to, float(i) / maxf(n - 1, 1))
		stone(level, at, (i + seed) % STONES.size(), turn + float((i * 7 + seed * 3) % 11) - 5.0)
		level.deco("grave:grave", at + Vector3(0, 0.02, 1.2).rotated(Vector3.UP, deg_to_rad(turn)), turn, 1.6)


## A mausoleum: the kit's large crypt with its roof, solid. Its door faces
## `turn` (0 faces south, towards +z).
static func mausoleum(level: Level, at: Vector3, turn := 0.0, scale := 2.0) -> void:
	level.piece("grave:crypt-large", at, turn, scale)
	level.piece("grave:crypt-large-roof", at + Vector3.UP * 1.0 * scale, turn, scale)
	var half := Vector3(0.95, 0, 1.2).rotated(Vector3.UP, deg_to_rad(turn)).abs() * scale
	level.solid(at - Vector3(half.x, 0, half.z), at + Vector3(half.x, 1.7 * scale, half.z))


## A small crypt with its roof, solid.
static func crypt(level: Level, at: Vector3, turn := 0.0, scale := 2.0) -> void:
	level.piece("grave:crypt-small", at, turn, scale)
	level.piece("grave:crypt-small-roof", at + Vector3.UP * 1.0 * scale, turn, scale)
	var half := Vector3(0.7, 0, 0.72).rotated(Vector3.UP, deg_to_rad(turn)).abs() * scale
	level.solid(at - Vector3(half.x, 0, half.z), at + Vector3(half.x, 1.65 * scale, half.z))


## A stone tomb (the kit's crypt), solid, its top flat enough to stand on.
static func tomb(level: Level, at: Vector3, turn := 0.0, scale := 2.4) -> float:
	level.piece("grave:crypt", at, turn, scale)
	var half := Vector3(0.36, 0, 0.56).rotated(Vector3.UP, deg_to_rad(turn)).abs() * scale
	level.solid(at - Vector3(half.x, 0, half.z), at + Vector3(half.x, 0.6 * scale, half.z))
	return at.y + 0.6 * scale


## A pine (or a crooked one) with a trunk the hero bumps into.
static func pine(level: Level, at: Vector3, kind := "grave:pine", scale := 1.7) -> void:
	level.piece(kind, at, fmod(absf(at.x * 37.0 + at.z * 11.0), 360.0), scale)
	level.solid(at + Vector3(-0.2, 0, -0.2) * scale, at + Vector3(0.2, 1.6, 0.2) * scale)


## A run of fence pieces from `from` to `to`, fitted to the length. Solid
## up to `high` (0 for none).
static func fence(level: Level, from: Vector3, to: Vector3, model := "grave:iron-fence", high := 1.1, size := 1.3) -> void:
	var span := to - from
	var n := maxi(1, roundi(span.length() / size))
	var step := span.length() / n
	var turn := rad_to_deg(atan2(span.x, span.z)) + 90.0
	# Kenney's iron fences stand a third of a metre behind their origin: bring
	# the bars onto the line, where the collision is.
	var back := Vector3.ZERO
	if model.begins_with("grave:iron-fence"):
		back = Vector3(sin(deg_to_rad(turn)), 0, cos(deg_to_rad(turn))) * IRON_BACK * step
	for i in n:
		var at := from + span * ((i + 0.5) / n)
		level.piece(model, at + back, turn, step)
	if high > 0.0:
		var side := span.normalized().cross(Vector3.UP) * 0.1
		var lo := Vector3(minf(from.x, to.x), from.y, minf(from.z, to.z)) - side.abs()
		var hi := Vector3(maxf(from.x, to.x), from.y + high, maxf(from.z, to.z)) + side.abs()
		level.solid(lo, hi)


## Pumpkins scattered over a patch, the same every time.
static func pumpkins(level: Level, a: Vector3, b: Vector3, n: int, seed := 1) -> void:
	var kinds := ["grave:pumpkin", "grave:pumpkin-tall", "grave:pumpkin", "grave:pumpkin-carved", "grave:pumpkin-tall-carved"]
	for i in n:
		var u := fposmod(sin(float(i * 12 + seed) * 12.9898) * 43758.5453, 1.0)
		var v := fposmod(sin(float(i * 7 + seed * 5) * 78.233) * 12543.123, 1.0)
		var at := Vector3(lerpf(a.x, b.x, u), a.y, lerpf(a.z, b.z, v))
		level.deco(kinds[(i + seed) % kinds.size()], at, fmod(u * 720.0, 360.0), 2.0 + v * 0.8)


## A swamp: murky water over a muddy bed, between two corners at height
## `y`. Falling in sends the hero back to the last flag.
static func swamp(level: Level, x0: int, z0: int, x1: int, z1: int, y: float) -> void:
	level.water(x0, z0, x1, z1, y, SWAMP)
	# Duller than clear water, so the murk doesn't just mirror the sky.
	var sheet := level.get_child(level.get_child_count() - 2) as MeshInstance3D
	var mat := sheet.material_override as StandardMaterial3D
	mat.roughness = 0.45
	mat.metallic_specular = 0.45
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.16, 0.06)
	level.land(x0, z0, x1, z1, y - 1.2, 1, "snow")


## A clump of reeds, a stump or a rock poking out of the swamp at `at`
## (on the water's surface), picked by `seed`.
static func reeds(level: Level, at: Vector3, seed := 0) -> void:
	var turn := float(seed * 67 % 360)
	match seed % 3:
		0:
			for i in 3:
				var off := Vector3(cos(i * 2.1 + seed), 0, sin(i * 2.1 + seed)) * 0.45
				level.deco("grass", at + off + Vector3.DOWN * 0.1, turn + i * 40.0, 2.6)
		1:
			level.deco("grave:trunk", at + Vector3.DOWN * 0.35, turn, 1.8)
			level.deco("grass", at + Vector3(0.6, -0.1, 0.3), turn, 2.2)
		2:
			level.deco("grave:rocks-tall", at + Vector3.DOWN * 0.3, turn, 1.6)
			level.deco("grass", at + Vector3(-0.5, -0.1, 0.4), turn, 2.2)


## Gives a model's meshes the world's block colours (for blocks that move,
## which aren't batched with the rest).
static func paint(level: Level, n: Node) -> void:
	if level.block_palette == "":
		return
	if not level.has_meta("spooky_paint"):
		var base: Material = (Kit.meshes("block-grass")[0][0] as Mesh).surface_get_material(0)
		var mat: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
		mat.albedo_texture = load(level.block_palette)
		level.set_meta("spooky_paint", mat)
	_paint(n, level.get_meta("spooky_paint"))


static func _paint(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = mat
	for c in n.get_children():
		_paint(c, mat)
