class_name CastleIsle
extends Island
## Sky Castle's island, for Adventure: a castle above the clouds at sunset.
## The meadow where the hero lands, the barbican and the drawbridge over the
## moat, the inner ward with its keep, curtain walls and towers, King Thud's
## siege yard and catapult bastion to the east, an orchard to the west, and
## a path of clouds behind the west tower.
##
## Stars: the four courses, Rufus's three banners, the Rampart Rush (silver
## coins), the top of the keep (wall kicks up beside its turret), the star on a
## cloud behind the castle, and Thud's catapult (ground pound it). One
## hidden gem behind a banner on the west tower, plus one in each course.

const P := preload("res://game/levels/castle/castle_parts.gd")

const RUSH_TIME := 35.0
## Heights: the ward and the catapult's bastion (the meadow is at 0).
const WARD := 2.0
const BASTION := 4.5

## Where the silver coins of the Rampart Rush appear.
const RUSH_SPOTS := [
	Vector3(16, 2, -16), Vector3(12, 2, -30), Vector3(0, 2, -26), Vector3(-15, 2, -22),
	Vector3(-13, 4.36, -13), Vector3(-3.5, 5.54, -13.5), Vector3(-9, 5.54, -36.5), Vector3(-16.5, 8.57, -36.5),
]

## The clouds from the west tower round to the west curtain wall, centres
## and sizes; the star waits on the biggest.
const CLOUDS := [
	[Vector3(-18.5, 8.0, -41.5), Vector2(2.4, 2.4)],
	[Vector3(-16, 7.4, -46), Vector2(2.4, 2.4)],
	[Vector3(-12, 6.8, -50), Vector2(3.4, 3.4)],
	[Vector3(-8, 6.4, -46), Vector2(2.4, 2.4)],
	[Vector3(-9, 6.0, -41.5), Vector2(2.4, 2.4)],
]

var rufus: Islander
var poles: Array[CastleBannerPole] = []
var banners_up := 0
var silver: SilverRush
var catapult: CastleCatapult
var drawbridge: CastleDrawbridge
var lift: MovingPlatform
## Floors worth knowing, set as the island builds: the gate towers' tops,
## the south and curtain wall walks, the corner towers and the keep.
var gate_top := 0.0
var wall_walk := 0.0
var curtain_walk := 0.0
var tower_top := 0.0
var keep_top := 0.0


func _init() -> void:
	super()
	title = "Sky Castle"
	spawn = Vector3(0, 0, 13)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_meadow()
	_orchard()
	_ward()
	_castle()
	_keep_climb()
	_cloud_path()
	_siege_yard()
	_bastion()
	_islanders()
	_scenery()
	add_skyway_gates(Vector3(-17, 0, 13), Vector3.RIGHT, Vector3(14, WARD, -20), Vector3.LEFT)
	P.cloud_sea(self, Vector3(4, 0, -12), 34.0, 90.0)
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "ward", "at": Vector3(-5, WARD, -24), "face": Vector3.FORWARD},
		{"name": "bastion", "at": Vector3(27, BASTION, -21.5), "face": Vector3.FORWARD},
		{"name": "clouds", "at": Vector3(-18.5, 8.0, -41.5), "face": Vector3.FORWARD},
	]


# --- The meadow (where the hero lands) and the barbican ----------------------

