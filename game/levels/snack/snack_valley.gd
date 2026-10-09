class_name SnackValley
extends Island
## Snack Valley's island, for Adventure: a frosting meadow (with Coco's
## sundae and the plaza where a donut rolls about), the terrace to the north
## with the chocolate falls and the Hungry Hog's pen, the Wedding Cake to
## the north-east, the kitchen counter to the east, the soda lake and
## Cookie Isle to the west, and the picnic landing to the south with the
## Skyway gates.
##
## Stars: the four courses, Coco's cherries, the sprinkle rush, the top of
## the Wedding Cake, a star behind the chocolate falls, and the runaway
## donut. Two hidden gems, plus one in each course.

const RUSH_TIME := 40.0
const RUNAWAY_AREA := Rect2(-10.2, -7.2, 8.4, 9.4)

var coco: Islander
var cherries: Array[SnackCherry] = []
var cherries_home := 0
var sundae_top := Vector3(8, 4.5, 4)
var donut: SnackDonut
var rush: SilverRush


func _init() -> void:
	super()
	title = "Snack Valley"
	spawn = Vector3(0, 0, 10)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_meadow()
	_plaza()
	_terrace()
	_wedding_cake()
	_kitchen()
	_soda_lake()
	_landing()
	_scenery()
	finish()


## Views for the screenshot tool.
func shots() -> Array:
	return [
		{"name": "cake", "at": Vector3(16, 0, -10.5), "face": Vector3.FORWARD},
		{"name": "lake", "at": Vector3(-11, 0, 4), "face": Vector3.LEFT},
		{"name": "kitchen", "at": Vector3(16, 1, 6), "face": Vector3.RIGHT},
	]


# --- The frosting meadow (where the hero lands) ------------------------------

func _meadow() -> void:
	land(-12, -10, 14, 14, 0, 3)
	add_checkpoint(Vector3(-2, 0, 12), Vector3.FORWARD)
	# A bouncy pudding by the cliff: the quick way up to the terrace.
	add(SnackPudding.make(), Vector3(3, 0, -8.6))
	add_sign("Bouncy puddings throw you up high. Just run onto one.", Vector3(5.5, 0, -7.5))
	coin_line(Vector3(3, 0.2, -2), Vector3(3, 0.2, -6.5), 4)
	# Coco's sundae, waiting for its three cherries.
	sundae_top = Vector3(8, SnackFood.solid(self, "food:sundae", Vector3(8, 0, 4), 7.0) - 0.15, 4)
	coco = Islander.make("animal-monkey", "Coco", [], 0.42)
	coco.facing = Vector3(-0.6, 0, 1).normalized()
	coco.on_talk = _talk_coco
	add(coco, Vector3(6.2, 0, 5.8))
	var stack := 0.0
	for i in 3:
		stack = SnackFood.solid(self, "food:donut-chocolate" if i == 1 else "food:donut", Vector3(12, stack, -4.5), 9.0, i * 40.0)
	var cookie_top := SnackFood.solid(self, "food:cookie-chocolate", Vector3(-35, 0.5, 3.5), 14.0)
	var spots := [Vector3(-35, cookie_top, 3.5), Vector3(12, stack, -4.5), Vector3(27.5, 4.5, -6.5)]
	for i in 3:
		var c := SnackCherry.new()
		c.home = sundae_top + Vector3(-0.35 + i * 0.35, 0, 0.15 * (i - 1))
		if found_stars.has("snack/cherries"):
			c.position = c.home
			c.is_home = true
		else:
			c.position = spots[i]
		c.level = self
		add_child(c)
		c.found.connect(_on_cherry_home)
		cherries.append(c)
	if found_stars.has("snack/cherries"):
		cherries_home = 3
	coin_ring(Vector3(8, 0, 4), 2.6, 8)
	# The sprinkle rush: step on the button, then find eight silver coins.
	rush = add_silver_rush("snack/sprinkles", Vector3(-6, 0, 10.5), RUSH_SPOTS, RUSH_TIME)
	add_sign("Step on the button, then find eight silver coins before time runs out.", Vector3(-8, 0, 12))
	# Bees.
	var bee := Critter.make("animal-bee", Vector3(6, 0, 0), 5.0)
	bee.bob = 0.3
	add(bee, Vector3(2, 0, 1))
	bee = Critter.make("animal-bee", Vector3(0, 0, -5), 4.0, 0.5)
	bee.bob = 0.3
	add(bee, Vector3(12, 0, 10))
	add_heart(Vector3(12.5, 0, 12.5))
	# Clover the cow knows the valley.
	var clover := add_islander("animal-cow", "Clover", [
		"Moo. That chocolate waterfall is lovely, isn't it? I always wonder what's behind it.",
		"The fizzy geysers out on the soda lake will lift anyone up. Mind you don't fall in!",
		"The Hungry Hog ate every cake in the valley but the Wedding Cake. Find five stars and his door opens.",
	], Vector3(1, 0, 4.5), Vector3(0.3, 0, 1).normalized(), 0.4)
	clover.name = "Clover"


