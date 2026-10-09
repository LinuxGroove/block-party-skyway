class_name SunnyIsle
extends Island
## Sunny Isles' first island, for Adventure: a meadow with a terrace to the
## north (and the door to Saw Mill Sprint), Windmill Hill beyond it to the
## west and a grove of giant trees to the east (the doors to Windmill Hills
## and Treetop Hop), Pebble the penguin's hollow to the west, the old tower
## to the east, a beach to the south (the door to Crab Shore Dash, and
## Captain Pinch's door, shut until five stars are found), and Lookout
## Islet across the Skyway once two stars are found, with the Skyway on to
## Frosty Peaks.
##
## Island stars: Pebble's lost chicks, the silver coin rush, the top of the
## old tower, a ledge hidden under the north cliff, and the crabs' crate on
## Lookout Islet. Two hidden gems here, plus one in each course.

const SILVER_TIME := 30.0

var pebble: Islander
var chicks: Array[Chick] = []
var chicks_home := 0
var bridge: SkywayBridge
var silver: SilverRush


func _init() -> void:
	super()
	title = "Sunny Isles"
	spawn = Vector3(0, 0, 9)
	spawn_facing = Vector3.FORWARD
	# Sand for the beach; the grass keeps the kit's colours.
	block_palette = SunnyCrabShore.SAND


func build() -> void:
	_meadow()
	_terrace()
	_windmill_hill()
	_grove()
	_hollow()
	_tower()
	_beach()
	_lookout()
	_scenery()
	finish()
	if world_stars() >= int(Worlds.get_def(world).skyway):
		bridge.show_bridge(false)


## Extra views for the screenshots: the beach with its two doors, Windmill
## Hill and the grove.
func shots() -> Array:
	return [
		{"name": "beach", "at": Vector3(2.5, 0, 20.4), "face": Vector3.FORWARD},
		{"name": "windmill", "at": Vector3(-13.5, 2, -10.6), "face": Vector3.FORWARD, "stick": Vector2(0, -1)},
		{"name": "grove", "at": Vector3(12.2, 2, -17), "face": Vector3.RIGHT},
	]


func collect_star(id: String) -> void:
	var before := world_stars()
	super(id)
	var need := int(Worlds.get_def(world).skyway)
	if before < need and world_stars() >= need:
		bridge.show_bridge(true)
		say("The Skyway is back! A rainbow bridge reaches Lookout Islet.")


# --- The meadow (where the hero lands) ---------------------------------------

func _meadow() -> void:
	land(-12, -10, 12, 12, 0, 3)
	# The east bump the old tower stands on.
	land(12, -8, 18, -1, 0, 3)
	add_checkpoint(Vector3(-2, 0, 10), Vector3.FORWARD)
	add_sign("Hold Run to go faster. Crouch while running, then jump: a long jump.", Vector3(2, 0, 9))
	# The way up to the terrace: two slopes and a step.
	ramp(Vector3(-1, 0, -5), Vector3.FORWARD)
	land(-2, -10, 0, -6, 1, 1)
	ramp(Vector3(-1, 1, -9), Vector3.FORWARD)
	coin_line(Vector3(-1, 0.4, -3), Vector3(-1, 1.9, -9.5), 4)
	coin_ring(Vector3(4, 0, 4), 1.6, 8)
	# Big rocks with a chick on top.
	land(8, 5, 10, 7, 2, 2)
	land(10, 5, 11, 7, 1, 1)
	# Silver Rush: step on the button and grab eight silver coins in time.
	silver = add_silver_rush("sunny/silver", Vector3(-6, 0, 5), SILVER_SPOTS, SILVER_TIME)
	add_sign("Step on the button, then find eight silver coins before time runs out.", Vector3(-8, 0, 6.5))
	# Crabs.
	add(Crab.make(Vector3(4, 0, 0), 3.5), Vector3(2, 0, -1))
	add(Crab.make(Vector3(0, 0, 3), 3.0, 0.5), Vector3(-9, 0, -3))
	add_heart(Vector3(10.5, 0, 10.5))
	# Truffle the hog knows a thing or two.
	var truffle := Islander.make("animal-hog", "Truffle", [
		"Psst. Stars hide in odd places. Have you looked over the edge of the north cliff?",
		"The old tower? Kick off one wall, then the other. Up you go.",
		"The crabs here are grumpy. Jump on them and they pop right into coins.",
		"Their captain is the grumpiest of all. He sits behind a big door down on the beach.",
	], 0.4)
	truffle.facing = Vector3(0.5, 0, 1).normalized()
	add(truffle, Vector3(6, 0, -7.5))


