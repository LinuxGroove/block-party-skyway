class_name CastleSiegeGauntlet
extends Level
## Course 4 of Sky Castle: straight through King Thud's siege camp. A field
## under fire from two catapults (keep moving and the stones land behind
## you) with a trench to jump, an alley where battering rams charge out
## from both sides, a causeway crossed by ballista bolts, then up onto the
## wall Thud is attacking, where his trebuchet drops stones along the walk,
## and on to the flag on the gate he captured.
##
## Adventure: coins, a heart, checkpoints, and a gem on top of a siege tower
## in the field (a spring behind it). Speedrun: just the camp and the clock.

const P := preload("res://game/levels/castle/castle_parts.gd")

const STAR := "castle/siege"
const GEM := "castle/gem_siege"
## The rams' lanes across the alley, and the ballistae's across the causeway.
const RAM_Z := [-35.0, -39.0, -43.0, -47.0]
const BOLT_Z := [-55.0, -59.0]
## The wall's scale and walkway, and where the trebuchet's stones land on it.
const SCALE := 3.0
const WALK := P.WALK * SCALE
const STONE_SPOTS := [Vector3(0, WALK, -76.5), Vector3(0, WALK, -81.0), Vector3(0, WALK, -85.5)]

var catapults: Array[CastleCatapult] = []
var rams: Array[CastleRam] = []
var ballistae: Array[CastleBallista] = []
var trebuchet: CastleCatapult


func _init() -> void:
	super()
	title = "Siege Gauntlet"
	spawn = Vector3(0, 0, 3)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 32.0, 9.5, false]


func build() -> void:
	# The way into the camp.
	land(-4, -2, 4, 5, 0, 4)
	add_sign("King Thud's siege camp! A red ring shows where a stone will land. Keep moving!", Vector3(-2.6, 0, 1.2))
	for at in [Vector3(-3, 0, 4), Vector3(3, 0, 4)]:
		P.tree(self, at, false, 1.6)
	_field()
	_alley()
	_causeway()
	_wall()
	P.cloud_sea(self, Vector3(0, 0, -45), 12.0, 80.0, -16.0, -8.0, 60, 41)
	finish()


## The field, with a catapult on a mound either side and a trench across.
func _field() -> void:
	land(-7, -17, 7, -2, 0, 4)
	land(-7, -32, 7, -20, 0, 4)
	for c in [[Vector3(-10, 2.5, -16), Vector3.RIGHT, 0.2], [Vector3(10, 2.5, -10), Vector3.LEFT, 0.7]]:
		var at: Vector3 = c[0]
		land(roundi(at.x) - 2, roundi(at.z) - 2, roundi(at.x) + 2, roundi(at.z) + 2, at.y, 5, "snow")
		var cat := CastleCatapult.make(c[1], 2.2, c[2])
		cat.reach = 14.0
		catapults.append(add(cat, at) as CastleCatapult)
	for at in [Vector3(-3.5, 0, -7), Vector3(3.2, 0, -12.5), Vector3(-2.8, 0, -24), Vector3(3.6, 0, -27.5)]:
		deco("crate", at, 0.0, 1.2)
		solid(at + Vector3(-0.6, 0, -0.6), at + Vector3(0.6, 1.2, 0.6))
	coin_line(Vector3(0, 0, -5), Vector3(0, 0, -14), 4)
	coin_line(Vector3(0, 1.4, -18.5), Vector3(0, 1.4, -18.5), 1)
	coin_line(Vector3(0, 0, -22), Vector3(0, 0, -29), 3)
	add_heart(Vector3(5.5, 0, -23))
	P.siege(self, "ram-demolished", Vector3(5, 0, -4), Vector3.LEFT, 1.4)
	P.siege(self, "trebuchet", Vector3(-5.5, 0, -4.5), Vector3.FORWARD, 1.3)
	P.siege(self, "tower", Vector3(-5, 0, -28), Vector3.BACK, 1.6)
	if not is_speedrun():
		# On top of the siege tower: the gem, with a spring behind it.
		add_gem(GEM, Vector3(-5, 4.2, -28))
		add(Spring.new(), Vector3(-5, 0, -26.3))
	add_checkpoint(Vector3(-2.5, 0, -30.5), Vector3.FORWARD)


