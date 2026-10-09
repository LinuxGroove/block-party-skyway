class_name SugarGears
extends StarCourse
## Star Road course 3, Snack Valley meets Gear Works: a candy press where
## crushers slam down on a belt that runs against you, a bridge of sugar
## cubes swept by spinning cogs over a lake of soda, pancakes and a waffle
## drifting across it, and two crushers that lift you up to a giant cake.

const STAR := "star/sugar_gears"
const GEM := "star/gem_sugar_gears"
## Where each press comes down on the belt.
const PRESS := [-10.0, -15.0, -20.0]
const BELT_SPEED := 2.5
## The cog spinners' posts beside the bridge.
const COGS := [Vector3(2.5, 0, -34.5), Vector3(-2.5, 0, -42.5), Vector3(2.5, 0, -50.5)]
## The two lifts: a crusher on the tower's landing, and one on its ledge.
const LIFTS := [Vector3(0, 0, -83.5), Vector3(0, 4.0, -88.8)]
const CAKE := Vector3(0, 7.0, -94.0)
const SODA := Color(1.0, 0.52, 0.16, 0.78)


func _init() -> void:
	super()
	title = "Sugar Gears"
	cloud_center = Vector3(0, 0, -50)
	cloud_spread = 70.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "A candy press, a lake of soda and two lifts. Run against the belt, and wait for each press to rise.")
	deco("food:lollypop", Vector3(-2.5, 0, -5.2), 90.0, 7.0)
	deco("food:lollypop", Vector3(2.5, 0, -5.2), 90.0, 7.0)
	deco("food:cupcake", Vector3(2.3, 0, 3.0), 30.0, 4.0)

	# The candy press: a belt running back at you, and three presses.
	land(-1, -24, 1, -6, -0.35, 2)
	add(Conveyor.make(18, Vector3.BACK, BELT_SPEED), Vector3(0, -0.35, -24))
	for i in PRESS.size():
		var z: float = PRESS[i]
		# They lift one after another, so a quick run can flow through.
		add(Crusher.make(3.0, Vector3(2, 1, 2), fposmod(-0.27 * i, 1.0)), Vector3(0, 0, z))
		for x in [-1.45, 1.45]:
			deco("factory:structure-yellow-tall", Vector3(x, -0.35, z), 0.0, 2.2)
		deco("factory:pipe-large-long", Vector3(0, 4.1, z), 0.0, 1.45)
		add_coin(Vector3(0, 0.6, z + 2.5))
	add_coin(Vector3(0, 0.6, -22.5))
	add_sign("The belt pushes you back. Wait for a press to rise, then dash under.", Vector3(-2.2, 0, -5.0))

	# A landing before the lake.
	land(-3, -30, 3, -24, 0, 3)
	add_checkpoint(Vector3(-2.0, 0, -25.4), Vector3.FORWARD)
	add_heart(Vector3(2.0, 0, -25.4))
	deco("factory:robot-arm-a", Vector3(-2.4, 0, -29.3), 45.0, 1.0)
	deco("factory:robot-arm-b", Vector3(2.4, 0, -29.3), -45.0, 1.0)

	# The soda lake: fall in and it's back to the flag.
	land(-9, -76, 9, -30, -2.0, 2)
	water(-9, -76, 9, -30, -0.9, SODA)
	_lake_scenery()

	# A bridge of sugar cubes, swept by cogs spinning on posts in the soda.
	land(-1, -55, 1, -30, 0, 2, "snow")
	for i in COGS.size():
		var at: Vector3 = COGS[i]
		land(floori(at.x), floori(at.z), floori(at.x) + 1, floori(at.z) + 1, 0, 2, "snow")
		# Each sweeps along the bridge the way you run, so you can chase an arm.
		var cog := Spinner.make(3, -120.0 if at.x > 0.0 else 120.0, "factory:cog-a", 2)
		cog.model_scale = 0.8
		cog.phase = 60.0 * i
		add(cog, at)
	for z in [-38.5, -46.5, -54.0]:
		add_coin(Vector3(0, 0.5, z))
	add_sign("Cogs! Wait between them, or jump each arm as it comes.", Vector3(-2.2, 0, -29.0))

	# An island in the middle, then sweets drifting across the soda.
	land(-3, -61, 3, -55, 0, 2)
	add_checkpoint(Vector3(-2.0, 0, -56.4), Vector3.FORWARD)
	deco("food:ice-cream", Vector3(2.4, 0, -60.2), 20.0, 4.0)
	add_sign("Ride the pancakes, then hop onto the waffle as it passes.", Vector3(2.2, 0, -56.0))
	# Pancakes out along the lake, then a waffle sliding across in step.
	add(StarFloat.make_float("food:pancakes", 5.2, 0.12, Vector3(0, 0, -6), 5.0), Vector3(0, 0, -63.5))
	add(StarFloat.make_float("food:waffle", 7.4, 0.04, Vector3(8, 0, 0), 5.0, 0.25), Vector3(-4, 0, -73.0))
	add_coin(Vector3(0, 1.2, -62.0))
	add_coin(Vector3(0, 1.2, -70.8))

	# The tower: ride a crusher up to the ledge, and another to the cake.
	land(-3, -85, 3, -76, 0, 3)
	add_checkpoint(Vector3(-2.0, 0, -77.2), Vector3.FORWARD)
	add_heart(Vector3(2.0, 0, -77.2))
	land(-3, -90, 3, -85, 4.0, 5)
	for at in LIFTS:
		var lift := Crusher.make(3.0, Vector3(2, 1, 2), 0.0, "block-moving-large")
		lift.down_time = 1.2
		lift.rise_time = 1.5
		lift.up_time = 1.2
		lift.fall_time = 0.4
		add(lift, at)
	add_sign("Stand on a crusher and it lifts you. Jump off at the top!", Vector3(-2.2, 0, -80.0))
	coin_line(Vector3(0, 4.6, -84.2), Vector3(0, 4.6, -86.0), 2)
	coin_line(Vector3(0, 8.6, -89.6), Vector3(0, 8.0, -91.4), 2)
	deco("factory:machine", Vector3(-2.2, 4.0, -86.0), 90.0, 1.0)
	deco("factory:hopper-high-round", Vector3(2.2, 4.0, -86.2), 0.0, 1.0)
	# Off the racing line: a shelf above the first lift, a double jump away.
	if not is_speedrun():
		ledge(3, -85, 6, -82, 6.5, "snow")
		add_gem(GEM, Vector3(4.6, 6.8, -83.5))
		add_heart(Vector3(5.4, 6.5, -84.4))

	# The cake at the top, with the flag.
	drum(CAKE, 3.9, CAKE.y - 3.3, CAKE.y)
	piece("food:cake", Vector3(CAKE.x, CAKE.y - 3.24, CAKE.z), 0.0, 12.0)
	goal(CAKE + Vector3(0, 0, -1.6), Vector3.FORWARD)
	for a in 6:
		var turn := TAU * (a + 0.5) / 6.0
		deco("food:cherries", CAKE + Vector3(sin(turn), 0, cos(turn)) * 3.2, rad_to_deg(turn), 4.0)
	glow(Vector3(-7, 9, -62), 1.8)
	glow(Vector3(8, 11, -88), 1.6, Color("ffb3f0"))
	add(StarRainbow.make(14.0, 0.0, 0.5), Vector3(0, -2, -106))
	finish()


## Giant sweets standing in the soda, and cogs and pipes along its shores.
func _lake_scenery() -> void:
	deco("food:soda-bottle", Vector3(-6.0, -2.0, -36.0), 30.0, 8.0)
	deco("food:soda-can", Vector3(6.2, -2.0, -40.0), 0.0, 9.0)
	deco("food:soda-glass", Vector3(-6.4, -2.0, -48.0), 0.0, 8.0)
	deco("food:popsicle", Vector3(6.4, -2.0, -55.0), 60.0, 8.0)
	deco("food:sundae", Vector3(-6.4, -2.0, -64.0), 0.0, 7.0)
	deco("food:soda-bottle", Vector3(6.6, -2.0, -66.0), 140.0, 7.0)
	deco("food:donut-sprinkles", Vector3(4.6, -1.0, -33.0), 20.0, 8.0)
	deco("food:donut-chocolate", Vector3(-4.6, -1.0, -57.5), 80.0, 8.0)
	for z in [-38.0, -52.0, -66.0]:
		prop("factory:cog-b", Vector3(-9.2, 0.6, z), 90.0, 3.2, 90.0)
		prop("factory:cog-c", Vector3(9.2, 0.6, z - 7.0), 90.0, 3.2, 90.0)