# --- The north terrace and the course door -----------------------------------

func _terrace() -> void:
	land(-8, -22, 10, -10, 2, 5)
	add_checkpoint(Vector3(-5, 2, -13), Vector3.BACK)
	add_course_door("sawmill", Vector3(3, 2, -18))
	coin_line(Vector3(-6, 2, -19), Vector3(0, 2, -19), 4)
	# The secret ledge under the north cliff, with a spring back up.
	add_sign("Something sparkles down below the cliff...", Vector3(6.5, 2, -21), Vector3.BACK)
	ledge(2, -26, 6, -23, -1.5)
	add_star("sunny/ledge", Vector3(4.5, -1.3, -24.5))
	add(Spring.new(), Vector3(2.7, -1.5, -23.6))
	camera_zone(Vector3(1, -6, -27), Vector3(7, 0.2, -22.5), 180.0, 26.0, 8.0, false, 2)


# --- Windmill Hill, north-west ----------------------------------------------

func _windmill_hill() -> void:
	land(-20, -22, -8, -10, 2, 5)
	land(-19, -21, -14, -16, 3, 1)
	ramp(Vector3(-13, 2, -18.5), Vector3.LEFT)
	var mill := SunnyWindmill.new()
	mill.facing = Vector3.BACK
	add(mill, Vector3(-17, 3, -18.5))
	add_course_door("windmill", Vector3(-12, 2, -12.5), Vector3.RIGHT)
	add_checkpoint(Vector3(-10, 2, -20), Vector3.RIGHT)
	add_islander("animal-cow", "Clover", [
		"Moo. That door leads up the Windmill Hills.",
		"Bars spin round on the hilltops. Wait for one to sweep past, then run!",
		"And the springs throw you right up the cliffs. Steer while you fly.",
	], Vector3(-10.5, 2, -16), Vector3(0.6, 0, 1).normalized(), 0.4)
	var bee := Critter.make("animal-bee", Vector3(4, 0, 0), 4.0)
	bee.bob = 0.3
	add(bee, Vector3(-19.5, 2, -14.5))
	coin_line(Vector3(-11, 2, -21), Vector3(-17, 2, -21), 4)
	# A spring in the hollow below throws you up here.
	add(Spring.new(), Vector3(-17.5, -1, -5.4))
	add_sign("Springs throw you high!", Vector3(-13.2, -1, -4.6), Vector3.BACK)


# --- The giant trees, north-east -----------------------------------------------

func _grove() -> void:
	land(10, -22, 21, -12, 2, 5)
	for t in [[Vector3(13, 2, -20), 2.8], [Vector3(19, 2, -14), 2.6], [Vector3(19.5, 2, -20.5), 2.2]]:
		tree(t[0], "tree", t[1])
	add_course_door("treetop", Vector3(17.5, 2, -17), Vector3.LEFT)
	add_islander("animal-monkey", "Mango", [
		"Up in the treetops the planks drop once you stand on them. So don't stand still!",
		"Some branches are too high for one jump. Crouch, then jump.",
	], Vector3(14, 2, -14.5), Vector3(-0.6, 0, 1).normalized(), 0.4)
	add(Critter.make("animal-caterpillar", Vector3(0, 0, -4), 3.5, 0.2), Vector3(11.5, 2, -13))
	add_heart(Vector3(20, 2, -21))
	for at in [Vector3(15, 2, -21), Vector3(11, 2, -18), Vector3(16, 2, -12.8)]:
		deco("mushrooms", at, at.x * 17.0, 1.5)
	coin_ring(Vector3(14.5, 2, -17.5), 1.5, 6)


# --- Pebble's hollow, to the west --------------------------------------------

