class_name PirateCove
extends Island
## Pirate Cove's island, for Adventure: a sandy beach in the middle of a
## sunny cove, with the sea all round. A long dock runs east to the old fort
## and its lookout tower, a short one west to a moored ship, a sandbar north
## to a beached wreck, and a pier south to the rowing boats. Polly's ship
## lies at anchor off the fort.
##
## Stars: catch Rascal the fox (Kip the parrot's request), the silver coins
## on the docks, the top of the lookout tower, Skull Rock out past the
## bobbing barrels (a secret), and Banjo's buried treasure (dig at the X).
## Two hidden gems, plus one in each course.

const SEA := PirateBuild.SEA
const SILVER_TIME := 40.0
## Rascal runs about the west of the beach, between the palms.
const RASCAL_PATCH := Rect2(-13, -9, 11, 13)
const FORT := 1.0
const TOWER := Vector3(39, FORT, -8)
## The tower's floor at the top, inside the battlements.
const TOWER_TOP := FORT + 8.0

var kip: Islander
var banjo: Islander
var rascal: PirateThief
var silver: SilverRush
var dig: PirateDigSpot
var boats: Array[PirateBoat] = []
var barrels: Array[PirateBarrel] = []
var talked_banjo := false


func _init() -> void:
	super()
	title = "Pirate Cove"
	spawn = Vector3(2, 0, 7)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_sea()
	_beach()
	_north()
	_west_ship()
	_east_dock()
	_fort()
	_sandbar()
	_skull_rock()
	_scenery()
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "fort", "at": Vector3(30, FORT, 0), "face": Vector3(1, 0, -0.6)},
		{"name": "ship", "at": Vector3(-22, 0, 1), "face": Vector3.LEFT},
		{"name": "wreck", "at": Vector3(0, 0, -14), "face": Vector3.FORWARD},
	]


# --- The sea -----------------------------------------------------------------

func _sea() -> void:
	PirateBuild.sea(self)


# --- The beach (where the hero lands) ----------------------------------------

func _beach() -> void:
	land(-14, -10, 14, 12, 0, 3)
	# A low dune to the north-east.
	land(4, -10, 12, -5, 0.5, 1)
	add_checkpoint(Vector3(-1, 0, 9), Vector3.FORWARD)
	add_sign("The sea sends you back to the last flag. Mind the gaps!", Vector3(4, 0, 8.5))
	coin_ring(Vector3(2, 0, 2), 1.6, 8)
	# Kip the parrot, and the fox who took her star.
	kip = add_islander("animal-parrot", "Kip", [], Vector3(-4, 0, 6.5), Vector3(-0.4, 0, -1).normalized(), 0.4)
	kip.on_talk = _talk_kip
	if found_stars.has("pirate/rascal"):
		add_islander("animal-fox", "Rascal", [
			"All right, all right! I've learned my lesson.",
			"Mostly.",
		], Vector3(-6, 0, 5.5), Vector3(0.5, 0, 1).normalized(), 0.4)
	else:
		rascal = PirateThief.new()
		rascal.bounds = RASCAL_PATCH
		rascal.caught.connect(_on_rascal_caught)
		add(rascal, Vector3(-8, 0, -3))
	# Banjo's map leads out to the sandbar.
	banjo = add_islander("animal-monkey", "Banjo", [], Vector3(8, 0, 9.5), Vector3(-0.5, 0, -1).normalized(), 0.42)
	banjo.on_talk = _talk_banjo
	add(Crab.make(Vector3(0, 0, 3.5), 3.5), Vector3(9, 0, -3))
	add_heart(Vector3(-12.5, 0, 11))
	# The Skyway back to Frosty Peaks.
	add_skyway_gate("frosty", Vector3(-5, 0, 10.8), Vector3.FORWARD)
	# The door to Dock Dash, where the long dock starts.
	add_course_door("dockdash", Vector3(11, 0, -1.5), Vector3.LEFT)