func _talk_coco() -> void:
	if cherries_home >= 3:
		speak("Coco", ["Three cherries on top. The finest sundae in the valley! Thank you!"])
	elif cherries_home == 0:
		speak("Coco", [
			"My sundae! It needs three cherries on top, but they all rolled away.",
			"One rolled over the soda lake to Cookie Isle, one is up on the donut stack, and one is on the kitchen's high shelf.",
			"Touch them and they'll hop right back. Please?",
		])
	else:
		speak("Coco", ["%d of 3 cherries back. Keep looking!" % cherries_home])


func _on_cherry_home(_c: SnackCherry) -> void:
	cherries_home += 1
	if cherries_home < 3:
		say("%d of 3 cherries back" % cherries_home)
		return
	coco.cheer()
	speak("Coco", ["Perfect! And look, there was a star at the bottom of the glass."], _give_cherry_star)


func _give_cherry_star() -> void:
	add_star("snack/cherries", coco.position + Vector3(-1.2, 0.4, 1.0))


# --- The sprinkle plaza: the runaway donut -----------------------------------

func _plaza() -> void:
	land(-11, -8, -1, 3, 0.3, 1, "snow")
	for at in [Vector3(-10.6, 0.3, -7.6), Vector3(-1.4, 0.3, -7.6), Vector3(-10.6, 0.3, 2.6), Vector3(-1.4, 0.3, 2.6)]:
		SnackFood.stick(self, "food:lollypop", at, 7.0, 90.0)
	var sprinkles := add_islander("animal-bunny", "Sprinkles", [
		"My donut rolled off the table and it just won't stop! Round and round the plaza all morning.",
		"It always rolls away from you, but it isn't as fast as a run. Corner it, or Dive at it!",
	], Vector3(-0.2, 0, 4.2), Vector3(-0.5, 0, 1).normalized(), 0.38)
	sprinkles.name = "Sprinkles"
	if found_stars.has("snack/runaway"):
		add_star("snack/runaway", Vector3(-6, 1.3, -2.5))
		return
	donut = SnackDonut.new()
	donut.area = RUNAWAY_AREA
	add(donut, Vector3(-6, 0.3, -2.5))
	donut.caught.connect(_on_donut_caught)


func _on_donut_caught(d: SnackDonut) -> void:
	say("Caught it! Something was inside...")
	add_star("snack/runaway", d.position + Vector3.UP * 0.3)


# --- The terrace: the chocolate falls and the Hog's pen ----------------------