func _hollow() -> void:
	land(-22, -6, -12, 10, -1, 3)
	add_checkpoint(Vector3(-14, -1, 7), Vector3.LEFT)
	pebble = Islander.make("animal-penguin", "Pebble", [], 0.42)
	pebble.facing = Vector3.RIGHT
	pebble.on_talk = _talk_pebble
	add(pebble, Vector3(-18, -1, 2))
	var nest := Vector3(-18.6, -1, 3.2)
	var chick_spots := [Vector3(8, 2, -20), Vector3(9, 2, 6), Vector3(-26, 0, -1)]
	for i in 3:
		var c := Chick.new()
		c.home = nest + Vector3(i * 0.5, 0, 0.3 * i)
		if found_stars.has("sunny/chicks"):
			c.position = c.home
			c.is_home = true
		else:
			c.position = chick_spots[i]
		c.level = self
		add_child(c)
		c.found.connect(_on_chick_home)
		chicks.append(c)
	if found_stars.has("sunny/chicks"):
		chicks_home = 3
	# A floating rock out west where one chick got stuck.
	ledge(-27, -2, -25, 0, 0)
	# A crate pile with a hidden gem in the strong one.
	for at in [Vector3(-20.5, -1, -4.5), Vector3(-19.5, -1, -4.5), Vector3(-20.5, -1, -3.5)]:
		add(Breakable.make("crate", "coins:2"), at)
	add(Breakable.make("crate-strong", "gem:sunny/gem_crates"), Vector3(-21, -1, -2))
	# Far out to the south-west, a gem for long jumpers.
	ledge(-20, 14, -18, 16, -1)
	add_gem("sunny/gem_far", Vector3(-19, -0.8, 15))
	coin_line(Vector3(-19, -0.9, 10.5), Vector3(-19, -0.9, 13.5), 3)


func _talk_pebble() -> void:
	if chicks_home >= 3:
		speak("Pebble", ["My chicks are staying right here from now on. Thank you again!"])
	elif chicks_home == 0:
		speak("Pebble", [
			"Oh, my chicks! Three of them wandered off while I was napping.",
			"One went up the hill to the north, one is up on the big rocks, and one... out past the cliffs to the west.",
			"Could you find them? Just touch them and they'll hop home.",
		])
	else:
		speak("Pebble", ["%d of 3 home. Please find the rest!" % chicks_home])


func _on_chick_home(_c: Chick) -> void:
	chicks_home += 1
	if chicks_home < 3:
		say("%d of 3 chicks home" % chicks_home)
		return
	pebble.cheer()
	speak("Pebble", ["All three, safe and sound! Here, this was shining in the nest."], _give_chick_star)


func _give_chick_star() -> void:
	add_star("sunny/chicks", pebble.position + Vector3(1.2, 0.4, 0.6))


# --- The old tower, to the east ----------------------------------------------

func _tower() -> void:
	# The tower, and a wall one square from it: kick between them to climb.
	land(13, -6, 15, -4, 7, 10)
	land(16, -6, 17, -4, 6.5, 9)
	add_star("sunny/tower", Vector3(14, 7.2, -5))
	add_sign("Jump at a wall, then jump again to kick off it.", Vector3(14, 0, -2.2))
	coin_line(Vector3(15.5, 1.5, -5), Vector3(15.5, 5.5, -5), 4)
	camera_zone(Vector3(11, -1, -9), Vector3(19, 12, -1), 0.0, 16.0, 11.0, false, 1)


# --- The beach, to the south --------------------------------------------------

func _beach() -> void:
	# Sand all round a little lagoon.
	land(-10, 12, 14, 14, 0, 3, "snow")
	land(-10, 14, 3, 21, 0, 3, "snow")
	land(9, 14, 14, 21, 0, 3, "snow")
	land(3, 18, 9, 21, 0, 3, "snow")
	land(3, 14, 9, 18, -1.5, 2, "snow")
	water(3, 14, 9, 18, -0.35)
	ledge(5, 15, 7, 17, -0.1, "snow")
	coin_ring(Vector3(6, -0.1, 16), 0.6, 4)
	add_checkpoint(Vector3(-2, 0, 13.5), Vector3.BACK)
	add_course_door("crabshore", Vector3(-6, 0, 19), Vector3.FORWARD)
	# Captain Pinch's door, out on the rocky point.
	add_boss_door(Vector3(11.5, 0, 19), Vector3.FORWARD)
	add_islander("animal-crab", "Sandy", [
		"Crab Shore Dash? I hold the record. Well. I would, if the tide hadn't been against me.",
		"The rafts out there sink under the waves. Don't wait around on them!",
	], Vector3(-2.5, 0, 18.5), Vector3(0.3, 0, -1).normalized(), 0.38)
	add_sign("Captain Pinch rules the sand bar past this door. Find five stars to open it.", Vector3(8.5, 0, 18.8), Vector3.BACK)
	add(Crab.make(Vector3(5, 0, 0), 3.4), Vector3(-9, 0, 15.5))
	add(Crab.make(Vector3(0, 0, -4), 2.8, 0.4), Vector3(13.3, 0, 17))
	add_sign("Crabs pinch! Jump on them and they pop into coins.", Vector3(-8.5, 0, 13), Vector3.BACK)
	for at in [Vector3(-9, 0, 20), Vector3(1.5, 0, 20.3), Vector3(9.8, 0, 13.0)]:
		tree(at, "pirate:palm-straight", 0.7)
	for at in [Vector3(13.5, 0, 20.3), Vector3(-3.8, 0, 20.4), Vector3(13.4, 0, 12.6)]:
		deco("rocks", at, at.x * 23.0, 1.8)
	for at in [Vector3(-7, 0, 17), Vector3(3, 0, 13), Vector3(11, 0, 15.5)]:
		deco("stones", at, at.z * 31.0, 1.5)


