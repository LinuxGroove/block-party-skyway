class_name BounceHollow
extends StarCourse
## Star Road course 7, Snack Valley meets Spooky Hollow: candy islands over
## a hollow too wide to jump, crossed by bouncing off the big bees that
## hover in the gaps, with spike traps, zombies and a ghost on the islands
## between, a stair of bees up to a high ledge, two bees in a row, spike
## traps and crumbling planks, and one big bounce up to the flag on a giant
## pumpkin patch.

const STAR := "star/bounce_hollow"
const GEM := "star/gem_bounce_hollow"
## Each bee: [where it starts, how far it drifts, seconds there and back,
## bounce speed].
const BEES := [
	[Vector3(-1.5, -0.7, -10.5), Vector3(3, 0, 0), 3.2, 16.0],
	[Vector3(1.5, -0.7, -30.5), Vector3(-3, 0, 0), 2.8, 16.0],
	[Vector3(0, 0.0, -50.5), Vector3(0, 0, 0), 3.0, 14.0],
	[Vector3(0, 2.4, -53.5), Vector3(0, 0, 0), 3.0, 14.0],
	[Vector3(-2.0, 4.3, -68.0), Vector3(4, 0, 0), 3.0, 13.0],
	[Vector3(2.0, 4.3, -72.5), Vector3(-4, 0, 0), 3.0, 13.0],
	[Vector3(0, 4.3, -108.5), Vector3(0, 0, 0), 3.0, 16.0],
]
## The bee off to the side, up to the gem.
const GEM_BEE := Vector3(-6.0, -0.7, -22.0)
const ZOMBIES := [-40.0, -44.0]
const HIGH := 5.0
const SPIKE_ROWS := [-82.0, -86.5]
const PLANKS := [-93.5, -97.0, -100.5, -104.0]
## The pumpkin patch, up the last bee's big bounce.
const PATCH := 8.0


func _init() -> void:
	super()
	title = "Bounce Hollow"
	cloud_center = Vector3(0, 0, -60)
	cloud_spread = 75.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "The gaps are too wide to jump. Land on a bee and it bounces you across!")
	deco("food:lollypop", Vector3(-2.5, 0, -5.2), 90.0, 7.0)
	deco("grave:pumpkin-carved", Vector3(2.4, 0, -5.0), 200.0, 1.6)
	deco("food:cupcake", Vector3(2.3, 0, 3.0), 30.0, 4.0)

	for i in BEES.size():
		var b: Array = BEES[i]
		var bee := StarBouncer.make(b[1], b[2], 0.25 * i)
		bee.power = b[3]
		add(bee, b[0])
		add_coin(b[0] + Vector3(0, 2.4, 0))

	# The first island: a row of spike traps.
	land(-3, -26, 3, -16, 0, 3)
	add_checkpoint(Vector3(-2.4, 0, -21.0), Vector3.FORWARD)
	for i in 6:
		add(SpikeTrap.make(0.1 * i), Vector3(-2.5 + i, 0, -19.0))
	deco("food:donut-sprinkles", Vector3(-2.3, 0, -25.3), 30.0, 5.0)
	deco("grave:gravestone-round", Vector3(2.4, 0, -25.4), 0.0, 1.4)

	# Off the racing line: a bee to the west, up to a ledge with the gem.
	if not is_speedrun():
		var gb := StarBouncer.make(Vector3.ZERO, 3.0)
		gb.power = 14.0
		add(gb, GEM_BEE)
		ledge(-13, -24, -9, -20, 3.0)
		add_gem(GEM, Vector3(-11.4, 3.3, -22.0))
		add_heart(Vector3(-10.0, 3.0, -20.8))

	# The second island: zombies shuffling to and fro.
	land(-4, -48, 4, -36, 0, 3)
	add_checkpoint(Vector3(-3.2, 0, -36.8), Vector3.FORWARD)
	add_heart(Vector3(3.2, 0, -36.8))
	for k in ZOMBIES.size():
		var dir := 1.0 if k == 0 else -1.0
		add(Critter.make("grave:character-zombie", Vector3(6.0 * dir, 0, 0), 3.6, 0.0, 0.9), Vector3(-3.0 * dir, 0, ZOMBIES[k]))
	add_sign("Two bees, one above the other: bounce up them to the ledge.", Vector3(-3.0, 0, -46.6))
	for x in [-3.4, 3.4]:
		deco("grave:lightpost-single", Vector3(x, 0, -47.4), 0.0, 1.4)

	# A high ledge with a ghost drifting across.
	land(-3, -64, 3, -56, HIGH, 4)
	add_checkpoint(Vector3(-2.4, HIGH, -56.8), Vector3.FORWARD)
	var ghost := Critter.make("grave:character-ghost", Vector3(6, 0, 0), 2.8, 0.0, 1.0)
	ghost.spiky = true
	ghost.bob = 0.25
	add(ghost, Vector3(-3.0, HIGH, -60.0))
	add_sign("Two bees in a row this time. Keep bouncing!", Vector3(2.4, HIGH, -57.0))

	# A candy island with two rows of spike traps.
	land(-4, -90, 4, -76, HIGH, 4)
	add_checkpoint(Vector3(-3.2, HIGH, -77.0), Vector3.FORWARD)
	add_heart(Vector3(3.2, HIGH, -77.0))
	for r in SPIKE_ROWS.size():
		var z: float = SPIKE_ROWS[r]
		for i in 8:
			add(SpikeTrap.make(0.06 * i + 0.6 * r), Vector3(-3.5 + i, HIGH, z))
		add_coin(Vector3(0, HIGH + 1.6, z))
	deco("food:lollypop", Vector3(3.3, HIGH, -89.2), 90.0, 7.0)
	deco("food:cupcake", Vector3(-3.2, HIGH, -79.5), 60.0, 4.0)
	add_sign("The planks crumble once you land, so keep hopping.", Vector3(-3.0, HIGH, -88.6))

	# Crumbling planks, then the last bee.
	for z in PLANKS:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(0, HIGH, z))
		add_coin(Vector3(0, HIGH + 1.6, z + 1.7))
	coin_line(Vector3(0, HIGH + 2.5, -109.0), Vector3(0, PATCH + 1.5, -112.0), 3)

	# The pumpkin patch, and the flag.
	land(-5, -124, 5, -112, PATCH, 5)
	goal(Vector3(0, PATCH, -118.5), Vector3.FORWARD)
	for p in [Vector3(-3.6, PATCH, -113.6), Vector3(3.8, PATCH, -114.8), Vector3(-3.4, PATCH, -122.6), Vector3(3.6, PATCH, -122.4)]:
		deco("grave:pumpkin-tall-carved", p, fmod(absf(p.x * 50.0), 360.0), 2.4)
	deco("food:cake-birthday", Vector3(0, PATCH, -122.8), 0.0, 4.0)
	glow(Vector3(-8, 7, -30), 1.8)
	glow(Vector3(8, 10, -60), 1.6, Color("ffb3f0"))
	glow(Vector3(-8, 12, -96), 1.8)
	glow(Vector3(-7, 15, -120), 2.0)
	add(StarRainbow.make(16.0, 0.0, 0.5), Vector3(0, 1, -138))
	finish()