func _meadow() -> void:
	land(-20, -2, 18, 18, 0, 4)
	land(-20, -6, -4, -2, 0, 4)
	land(4, -6, 18, -2, 0, 4)
	add_checkpoint(Vector3(-3, 0, 14), Vector3.FORWARD)
	add_sign("Welcome to Sky Castle! The drawbridge goes up and down: wait for it to come down, then run across.", Vector3(3, 0, 11.5))
	# The barbican, up its stairs, and the drawbridge over the moat.
	land(-4, -6, 4, -2, WARD, 6, "snow")
	P.stairs(self, Vector3(0, 0, 0.45), Vector3.FORWARD, WARD, 3.0)
	coin_line(Vector3(0, 0, 6), Vector3(0, 0, 2), 3)
	# Hinged on the barbican, so raised it stands in front of you, not behind.
	drawbridge = add(CastleDrawbridge.make(Vector3(0, 0, -6), 4.0, 4.5, 2.5), Vector3(0, WARD, -6)) as CastleDrawbridge
	for x in [-3.0, 3.0]:
		P.tower(self, Vector3(x, WARD, -5.2), 1.4, 2, "roof")
	add_course_door("drawbridge", Vector3(-12, 0, -3), Vector3.BACK)
	coin_ring(Vector3(7, 0, 9), 1.6, 8)
	add(Critter.make("animal-pig", Vector3(6, 0, 0), 4.5), Vector3(3, 0, 3))
	add(Critter.make("animal-pig", Vector3(0, 0, 5), 4.0, 0.5), Vector3(-13, 0, 3))
	add_heart(Vector3(15, 0, 15))


# --- The orchard, a step down to the west -----------------------------------

func _orchard() -> void:
	land(-30, -4, -20, 12, -1, 3)
	ramp(Vector3(-21, -1, 6), Vector3.RIGHT)
	for at in [Vector3(-27, -1, -2), Vector3(-24, -1, 2), Vector3(-28, -1, 6), Vector3(-25, -1, 9)]:
		P.tree(self, at, at.z < 4)
	coin_ring(Vector3(-25.5, -1, 4.5), 1.4, 6)
	var bee := Critter.make("animal-bee", Vector3(0, 0, 4), 3.5)
	bee.bob = 0.3
	add(bee, Vector3(-22.5, -1, -2.5))


# --- The inner ward -----------------------------------------------------------

func _ward() -> void:
	land(-18, -40, -2, -12, WARD, 8)
	land(-2, -34, 2, -12, WARD, 8, "snow")
	land(-2, -40, 2, -34, WARD, 8)
	land(2, -40, 18, -12, WARD, 8)
	add_checkpoint(Vector3(-3, WARD, -16.5), Vector3.FORWARD)
	# The gatehouse: a tower each side of the drawbridge.
	gate_top = P.tower(self, Vector3(-3.5, WARD, -13.5), 3.0, 1)
	P.tower(self, Vector3(3.5, WARD, -13.5), 3.0, 1)
	P.pennant(self, Vector3(3.5, gate_top, -13.5), 90.0)
	# The south walls either side, with little corner towers.
	wall_walk = P.wall(self, Vector3(-16, WARD, -13), Vector3(-5, WARD, -13), 2.0, [1.0])
	P.wall(self, Vector3(5, WARD, -13), Vector3(16, WARD, -13), 2.0, [1.0])
	P.tower(self, Vector3(-17, WARD, -13), 2.0, 2, "spire")
	P.tower(self, Vector3(17, WARD, -13), 2.0, 2, "spire")
	P.stairs(self, Vector3(-10, WARD, -14 - 0.82 * (wall_walk - WARD) / 0.67), Vector3.BACK, wall_walk - WARD, 2.0)
	add_sign("Ballistae fire bolts straight ahead. Jump over them!", Vector3(-12.5, WARD, -17.5))
	var ballista := CastleBallista.make(Vector3.RIGHT, 2.6)
	ballista.bolt_range = 9.5
	add(ballista, Vector3(-15.2, wall_walk, -13))
	coin_line(Vector3(-9, wall_walk, -13), Vector3(-6, wall_walk, -13), 3)
	# Looking down more steeply near the south walls, so they don't hide the hero.
	camera_zone(Vector3(-18, 1, -21), Vector3(18, 9, -14), 0.0, 50.0, 10.0, true, 1)
	coin_line(Vector3(0, WARD, -18), Vector3(0, WARD, -30), 5)
	add(Critter.make("animal-pig", Vector3(-6, 0, 0), 5.0), Vector3(12, WARD, -24))
	add(Critter.make("animal-pig", Vector3(0, 0, -5), 4.0, 0.3), Vector3(-14, WARD, -18.5))
	add_heart(Vector3(15, WARD, -28))
	# The Rampart Rush.
	silver = add_silver_rush("castle/silver", Vector3(6, WARD, -19), RUSH_SPOTS, RUSH_TIME)
	add_sign("Step on the button, then find eight silver coins round the walls before time runs out.", Vector3(8.5, WARD, -17.5))
	add_course_door("ramparts", Vector3(-12, WARD, -26), Vector3.BACK)
	add_course_door("spire", Vector3(11, WARD, -26), Vector3.BACK)