# --- Lookout Islet, across the Skyway ----------------------------------------

func _lookout() -> void:
	bridge = SkywayBridge.new()
	bridge.to = Vector3(10, 0, 0)
	add(bridge, Vector3(12, 0, 8))
	land(22, 2, 32, 14, 0, 3)
	add_checkpoint(Vector3(23.5, 0, 6), Vector3.RIGHT)
	add(Crab.make(Vector3(0, 0, 4), 2.6), Vector3(26, 0, 4))
	add(Crab.make(Vector3(3, 0, 0), 2.2, 0.3), Vector3(25, 0, 11))
	for at in [Vector3(29.5, 0, 4), Vector3(30.3, 0, 5), Vector3(30.3, 0, 3.2)]:
		add(Breakable.make("crate", "coins:2"), at)
	add(Breakable.make("crate-item-strong", "star:sunny/crates"), Vector3(29, 0, 10.5))
	add_sign("A crate too strong to break? Crouch in the air to ground pound.", Vector3(27, 0, 12.5), Vector3.LEFT)
	add_heart(Vector3(31, 0, 13))
	coin_ring(Vector3(27, 0, 8), 1.4, 6)
	# The Skyway on to Frosty Peaks, faded until Captain Pinch is beaten.
	add_skyway_gate("frosty", Vector3(31, 0, 8.5), Vector3.LEFT)


# --- Silver Rush -------------------------------------------------------------

const SILVER_SPOTS := [
	Vector3(-10, 0, 10), Vector3(10, 0, -8), Vector3(-7, 2, -20), Vector3(9, 2, -12),
	Vector3(-21, -1, 9), Vector3(-15, -1, -5), Vector3(16, 0, -2), Vector3(2, 0, -8),
]


# --- Scenery -----------------------------------------------------------------

func _scenery() -> void:
	for at in [Vector3(-10, 0, -8), Vector3(-9, 0, 0), Vector3(10, 0, 0), Vector3(-6, 2, -12), Vector3(8, 2, -14), Vector3(-16, -1, -4), Vector3(-21, -1, 8), Vector3(30, 0, 13)]:
		tree(at, "tree")
	for at in [Vector3(-11, 0, 4), Vector3(6, 2, -21), Vector3(-7, 2, -21), Vector3(11, 0, -9.0), Vector3(31, 0, 3)]:
		tree(at, "tree-pine")
	for at in [Vector3(-4, 0, 8), Vector3(5, 0, 10), Vector3(9, 0, 3), Vector3(-15, -1, 3), Vector3(25, 0, 9), Vector3(0, 2, -14)]:
		deco("flowers", at, fmod(at.x * 20.0, 360.0))
	for at in [Vector3(-8, 0, 9), Vector3(7, 0, 8), Vector3(-3, 0, 2), Vector3(-17, -1, 7), Vector3(4, 2, -12), Vector3(28, 0, 7)]:
		deco("grass", at, fmod(at.z * 33.0, 360.0), 1.4)
	for at in [Vector3(11, 0, 11), Vector3(-11.3, 0, -9.3), Vector3(-21, -1, -5.5)]:
		deco("rocks", at, 30.0, 1.5)
	for at in [Vector3(-5, 0, -1), Vector3(-17.5, -1, 0)]:
		deco("mushrooms", at, 0.0, 1.4)
	for x in range(-11, 12, 1):
		if absi(x) > 2:
			deco("fence-low-straight", Vector3(x + 0.5, 0, 11.9 - 0.3), 0.0)