func _talk_kip() -> void:
	if found_stars.has("pirate/rascal"):
		speak("Kip", ["My star's back where it belongs. You're quicker than you look!"])
	else:
		speak("Kip", [
			"Squawk! That rascal of a fox pinched my star!",
			"He's on the beach, just over there. He's quick, but you're quicker if you Run.",
			"Corner him by the water and he'll have nowhere to go.",
		])


func _on_rascal_caught() -> void:
	speak("Rascal", ["Oof! Fine, fine. Here, take it. It was too shiny anyway."], _give_rascal_star)


func _give_rascal_star() -> void:
	add_star("pirate/rascal", rascal.position + Vector3(0, 0.6, 1.2))
	kip.cheer()


func _talk_banjo() -> void:
	talked_banjo = true
	if dig and dig.is_dug:
		speak("Banjo", ["My treasure! Well, your treasure now. A pirate keeps their word."])
	else:
		speak("Banjo", [
			"Arr, I buried my treasure out on the sandbar to the south-east, and now I can't swim out to it.",
			"Take the pier, and hop on a rowing boat when one comes close.",
			"Find the X, then Crouch in the air to ground pound it. Dig deep!",
		])


# --- North: the sandbar and the wreck ----------------------------------------

func _north() -> void:
	land(-2, -24, 2, -10, 0, 3)
	add(Crab.make(Vector3(0, 0, 4), 3.0), Vector3(-0.5, 0, -20))
	land(-10, -40, 10, -24, 0, 3)
	add_checkpoint(Vector3(-3, 0, -25.5), Vector3.FORWARD)
	# The wreck, beached and half sunk in the sand. Its stern hides a gem.
	PirateBuild.ship(self, "pirate:ship-wreck", Vector3(2, -1.0, -33), 100.0, 1.4)
	add_gem("pirate/gem_wreck", Vector3(-3.6, 4.1, -34.0))
	add_course_door("wreckclimb", Vector3(-6, 0, -27), Vector3.BACK)
	add_sign("Shipwreck Climb: up the sea stack to the old wreck at the top.", Vector3(-8.5, 0, -26.5))
	for at in [Vector3(-7.5, 0, -32), Vector3(6, 0, -27), Vector3(8, 0, -38)]:
		add(Breakable.make("crate", "coins:2"), at)
	# A crate and a barrel to climb aboard by, at the gap in her rail; the
	# stairs on deck go up to the stern.
	piece("pirate:barrel", Vector3(1.5, 0, -28.6), 20.0, 0.9)
	solid(Vector3(0.9, 0, -29.2), Vector3(2.1, 1.1, -28.0))
	piece("pirate:crate", Vector3(3.1, 0, -28.2), 10.0, 0.9)
	solid(Vector3(2.6, 0, -28.7), Vector3(3.6, 0.7, -27.7))
	add(Critter.make("animal-crab", Vector3(5, 0, 0), 3.5), Vector3(-4, 0, -38))
	add_heart(Vector3(8, 0, -26))


# --- West: the moored ship (and the door to Cannon Cove) ---------------------

func _west_ship() -> void:
	PirateBuild.dock(self, Vector3(-14, 0, 1.25), Vector3(-26.5, 0, 1.25))
	add_checkpoint(Vector3(-17, 0, 1.25), Vector3.LEFT)
	add_sign("Cannons fire on a beat. Wait for the shot, then run.", Vector3(-15.5, 0, -0.4), Vector3.LEFT)
	# A barrel to climb aboard by.
	piece("pirate:barrel", Vector3(-25.6, 0, 1.25), 30.0, 0.9)
	solid(Vector3(-26.2, 0, 0.65), Vector3(-25.0, 1.1, 1.85))
	# The ship, deck at about 1.3.
	PirateBuild.ship(self, "pirate:ship-large", Vector3(-30.5, -1.5, 1), 0.0, 1.35)
	add_course_door("cannoncove", Vector3(-30.5, 1.34, -2.7), Vector3.BACK)
	add_islander("animal-cat", "Sails", [
		"Cannon Cove is a ship-to-ship crossing, with cannons firing all the way.",
		"They fire on a beat. Count, then run.",
	], Vector3(-29.2, 1.34, -1.2), Vector3.RIGHT, 0.4)
	# Barrels up on the stern deck: one has a gem in it.
	for at in [Vector3(-31.8, 2.28, 4.5), Vector3(-31.8, 2.28, 5.4)]:
		add(Breakable.make("barrel", "coins:2"), at)
	add(Breakable.make("barrel", "gem:pirate/gem_barrel"), Vector3(-31.0, 2.28, 5.0))


