class_name FrostyPeaks
extends Island
## Frosty Peaks' island, for Adventure: a snowy village of log cabins round
## a big decorated tree (where the hero lands), the frozen pond to the east,
## the pine woods to the west with an icy cliff at their far end, and Frosty
## Peak to the north, a mountain of snowy tiers on a plateau that holds the
## boss's door. The Skyway back to Sunny Isles lands to the south; the one
## on to Pirate Cove leaves past the pond.
##
## Stars: the four courses, Dasher's lost presents (a request), the silver
## coins on and around the ice (a timed rush), the top of Frosty Peak (a
## climb), a hollow behind the ice curtain in the woods' cliff (a secret),
## and catching Pingo on the pond (a chase). Two hidden gems: in a present
## tied too tight to open without a ground pound, and on an ice floe past
## the pond.

const SILVER_TIME := 40.0
## Dasher's sled, where his presents go back to.
const SLED := Vector3(6.2, 0, 3.0)
## The pond's ice, where Pingo plays.
const POND := Rect2(18, -8, 16, 16)
const PRESENT_SPOTS := [Vector3(-10, 3.62, -9), Vector3(-8.5, 3.5, -40.5), Vector3(42.5, 0, -0.5)]

var dasher: Islander
var presents: Array[FrostyPresent] = []
var presents_home := 0
var waddles: Islander
var pingo: FrostyPingo
var silver: SilverRush


func _init() -> void:
	super()
	title = "Frosty Peaks"
	spawn = Vector3(0, 0, 11)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_village()
	_plateau()
	_peak()
	_pond()
	_woods()
	_landing()
	_scenery()
	finish()


## Extra views for the screenshot tool.
func shots() -> Array:
	return [
		{"name": "peak", "at": Vector3(1, 2, -16.2), "face": Vector3(-0.1, 0, -1), "stick": Vector2(0, -1)},
		{"name": "pond", "at": Vector3(16, 0, 9), "face": Vector3(1, 0, -0.6)},
		{"name": "woods", "at": Vector3(-20, -1, 6), "face": Vector3(-1, 0, -0.4)},
	]


# --- The village (where the hero lands) --------------------------------------

func _village() -> void:
	land(-14, -14, 14, 16, 0, 3, "snow")
	add_checkpoint(Vector3(-3, 0, 12), Vector3.FORWARD)
	add_sign("Hold Run to go faster. Crouch while running, then jump: a long jump.", Vector3(2.5, 0, 12.5))
	# The big tree in the square, with a toy train set round it.
	tree(Vector3(0, 0, 0), "holiday:tree-decorated-snow", 2.6)
	_train_ring(Vector3(0, 0, 0), 2.6)
	# Cabins round the square. The north-west one has a present on its roof:
	# up the presents stacked by its side.
	FrostyBuild.cabin(self, -12, -12, 2, 3, 0.0, Vector3.RIGHT)
	FrostyBuild.cabin(self, -12, -2, 2, 2, 0.0, Vector3.RIGHT)
	FrostyBuild.cabin(self, 6, -12, 2, 2, 0.0, Vector3.BACK)
	FrostyBuild.cabin(self, 9, 7, 2, 2, 0.0, Vector3.LEFT, false)
	FrostyBuild.present(self, Vector3(-6.8, 0, -4.9), 1.2, 1.0, 1)
	FrostyBuild.present(self, Vector3(-6.9, 0, -6.9), 1.4, 1.9, 0)
	coin_line(Vector3(-6.8, 1.2, -4.9), Vector3(-6.9, 2.1, -6.9), 2)
	# The way up to the plateau: two slopes and a step.
	for x in [-1.0, 1.0]:
		ramp(Vector3(x, 0, -8), Vector3.FORWARD, "snow")
		ramp(Vector3(x, 1, -13), Vector3.FORWARD, "snow")
	land(-2, -12, 2, -9, 1, 1, "snow")
	coin_line(Vector3(0, 0.4, -6.5), Vector3(0, 1.9, -13.5), 5)
	add_course_door("chimneys", Vector3(-5, 0, -12.6))
	# Dasher the reindeer and his sled, with the presents he's found so far.
	dasher = Islander.make("animal-deer", "Dasher", [], 0.44)
	dasher.facing = Vector3(-0.3, 0, 1).normalized()
	dasher.on_talk = _talk_dasher
	add(dasher, Vector3(4.2, 0, 2.2))
	piece("holiday:sled-long", SLED, 90.0, 2.6)
	var done := found_stars.has("frosty/presents")
	for i in PRESENT_SPOTS.size():
		var p := FrostyPresent.new()
		p.kind = i
		p.home = SLED + Vector3(-0.6 + i * 0.6, 0.85, 0)
		p.position = PRESENT_SPOTS[i]
		add(p, p.position)
		p.found.connect(_on_present_home)
		if done:
			p.place_home()
		presents.append(p)
	if done:
		presents_home = presents.size()
	# Silver Rush: step on the button, then find eight silver coins in time.
	silver = add_silver_rush("frosty/silver", Vector3(-6, 0, 9), SILVER_SPOTS, SILVER_TIME)
	add_sign("Step on the button, then find eight silver coins before time runs out. Some are out on the ice!", Vector3(-8.5, 0, 10.5))
	coin_ring(Vector3(0, 0, 0), 3.6, 10)
	add_heart(Vector3(12.5, 0, -3))
	# Juniper the fox knows the island.
	add_islander("animal-fox", "Juniper", [
		"Welcome to Frosty Peaks! Mind the ice on the pond: it's slippery.",
		"They say the woods' cliff hides something. The ice there looks awfully thin.",
		"Frosty Peak is a tall climb. Crouch, then jump to reach the high ledges.",
	], Vector3(-4.5, 0, 4.5), Vector3(0.4, 0, 1).normalized(), 0.4)


