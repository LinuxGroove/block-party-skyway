class_name LayerCakeClimb
extends Level
## Course 1 of Snack Valley: up a giant layer cake. A pudding throws you
## onto the first tier, fruit rolls across it, falling wafers climb to the
## second tier, which turns west past a sweeping cooking fork; a pancake
## lift rises to the third tier, more fruit rolls by, and a double jump
## reaches the topper and the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge below the first tier's
## east side (with a pudding back up) and checkpoints. Speedrun: just the
## course and the clock.

const STAR := "snack/cake_climb"
const GEM := "snack/gem_cake_climb"

var fork: SnackSkewer
var lift: SnackRaft
var glider: SnackRaft


func _init() -> void:
	super()
	title = "Layer Cake Climb"
	spawn = Vector3(0, 0, 18.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The start, and donuts out to the plate at the bottom of the cake.
	land(-3, 15, 3, 21, 0, 3, "snow")
	add_sign("Climb the cake! Hop the donuts, then run onto the pudding to bounce up.", Vector3(-2, 0, 19.5))
	add(SnackRaft.make("food:donut-sprinkles", 12.0), Vector3(0, 0, 12))
	glider = add(SnackRaft.glide("food:donut", 12.0, Vector3(5, 0, 0), 3.2), Vector3(-2.5, 0.4, 8)) as SnackRaft
	add_coin(Vector3(0, 1.2, 13.8))
	add_coin(Vector3(0, 1.4, 10))
	add_coin(Vector3(0, 1.4, 5.5))
	land(-3, -6, 3, 4, 0, 3, "snow")
	SnackFood.prop(self, "food:plate", Vector3(0, -0.75, -1), 10.0)
	add(SnackPudding.make(), Vector3(0, 0, -2.5))
	add_coin(Vector3(0, 2.5, -4.5))
	add_coin(Vector3(0, 4.5, -6))

	# Tier one: fruit rolls across.
	land(-5, -28, 5, -6, 4.0, 6, "snow")
	add_checkpoint(Vector3(-3, 4.0, -7.5), Vector3.FORWARD)
	add(SnackRoller.make("food:orange", Vector3(-9, 0, 0), 4.5, 1.1), Vector3(4.5, 4.0, -11))
	add(SnackRoller.make("food:orange", Vector3(-9, 0, 0), 4.5, 1.1, 0.5), Vector3(4.5, 4.0, -11))
	for z in [-9.0, -11.0, -13.0]:
		add_coin(Vector3(0, 5.2, z))
	SnackFood.prop(self, "food:strawberry", Vector3(-4, 4.0, -9), 4.5, 30.0)
	if not is_speedrun():
		# Off the racing line: a ledge below the east side.
		land(5, -15, 9, -10, 1.5, 2, "snow")
		add_gem(GEM, Vector3(8, 1.7, -14))
		add_heart(Vector3(8, 1.5, -11.2))
		add(SnackPudding.make(), Vector3(6.3, 1.5, -11.5))

	# Wafers up to tier two: each drops a moment after you land.
	add(SnackRaft.wafer("food:waffle", 6.0), Vector3(0, 5.2, -16))
	add(SnackRaft.wafer("food:waffle", 6.0), Vector3(0, 6.4, -19))
	add_sign("Wafers drop when you land on them. Keep moving!", Vector3(-3, 4.0, -14), Vector3.BACK)

	# Tier two runs west, past a sweeping fork.
	land(-13, -28, 4, -22, 7.6, 4)
	add_checkpoint(Vector3(2.5, 7.6, -23.5), Vector3.LEFT)
	fork = SnackSkewer.make(3.6, 75.0)
	fork.phase = 57.0
	add(fork, Vector3(-6, 7.6, -25))
	camera_zone(Vector3(-14, 6.5, -29), Vector3(5, 13, -21.5), 90.0, 30.0, 10.0)
	for x in [-1.0, -3.5, -8.5, -11.0]:
		add_coin(Vector3(x, 7.7, -25.7))
	add_heart(Vector3(3, 7.6, -27))

	# The pancake lift up to tier three.
	lift = add(SnackRaft.glide("food:pancakes", 7.0, Vector3(0, 3.4, 0), 4.6, 0.89, 0.8), Vector3(-10, 7.6, -29.75)) as SnackRaft
	camera_zone(Vector3(-14, 6.5, -48), Vector3(-5, 18, -28.2), 0.0, 30.0, 10.0, false, 1)

	# Tier three: fruit again, then the topper.
	land(-14, -48, -6, -33, 11.0, 3, "snow")
	add_checkpoint(Vector3(-12.5, 11.0, -34.5), Vector3.FORWARD)
	add(SnackRoller.make("food:apple", Vector3(-8, 0, 0), 4.0, 1.1), Vector3(-6.2, 11.0, -37))
	add(SnackRoller.make("food:apple", Vector3(-8, 0, 0), 4.0, 1.1, 0.5), Vector3(-6.2, 11.0, -37))
	add(SnackRoller.make("food:orange", Vector3(8, 0, 0), 5.0, 1.1, 0.25), Vector3(-13.8, 11.0, -41.5))
	add(SnackRoller.make("food:orange", Vector3(8, 0, 0), 5.0, 1.1, 0.75), Vector3(-13.8, 11.0, -41.5))
	add_sign("Too high? Jump, then jump again in the air.", Vector3(-7.5, 11.0, -45.5), Vector3.BACK)
	for z in [-35.0, -39.0, -43.5]:
		add_coin(Vector3(-10, 11.6, z))

	# The topper and the flag.
	land(-13, -54, -7, -48, 13.5, 3)
	add_flag(Vector3(-10, 13.5, -51.5), Vector3.FORWARD)
	for x in [-12.4, -7.6]:
		SnackFood.prop(self, "food:strawberry", Vector3(x, 13.5, -53.4), 4.0, x * 30.0)
	_scenery()
	finish()


func _scenery() -> void:
	for at in [Vector3(-4, 7.6, -27), Vector3(-12, 7.6, -23), Vector3(-13, 11.0, -47)]:
		SnackFood.prop(self, "food:strawberry", at, 3.5, at.z * 20.0)
	for at in [Vector3(4.3, 4.0, -7), Vector3(-4.3, 4.0, -20), Vector3(-6.5, 11.0, -33.5)]:
		SnackFood.stick(self, "food:lollypop", at, 5.0, at.x * 30.0)
	for x in [-2.4, 2.4]:
		SnackFood.stick(self, "food:lollypop", Vector3(x, 0, 20.4), 4.0, x * 30.0)
