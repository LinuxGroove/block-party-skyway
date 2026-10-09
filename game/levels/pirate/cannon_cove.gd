class_name PirateCannonCove
extends Level
## Course 2 of Pirate Cove: a crossing under cannon fire. A gangway between
## two ships with a cannon either side, over the deck of a ship moored
## across the way, up the long pier of the broadside, where five cannons
## fire one after another in a wave (run right behind it), then west over
## rafts while a mortar lobs shells at you, to the flag on the fort.
##
## Every cannon rocks back and puffs smoke just before it fires.
##
## Adventure: coins, a heart, a hidden gem up on the moored ship's stern and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "pirate/cannoncove"
const GEM := "pirate/gem_cannoncove"
const SEA := PirateBuild.SEA
## The ship across the way: its middle, and the height of its deck.
const SHIP := Vector3(-3, -1.5, -23)
const DECK := 1.34
## Where the broadside pier starts, its cannons' lines, and the beat.
const PIER_Z := -28.0
const WAVE_Z := [-31.0, -35.0, -39.0, -43.0, -47.0, -51.0, -55.0]
const WAVE_PERIOD := 2.0
const WAVE_STEP := 0.5
## The rafts west from the end of the pier, and their line.
const RAFT_X := [-6.25, -10.25, -14.25, -18.25, -22.25, -26.25]
const LANE_Z := -57.25

var gangway_cannons: Array[PirateCannon] = []
var wave: Array[PirateCannon] = []
var mortar: PirateMortar


func _init() -> void:
	super()
	title = "Cannon Cove"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 32.0, 10.0, false]


func build() -> void:
	PirateBuild.sea(self)
	# The start, on the beach.
	land(-3, -3, 3, 4, 0, 3)
	add_sign("Cannons fire on a beat. When one puffs smoke, wait for the shot, then run!", Vector3(-2, 0, 1))
	tree(Vector3(2.4, 0, 3.0), "pirate:palm-straight")

	# The gangway, between two ships, with a cannon either side.
	PirateBuild.dock(self, Vector3(0, 0, -3), Vector3(0, 0, -18))
	PirateBuild.ship(self, "pirate:ship-pirate-medium", Vector3(-10, SEA - 1.0, -10), 0.0, 1.2)
	PirateBuild.ship(self, "pirate:ship-pirate-medium", Vector3(10, SEA - 1.0, -10), 180.0, 1.2)
	for c in GANGWAY:
		var side: float = c.x
		PirateBuild.dock(self, Vector3(side * 1.25, 0, c.y), Vector3(side * 6.25, 0, c.y))
		var cannon := add(PirateCannon.aim(Vector3(-side, 0, 0), 2.4, c.z), Vector3(side * 4.5, 0, c.y)) as PirateCannon
		gangway_cannons.append(cannon)
	coin_line(Vector3(0, 0.2, -4), Vector3(0, 0.2, -16), 5)
	add_checkpoint(Vector3(-0.7, 0, -15.5), Vector3.FORWARD)

	# Over the deck of the ship moored across the way. A barrel to climb
	# aboard by.
	PirateBuild.ship(self, "pirate:ship-large", SHIP, 90.0, 1.35, false)
	PirateBuild.dock(self, Vector3(2.5, 0, -15.5), Vector3(2.5, 0, -18))
	piece("pirate:barrel", Vector3(-0.5, 0, -17.4), 30.0, 0.9)
	solid(Vector3(-1.1, 0, -18.0), Vector3(0.1, 1.1, -16.8))
	add_sign("Climb aboard! Jump twice to clear the rail.", Vector3(-1.0, 0, -15.0), Vector3.BACK)
	add_coin(Vector3(1.5, DECK + 0.3, -23))
	if not is_speedrun():
		# Off the racing line: up the stairs to the stern.
		add_gem(GEM, Vector3(-10.4, 3.2, -23))
		add_heart(Vector3(-9.6, 3.2, -24.6))

	# The broadside: a long pier with cannons on pontoons, firing one after
	# another up the pier.
	PirateBuild.dock(self, Vector3(0, 0, PIER_Z), Vector3(0, 0, -55.5))
	add_checkpoint(Vector3(0, 0, PIER_Z - 0.7), Vector3.FORWARD)
	add_sign("The cannons fire one after another. Run right behind the wave!", Vector3(-0.8, 0, PIER_Z - 0.3), Vector3.BACK)
	for i in WAVE_Z.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var z: float = WAVE_Z[i]
		PirateBuild.dock(self, Vector3(side * 1.25, 0, z), Vector3(side * 6.25, 0, z))
		var phase := fposmod(-WAVE_STEP * i / WAVE_PERIOD, 1.0)
		var cannon := add(PirateCannon.aim(Vector3(-side, 0, 0), WAVE_PERIOD, phase), Vector3(side * 4.5, 0, z)) as PirateCannon
		wave.append(cannon)
		add_coin(Vector3(0, 0.2, z - 2.0))
	PirateBuild.ship(self, "pirate:ship-pirate-large", Vector3(-11, SEA - 1.2, -40), 0.0, 1.3)
	for z in [-33.0, -51.0]:
		PirateBuild.ship(self, "pirate:ship-pirate-large", Vector3(11, SEA - 1.2, z), 180.0, 1.3)

	# The turn: west over rafts, with a mortar on a ship lobbing shells at
	# wherever you stand. Its rings show where they'll land: keep moving!
	for x in [-2.5, 0.0, 2.5]:
		PirateBuild.dock(self, Vector3(x, 0, -55.5), Vector3(x, 0, -58))
	add_checkpoint(Vector3(-1.2, 0, LANE_Z), Vector3.LEFT)
	camera_zone(Vector3(-44, -6, -68), Vector3(1.3, 12, -55.6), 90.0, 34.0, 11.0)
	add_sign("Red rings show where shells will land. Keep moving!", Vector3(-1.0, 0, -58.0), Vector3.LEFT)
	for x in RAFT_X:
		piece("pirate:platform", Vector3(x, -0.22, LANE_Z), fmod(x * 33.0, 4.0))
		solid(Vector3(x - 1.25, -0.4, LANE_Z - 1.25), Vector3(x + 1.25, 0, LANE_Z + 1.25))
		add_coin(Vector3(x, 0.3, LANE_Z))
	PirateBuild.ship(self, "pirate:ship-pirate-medium", Vector3(-16, SEA - 1.0, -67), 90.0, 1.2)
	mortar = add(PirateMortar.make(1.8, 0.0, 15.0), Vector3(-16, 0.95, -67)) as PirateMortar

	# The fort at the end, and the flag.
	land(-38, -63, -29, -52, 0, 3)
	add_flag(Vector3(-33, 0, LANE_Z), Vector3.LEFT)
	piece("pirate:tower-watch", Vector3(-36, 0, -60.5))
	solid(Vector3(-37.5, 0, -62), Vector3(-34.5, 2.6, -59))
	piece("pirate:flag-pirate-high", Vector3(-36.5, 0, -53.5))
	for z in [-54.0, -60.5]:
		piece("pirate:cannon", Vector3(-30.5, 0, z), 90.0, 0.8)
	tree(Vector3(-37, 0, -55.5), "pirate:palm-straight")
	finish()


## The gangway's cannons: (side, z, phase), side -1 west and 1 east.
const GANGWAY := [Vector3(-1, -7.5, 0.0), Vector3(1, -12.5, 0.5)]