func _talk_dasher() -> void:
	if presents_home >= presents.size():
		speak("Dasher", ["Every present back on the sled. The village party is saved!"])
	elif presents_home == 0:
		speak("Dasher", [
			"Oh no, oh no. I took the corner too fast and three presents flew off my sled!",
			"One landed on a cabin roof, one up on Frosty Peak, and one out past the pond, on the ice.",
			"Touch them and they'll fly right back. Could you?",
		])
	else:
		speak("Dasher", ["%d of 3 back on the sled. Just a few more!" % presents_home])


func _on_present_home(_p: FrostyPresent) -> void:
	presents_home += 1
	if presents_home < presents.size():
		say("%d of 3 presents back on the sled" % presents_home)
		return
	dasher.cheer()
	speak("Dasher", ["All three! And look what was tucked in with them. It's yours."], _give_present_star)


func _give_present_star() -> void:
	add_star("frosty/presents", dasher.position + Vector3(-1.0, 0.4, 1.0))


## A ring of toy train track round the tree, with the train parked on it.
func _train_ring(at: Vector3, radius: float) -> void:
	var n := 20
	for i in n:
		var a := TAU * i / n
		var p := at + Vector3(cos(a), 0.02, sin(a)) * radius
		deco("holiday:trainset-rail-detailed-straight", p, rad_to_deg(-a), 2.2)
	var front := at + Vector3(radius, 0.02, 0)
	deco("holiday:train-locomotive", front + Vector3(0, 0, -0.8), 90.0, 2.2)
	deco("holiday:train-wagon", front + Vector3(0, 0, 0.8), 90.0, 2.2)


# --- The plateau at the foot of the peak --------------------------------------

func _plateau() -> void:
	land(-16, -46, 16, -14, 2, 5, "snow")
	add_checkpoint(Vector3(-3, 2, -16), Vector3.FORWARD)
	add_boss_door(Vector3(-8, 2, -19))
	add_course_door("giftstack", Vector3(8, 2, -19))
	add_sign("The Big Chill waits through this door. Find five stars to open it.", Vector3(-11, 2, -17), Vector3(0.4, 0, 1).normalized())
	# Grumpy penguins waddle about, and a snowman rolls snowballs across.
	add(Critter.make("animal-penguin", Vector3(6, 0, 0), 4.0), Vector3(-14, 2, -44))
	add(Critter.make("animal-penguin", Vector3(0, 0, -8), 3.5, 0.5), Vector3(13, 2, -24))
	add(FrostyThrower.snowman(Vector3.LEFT, 2.6, 0.0), Vector3(15, 2, -20.5))
	add_sign("Snowmen roll snowballs. Jump over them!", Vector3(12, 2, -16), Vector3(0, 0, 1))
	coin_line(Vector3(-12, 2, -24), Vector3(-12, 2, -40), 5)
	coin_line(Vector3(12.5, 2, -27), Vector3(12.5, 2, -43), 5)
	add_heart(Vector3(-14, 2, -16))