# --- East: the long dock --------------------------------------------------------

func _east_dock() -> void:
	PirateBuild.dock(self, Vector3(14, 0, 1.25), Vector3(26.5, 0, 1.25))
	silver = add_silver_rush("pirate/silver", Vector3(16.5, 0, 1.25), SILVER_SPOTS, SILVER_TIME)
	add_sign("Step on the button, then find eight silver coins on the docks and beaches before time runs out.", Vector3(15.5, 0, -0.2), Vector3.RIGHT)
	coin_line(Vector3(19, 0, 1.25), Vector3(26, 0, 1.25), 4)
	# A rowing boat sculls about beside the dock.
	var b := add(PirateBoat.make(Vector3(0, 0, 5), 6.0, 0.0, "pirate:boat-row-small"), Vector3(22, SEA - 0.12, 5)) as PirateBoat
	b.heading = Vector3.BACK
	boats.append(b)


# --- The fort and its lookout tower ------------------------------------------

func _fort() -> void:
	land(28, -16, 46, 8, FORT, 4)
	ramp(Vector3(27, 0, 1.25), Vector3.RIGHT)
	add_checkpoint(Vector3(31, FORT, 3.5), Vector3.RIGHT)
	add_islander("animal-pig", "Gus", [
		"See that ship out past the fort? That's Polly's. She's a parrot, and the captain.",
		"She flies about firing her cannons, and you'll see where each shot lands. Keep moving!",
		"When she lands on deck to reload, that's your chance. Jump on her!",
	], Vector3(42, FORT, -12.5), Vector3(-0.6, 0, 1).normalized(), 0.42)
	add_boss_door(Vector3(44, FORT, -14), Vector3(-1, 0, 0.8).normalized())
	add_course_door("riggingrun", Vector3(33, FORT, -13), Vector3.BACK)
	# The Skyway on to Spooky Hollow, faded until Polly is beaten.
	add_skyway_gate("spooky", Vector3(44.5, FORT, 3), Vector3.LEFT)
	for at in [Vector3(30, FORT, -15), Vector3(36, FORT, -15.2)]:
		piece("pirate:cannon", at, 180.0)
		solid(at + Vector3(-0.6, 0, -0.8), at + Vector3(0.6, 0.9, 0.8))
	piece("pirate:flag-pirate-high", Vector3(30, FORT, 6.5), 0.0)
	solid(Vector3(29.8, FORT, 6.3), Vector3(30.2, FORT + 3.5, 6.7))
	add_heart(Vector3(45, FORT, -5))
	_tower()