func _terrace() -> void:
	land(-14, -26, 10, -12, 3, 6)
	land(-14, -12, -6, -10, 3, 6)
	land(-2, -12, 10, -10, 3, 6)
	# Behind the falls, a hollow under an overhang.
	land(-6, -12, -2, -10, 3, 1)
	land(-6, -12, -2, -10, 0, 3)
	var falls := SnackFalls.new()
	falls.width = 4.0
	falls.height = 3.0
	add(falls, Vector3(-4, 0, -9.95))
	SnackFood.solid(self, "food:pot", Vector3(-4, 3, -17.5), 4.5)
	SnackFalls.stream(self, Vector3(-4, 3, -15.4), Vector3(-4, 3, -9.95), 2.6)
	add_star("snack/falls", Vector3(-4, 0.25, -11.2))
	camera_zone(Vector3(-7, -0.5, -13), Vector3(-1, 2, -10.4), 0.0, 18.0, 6.5, false, 2)
	# The walk up: two slopes and two steps of cream.
	ramp(Vector3(9, 0, -1), Vector3.FORWARD, "snow")
	land(8, -4, 10, -2, 1.0, 1, "snow")
	ramp(Vector3(9, 1, -5), Vector3.FORWARD, "snow")
	land(8, -8, 10, -6, 2.0, 2, "snow")
	ramp(Vector3(9, 2, -9), Vector3.FORWARD, "snow")
	add_checkpoint(Vector3(-10, 3, -14), Vector3.BACK)
	coin_line(Vector3(-10, 3.1, -18), Vector3(-10, 3.1, -24), 4)
	# The Hungry Hog's pen.
	add_boss_door(Vector3(-4, 3, -23.5), Vector3.BACK)
	add_sign("The Hungry Hog's pen. He ate every cake in the valley but one!", Vector3(-7.5, 3, -21), Vector3.BACK)
	for x in range(-9, 2):
		deco("fence-low-straight", Vector3(x + 0.5, 3, -25.3), 180.0)
	SnackFood.solid(self, "food:pan-stew", Vector3(0, 3, -21.5), 4.0, 20.0, false)
	SnackFood.prop(self, "food:apple-half", Vector3(-9.5, 3, -24), 6.0, 30.0)
	var bee := Critter.make("animal-bee", Vector3(0, 0, 5), 4.5)
	bee.bob = 0.3
	add(bee, Vector3(-11, 3, -20))


# --- The Wedding Cake, to the north-east -------------------------------------

func _wedding_cake() -> void:
	land(10, -30, 30, -10, 0, 3)
	# Three tiers of cream: a tall step, then wafers, then wall kicks.
	land(12, -28, 28, -14, 2.5, 4, "snow")
	land(16, -28, 24, -22, 7.0, 5, "snow")
	land(16, -27, 22, -23, 11.5, 5, "snow")
	# The candle beside the top tier, taller than it: kick between them.
	land(23, -26, 24, -24, 13.5, 7)
	SnackFood.prop(self, "food:strawberry", Vector3(23.5, 13.5, -25), 4.0)
	for at in [Vector3(16.6, 11.5, -26.4), Vector3(16.6, 11.5, -23.6), Vector3(21.4, 11.5, -26.4), Vector3(21.4, 11.5, -23.6)]:
		SnackFood.prop(self, "food:strawberry", at, 3.0, at.x * 40.0)
	add_star("snack/cake_top", Vector3(19.5, 11.7, -25.0))
	add(SnackRaft.wafer("food:waffle", 6.0), Vector3(23, 4.0, -17.2))
	add(SnackRaft.wafer("food:waffle", 6.0), Vector3(23, 5.5, -20.2))
	add_course_door("cake_climb", Vector3(16, 0, -12), Vector3.BACK)
	add_sign("Too tall? Crouch, then jump. Wafers drop when you stand on them: keep moving!", Vector3(11.5, 0, -12.5))
	coin_line(Vector3(13, 2.6, -16), Vector3(17.5, 2.6, -16), 3)
	coin_line(Vector3(22.5, 7.5, -25), Vector3(22.5, 10.5, -25), 3)
	add_heart(Vector3(26.5, 2.5, -26.5))
	# A bowl of fruit at the cake's foot.
	SnackFood.solid(self, "food:watermelon", Vector3(27, 0, -12), 4.0)
	SnackFood.solid(self, "food:pumpkin", Vector3(29, 0, -21), 4.5, 30.0)
	camera_zone(Vector3(10, 2.3, -30), Vector3(30, 16, -14), 0.0, 24.0, 13.0, false, 1)


# --- The kitchen counter, to the east ----------------------------------------

