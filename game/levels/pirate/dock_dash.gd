class_name PirateDockDash
extends Level
## Course 1 of Pirate Cove: a dash along a rickety harbour. Docks with
## missing planks, a wide wharf with crabs, planks that give way, two
## rowing boats over open water, then west over bobbing barrels, past a
## crab and along a broken boardwalk to the flag. Falling in the sea is
## back to the last flag.
##
## Adventure: coins, a heart, a hidden gem on an islet off the wharf and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "pirate/dockdash"
const GEM := "pirate/gem_dockdash"
const SEA := PirateBuild.SEA
const BOAT_Z := [-44.5, -48.5]
const BARREL_X := [-4.0, -7.0, -10.0, -13.0]
## The line the run turns west on.
const TURN_Z := -56.0
## The boardwalk's stretches, as (east end, west end) in x.
const BOARDWALK := [Vector2(-21, -24), Vector2(-26, -29), Vector2(-31, -34)]

var boats: Array[PirateBoat] = []
var barrels: Array[PirateBarrel] = []


func _init() -> void:
	super()
	title = "Dock Dash"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	PirateBuild.sea(self)
	# The start, on the beach.
	land(-3, -3, 3, 4, 0, 3)
	add_sign("Run the docks! Jump the gaps, and mind the sea.", Vector3(-2, 0, 1))
	tree(Vector3(-2.3, 0, 3.3), "pirate:palm-straight")
	tree(Vector3(2.4, 0, 3.0), "pirate:palm-bend")

	# The first dock, with planks missing.
	PirateBuild.dock(self, Vector3(0, 0, -3), Vector3(0, 0, -8))
	PirateBuild.dock(self, Vector3(0, 0, -9.5), Vector3(0, 0, -12))
	PirateBuild.dock(self, Vector3(0, 0, -13.5), Vector3(0, 0, -16))
	coin_line(Vector3(0, 0.3, -4), Vector3(0, 0.3, -7), 3)
	add_coin(Vector3(0, 1.2, -8.75))
	add_coin(Vector3(0, 1.2, -12.75))

	# Open water, then the wide wharf, where crabs walk their beat.
	for x in [-2.5, 0.0, 2.5]:
		PirateBuild.dock(self, Vector3(x, 0, -19), Vector3(x, 0, -26.5))
	add_checkpoint(Vector3(-2, 0, -20), Vector3.FORWARD)
	add(Crab.make(Vector3(0, 0, -5), 3.2), Vector3(-2.6, 0, -20.5))
	add(Crab.make(Vector3(0, 0, 5), 3.2, 0.5), Vector3(2.6, 0, -25.5))
	coin_line(Vector3(0, 0, -20), Vector3(0, 0, -25), 3)
	piece("pirate:barrel", Vector3(-3.2, 0, -26), 10.0, 0.6)
	piece("pirate:crate", Vector3(3.2, 0, -19.6), 80.0, 0.7)
	if not is_speedrun():
		# Off the racing line: an islet east of the wharf.
		land(7, -25, 10, -21, 0, 2)
		add_gem(GEM, Vector3(8.5, 0, -23.5))
		add_heart(Vector3(8.5, 0, -22))
		tree(Vector3(9.3, 0, -24.4), "pirate:palm-detailed-straight", 0.8)

	# Old planks that give way a moment after you land on them.
	for z in [-28.0, -31.0, -34.0]:
		add(FallingPlatform.make(Vector3(2, 0.3, 2), "platform", 0.55), Vector3(0, 0, z))
		add_coin(Vector3(0, 0.6, z))
	add_sign("Old planks give way. Keep moving!", Vector3(-2.8, 0, -25.6))

	# A short dock, then two rowing boats across open water.
	PirateBuild.dock(self, Vector3(0, 0, -36), Vector3(0, 0, -41))
	add_checkpoint(Vector3(-0.6, 0, -38), Vector3.FORWARD)
	add_sign("Rowing boats come and go. Jump on when one is close.", Vector3(1.0, 0, -36.6), Vector3.BACK)
	for z in BOAT_Z:
		var b := add(PirateBoat.make(Vector3(5, 0, 0), 5.0), Vector3(-2.5, SEA - 0.12, z)) as PirateBoat
		boats.append(b)

	# The far wharf, where the run turns west.
	for x in [-2.5, 0.0, 2.5]:
		PirateBuild.dock(self, Vector3(x, 0, -51.5), Vector3(x, 0, -59))
	add_checkpoint(Vector3(2, 0, -53), Vector3.FORWARD)
	camera_zone(Vector3(-46, -6, -66), Vector3(1.3, 12, -53.5), 90.0, 30.0, 10.0)
	coin_line(Vector3(0, 0, -52.5), Vector3(-1, 0, TURN_Z), 2)
	piece("pirate:flag-pirate", Vector3(3.3, 0, -58.5), 0.0)

	# Barrels bobbing in the water, all the way to the sandbar.
	for i in BARREL_X.size():
		var b := add(PirateBarrel.make(i * 0.27), Vector3(BARREL_X[i], SEA, TURN_Z)) as PirateBarrel
		barrels.append(b)
		add_coin(Vector3(BARREL_X[i], 1.1, TURN_Z))
	add_sign("Barrels bob up and down. Hop across!", Vector3(-0.5, 0, -58.2), Vector3.LEFT)

	# A sandbar with a crab on it, then a narrow boardwalk to the finish.
	land(-21, -60, -15, -52, 0, 3)
	add_checkpoint(Vector3(-16.5, 0, -53), Vector3.LEFT)
	add(Crab.make(Vector3(0, 0, -5), 2.6), Vector3(-19.5, 0, -53))
	tree(Vector3(-20, 0, -59.2), "pirate:palm-straight")
	piece("pirate:chest", Vector3(-16, 0, -59.2), 30.0, 0.6)
	for seg in BOARDWALK:
		for x in range(int(seg.x), int(seg.y), -1):
			piece("platform", Vector3(x - 0.5, -0.2, TURN_Z))
		solid(Vector3(seg.y, -0.2, TURN_Z - 0.5), Vector3(seg.x, 0, TURN_Z + 0.5))
		add_coin(Vector3((seg.x + seg.y) / 2.0, 0.3, TURN_Z))

	# The finish, on the far sandbar.
	land(-40, -60, -34, -52, 0, 3)
	add_flag(Vector3(-37, 0, TURN_Z), Vector3.LEFT)
	tree(Vector3(-39, 0, -53), "pirate:palm-bend")
	tree(Vector3(-39, 0, -59), "pirate:palm-straight")
	finish()