## The lookout: a stone tower with plank ledges round it, each a double
## jump above the last. A ledge part way up gives way.
func _tower() -> void:
	var t := TOWER
	piece("pirate:tower-base", t)
	piece("pirate:tower-middle", t + Vector3.UP * 2.0, 90.0)
	piece("pirate:tower-middle", t + Vector3.UP * 4.0)
	piece("pirate:tower-top", t + Vector3.UP * 6.0)
	solid(t + Vector3(-1.4, 0, -1.4), t + Vector3(1.4, 8.0, 1.4))
	# Battlements round the top.
	for s in [Vector3(-1.55, 0, -1.55), Vector3(1.25, 0, -1.55)]:
		solid(t + s + Vector3(0, 8.0, 0), t + s + Vector3(0.3, 8.7, 3.1))
	for s in [Vector3(-1.55, 0, -1.55), Vector3(-1.55, 0, 1.25)]:
		solid(t + s + Vector3(0, 8.0, 0), t + s + Vector3(3.1, 8.7, 0.3))
	add_star("pirate/lookout", t + Vector3.UP * 8.2)
	add_sign("The lookout. Jump twice to get from ledge to ledge.", Vector3(36.5, FORT, -4.2), Vector3(-0.5, 0, 1).normalized())
	# Up from a stack of barrels by the door.
	piece("pirate:barrel", t + Vector3(-2.6, 0, 1.0))
	solid(t + Vector3(-3.2, 0, 0.4), t + Vector3(-2.0, 1.2, 1.6))
	for l in LEDGES:
		var at: Vector3 = t + l
		piece("pirate:platform", at + Vector3.DOWN * 0.22, 0.0, 0.64)
		solid(at + Vector3(-0.8, -0.25, -0.8), at + Vector3(0.8, 0, 0.8))
	var falling := add(FallingPlatform.make(Vector3(2, 0.3, 2), "platform", 0.7), t + FALLING_LEDGE)
	falling.name = "TowerFalling"
	coin_line(t + Vector3(-2.6, 1.4, 1.0), t + Vector3(-2.6, 2.6, -1.6), 3)
	camera_zone(t + Vector3(-7, 1.5, -7), t + Vector3(7, 12, 7), 0.0, 24.0, 12.0, true, 1)


## Ledges round the tower, from the barrels by its foot: west, north
## (where one gives way), east and south, then over the battlements.
const LEDGES := [Vector3(-2.3, 2.6, -1.4), Vector3(2.3, 6.6, 1.2), Vector3(-1.0, 8.5, 2.6)]
const FALLING_LEDGE := Vector3(1.2, 4.4, -2.3)


# --- South: the pier, the rowing boats and the sandbar -----------------------

func _sandbar() -> void:
	PirateBuild.dock(self, Vector3(10, 0, 12), Vector3(10, 0, 17))
	add_sign("Rowing boats come and go. Hop on when one is close.", Vector3(11.5, 0, 13), Vector3.LEFT)
	for i in 2:
		var b := add(PirateBoat.make(Vector3(7, 0, 0), 6.0, i * 0.5), Vector3(10.5, SEA - 0.12, 19 + i * 3.2)) as PirateBoat
		boats.append(b)
	land(19, 15, 29, 25, 0, 3)
	add_checkpoint(Vector3(20.5, 0, 17), Vector3.RIGHT)
	dig = PirateDigSpot.make("star:pirate/treasure")
	add(dig, Vector3(25, 0, 20))
	for at in [Vector3(22, 0, 23), Vector3(25, 0, 23.5), Vector3(28, 0, 23)]:
		tree(at, "pirate:palm-straight")
	add(Crab.make(Vector3(3, 0, 0), 3.0, 0.4), Vector3(21, 0, 16.5))
	coin_line(Vector3(20, 0, 21), Vector3(23, 0, 21), 3)


# --- Skull Rock, out past the bobbing barrels -----------------------------------

func _skull_rock() -> void:
	# The barrels start behind the big rock in the beach's south-west corner.
	for i in BARREL_SPOTS.size():
		var b := add(PirateBarrel.make(i * 0.23), BARREL_SPOTS[i]) as PirateBarrel
		barrels.append(b)
	land(-36, 25, -27, 33, 0, 3)
	piece("pirate:rocks-sand-b", Vector3(-31, 0, 30.5), 200.0, 1.0)
	solid(Vector3(-33, 0, 29), Vector3(-29.5, 1.4, 32))
	solid(Vector3(-32.2, 0, 29.6), Vector3(-30.2, 3.3, 31.4))
	add_star("pirate/skull", Vector3(-31.2, 3.5, 30.5))
	piece("pirate:rocks-sand-c", Vector3(-28.5, 0, 31.5), 40.0)
	solid(Vector3(-29.8, 0, 30.2), Vector3(-27.8, 1.0, 32.6))
	add_checkpoint(Vector3(-29, 0, 27), Vector3(-1, 0, 0))
	coin_ring(Vector3(-33, 0, 27), 1.0, 5)
	tree(Vector3(-35, 0, 26), "pirate:palm-bend")


