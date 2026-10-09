class_name MoonRamparts
extends StarCourse
## Star Road course 4, Sky Castle meets Star Station, in low gravity: hops
## up three castle towers, a rampart swept by spiked spinners, crumbling
## planks, a spring up to a station deck under cannon fire, and one long
## floating leap to the flag tower.

const STAR := "star/moon_ramparts"
const GEM := "star/gem_moon_ramparts"
## Gravity up here, as a share of the usual.
const LOW_GRAVITY := 0.6
## The three towers: their tops' centres.
const TOWERS := [Vector3(0, 1.5, -11), Vector3(2.5, 3.0, -17), Vector3(-1, 4.5, -22.5)]
const RAMPART_TOP := 4.5
## The spiked spinners' posts beside the rampart.
const SPINNERS := [Vector3(2.5, 4.5, -31.5), Vector3(-2.5, 4.5, -38.5), Vector3(2.5, 4.5, -45.5)]
const PLANKS := [-53.5, -57.0, -60.5, -64.0, -67.5, -71.0]
const SPRING := Vector3(0, 4.5, -77)
const HIGH_DECK := 11.0
## Cannons on the high deck: where each stands, and which way it fires.
const CANNONS := [[Vector3(2.5, 11.0, -83.5), Vector3.LEFT], [Vector3(-2.5, 11.0, -87.5), Vector3.RIGHT]]
const FLAG_TOWER := Vector3(0, 9.0, -104)


func _init() -> void:
	super()
	title = "Moon Ramparts"
	gravity_scale = LOW_GRAVITY
	cloud_center = Vector3(0, 0, -55)
	cloud_spread = 70.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "The air is thin up here: every jump floats. Hop up the towers!")
	deco("castle:flag-banner-long", Vector3(-2.6, 0, -5.6), 90.0, 1.2)
	deco("castle:flag-banner-long", Vector3(2.6, 0, -5.6), 90.0, 1.2)
	deco("station:container-tall", Vector3(2.4, 0, 3.2), 20.0, 1.6)

	# Three towers, each a little higher.
	for i in TOWERS.size():
		var t: Vector3 = TOWERS[i]
		tower(t, 2.5, t.y + 8.0)
		deco("castle:flag-pennant", t + Vector3(1.0, 0, 1.0), 45.0, 1.2)
	coin_line(Vector3(0, 3.2, -7.5), Vector3(0, 3.0, -10.0), 2)
	coin_line(Vector3(1.0, 4.6, -13.6), Vector3(2.0, 4.6, -15.4), 2)
	coin_line(Vector3(1.4, 6.0, -19.2), Vector3(0.0, 6.0, -21.0), 2)
	add_checkpoint(Vector3(-1.9, TOWERS[2].y, -21.6), Vector3.FORWARD)

	# Off the racing line: a ledge high above the third tower. Crouch and
	# jump, then jump again.
	if not is_speedrun():
		ledge(-7, -25, -4, -22, 10.0, "snow")
		add_gem(GEM, Vector3(-5.6, 10.3, -23.6))
		add_heart(Vector3(-4.6, 10.0, -24.4))
		coin_line(Vector3(-2.0, 7.0, -22.8), Vector3(-3.4, 9.4, -23.2), 3)

	# The rampart, swept by spinners on posts beside it.
	land(-1, -50, 1, -27, RAMPART_TOP, 3, "snow")
	for z in range(-49, -26, 2):
		for x in [-1.25, 1.25]:
			deco("castle:wall-narrow", Vector3(x, RAMPART_TOP - 0.9, z + 1.0), 90.0, 1.0)
	for i in SPINNERS.size():
		var at: Vector3 = SPINNERS[i]
		tower(at, 1.0, 6.0)
		# Each sweeps along the rampart the way you run.
		var sp := Spinner.make(3, -80.0 if at.x > 0.0 else 80.0)
		sp.phase = 90.0 * i
		add(sp, at)
	for z in [-29.0, -35.0, -42.0, -48.5]:
		add_coin(Vector3(0, RAMPART_TOP + 0.5, z))
	add_sign("Spinners! Float over the arms, or run behind them.", Vector3(-1.2, TOWERS[2].y, -23.4))

	# Crumbling planks out to the station.
	for z in PLANKS:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(0, RAMPART_TOP, z))
		add_coin(Vector3(0, RAMPART_TOP + 1.6, z + 1.7))

	# The station deck, and a spring up to the high deck.
	deck(-3, -79, 3, -73, RAMPART_TOP, "station:floor-panel", 0.3)
	add_checkpoint(Vector3(-2.2, RAMPART_TOP, -73.8), Vector3.FORWARD)
	add_heart(Vector3(2.2, RAMPART_TOP, -73.8))
	add(Spring.new(), SPRING)
	add_sign("Up here a spring throws you very high. Steer onto the deck above.", Vector3(-2.2, RAMPART_TOP, -76.0))
	coin_line(SPRING + Vector3(0, 2.0, 0), SPRING + Vector3(0, 6.0, -1.2), 3)
	deco("station:container", Vector3(2.3, RAMPART_TOP, -78.3), 10.0, 1.6)
	deco("station:container-wide", Vector3(-2.3, RAMPART_TOP, -78.3), -15.0, 1.6)

	# The high deck, with cannons firing across it.
	deck(-3, -91, 3, -80, HIGH_DECK, "station:floor-panel", 0.3)
	add_checkpoint(Vector3(-2.2, HIGH_DECK, -80.8), Vector3.FORWARD)
	for c in CANNONS:
		var cannon := Launcher.make("pirate:cannon", c[1], 2.2, 0.5 if c[1] == Vector3.LEFT else 0.0)
		cannon.shot_life = 1.0
		add(cannon, c[0])
	for x in [-2.6, 2.6]:
		deco("station:table-display-planet", Vector3(x, HIGH_DECK + 0.3, -90.4), 0.0, 1.5)
	add_sign("A long jump floats for ages: Run, Crouch and Jump at the end.", Vector3(-2.2, HIGH_DECK, -89.0))
	coin_line(Vector3(0, HIGH_DECK + 2.0, -93.0), Vector3(0, HIGH_DECK + 1.0, -99.0), 4)

	# The flag tower.
	tower(FLAG_TOWER, 8.0, FLAG_TOWER.y + 10.0)
	goal(FLAG_TOWER + Vector3(0, 0, -1.0), Vector3.FORWARD)
	for x in [-3.4, 3.4]:
		deco("castle:flag-banner-long", FLAG_TOWER + Vector3(x, 0, -3.4), 0.0, 1.6)
		deco("castle:siege-trebuchet", FLAG_TOWER + Vector3(x, 0, 2.6), 180.0, 1.2)
	glow(Vector3(-8, 9, -40), 1.8)
	glow(Vector3(9, 15, -85), 1.6, Color("ffb3f0"))
	glow(Vector3(-7, 16, -103), 2.0)
	add(StarRainbow.make(16.0, 0.0, 0.5), Vector3(0, 0, -119))
	finish()