func _kitchen() -> void:
	land(14, -10, 30, 12, 1.0, 4, "snow")
	ramp(Vector3(13, 0, 8), Vector3.RIGHT, "snow")
	ramp(Vector3(20, 0, -11), Vector3.BACK, "snow")
	add_checkpoint(Vector3(16, 1, 9.5), Vector3.RIGHT)
	add_course_door("kitchen_dash", Vector3(24.5, 1, 6.5), Vector3.LEFT)
	# Fruit rolls off the stove and across the counter.
	add(SnackRoller.make("food:orange", Vector3(-11, 0, 0), 4.0, 1.1), Vector3(26.3, 1, 0.5))
	add(SnackRoller.make("food:apple", Vector3(-11, 0, 0), 4.5, 1.1, 0.5), Vector3(26.3, 1, -3.5))
	add_sign("Giant fruit rolls off the stove. Jump over it, or wait for a gap.", Vector3(16, 1, 3.5))
	# The stove along the back.
	SnackFood.solid(self, "food:pot-stew", Vector3(28.4, 1, 0.5), 3.6, 90.0, false)
	SnackFood.solid(self, "food:pot", Vector3(28.4, 1, -3.5), 3.6, 90.0, false)
	SnackFood.solid(self, "food:knife-block", Vector3(28.8, 1, 4), 4.0, -90.0, false)
	# The high shelf (a cherry is up there) and the pudding that reaches it.
	ledge(25, -9, 30, -5, 4.5, "snow")
	add(SnackPudding.make(), Vector3(23.2, 1, -7))
	SnackFood.prop(self, "food:honey", Vector3(29, 4.5, -8), 3.5)
	SnackFood.prop(self, "food:peanut-butter", Vector3(26, 4.5, -8.2), 3.5)
	# The pantry crate behind the pizza boxes: only a pound opens it.
	var box_top := SnackFood.solid(self, "food:pizza-box", Vector3(27.5, 1, 10.2), 3.0, 0.0, false)
	SnackFood.solid(self, "food:pizza-box", Vector3(27.5, box_top, 10.2), 3.0, 10.0, false)
	add(Breakable.make("crate-strong", "gem:snack/gem_pantry"), Vector3(29, 1, 7.4))
	var pepper := add_islander("animal-cat", "Pepper", [
		"Welcome to my kitchen! Mind the fruit, it's been rolling off the stove all day.",
		"My pantry crate is stuck shut. Only a good ground pound would open it: Crouch while in the air.",
		"The belts in Kitchen Dash run fast. Ride them the way they go!",
	], Vector3(18.5, 1, 7.5), Vector3(-1, 0, 0.3).normalized(), 0.4)
	pepper.name = "Pepper"
	var bee := Critter.make("animal-bee", Vector3(0, 0, -6), 4.0)
	bee.bob = 0.35
	add(bee, Vector3(21.5, 1, -2))
	coin_line(Vector3(17, 1.1, -7), Vector3(22, 1.1, -7), 4)
	add_heart(Vector3(15, 1, -8.5))


# --- The soda lake and Cookie Isle, to the west ------------------------------

func _soda_lake() -> void:
	land(-38, -13, -12, 14, -2.6, 1, "snow")
	water(-38, -13, -12, 14, -0.5, Color(1.0, 0.55, 0.16, 0.8))
	add_sign("Soda is far too fizzy to swim in. Hop across on the donuts, and don't wait about on cookies!", Vector3(-11, 0, 6.5), Vector3.RIGHT)
	# The stepping stones: donuts bob, the cookie sinks.
	add(SnackRaft.make("food:donut-sprinkles", 12.0, 0.1), Vector3(-15, 0, 4))
	add(SnackRaft.make("food:donut", 12.0, 0.1), Vector3(-18.5, 0, 4))
	var cookie := SnackRaft.make("food:cookie", 13.0)
	cookie.sinks = 0.45
	add(cookie, Vector3(-22, 0, 4))
	add(SnackRaft.make("food:donut-chocolate", 12.0, 0.1), Vector3(-25.5, 0, 4))
	# A donut off to the north, and a fizzy geyser by a cream cloud.
	add(SnackRaft.make("food:donut-sprinkles", 11.0, 0.1), Vector3(-19, 0, 0.6))
	var fizz := WindZone.make(Vector3(2.4, 8.5, 2.4), Vector3.UP * 52.0)
	add(fizz, Vector3(-19.5, -0.5, -3.4))
	_fizz_column(Vector3(-19.5, -0.5, -3.4), 8.5)
	ledge(-22, -7, -17, -4.5, 6.0, "snow")
	add_gem("snack/gem_fizz", Vector3(-19.5, 6.2, -6))
	SnackFood.prop(self, "food:whipped-cream", Vector3(-21.2, 6.0, -6), 6.0)
	# Cookie Isle.
	land(-38, -6, -28, 6, 0.5, 3, "snow")
	add_checkpoint(Vector3(-29.5, 0.5, 1), Vector3.LEFT)
	add_course_door("fizzy_crossing", Vector3(-33, 0.5, -3.5), Vector3.RIGHT)
	SnackFood.solid(self, "food:soda-can", Vector3(-36.5, 0.5, -1), 7.0)
	SnackFood.stick(self, "food:soda-bottle", Vector3(-36.5, 0.5, -4.5), 6.0, 0.0, 1.0)
	SnackFood.prop(self, "food:soda-can-crushed", Vector3(-30, 0.5, 4.8), 5.0, 30.0)
	coin_line(Vector3(-15, 0.4, 4), Vector3(-25.5, 0.4, 4), 4)


