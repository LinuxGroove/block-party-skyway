class_name PirateWreckClimb
extends Level
## Course 3 of Pirate Cove: up the sea stack where a storm left an old wreck
## stranded at the top. Rocks out of the reef, old planks that give way,
## cannonballs swinging round on the stack's foot, a chimney to kick up,
## then a plank walk over the drop, where parrots fly back and forth, to
## a salvage lift up to the top, and the flag beside the wreck.
##
## Adventure: coins, a heart, a hidden gem on a ledge down in the drop
## (with a spring back up) and checkpoints; the flag gives the star.
## Speedrun: just the course and the clock.

const STAR := "pirate/wreckclimb"
const GEM := "pirate/gem_wreckclimb"
const SEA := PirateBuild.SEA
## The stack's foot, the chimney's top, the summit and the very top.
const FOOT := 4.5
const CHIMNEY_TOP := 15.0
const SUMMIT := 15.0
const TOP := 19.5
## The plank walk over the drop: its middle in x, and where the parrots
## cross it.
const WALK_X := -3.0
const PARROT_Z := [-36.0, -38.5, -41.0]
const PARROT_PERIOD := 4.4

var spinner: Spinner
var parrots: Array[Critter] = []
var lift: MovingPlatform


func _init() -> void:
	super()
	title = "Shipwreck Climb"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 10.0, false]


