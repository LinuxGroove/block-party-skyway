class_name GearsBeltRush
extends Level
## Course 1 of Gear Works: a conveyor gauntlet. Up belts that push you
## back across three gaps, a deck of side belts between sweeping saws, an
## express belt under two crushers, then a turn east across belts running
## the other way, to the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge below the turn, and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "gears/belt_rush"
const GEM := "gears/gem_belt_rush"

var crushers: Array[Crusher] = []


func _init() -> void:
	super()
	title = "Belt Rush"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The start pad.
	land(-3, -6, 3, 4, 0, 3)
	add_sign("Belts push you about. Keep running, and jump the gaps!", Vector3(-2, 0, 1))
	deco("factory:indicator-special-arrow", Vector3(0, 0.01, -4.5), 180.0, 1.6)
	for x in [-2.5, 2.5]:
		deco("factory:warning-orange", Vector3(x, 0, 3.2), 0.0, 1.3)

	# Up belts: four belts pushing back towards the start, three gaps.
	for z0 in [-6, -14, -22, -30]:
		land(-1, z0 - 5, 1, z0, 0, 2)
		add(Conveyor.make(5, Vector3.BACK, 3.0), Vector3(0, -0.33, z0 - 5))
	for z in [-12.5, -20.5, -28.5]:
		add_coin(Vector3(0, 1.3, z))
	add_checkpoint(Vector3(0, 0, -23.5), Vector3.FORWARD)

	# The side-belt deck: belts push left, right, left... between saws
	# sweeping up and down the edges.
	land(-3, -45, 3, -35, 0, 2)
	for i in 5:
		var z := -36.0 - i * 2.0
		if i % 2 == 0:
			add(Conveyor.make(6, Vector3.LEFT, 4.0), Vector3(3, -0.33, z))
		else:
			add(Conveyor.make(6, Vector3.RIGHT, 4.0), Vector3(-3, -0.33, z))
	add(Saw.make(Vector3(0, 0, -8), 3.2, 0.0), Vector3(-2.4, 0.02, -36))
	add(Saw.make(Vector3(0, 0, -8), 3.2, 0.5), Vector3(2.4, 0.02, -36))
	for z in [-37.0, -40.0, -43.0]:
		add_coin(Vector3(0, 0.5, z))

	# The landing, then the express belt under two crushers.
	land(-3, -51, 3, -45, 0, 3)
	add_checkpoint(Vector3(-2, 0, -46.5), Vector3.FORWARD)
	add_heart(Vector3(2.2, 0, -50))
	add_sign("The express belt runs under the crushers. Go when the first one lifts!", Vector3(2.2, 0, -46.5))
	land(-1, -61, 1, -51, 0, 2)
	add(Conveyor.make(10, Vector3.FORWARD, 3.0), Vector3(0, -0.33, -51))
	for i in 2:
		var c := Crusher.make(2.6, Vector3(2, 1, 2), 0.0)
		c.down_time = 0.6
		c.rise_time = 0.9
		c.up_time = 0.7
		c.fall_time = 0.2
		# The second lags the first, so one dash clears both.
		c.phase = -0.4 * i / c.cycle()
		add(c, Vector3(0, 0.02, -54.0 - i * 4.0))
		crushers.append(c)
	for z in [-52.5, -56.0, -59.5]:
		add_coin(Vector3(0, 0.5, z))

	# The turn: the course heads east from here.
	land(-3, -67, 5, -61, 0, 3)
	add_checkpoint(Vector3(-1.5, 0, -64), Vector3.RIGHT)
	camera_zone(Vector3(-4, -8, -72), Vector3(34, 14, -60.5), -90.0, 30.0, 10.0)
	if not is_speedrun():
		# Off the racing line: a ledge below the turn, with a spring back.
		ledge(-9, -68, -5, -64, -1.5)
		add_gem(GEM, Vector3(-7.5, -1.3, -66.5))
		add_heart(Vector3(-8.3, -1.5, -64.7))
		add(Spring.new(), Vector3(-5.8, -1.5, -66))

	# Cross belts: hop east over belts running north and south. Stand still
	# and they carry you off the end.
	for i in 4:
		var x := 8 + i * 4
		land(x - 1, -67, x + 1, -61, 0, 2)
		if i % 2 == 0:
			add(Conveyor.make(6, Vector3.FORWARD, 3.5), Vector3(x, -0.33, -61))
		else:
			add(Conveyor.make(6, Vector3.BACK, 3.5), Vector3(x, -0.33, -67))
		add_coin(Vector3(x, 0.5, -64))

	# The finish.
	land(23, -68, 31, -60, 0, 3)
	add_flag(Vector3(26.5, 0, -64), Vector3.RIGHT)
	piece("factory:robot-arm-a", Vector3(29.5, 0, -67), -90.0, 1.4)
	piece("factory:robot-arm-b", Vector3(29.5, 0, -61), -90.0, 1.4)
	_scenery()
	finish()


func _scenery() -> void:
	# Machines and boxes beside the belts, out of the way.
	piece("factory:machine", Vector3(-2.2, 0, -5.0), 90.0, 1.2)
	piece("factory:hopper-round", Vector3(2.4, 0, -5.2), 0.0, 1.2)
	for at in [Vector3(-2.4, 0, -50.2), Vector3(4.2, 0, -66.2)]:
		piece("factory:box-large", at, 0.0, 1.4)
	for at in [Vector3(-2.6, 0, -61.6), Vector3(30.4, 0, -60.6), Vector3(30.4, 0, -67.4)]:
		deco("factory:warning-traffic", at, 0.0, 1.3)