# --- Frosty Peak -------------------------------------------------------------

func _peak() -> void:
	# Three tiers: a jump up the first, the icy second needs a high jump,
	# and so does the third.
	land(-10, -42, 10, -22, 3.5, 2, "snow")
	land(-7, -39, 7, -25, 5.5, 2, "snow")
	FrostyBuild.ice(self, -7, -39, 7, -25, 6.0, 0.5)
	land(-4, -36, 4, -28, 8.5, 2, "snow")
	add_sign("Crouch, then jump: a high jump reaches tall ledges.", Vector3(-2.5, 3.5, -23.2))
	add_checkpoint(Vector3(3, 3.5, -23.5), Vector3.FORWARD)
	# Then three snowy ledges spiral up to the summit.
	ledge(2, -30, 4, -28, 10.0, "snow")
	ledge(2, -34, 4, -32, 11.5, "snow")
	land(-1, -33, 1, -31, 13.0, 5, "snow")
	add_star("frosty/peak", Vector3(0, 13.2, -32))
	coin_line(Vector3(-5.5, 6.1, -26.5), Vector3(5.5, 6.1, -26.5), 6)
	coin_line(Vector3(3, 10.1, -29), Vector3(3, 11.6, -33), 3)
	add_heart(Vector3(-8.5, 3.5, -24))
	for at in [Vector3(-8.5, 3.5, -36), Vector3(8.5, 3.5, -30), Vector3(5.5, 6.0, -37.5)]:
		tree(at, "tree-pine-snow")
	# A wider view while climbing.
	camera_zone(Vector3(-11, 3.0, -43), Vector3(11, 20, -21.2), 0.0, 30.0, 12.0, true, 1)


# --- The frozen pond ---------------------------------------------------------

func _pond() -> void:
	# A rim of snow round a sheet of ice.
	land(14, -12, 38, -8, 0, 3, "snow")
	land(14, 8, 38, 14, 0, 3, "snow")
	land(14, -8, 18, 8, 0, 3, "snow")
	land(34, -8, 38, 8, 0, 3, "snow")
	land(18, -8, 34, 8, -0.5, 3, "snow")
	FrostyBuild.ice(self, 18, -8, 34, 8, 0.0, 0.5)
	add_checkpoint(Vector3(16, 0, 10), Vector3.RIGHT)
	add_sign("Ice is slippery! Let go early to stop, and jump from it to keep your speed.", Vector3(15.5, 0, 6.5), Vector3.RIGHT)
	add_course_door("icerink", Vector3(26, 0, -10.6))
	# Waddles and her chick Pingo, who won't come in off the ice.
	waddles = Islander.make("animal-penguin", "Waddles", [], 0.42)
	waddles.facing = Vector3.RIGHT
	waddles.on_talk = _talk_waddles
	add(waddles, Vector3(15.6, 0, 1.5))
	pingo = FrostyPingo.new()
	pingo.bounds = AABB(Vector3(POND.position.x + 0.6, 0, POND.position.y + 0.6), Vector3(POND.size.x - 1.2, 1, POND.size.y - 1.2))
	pingo.home = Vector3(15.9, 0, 2.6)
	pingo.caught.connect(_on_pingo_caught)
	add(pingo, Vector3(28, 0, -2))
	if found_stars.has("frosty/pingo"):
		pingo.place_home()
	# Ice floes out past the pond: don't stop on the first, it's slippery.
	FrostyBuild.ice(self, 41, -2, 44, 1, 0.0, 0.6)
	ledge(47, -2, 50, 1, 0.0, "snow")
	add_gem("frosty/gem_floe", Vector3(48.8, 0.2, -0.5))
	coin_line(Vector3(39, 0.5, -0.5), Vector3(46, 0.5, -0.5), 4)
	add_heart(Vector3(36.5, 0, -10.5))
	add_skyway_gate("pirate", Vector3(36.4, 0, 11), Vector3.LEFT)
	coin_ring(Vector3(26, 0, 0), 4.5, 12)


