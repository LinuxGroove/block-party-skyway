class_name SunnyWindmillHills
extends Level
## Course 3 of Sunny Isles: up the hills to the windmill. A spinning bar on
## the first hill, a spring up the cliff, bees over the high meadow, then
## west past a second bar, down to a stream and a high jump up to the
## windmill and the flag. The camera turns west with the course.
##
## Adventure: coins, a heart, a hidden gem on a little meadow below the
## high one (a spring throws you back up) and checkpoints; the flag gives
## the star. Speedrun: just the course and the clock.

const STAR := "sunny/windmill"
const GEM := "sunny/gem_windmill"
## Where the bees cross the high meadow.
const BEE_LANES := [-27.5, -32.5]


func _init() -> void:
	super()
	title = "Windmill Hills"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The start meadow.
	land(-4, -10, 4, 4, 0, 3)
	add_sign("Spinning bars sweep the hills. Let one pass, then run. Or jump it!", Vector3(-2.5, 0, 1))
	for x in [-2.6, 2.6]:
		deco("flowers", Vector3(x, 0, 3))
	deco("arrows", Vector3(0, 0, -5.5), 0.0, 2.0)

	# The first hill and its bar.
	ramp(Vector3(0, 0, -9), Vector3.FORWARD)
	land(-4, -22, 4, -10, 1.0, 3)
	_bar("Bar1", Vector3(3.4, 1.0, -15.5), 4, 80.0)
	coin_line(Vector3(0, 1.1, -12.5), Vector3(0, 1.1, -18.5), 4)
	add_checkpoint(Vector3(-2.5, 1.0, -19.5), Vector3.FORWARD)

	# A spring up the cliff to the high meadow.
	add(Spring.new(), Vector3(0, 1.0, -20.6))
	add_sign("Springs throw you high. Steer as you fly!", Vector3(-2.6, 1.0, -21), Vector3.BACK)
	land(-5, -38, 5, -22, 4.5, 6)
	coin_line(Vector3(0, 6.5, -21.2), Vector3(0, 5.2, -23.0), 2)

	# Bees over the high meadow.
	for i in BEE_LANES.size():
		var bee := Critter.make("animal-bee", Vector3(7, 0, 0), 3.2 - i * 0.4, i * 0.4)
		bee.bob = 0.25
		add(bee, Vector3(-3.5, 4.5, BEE_LANES[i]))
		add_coin(Vector3(0, 6.2, BEE_LANES[i]))
	add_checkpoint(Vector3(-3, 4.5, -24), Vector3.FORWARD)
	add_heart(Vector3(4, 4.5, -25))
	for at in [Vector3(4, 4.5, -36.8), Vector3(-4.2, 4.5, -23)]:
		tree(at)

	# Off the racing line: a little meadow below the high one, with a spring
	# back up.
	if not is_speedrun():
		land(-1, -43, 3, -40, 3.0, 2)
		add_gem(GEM, Vector3(0.6, 3.2, -41.6))
		add_coin(Vector3(2, 3.1, -40.8))
		add(Spring.new(), Vector3(2.2, 3.0, -42.2))
		deco("flowers", Vector3(0, 3.0, -42.4), 30.0)

	# West along the ridge, past the second bar.
	land(-21, -38, -5, -32, 4.5, 5)
	land(-14, -32, -12, -30, 4.5, 4)
	_bar("Bar2", Vector3(-13, 4.5, -31.4), 4, -70.0)
	camera_zone(Vector3(-52, -6, -48), Vector3(-2, 20, -29), 90.0, 30.0, 10.0)
	add_checkpoint(Vector3(-7, 4.5, -33), Vector3.LEFT)
	coin_line(Vector3(-10, 4.6, -35), Vector3(-17, 4.6, -35), 4)
	for x in range(-20, -5, 2):
		deco("hedge", Vector3(x + 1.0, 4.5, -38.3), 0.0)

	# Down to the stream: jump it.
	land(-26, -38, -21, -32, 2.5, 4)
	land(-29, -38, -26, -32, 0.5, 2)
	water(-29, -38, -26, -32, 2.0)
	var bee := Critter.make("animal-bee", Vector3(0, 0, 4.4), 2.8)
	bee.bob = 0.25
	add(bee, Vector3(-27.5, 2.5, -37.2))
	add_coin(Vector3(-27.5, 4.3, -35))
	land(-33, -38, -29, -32, 2.5, 4)
	add_checkpoint(Vector3(-31, 2.5, -33), Vector3.LEFT)
	add_sign("A big step. Crouch, then Jump: a high jump.", Vector3(-30, 2.5, -37), Vector3.RIGHT)

	# The windmill hill and the flag.
	land(-47, -40, -33, -30, 5.0, 6)
	var mill := SunnyWindmill.new()
	mill.facing = Vector3.RIGHT
	add(mill, Vector3(-44, 5.0, -35))
	add_flag(Vector3(-38.5, 5.0, -35), Vector3.LEFT)
	for at in [Vector3(-35, 5.0, -39), Vector3(-45.5, 5.0, -31)]:
		tree(at, "tree-pine")
	for at in [Vector3(-36, 5.0, -31.5), Vector3(-41, 5.0, -38.5), Vector3(-15, 4.5, -36.5)]:
		deco("flowers", at, at.x * 13.0)

	# Meadow dressing.
	for at in [Vector3(-3, 1.0, -12), Vector3(2.5, 4.5, -29), Vector3(-2, 4.5, -36), Vector3(-23, 2.5, -33)]:
		deco("grass", at, at.z * 21.0, 1.4)
	for at in [Vector3(3, 0, -6), Vector3(-3, 1.0, -21), Vector3(-24.5, 2.5, -37)]:
		deco("flowers-tall", at, at.x * 7.0)
	finish()


## A bar of spike blocks sweeping round a post.
func _bar(id: String, at: Vector3, length: int, speed: float) -> Spinner:
	var s := Spinner.make(length, speed)
	s.name = id
	return add(s, at) as Spinner


## An extra view for the screenshots.
func shots() -> Array:
	return [{"name": "mill", "at": Vector3(-35.5, 5, -35), "face": Vector3.LEFT}]