# --- The castle: keep, curtain walls and corner towers ------------------------

func _castle() -> void:
	keep_top = P.tower(self, Vector3(0, WARD, -37), 6.0, 2, "walk", true, true)
	for x in [-2.4, 2.4]:
		for z in [-39.4, -34.6]:
			P.pennant(self, Vector3(x, keep_top, z), 90.0, 2.5)
	add_boss_door(Vector3(-1.6, WARD, -33.3), Vector3.BACK)
	curtain_walk = P.wall(self, Vector3(-15, WARD, -36.5), Vector3(-3, WARD, -36.5), 3.0, [-1.0])
	P.wall(self, Vector3(3, WARD, -36.5), Vector3(15, WARD, -36.5), 3.0, [-1.0])
	P.stairs(self, Vector3(-9, WARD, -35 + 0.82 * (curtain_walk - WARD) / 0.67), Vector3.FORWARD, curtain_walk - WARD, 1.8)
	add_checkpoint(Vector3(-6, curtain_walk, -36.5), Vector3.LEFT)
	coin_line(Vector3(-5, curtain_walk, -36.5), Vector3(-8, curtain_walk, -36.5), 3)
	# The west tower, with a hollow behind its banner.
	tower_top = P.tower(self, Vector3(-16.5, WARD, -36.5), 3.0, 2, "walk", true, false, false)
	solid(Vector3(-18, WARD, -38), Vector3(-15, tower_top, -36.3))
	solid(Vector3(-18, WARD, -36.3), Vector3(-17.2, tower_top, -35))
	solid(Vector3(-15.8, WARD, -36.3), Vector3(-15, tower_top, -35))
	solid(Vector3(-17.2, WARD + 2.2, -36.3), Vector3(-15.8, tower_top, -35))
	P.banner(self, Vector3(-16.5, WARD + 4.3, -34.98), Vector3.BACK, true, 2.0)
	add_gem("castle/gem_banner", Vector3(-16.5, WARD + 0.2, -35.7))
	var x0 := -15.0 + 0.82 * (tower_top - curtain_walk) / 0.67
	P.stairs(self, Vector3(x0, curtain_walk, -36.5), Vector3.LEFT, tower_top - curtain_walk, 1.0)
	# The east tower, with a lift up its south face.
	P.tower(self, Vector3(16.5, WARD, -36.5), 3.0, 2, "walk")
	lift = add(MovingPlatform.make(Vector3(0, tower_top - WARD - 0.2, 0), 7.0, 0.0, Vector3(2, 0.4, 2), "platform-fortified"), Vector3(16.5, WARD + 0.2, -34)) as MovingPlatform
	camera_zone(Vector3(14, 1, -36), Vector3(19, 12, -31), 0.0, 24.0, 12.0, false, 2)
	# Rufus's banner poles: the west tower, the west gate tower and the east tower.
	for at in [Vector3(-16.5, tower_top, -36.5), Vector3(-3.5, gate_top, -13.5), Vector3(16.5, tower_top, -36.5)]:
		var pole := CastleBannerPole.new()
		pole.is_raised = found_stars.has("castle/banners")
		pole.raised.connect(_on_banner)
		poles.append(add(pole, at) as CastleBannerPole)


# --- Top of the keep: wall kicks up beside its turret -------------------------