## A see-through column of fizz over the geyser.
func _fizz_column(at: Vector3, height: float) -> void:
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.95
	cyl.bottom_radius = 1.2
	cyl.height = height
	m.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.4, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = at + Vector3.UP * height / 2.0
	add_child(m)


# --- The picnic landing and the Skyway, to the south -------------------------

func _landing() -> void:
	land(-8, 14, 12, 22, 0, 3, "snow")
	add_course_door("donut_hop", Vector3(2, 0, 20.5), Vector3.FORWARD)
	add_skyway_gates(Vector3(-5, 0, 20.5), Vector3.FORWARD, Vector3(9, 0, 20.5), Vector3.FORWARD)
	SnackFood.solid(self, "food:pie", Vector3(-4.5, 0, 16.5), 3.0)
	SnackFood.prop(self, "food:cup-tea", Vector3(-6.8, 0, 15.5), 5.0, 120.0)
	SnackFood.prop(self, "food:plate", Vector3(7, 0, 16.5), 3.2)
	SnackFood.prop(self, "food:croissant", Vector3(7, 0.25, 16.5), 4.5, 40.0)
	coin_line(Vector3(-2, 0.1, 17), Vector3(6, 0.1, 17), 5)


# --- The sprinkle rush -------------------------------------------------------

const RUSH_SPOTS := [
	Vector3(-10, 0, 13), Vector3(12.5, 0, 9), Vector3(-12, 3, -16), Vector3(4, 3, -24),
	Vector3(17, 1, -4.5), Vector3(22, 1, 11), Vector3(11, 0, -22), Vector3(10, 0, 20),
]


# --- Scenery -----------------------------------------------------------------

func _scenery() -> void:
	for at in [Vector3(-11, 0, -9), Vector3(-11, 0, 8), Vector3(13, 0, 2), Vector3(0.5, 0, -9.2), Vector3(-13, 3, -25), Vector3(8, 3, -25), Vector3(29, 0, -29), Vector3(-37, 0.5, 5.3)]:
		SnackFood.stick(self, "food:lollypop", at, 6.0, fmod(at.x * 37.0, 360.0))
	for at in [Vector3(-9, 0, 5.5), Vector3(4.5, 0, 13), Vector3(-12, 3, -12.8)]:
		SnackFood.solid(self, "food:cupcake", at, 4.0, fmod(at.z * 50.0, 360.0))
	for at in [Vector3(12.8, 0, -8.8), Vector3(-7.5, 0, 13.2), Vector3(11, 0, 15.5)]:
		SnackFood.stick(self, "food:popsicle", at, 5.0, fmod(at.x * 23.0, 360.0), 0.4)
	for at in [Vector3(-3.5, 0, 7), Vector3(6, 0, -2), Vector3(-9, 3, -16), Vector3(4, 3, -14), Vector3(26, 0, -16), Vector3(-6, 0, 18)]:
		deco("grass", at, fmod(at.z * 33.0, 360.0), 1.4)
	SnackFood.prop(self, "food:candy-bar", Vector3(-0.5, 0, 12.8), 7.0, 15.0)
	SnackFood.prop(self, "food:chocolate", Vector3(10.5, 0, 8.5), 7.0, -30.0)
	SnackFood.prop(self, "food:ice-cream", Vector3(-12.8, 3, -21), 6.0)