func build() -> void:
	PirateBuild.sea(self)
	# The start, on a sandbar, with the stack ahead.
	land(-3, -3, 3, 4, 0, 3)
	add_sign("Climb the sea stack to the old wreck at the top!", Vector3(-2, 0, 1))
	tree(Vector3(2.4, 0, 3.0), "pirate:palm-bend")
	tree(Vector3(-2.4, 0, 3.4), "pirate:palm-straight")

	# Rocks out of the reef.
	land(-2, -8, 2, -5, 1.5, 3)
	land(-3, -14, 3, -9, 3.0, 4)
	coin_line(Vector3(0, 1.6, -5.5), Vector3(0, 1.6, -7.5), 2)
	coin_line(Vector3(0, 3.1, -9.5), Vector3(0, 3.1, -13), 3)
	add_checkpoint(Vector3(-2, 3.0, -10.5), Vector3.FORWARD)
	piece("pirate:rocks-sand-b", Vector3(4.5, SEA, -7), 40.0)
	piece("pirate:rocks-sand-c", Vector3(-4.5, SEA, -12), 160.0)

	# Old planks that give way, up to the stack's foot.
	for at in [Vector3(0, 3.5, -16.5), Vector3(0, 4.0, -19.5)]:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.55), at)
		add_coin(at + Vector3.UP * 0.4)
	add_sign("Old planks give way. Keep moving!", Vector3(2.4, 3.0, -13.3))

	# The foot of the stack, where cannonballs swing round an old capstan.
	land(-5, -34, 5, -22, FOOT, 6)
	add_checkpoint(Vector3(-3.6, FOOT, -23), Vector3.FORWARD)
	add_sign("Jump the cannonballs as they swing round!", Vector3(-4.2, FOOT, -25.5), Vector3.RIGHT)
	spinner = Spinner.make(3, 80.0, "pirate:cannon-ball")
	spinner.model_scale = 0.9
	spinner.height = 0.55
	add(spinner, Vector3(1.8, FOOT, -26.5))
	piece("pirate:barrel", Vector3(1.8, FOOT, -26.5), 0.0, 0.8)
	solid(Vector3(1.4, FOOT, -26.9), Vector3(2.2, FOOT + 1.0, -26.1))
	add_heart(Vector3(4.2, FOOT + 0.3, -23))
	piece("pirate:crate", Vector3(4.2, FOOT, -29.2), 20.0, 0.8)

	# The chimney: kick between its walls to the top.
	land(-5, -34, -1, -30, CHIMNEY_TOP, int(CHIMNEY_TOP - FOOT))
	land(0, -34, 5, -30, CHIMNEY_TOP + 1.0, int(CHIMNEY_TOP - FOOT) + 1)
	add_sign("Jump at a wall, then jump again to kick off it.", Vector3(-2.0, FOOT, -29.6), Vector3.BACK)
	coin_line(Vector3(-0.5, 6.5, -32), Vector3(-0.5, 13.5, -32), 5)
	camera_zone(Vector3(-6, 3, -35), Vector3(6, 18, -29), 0.0, 16.0, 11.0, false, 1)
	add_checkpoint(Vector3(-4, CHIMNEY_TOP, -31), Vector3.FORWARD)

	# The plank walk over the drop, with parrots flying across it.
	for z in [-35.3, -37.6, -39.9, -42.2]:
		piece("pirate:platform-planks", Vector3(WALK_X, SUMMIT - 0.3, z))
	solid(Vector3(WALK_X - 1.0, SUMMIT - 0.4, -43), Vector3(WALK_X + 1.0, SUMMIT, -34))
	add_sign("Parrots guard the top. Jump on one, or wait till it flies by.", Vector3(-4.2, CHIMNEY_TOP, -33.4), Vector3.BACK)
	for i in PARROT_Z.size():
		var p := Critter.make("animal-parrot", Vector3(6, 0, 0), PARROT_PERIOD, 0.3 * i, 0.42)
		p.bob = 0.2
		parrots.append(add(p, Vector3(WALK_X - 3.0, SUMMIT + 0.5, PARROT_Z[i])) as Critter)
	coin_line(Vector3(WALK_X, SUMMIT + 0.1, -34.5), Vector3(WALK_X, SUMMIT + 0.1, -42.5), 4)

	if not is_speedrun():
		# Off the racing line: a ledge down in the drop, and a spring back up.
		ledge(-8, -43, -4, -41, SUMMIT - 3.5)
		add_gem(GEM, Vector3(-7.0, SUMMIT - 3.4, -42))
		add(Spring.new(), Vector3(-5.0, SUMMIT - 3.5, -41.8))
		coin_line(Vector3(-4.6, SUMMIT - 1.2, -40.5), Vector3(-6.4, SUMMIT - 2.6, -41.5), 3)

	# The lower summit, and a salvage lift up to the top.
	land(-8, -49, 5, -43, SUMMIT, int(SUMMIT - SEA) + 1)
	add(Crab.make(Vector3(0, 0, 3), 3.0), Vector3(2.5, SUMMIT, -48))
	coin_line(Vector3(2.5, SUMMIT + 0.1, -47.5), Vector3(2.5, SUMMIT + 0.1, -45), 2)
	lift = add(MovingPlatform.make(Vector3(0, TOP - SUMMIT, 0), 5.0), Vector3(WALK_X, SUMMIT, -50)) as MovingPlatform
	add_sign("The salvage lift goes up and down. Hop on!", Vector3(WALK_X - 2.0, SUMMIT, -47.6), Vector3.BACK)
	add_checkpoint(Vector3(WALK_X - 3.0, SUMMIT, -45.5), Vector3.FORWARD)
	piece("pirate:flag-pirate-high", Vector3(-7, SUMMIT, -44), 30.0)
	piece("pirate:barrel", Vector3(-6.6, SUMMIT, -48.0), 0.0, 0.8)
	piece("pirate:crate", Vector3(4.0, SUMMIT, -44.0), 70.0, 0.8)

	# The top, with the wreck the storm left there, and the flag.
	land(-9, -61, 7, -51, TOP, int(TOP - SEA) + 1)
	add_flag(Vector3(WALK_X, TOP, -54.5))
	PirateBuild.ship(self, "pirate:ship-wreck", Vector3(1.4, TOP - 0.8, -56.5), 200.0, 1.3, false)
	tree(Vector3(-7.8, TOP, -59.5), "pirate:palm-detailed-bend")
	tree(Vector3(-7.5, TOP, -52.2), "pirate:palm-straight")
	piece("pirate:chest", Vector3(-5.5, TOP, -58.5), -30.0, 0.8)
	piece("pirate:barrel", Vector3(-6.8, TOP, -56.6), 0.0, 0.8)

	# Wrecks and rocks about the reef.
	piece("pirate:ship-wreck", Vector3(-12, SEA - 2.0, -16), 70.0, 1.1)
	piece("pirate:rocks-a", Vector3(9, SEA, -20), 10.0, 1.2)
	piece("pirate:rocks-sand-a", Vector3(-11, SEA, -32), 200.0, 1.3)
	piece("pirate:rocks-b", Vector3(10, SEA, -38), 120.0, 1.4)
	piece("pirate:boat-row-small", Vector3(6, SEA - 0.1, -4), 30.0)
	finish()
