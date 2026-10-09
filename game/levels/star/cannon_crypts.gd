class_name CannonCrypts
extends StarCourse
## Star Road course 2, Pirate Cove meets Spooky Hollow: a dock under
## cannon fire, a graveyard climbing in three terraces with a ghost
## drifting across each, rotting planks that drop under your feet, and a
## narrow gangway with a cannon firing straight down it, then the flag on
## the ghost ship's landing.

const STAR := "star/cannon_crypts"
const GEM := "star/gem_cannon_crypts"
const CANNON_LINES := [-10.0, -14.0, -18.0, -22.0]
const GHOSTS := [[-31.0, 0.0], [-41.0, 1.5], [-51.0, 3.0]]
const PLANKS := 7
## Where the pilot (and a careful runner) jumps each ball on the gangway.
const GANGWAY_JUMPS := [-90.0, -94.5, -99.0, -103.5]


func _init() -> void:
	super()
	title = "Cannon Crypts"
	cloud_center = Vector3(0, 0, -55)
	cloud_spread = 70.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "Cannons on the dock, ghosts in the graveyard. Ghosts can't be jumped on: wait for them to drift aside.")
	deco("pirate:barrel", Vector3(-2.3, 0, -4.6), 0.0, 0.5)
	deco("pirate:barrel", Vector3(2.3, 0, -4.4), 40.0, 0.45)
	deco("pirate:flag-pirate", Vector3(2.4, 0, 3.2), 180.0, 0.7)

	# The dock: cannons fire across it from the east, one after another.
	deck(-2, -26, 2, -6, 0)
	for i in CANNON_LINES.size():
		var z: float = CANNON_LINES[i]
		deck(4, int(z) - 1, 6, int(z) + 1, 0)
		add(Launcher.make("pirate:cannon", Vector3.LEFT, 2.0, 0.25 * i), Vector3(5, 0, z))
		deco("pirate:crate", Vector3(5.6, 0, z + 0.6), 90.0, 0.5)
	for z in [-8.0, -12.0, -16.0, -20.0, -24.0]:
		add_coin(Vector3(0, 0.5, z))
	for z in range(-25, -6, 2):
		deco("fence-rope", Vector3(-1.9, 0, z + 0.5), 90.0)
	add_sign("Cannonballs! Jump over them, or run between them.", Vector3(-1.4, 0, -6.6))
	# Off the racing line: a ledge below the dock, with a spring.
	if not is_speedrun():
		ledge(-7, -17, -4, -15, -2.5)
		add_gem(GEM, Vector3(-5.9, -2.3, -16.0))
		add(Spring.new(), Vector3(-4.6, -2.5, -15.6))
		add_heart(Vector3(-6.4, -2.5, -15.4))

	# The graveyard, up three terraces with a ghost on each.
	land(-3, -36, 3, -26, 0, 3)
	land(-3, -46, 3, -36, 1.5, 3)
	land(-3, -56, 3, -46, 3.0, 4)
	add_checkpoint(Vector3(-2.0, 0, -27.0), Vector3.FORWARD)
	for i in GHOSTS.size():
		var g: Array = GHOSTS[i]
		var side := -1.0 if i % 2 == 0 else 1.0
		var ghost := Critter.make("grave:character-ghost", Vector3(4.8 * -side, 0, 0), 2.4, 0.3 * i, 1.0)
		ghost.spiky = true
		ghost.bob = 0.25
		add(ghost, Vector3(2.4 * side, g[1], g[0]))
		add_coin(Vector3(0, g[1] + 0.5, g[0] + 3.0))
	_graveyard()

	# Rotting planks: each drops a moment after you land on it.
	for i in PLANKS:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(0, 3.0, -59.0 - i * 3.5))
		add_coin(Vector3(0, 4.1, -59.0 - i * 3.5))
	add_sign("Rotten planks! They drop when you land. Keep hopping!", Vector3(2.3, 3.0, -55.0))

	# The gangway, with a cannon at the far end firing straight down it.
	deck(-2, -87, 2, -82, 3.0)
	add_checkpoint(Vector3(-1.2, 3.0, -83.0), Vector3.FORWARD)
	add_heart(Vector3(1.4, 3.0, -83.2))
	deck(-1, -108, 1, -87, 3.0)
	land(-1, -111, 1, -108, 3.0, 3)
	var cannon := Launcher.make("pirate:cannon", Vector3.BACK, 1.8, 0.0)
	# Its balls stop at the end of the gangway.
	cannon.shot_life = 3.0
	add(cannon, Vector3(0, 3.0, -109.0))
	add_sign("A cannon down the gangway! Jump each ball as it comes.", Vector3(-1.4, 3.0, -85.6))
	for z in GANGWAY_JUMPS:
		add_coin(Vector3(0, 4.6, z - 2.0))
	deco("pirate:ship-ghost", Vector3(-8.0, -2.0, -97.0), 0.0, 1.0)

	# The finish, on the ghost ship's landing to the east.
	land(1, -113, 10, -104, 3.0, 3)
	goal(Vector3(6.5, 3.0, -108.5), Vector3.RIGHT)
	deco("pirate:flag-pirate-high", Vector3(9.2, 3.0, -112.2), 90.0, 0.7)
	deco("grave:lightpost-single", Vector3(2.0, 3.0, -112.4), 0.0, 1.4)
	deco("grave:lightpost-single", Vector3(2.0, 3.0, -104.6), 0.0, 1.4)
	deco("pirate:chest", Vector3(9.0, 3.0, -105.0), 220.0, 0.6)
	glow(Vector3(-6, 7, -40), 1.8)
	glow(Vector3(8, 9, -72), 1.6, Color("ffb3f0"))
	add(StarRainbow.make(16.0, 0.0, 0.5), Vector3(4, -6, -130))
	finish()


## Gravestones, fences, pumpkins and crooked pines along the terraces.
func _graveyard() -> void:
	var stones := ["grave:gravestone-cross", "grave:gravestone-round", "grave:gravestone-bevel", "grave:gravestone-decorative"]
	for t in 3:
		var top := 1.5 * t
		var z0 := -26.0 - 10.0 * t
		for k in 4:
			var x := -2.6 if k % 2 == 0 else 2.6
			deco(stones[(t + k) % stones.size()], Vector3(x, top, z0 - 1.5 - k * 2.2), 90.0 if x < 0 else -90.0, 1.4)
		deco("grave:pumpkin-carved", Vector3(2.5, top, z0 - 8.9), 200.0, 1.6)
		deco("grave:lightpost-single", Vector3(-2.6, top, z0 - 9.2), 0.0, 1.4)
	tree(Vector3(-2.4, 3.0, -55.2), "grave:pine-crooked")
	deco("grave:crypt-small", Vector3(4.6, 0.0, -30.0), -90.0, 1.4)
	solid(Vector3(3.6, 0, -31.0), Vector3(5.6, 1.4, -29.0))
	land(3, -32, 6, -28, 0, 2)
	deco("grave:crypt-large", Vector3(-5.2, 1.5, -42.0), 90.0, 1.0)
	land(-7, -44, -3, -40, 1.5, 3)
	solid(Vector3(-6.2, 1.5, -43.2), Vector3(-4.2, 2.5, -40.8))