func _talk_waddles() -> void:
	if pingo.is_home:
		speak("Waddles", ["Pingo's tucked up and warm. Thank you!"])
	else:
		speak("Waddles", [
			"My little Pingo won't come in off the ice, and it's nearly supper time.",
			"He's quick on the ice, but he gets puffed out. Could you catch him for me?",
		])


func _on_pingo_caught() -> void:
	waddles.cheer()
	speak("Waddles", ["Got you, you little scamp! Thank you. Here, he was hiding this under his wing."], _give_pingo_star)


func _give_pingo_star() -> void:
	add_star("frosty/pingo", waddles.position + Vector3(1.2, 0.4, -1.0))


# --- The pine woods, and the cliff with the ice curtain ----------------------

func _woods() -> void:
	land(-38, -14, -14, 14, -1, 3, "snow")
	# Up from the woods to the village.
	ramp(Vector3(-15, -1, 4), Vector3.RIGHT, "snow")
	ramp(Vector3(-15, -1, 6), Vector3.RIGHT, "snow")
	add_checkpoint(Vector3(-17, -1, 8), Vector3.LEFT)
	add_course_door("toytrain", Vector3(-26, -1, -12.6))
	# A toy train set by the door.
	for i in 6:
		deco("holiday:trainset-rail-detailed-straight", Vector3(-31 + i * 1.1, -0.98, -9), 0.0, 2.2)
	deco("holiday:train-locomotive", Vector3(-29.5, -0.98, -9), 0.0, 2.2)
	deco("holiday:train-wagon-logs", Vector3(-27.6, -0.98, -9), 0.0, 2.2)
	# Polar bear cubs on patrol, and a snowman by the path.
	add(Critter.make("animal-polar", Vector3(0, 0, 6), 4.0, 0.0, 0.3), Vector3(-22, -1, -6))
	add(Critter.make("animal-polar", Vector3(5, 0, 0), 4.5, 0.4, 0.3), Vector3(-30, -1, 6.5))
	add(FrostyThrower.snowman(Vector3.BACK, 3.0, 0.3), Vector3(-30, -1, -13))
	# A present tied too tight: only a ground pound opens it.
	var tight := Breakable.make("holiday:present-a-cube", "gem:frosty/gem_present")
	tight.strong = true
	add(tight, Vector3(-35, -1, 11))
	add_sign("A present tied too tight? Crouch in the air to ground pound it.", Vector3(-32, -1, 12.5), Vector3.BACK)
	add_heart(Vector3(-36, -1, -12))
	coin_line(Vector3(-18, -0.9, 0), Vector3(-34, -0.9, 0), 6)
	# The cliff at the far end, with a hollow behind a curtain of thin ice.
	land(-46, -14, -38, -2, 3, 7, "snow")
	land(-46, 2, -38, 8, 3, 7, "snow")
	land(-46, -2, -42, 2, 3, 7, "snow")
	land(-42, -2, -38, 2, 3, 2, "snow")
	land(-42, -2, -38, 2, -1, 3, "snow")
	var curtain := FrostyIceCurtain.new()
	curtain.size = Vector3(4, 2, 0.3)
	curtain.turn = 90.0
	add(curtain, Vector3(-38.2, -1, 0))
	add_star("frosty/curtain", Vector3(-40.5, -0.8, 0))
	add_sign("Brr. Even the cliff has frozen over. Or has it?", Vector3(-36, -1, 3), Vector3.RIGHT)
	camera_zone(Vector3(-42, -2, -2), Vector3(-37.6, 1, 2), 270.0, 14.0, 5.5, false, 2)


# --- The Skyway landing, to the south ----------------------------------------