func _keep_climb() -> void:
	# A tall turret in front of the keep, a metre apart: kick up between
	# them, and once above the keep, steer onto it. Seen from the side, so
	# the turret never hides the climb.
	P.round_tower(self, Vector3(1.8, WARD, -31.95), 2.7, 9, "roof")
	add_sign("Jump at a wall, then jump again to kick off it. Up you go!", Vector3(4.6, WARD, -30.5))
	coin_line(Vector3(1.8, WARD + 2.0, -33.5), Vector3(1.8, WARD + 11.0, -33.5), 5)
	camera_zone(Vector3(-1, 1, -35), Vector3(4.5, 19, -29.5), 90.0, 14.0, 11.0, false, 2)
	add_star("castle/keep", Vector3(0, keep_top, -37.5))
	coin_ring(Vector3(0, keep_top, -37.5), 1.6, 6)


# --- The cloud path behind the west tower --------------------------------------

func _cloud_path() -> void:
	for i in CLOUDS.size():
		var c: Array = CLOUDS[i]
		add(CastleCloud.make(c[1], i * 0.21), c[0])
	add_star("castle/cloud", (CLOUDS[2][0] as Vector3) + Vector3.UP * 0.2)
	for i in [1, 3]:
		add_coin((CLOUDS[i][0] as Vector3) + Vector3.UP * 0.4)
	camera_zone(Vector3(-24, 0, -56), Vector3(-4, 14, -38.5), 0.0, 40.0, 11.0, false, 1)


# --- The siege yard and the catapult bastion ----------------------------------

func _siege_yard() -> void:
	land(18, -20, 34, 14, 0, 4)
	add_checkpoint(Vector3(24, 0, 8), Vector3.LEFT)
	add_course_door("siege", Vector3(30, 0, 9), Vector3.BACK)
	P.stairs(self, Vector3(18 + 0.82 * WARD / 0.67, 0, -16.5), Vector3.LEFT, WARD, 2.0)
	P.siege(self, "trebuchet", Vector3(31, 0, 1), Vector3.LEFT, 1.6)
	P.siege(self, "ram", Vector3(23, 0, -3), Vector3.FORWARD, 1.5)
	P.siege(self, "tower", Vector3(32, 0, -8), Vector3.LEFT, 1.5)
	P.siege(self, "ballista", Vector3(21, 0, 11), Vector3.RIGHT, 1.3)
	add(Critter.make("animal-pig", Vector3(5, 0, 0), 4.0), Vector3(23, 0, -9))
	coin_line(Vector3(22, 0, 4), Vector3(28, 0, 4), 4)


func _bastion() -> void:
	land(24, -30, 34, -20, BASTION, 7, "snow")
	P.stairs(self, Vector3(29, 0, -20 + 0.82 * BASTION / 0.67), Vector3.FORWARD, BASTION, 2.0)
	add_sign("King Thud's catapult! A red ring shows where each stone lands. Keep moving, then ground pound the catapult to break it.", Vector3(26.8, 0, -12.5))
	P.wall(self, Vector3(24, BASTION, -29.25), Vector3(34, BASTION, -29.25), 1.5)
	P.wall(self, Vector3(33.25, BASTION, -28.5), Vector3(33.25, BASTION, -20), 1.5)
	catapult = CastleCatapult.make(Vector3.BACK, 2.2)
	catapult.breakable = true
	catapult.reach = 19.0
	catapult.is_wrecked = found_stars.has("castle/catapult")
	add(catapult, Vector3(29, BASTION, -25.5))
	if catapult.is_wrecked:
		add_star("castle/catapult", _catapult_star_spot())
	else:
		catapult.wrecked.connect(_on_catapult_wrecked)
	add_heart(Vector3(31.5, BASTION, -27.5))


func _catapult_star_spot() -> Vector3:
	return catapult.position + Vector3(1.8, 0.4, 1.2)


func _on_catapult_wrecked() -> void:
	say("The catapult is wrecked!")
	add_star("castle/catapult", _catapult_star_spot())


# --- Islanders -----------------------------------------------------------------

