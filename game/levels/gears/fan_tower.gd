class_name GearsFanTower
extends Level
## Course 3 of Gear Works: up the fan tower, floor by floor. A fan lifts
## you to a deck swept by a cog spinner, a broken catwalk crosses a gust
## that blows you sideways, a second fan lifts you higher, falling
## platforms lead west, and a last tall fan blows you up to the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge the gust blows you
## towards, and checkpoints; the flag gives the star. Speedrun: just the
## course and the clock.

const STAR := "gears/fan_tower"
const GEM := "gears/gem_fan_tower"

var spinner: GearsCogSpinner


func _init() -> void:
	super()
	title = "Fan Tower"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The start pad, and the first fan.
	land(-3, -8, 3, 4, 0, 3)
	add_sign("Fans blow you up. Float over one, then steer onto the next floor.", Vector3(-2, 0, 1))
	add(GearsFan.make(7.5, 42.0), Vector3(0, 0, -7))
	coin_line(Vector3(0, 1.5, -7), Vector3(0, 6.0, -7), 3)

	# The spinner deck: run through just after an arm sweeps by.
	land(-3, -22, 3, -9, 5.0, 3)
	add_checkpoint(Vector3(1.0, 5, -11), Vector3.FORWARD)
	spinner = add(GearsCogSpinner.cogs(3, 80.0, 2), Vector3(0, 5, -16)) as GearsCogSpinner
	add_sign("Spinning cogs! Dash through just after an arm goes by, or jump it.", Vector3(2.2, 5, -10.2))

	# The broken catwalk across the gust: it blows you east as you jump.
	for z0 in [-22, -28, -34]:
		ledge(-1, z0 - 4, 1, z0, 5.0, "snow")
	add_sign("A gust blows across the catwalk. Lean into it as you jump!", Vector3(-2.2, 5, -20.6))
	var gust := WindZone.make(Vector3(8, 4, 16), Vector3.RIGHT * 10.0)
	add(gust, Vector3(0, 4.5, -30))
	add_coin(Vector3(0, 6.3, -27))
	add_coin(Vector3(0, 6.3, -33))
	if not is_speedrun():
		# Off the racing line: a ledge the gust blows you towards, with a
		# spring over to the next deck.
		ledge(6, -37, 9, -33, 4.5)
		add_gem(GEM, Vector3(7.5, 4.7, -34))
		add(Spring.new(), Vector3(6.6, 4.5, -36.4))

	# The second deck and fan.
	land(-4, -44, 4, -38, 5.0, 3)
	add_checkpoint(Vector3(-0.7, 5, -39.8), Vector3.FORWARD)
	add_heart(Vector3(3, 5, -39))
	add(GearsFan.make(8.0, 42.0), Vector3(0, 5, -42.9))
	coin_line(Vector3(0, 7, -42.9), Vector3(0, 12, -42.9), 3)

	# The third deck, then falling platforms west.
	land(-4, -54, 4, -45, 10.5, 3)
	add_checkpoint(Vector3(0.5, 10.5, -47.8), Vector3.LEFT)
	camera_zone(Vector3(-34, 8, -58), Vector3(4.5, 26, -45.5), 90.0, 28.0, 10.0)
	for i in 3:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(-6.0 - i * 3.5, 10.5, -50))
		add_coin(Vector3(-6.0 - i * 3.5, 11.1, -50))
	add_sign("These platforms drop when you land. Keep moving!", Vector3(-3, 10.5, -47), Vector3.LEFT)

	# The last deck and the tall fan up to the flag.
	land(-20, -54, -15, -46, 10.5, 3)
	add_checkpoint(Vector3(-15.5, 10.5, -49.2), Vector3.LEFT)
	add_heart(Vector3(-16, 10.5, -53))
	add(GearsFan.make(9.0, 42.0), Vector3(-17.6, 10.5, -50))
	coin_line(Vector3(-17.6, 13, -50), Vector3(-17.6, 18, -50), 3)
	land(-29, -54, -20, -46, 17.0, 3)
	add_flag(Vector3(-25, 17, -50), Vector3.LEFT)
	piece("factory:robot-arm-a", Vector3(-28, 17, -53), 90.0, 1.4)
	piece("factory:robot-arm-b", Vector3(-28, 17, -47), 90.0, 1.4)
	_scenery()
	finish()


func _scenery() -> void:
	GearsDecor.strip(self, Vector3(0, 0, 3), Vector3(0, 0, -3))
	GearsDecor.arrow(self, Vector3(0, 0, -3.4), Vector3.FORWARD)
	GearsDecor.strip(self, Vector3(-21, 17, -50), Vector3(-28, 17, -50))
	for c in [[Vector3(-3.7, 2, -15), 6.0, 90.0], [Vector3(1, 7.5, -54.7), 6.0, 0.0], [Vector3(-17.5, 7.5, -54.7), 6.0, 0.0], [Vector3(-29.7, 14, -50), 6.0, 90.0]]:
		add(GearsBigCog.make(c[1], c[2], -10.0), c[0])
	piece("factory:machine", Vector3(-2.2, 0, -1.8), 90.0, 1.2)
	piece("factory:hopper-round", Vector3(2.4, 0, -2.0), 0.0, 1.2)
	for at in [Vector3(-2.5, 5, -21.3), Vector3(2.5, 5, -21.3), Vector3(-3.4, 10.5, -53.4)]:
		deco("factory:warning-traffic", at, 0.0, 1.3)
	for at in [Vector3(-3.2, 5, -43.2), Vector3(3.2, 10.5, -53.2)]:
		piece("factory:box-large", at, 0.0, 1.3)