func _landing() -> void:
	land(-6, 16, 6, 26, 0, 3, "snow")
	add_skyway_gate("sunny", Vector3(0, 0, 24.4), Vector3.FORWARD)
	coin_line(Vector3(0, 0.4, 21), Vector3(0, 0.4, 16.5), 4)


# --- Silver Rush -------------------------------------------------------------

const SILVER_SPOTS := [
	Vector3(-11, 0, 13), Vector3(11, 0, -1), Vector3(26, 0, 4), Vector3(31, 0, -6),
	Vector3(36, 0, -10), Vector3(-20, -1, 11), Vector3(-30, -1, -4), Vector3(-10, 2, -21),
]


# --- Scenery -----------------------------------------------------------------

func _scenery() -> void:
	for at in [Vector3(-12.5, 0, 4.5), Vector3(12.5, 0, 13), Vector3(-12.5, 0, 14), Vector3(5, 0, -6.5), Vector3(-14, 2, -30), Vector3(14, 2, -38), Vector3(15, 2, -45), Vector3(-15, 2, -45), Vector3(37, 0, 13), Vector3(37, 0, -8.5)]:
		tree(at, "tree-pine-snow")
	for at in [Vector3(-18, -1, -10), Vector3(-21, -1, 2), Vector3(-25, -1, 9), Vector3(-28, -1, -2), Vector3(-33, -1, -7), Vector3(-36, -1, 6), Vector3(-24, -1, -12.5), Vector3(-31, -1, 12.5), Vector3(-19, -1, 12.5)]:
		tree(at, ["holiday:tree-snow-a", "holiday:tree-snow-b", "holiday:tree-snow-c"][int(absf(at.x + at.z)) % 3], 1.5)
	for at in [Vector3(-2.5, 0, 8), Vector3(7.5, 0, 9.5), Vector3(-9, 0, 6), Vector3(9, 0, -5), Vector3(4, 0, -12)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for at in [Vector3(-3, 0, 14.5), Vector3(3, 0, 14.5)]:
		deco("holiday:bench", at, 180.0, 1.6)
	deco("holiday:snowman-hat", Vector3(10.5, 0, 12.5), -30.0, 1.4)
	deco("holiday:snowman", Vector3(16.5, 0, -10), 160.0, 1.3)
	deco("holiday:reindeer", Vector3(7.8, 0, 4.6), 200.0, 1.6)
	deco("holiday:nutcracker", Vector3(-5.6, 0, -12.2), 0.0, 1.5)
	deco("holiday:nutcracker", Vector3(-4.4 + 1.0, 0, -12.2), 0.0, 1.5)
	for at in [Vector3(-1.5, 0, 6.5), Vector3(1.8, 0, 5.8), Vector3(-6, 0, 1.5), Vector3(8, 0, -6.5), Vector3(-10, 2, -16), Vector3(20, 0, 11), Vector3(-26, -1, 4), Vector3(-36, -1, -2)]:
		var kind := int(absf(at.x * 3.0 + at.z)) % 4
		deco("holiday:" + FrostyBuild.PRESENTS[kind], at, at.x * 25.0, 1.6)
	for at in [Vector3(-8, 0, 15), Vector3(8, 0, 15.2), Vector3(-13, 0, -13), Vector3(22, 0, 12.5), Vector3(-37, -1, 13), Vector3(14.5, 2, -31)]:
		deco("holiday:rocks-medium", at, at.z * 40.0, 1.0)
	for at in [Vector3(-7, 0, 13), Vector3(6, 0, -2.5), Vector3(-4, 2, -17), Vector3(30, 0, 11), Vector3(-20, -1, -2), Vector3(-30, -1, 8)]:
		deco("holiday:snow-pile", at, at.x * 17.0, 1.6)
	for at in [Vector3(-1.6, 0, 15.6), Vector3(1.6, 0, 15.6), Vector3(-1.6, 2, -14.3), Vector3(1.6, 2, -14.3)]:
		deco("holiday:candy-cane-red", at, 0.0, 2.5)
	for x in range(-13, 14, 1):
		if absi(x) > 1:
			deco("holiday:cabin-fence", Vector3(x + 1.0, 0, 15.6), 0.0, 1.0)
