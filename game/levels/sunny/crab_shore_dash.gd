class_name SunnyCrabShore
extends Level
## Course 2 of Sunny Isles: a sandbar where crabs scuttle across, a ferry
## raft over the sea, rafts that sink under the waves and bob back up, then
## the dunes to the east and a long jump to the flag. It runs north, then
## turns east at the dunes, where the camera turns with it.
##
## Adventure: coins, a heart, a hidden gem on a sandy islet beside the
## ferry (a spring throws you back) and checkpoints; the flag gives the star.
## Speedrun: just the course and the clock.

const STAR := "sunny/crabshore"
const GEM := "sunny/gem_crabshore"
## The kit's colour map with the snow tops turned to sand, for beaches.
const SAND := "res://game/levels/sunny/sunny_sand.png"
const SEA := -0.9
## Where the crabs cross the sandbar, and where they cross the dune.
const CRAB_LANES := [-12.0, -18.0, -24.0]
const DUNE_CRAB_X := 11.5


func _init() -> void:
	super()
	title = "Crab Shore Dash"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]
	block_palette = SAND


func build() -> void:
	water(-40, -100, 50, 30, SEA, Color(0.2, 0.62, 0.9, 0.8))

	# The start beach.
	land(-4, -8, 4, 4, 0, 2, "snow")
	add_sign("Crabs pinch! Jump over them, or jump on them.", Vector3(-2.5, 0, 1))
	palm(Vector3(3, 0, 2.5))
	palm(Vector3(-3.2, 0, -5.5))
	deco("rocks", Vector3(2.8, 0, -6), 20.0, 1.6)
	deco("stones", Vector3(-1.5, 0, 3), 0.0, 1.4)

	# The sandbar: crabs scuttle across it, each on its own beat.
	land(-2, -28, 2, -8, 0, 2, "snow")
	for i in CRAB_LANES.size():
		add(Crab.make(Vector3(3.2, 0, 0), 2.4 - i * 0.2, i * 0.3), Vector3(-1.6, 0, CRAB_LANES[i]))
		coin_line(Vector3(0, 1.3, CRAB_LANES[i] + 1.2), Vector3(0, 1.3, CRAB_LANES[i] - 1.2), 2)
	for z in [-9.0, -15.0, -21.0, -27.0]:
		for x in [-1.8, 1.8]:
			deco("fence-rope", Vector3(x, 0, z), 90.0)
	add_checkpoint(Vector3(-1, 0, -26.5), Vector3.FORWARD)

	# The ferry raft over the sea: hop on, ride it across, hop off.
	var ferry := MovingPlatform.make(Vector3(0, 0, -7), 5.0, 0.0, Vector3(3, 0.4, 3))
	ferry.name = "Ferry"
	add(ferry, Vector3(0, 0, -30.1))
	add_sign("Ride the raft across the sea.", Vector3(1.5, 0, -26.5))
	coin_line(Vector3(0, 0.4, -31), Vector3(0, 0.4, -36), 3)
	if not is_speedrun():
		# Off the racing line: a sandy islet east of the ferry, with a spring
		# that throws you on to the far shore.
		land(5, -38, 9, -33, 0, 2, "snow")
		palm(Vector3(8.2, 0, -33.8))
		add_gem(GEM, Vector3(7, 0.1, -35.5))
		add_heart(Vector3(5.8, 0, -33.8))
		add(Spring.new(), Vector3(5.8, 0, -37.2))

	# The far shore, then rafts that sink under the waves and bob back up.
	land(-3, -45, 3, -39, 0, 2, "snow")
	add_checkpoint(Vector3(-1.5, 0, -40.5), Vector3.FORWARD)
	add_sign("Those rafts sink! Keep hopping.", Vector3(2, 0, -41), Vector3.BACK)
	for i in 3:
		var raft := MovingPlatform.make(Vector3(0, -2.0, 0), 4.0, fposmod(-0.18 * i, 1.0), Vector3(2, 0.4, 2))
		raft.name = "Tide%d" % (i + 1)
		add(raft, Vector3(0, 0, -47.5 - i * 4.0))
		add_coin(Vector3(0, 1.4, -49.5 - i * 4.0))

	# The turn east, up the dune.
	land(-4, -66, 6, -58, 0, 2, "snow")
	palm(Vector3(-3, 0, -65))
	deco("rocks", Vector3(-3.2, 0, -59), 0.0, 1.5)
	add_checkpoint(Vector3(-1, 0, -60), Vector3.RIGHT)
	camera_zone(Vector3(2, -8, -74), Vector3(44, 16, -50), -90.0, 30.0, 10.0)
	ramp(Vector3(7, 0, -62), Vector3.RIGHT, "snow")
	land(8, -64, 15, -60, 1.0, 3, "snow")
	add(Crab.make(Vector3(0, 0, 3.2), 2.0, 0.5), Vector3(DUNE_CRAB_X, 1.0, -63.6))
	add_sign("A long gap: Run, Crouch, then Jump for a long jump.", Vector3(9, 1.0, -60.6), Vector3.LEFT)
	for x in [3.0, 5.0, 9.0, 14.0]:
		add_coin(Vector3(x, 0.4 if x < 8 else 1.4, -62))
	coin_line(Vector3(16.5, 2.4, -62), Vector3(20.5, 2.4, -62), 3)

	# The finish island.
	land(22, -66, 32, -58, 0.5, 2, "snow")
	add_flag(Vector3(27, 0.5, -62), Vector3.RIGHT)
	palm(Vector3(30.5, 0.5, -65))
	palm(Vector3(30.5, 0.5, -59))
	deco("stones", Vector3(24, 0.5, -59.5), 30.0, 1.4)
	finish()


## A palm tree (from the pirates' beaches, a little smaller).
func palm(at: Vector3) -> void:
	tree(at, "pirate:palm-straight", 0.7)