func _islanders() -> void:
	add_islander("animal-lion", "Captain Mane", [
		"Halt! Oh, it's you. Welcome to Sky Castle.",
		"The drawbridge goes up and down all day. Wait for it to come down, then run across.",
		"King Thud parked his Siege Tower behind the keep. Find five stars and the keep's door will open.",
	], Vector3(-2.6, WARD, -4.4), Vector3.BACK, 0.45)
	add_islander("animal-deer", "Fern", [
		"Lovely evening. From the top of the west tower, I once saw a star sitting on a cloud.",
		"Banners hide all sorts of things. Have you looked behind the one on the west tower?",
		"Thud's catapult on the bastion keeps throwing stones into the yard. Somebody should ground pound it.",
	], Vector3(-8, 0, 7), Vector3.BACK, 0.42)
	add_islander("animal-bunny", "Bramble", [
		"Thud's soldiers left their siege engines lying all over my yard.",
		"The stairs past the battering ram go up into the castle, if the drawbridge is up.",
	], Vector3(21.5, 0, 6), Vector3.BACK, 0.4)
	rufus = add_islander("animal-fox", "Rufus", [], Vector3(-5.5, WARD, -20), Vector3.BACK, 0.42)
	rufus.on_talk = _talk_rufus
	if found_stars.has("castle/banners"):
		banners_up = poles.size()


func _talk_rufus() -> void:
	if banners_up >= poles.size():
		speak("Rufus", ["The castle looks itself again. Thank you!"])
	elif banners_up == 0:
		speak("Rufus", [
			"I'm the castle's herald, and King Thud's soldiers pulled down all our banners!",
			"There's a pole on the west tower, one on the gate tower by the drawbridge, and one on the east tower.",
			"Touch each pole and the banner runs right back up. Could you?",
		])
	else:
		speak("Rufus", ["%d of 3 banners flying. Keep going!" % banners_up])


func _on_banner(_pole: CastleBannerPole) -> void:
	banners_up += 1
	if banners_up < poles.size():
		say("%d of 3 banners flying" % banners_up)
		return
	rufus.cheer()
	speak("Rufus", ["All three banners, flying high! Here, King Thud dropped this on his way out."], _give_banner_star)


func _give_banner_star() -> void:
	add_star("castle/banners", rufus.position + Vector3(1.2, 0.4, 0.8))


# --- Scenery -------------------------------------------------------------------

func _scenery() -> void:
	for at in [Vector3(-12, 0, 9), Vector3(13, 0, 4), Vector3(-16, 0, -3), Vector3(9, 0, 15), Vector3(-15, WARD, -30), Vector3(14, WARD, -15.8), Vector3(26, 0, 12)]:
		P.tree(self, at, true)
	for at in [Vector3(-9, 0, 15), Vector3(15, 0, -4), Vector3(-9, WARD, -22), Vector3(11, WARD, -29.5), Vector3(33, 0, 12)]:
		P.tree(self, at, false)
	for at in [Vector3(16, 0, 11), Vector3(-18, 0, 1), Vector3(33, 0, -14)]:
		P.rocks(self, at)
	for at in [Vector3(-5, 0, 9), Vector3(6, 0, 15), Vector3(-14, 0, 13), Vector3(11, 0, -1), Vector3(5, WARD, -22), Vector3(-10, WARD, -32)]:
		deco("flowers", at, fmod(at.x * 20.0, 360.0), 1.3)
	for at in [Vector3(-7, 0, 13), Vector3(4, 0, 6), Vector3(14, 0, 9), Vector3(-6, WARD, -27), Vector3(13, WARD, -21), Vector3(27, 0, -2)]:
		deco("grass", at, fmod(at.z * 33.0, 360.0), 1.4)
	P.siege(self, "catapult", Vector3(-7, 0, -3.5), Vector3.FORWARD, 1.3)
	P.banner(self, Vector3(-6, curtain_walk - 0.3, -34.98), Vector3.BACK, false, 2.0)
	P.banner(self, Vector3(8, curtain_walk - 0.3, -34.98), Vector3.BACK, false, 2.0)
	P.banner(self, Vector3(-8, WARD + 2.0, -14.02), Vector3.BACK, false, 1.6)
	P.banner(self, Vector3(9, WARD + 2.0, -14.02), Vector3.BACK, false, 1.6)
	for at in [Vector3(-16.5, tower_top, -36.5), Vector3(16.5, tower_top, -36.5)]:
		P.pennant(self, at + Vector3(0.9, 0, 0.9), 90.0, 2.0)