## The ram alley: rams on little platforms either side charge across.
func _alley() -> void:
	land(-2, -50, 2, -32, 0, 3, "snow")
	add_sign("Battering rams! Run past while they're rolled back.", Vector3(3.2, 0, -30.5))
	for i in RAM_Z.size():
		var z: float = RAM_Z[i]
		var side := -1.0 if i % 2 == 0 else 1.0
		land(roundi(side * 3.5) - 2, roundi(z) - 1, roundi(side * 3.5) + 2, roundi(z) + 1, 0, 3, "snow")
		var ram := CastleRam.make(Vector3(-side, 0, 0), 4.4, fposmod(0.5 - i * 0.193, 1.0))
		rams.append(add(ram, Vector3(side * 3.5, 0, z)) as CastleRam)
	coin_line(Vector3(0, 0, -37), Vector3(0, 0, -45), 3)


## The causeway, under fire from a ballista on each side.
func _causeway() -> void:
	land(-2, -62, 2, -50, 0, 3, "snow")
	add_checkpoint(Vector3(-1.2, 0, -51), Vector3.FORWARD)
	add_sign("Ballistae! Wait for the bolts to pass.", Vector3(1.3, 0, -51.5), Vector3.LEFT)
	for i in BOLT_Z.size():
		var z: float = BOLT_Z[i]
		var side := -1.0 if i == 0 else 1.0
		land(roundi(side * 5.5) - 2, roundi(z) - 1, roundi(side * 5.5) + 2, roundi(z) + 1, 0, 3, "snow")
		var b := CastleBallista.make(Vector3(-side, 0, 0), 2.4, 0.5 * i)
		b.bolt_range = 12.0
		ballistae.append(add(b, Vector3(side * 5.5, 0, z)) as CastleBallista)
		P.pennant(self, Vector3(side * 6.8, 0, z - 0.6), 0.0, 1.4)
	add_coin(Vector3(0, 0, -57))


## Up onto the wall, where the trebuchet drops stones on the walk, and the
## gate at the end with the flag.
func _wall() -> void:
	land(-4, -69, 4, -62, 0, 4)
	add_checkpoint(Vector3(2.5, 0, -64), Vector3.FORWARD)
	add_sign("Thud's trebuchet is aiming at the wall. Watch the rings and time your run!", Vector3(-2.6, 0, -64), Vector3.BACK)
	P.stairs(self, Vector3(0, 0, -73 + 0.82 * WALK / 0.67), Vector3.FORWARD, WALK, 3.0)
	P.rampart(self, Vector3(0, 0, -73), Vector3(0, 0, -88), SCALE)
	land(7, -84, 11, -78, 2.0, 5, "snow")
	trebuchet = CastleCatapult.make(Vector3.LEFT, 0.9, 0.3)
	trebuchet.model_name = "castle:siege-trebuchet"
	trebuchet.arm_name = "arm"
	trebuchet.muzzle_height = 1.9
	trebuchet.model_scale = 1.5
	trebuchet.spots = STONE_SPOTS
	trebuchet.flight = 1.4
	add(trebuchet, Vector3(9, 2.0, -81))
	for i in STONE_SPOTS.size() - 1:
		add_coin(((STONE_SPOTS[i] as Vector3) + (STONE_SPOTS[i + 1] as Vector3)) / 2.0 + Vector3.UP * 0.1)
	# The captured gate, with the flag on top.
	P.bastion(self, Vector3(0, WALK, -92), 8, [Vector2(1, -1), Vector2(-1, -1)], 6)
	add_flag(Vector3(0, WALK, -92.5), Vector3.FORWARD)
	P.banner(self, Vector3(-2.0, WALK - 0.2, -88.0), Vector3.BACK, false, 2.0)
	P.banner(self, Vector3(2.0, WALK - 0.2, -88.0), Vector3.BACK, false, 2.0)
	P.siege(self, "catapult-demolished", Vector3(2.5, 0, -67), Vector3.LEFT, 1.3)
	P.siege(self, "ballista-demolished", Vector3(-2.8, 0, -67.5), Vector3.RIGHT, 1.2)