const BARREL_SPOTS := [
	Vector3(-16.5, SEA, 13.5), Vector3(-19, SEA, 15.8), Vector3(-21.5, SEA, 18.0),
	Vector3(-24.0, SEA, 20.2), Vector3(-26.2, SEA, 22.6),
]


# --- Silver Rush --------------------------------------------------------------

const SILVER_SPOTS := [
	Vector3(24, 0, 1.25), Vector3(35, FORT, 0), Vector3(43, FORT, -9), Vector3(8, 0.5, -8),
	Vector3(1.2, 0, -13.5), Vector3(-10, 0, -8), Vector3(-22, 0, 1.25), Vector3(10, 0, 16),
]


# --- Scenery ------------------------------------------------------------------

func _scenery() -> void:
	# Polly's ship at anchor, out past the fort.
	piece("pirate:ship-pirate-large", Vector3(60, SEA - 1.0, -30), 140.0, 2.0)
	for at in [Vector3(-13, 0, -9.3), Vector3(12.5, 0, 6), Vector3(-6, 0, -9.6), Vector3(12.5, 0, 10.5), Vector3(-12.5, 0, 6.5), Vector3(8, 0.5, -9)]:
		tree(at, "pirate:palm-straight")
	for at in [Vector3(-8.5, 0, -38.5), Vector3(8.5, 0, -30), Vector3(29.5, FORT, -6), Vector3(45, FORT, 6.5), Vector3(-8.5, 0, 11.2)]:
		tree(at, "pirate:palm-bend")
	for at in [Vector3(44.5, FORT, -1), Vector3(29, FORT, -10.5), Vector3(-3, 0, -36)]:
		tree(at, "pirate:palm-detailed-straight")
	# The big rock that hides the barrels.
	piece("pirate:rocks-sand-a", Vector3(-12.3, 0, 8.6), 30.0)
	solid(Vector3(-14, 0, 7.4), Vector3(-10.8, 1.6, 10.2))
	piece("pirate:rocks-sand-c", Vector3(13, 0, -9), 0.0, 0.9)
	solid(Vector3(11.8, 0, -10), Vector3(14, 1.2, -7.8))
	for at in [Vector3(-6, 0, 2), Vector3(5, 0, -3), Vector3(-10, 0, -30), Vector3(36, FORT, 4), Vector3(26, 0, 17)]:
		deco("pirate:grass-plant", at, fmod(at.x * 40.0, 360.0))
	for at in [Vector3(1, 0, 4), Vector3(-9, 0, 8), Vector3(5, 0, -34), Vector3(40, FORT, 2), Vector3(-6, 0, -12 + 2)]:
		deco("pirate:grass-patch", at, fmod(at.z * 30.0, 360.0))
	for at in [Vector3(10.5, 0, 5), Vector3(-30.5, 1.34, -4.6)]:
		deco("pirate:crate-bottles", at, 15.0, 0.8)
	deco("pirate:bottle-large", Vector3(6.5, 0, 10.5), 0.0, 0.8)
	for at in [Vector3(34, FORT, 5.5), Vector3(35.2, FORT, 5.7), Vector3(34.6, FORT, 4.6)]:
		piece("pirate:barrel", at, fmod(at.x * 50.0, 360.0), 0.7)
	solid(Vector3(33.4, FORT, 4.0), Vector3(35.9, FORT + 0.86, 6.3))
	piece("pirate:flag-pirate", Vector3(-26.5, 0, -0.1), 0.0)
	# Rowing boats pulled up on the beach.
	piece("pirate:boat-row-small", Vector3(-11, 0, 0), 70.0)
