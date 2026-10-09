class_name SunnyTreetopHop
extends Level
## Course 4 of Sunny Isles: tree house decks high in the treetops. A bridge
## of planks that drop once stood on, a caterpillar on the second deck, a
## high jump up to a higher branch, then east up a stair of falling planks,
## past a bee, across branches swaying in the breeze, past another
## caterpillar and a long jump down to the flag. The camera turns east with
## the course.
##
## Adventure: coins, a heart, a hidden gem on a little deck below the
## second one (a spring throws you back up) and checkpoints; the flag gives
## the star. Speedrun: just the course and the clock.

const STAR := "sunny/treetop"
const GEM := "sunny/gem_treetop"
## The plank bridge's planks: how many, and how far apart.
const BRIDGE_PLANKS := 8
const CATERPILLAR_Z := -17.5
## The falling stair's planks, as their centres.
const STAIR := [Vector3(6.0, 7.6, -27.5), Vector3(9.5, 8.4, -27.5), Vector3(13.0, 9.2, -27.5)]
const BEE_X := 19.5
const BRANCHES := 3
const CATERPILLAR2_X := 42.0


func _init() -> void:
	super()
	title = "Treetop Hop"
	spawn = Vector3(0, 4.0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The first tree house, where the course starts.
	deck(-3, -4, 3, 4, 4.0)
	giant_tree(Vector3(0, 4.0, 0))
	add_sign("Planks drop once you stand on them. Keep moving!", Vector3(-2.2, 4.0, 1.5))
	for x in [-2.5, 2.5]:
		deco("fence-rope", Vector3(x, 4.0, 3.6), 0.0)
		deco("barrel", Vector3(x, 4.0, -3.2), 0.0, 1.2)

	# A bridge of planks that drop a moment after you step on them.
	for i in BRIDGE_PLANKS:
		var z := -4.625 - i * 1.25
		add(FallingPlatform.make(Vector3(2, 0.4, 1), "platform", 0.6), Vector3(0, 4.0, z))
		if i % 2 == 1:
			add_coin(Vector3(0, 4.4, z))

	# The second deck: a caterpillar crawls across it.
	deck(-3, -23, 3, -14, 4.0)
	giant_tree(Vector3(0, 4.0, -18.5))
	add_checkpoint(Vector3(-2, 4.0, -15), Vector3.FORWARD)
	add(Critter.make("animal-caterpillar", Vector3(4.4, 0, 0), 2.6), Vector3(-2.2, 4.0, CATERPILLAR_Z))
	add_coin(Vector3(0, 5.9, CATERPILLAR_Z))
	add_sign("Crouch, then Jump to reach a high branch.", Vector3(2.3, 4.0, -21.5), Vector3.BACK)
	if not is_speedrun():
		# Off the racing line: a little deck below to the west, with a spring
		# back up.
		deck(-9, -20, -6, -16, 2.2)
		add_gem(GEM, Vector3(-7.6, 2.4, -17.4))
		add_heart(Vector3(-6.6, 2.2, -16.6))
		add(Spring.new(), Vector3(-6.7, 2.2, -19.2))
		deco("hedge", Vector3(-8.5, 2.2, -19.6), 90.0)

	# The high branch, then the course turns east.
	deck(-3, -31, 3, -24, 6.8)
	giant_tree(Vector3(0, 6.8, -27.5), 4.6)
	add_checkpoint(Vector3(-2, 6.8, -25), Vector3.RIGHT)
	coin_line(Vector3(0, 7.2, -21.6), Vector3(0, 8.4, -24.0), 2)
	camera_zone(Vector3(2, -6, -42), Vector3(70, 24, -12), -90.0, 28.0, 10.0)

	# A stair of falling planks, up to the top tree house.
	for i in STAIR.size():
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.6), STAIR[i])
		add_coin(STAIR[i] + Vector3(0, 0.5, 0))

	# The top tree house, with a bee buzzing across it.
	deck(15, -31, 25, -24, 10.0)
	giant_tree(Vector3(17.5, 10.0, -27.5))
	giant_tree(Vector3(22.5, 10.0, -27.5), 3.8)
	var bee := Critter.make("animal-bee", Vector3(0, 0, 5.6), 2.4)
	bee.bob = 0.25
	add(bee, Vector3(BEE_X, 10.0, -30.3))
	add_checkpoint(Vector3(16.5, 10.0, -25), Vector3.RIGHT)
	add_sign("Branches sway in the breeze. Hop when the next one comes round.", Vector3(23.6, 10.0, -24.8), Vector3.LEFT)

	# Branches swaying in the breeze, one a beat behind the other.
	for i in BRANCHES:
		var branch := MovingPlatform.make(Vector3(0, 0, 3.0), 3.2, 0.1 * i, Vector3(2, 0.5, 2), "block-grass-low")
		branch.name = "Branch%d" % (i + 1)
		add(branch, Vector3(28.0 + i * 3.5, 10.0, -29.0))
		add_coin(Vector3(28.0 + i * 3.5, 11.2, -27.5))

	# The last tree house: a caterpillar, then a long jump down to the flag.
	deck(38, -31, 46, -24, 10.0)
	giant_tree(Vector3(42, 10.0, -27.5), 4.4)
	add_checkpoint(Vector3(39.5, 10.0, -25), Vector3.RIGHT)
	add(Critter.make("animal-caterpillar", Vector3(0, 0, 4.4), 2.4, 0.5), Vector3(CATERPILLAR2_X, 10.0, -29.7))
	add_sign("A long way down: Run, Crouch, then Jump.", Vector3(44.6, 10.0, -24.8), Vector3.LEFT)
	for z in [-30.5, -24.5]:
		deco("fence-rope", Vector3(45.6, 10.0, z), 90.0)
	coin_line(Vector3(47.5, 10.6, -27.5), Vector3(51.5, 9.4, -27.5), 3)

	# The finish tree house.
	deck(52, -32, 61, -23, 8.0)
	giant_tree(Vector3(56.5, 8.0, -27.5), 4.6)
	add_flag(Vector3(56.5, 8.0, -27.5), Vector3.RIGHT)
	for z in [-31.3, -23.7]:
		deco("barrel", Vector3(59.8, 8.0, z), 0.0, 1.2)
	tree(Vector3(60, 8.0, -29.5), "tree-pine")
	tree(Vector3(60, 8.0, -25.5), "tree-pine")

	# More treetops all around, below the decks.
	for t in [[Vector3(-8, 1.0, -6), 3.6], [Vector3(8, -1.0, -12), 4.4], [Vector3(-9, 0.5, -28), 4.0],
			[Vector3(10, 2.0, -36), 4.2], [Vector3(10, 3.0, -18), 3.4], [Vector3(28, 4.0, -36), 4.4],
			[Vector3(28, 3.0, -18), 4.0], [Vector3(36, 5.0, -35), 3.6], [Vector3(-6, -2.0, 8), 4.0],
			[Vector3(34, 4.0, -19), 3.8], [Vector3(50, 3.0, -35), 4.2], [Vector3(50, 2.0, -19), 3.8], [Vector3(66, 2.0, -30), 4.0]]:
		giant_tree(t[0], t[1])
	finish()


## A tree house deck of planks over the grid squares from (x0, z0) to
## (x1, z1), its top at `top`.
func deck(x0: int, z0: int, x1: int, z1: int, top: float) -> void:
	solid(Vector3(x0, top - 0.4, z0), Vector3(x1, top, z1))
	for x in range(x0, x1):
		for z in range(z0, z1):
			piece("platform-fortified" if (x == x0 or x == x1 - 1 or z == z0 or z == z1 - 1) else "platform", Vector3(x + 0.5, top - 0.21, z + 0.5))


## A giant tree whose crown reaches up to just under `top` (scenery only).
func giant_tree(top: Vector3, scale := 4.2) -> void:
	piece("tree", top - Vector3.UP * (1.93 * scale + 0.15), fmod(absf(top.x * 41.0 + top.z * 17.0), 360.0), scale)


## An extra view for the screenshots.
func shots() -> Array:
	return [{"name": "branches", "at": Vector3(23.5, 10, -27.5), "face": Vector3.RIGHT}]
