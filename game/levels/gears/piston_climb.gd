class_name GearsPistonClimb
extends Level
## Course 2 of Gear Works: a climb up the piston tower. Ride a piston up to
## a narrow walk under two crushers, ride the next piston up again, kick up
## between two stacks, then turn west and hop across three pistons pumping
## in a wave to the flag, fifteen metres up.
##
## Adventure: coins, hearts, a hidden gem on a ledge off the second deck,
## and checkpoints; the flag gives the star. Speedrun: just the course and
## the clock.

const STAR := "gears/piston_climb"
const GEM := "gears/gem_piston_climb"

var lifts: Array[GearsPiston] = []
var hops: Array[GearsPiston] = []
var crushers: Array[Crusher] = []


func _init() -> void:
	super()
	title = "Piston Climb"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The start pad.
	land(-3, -4, 3, 4, 0, 3)
	add_sign("Pistons pump up and down. Step on one while it's low and ride it up!", Vector3(-2, 0, 1))
	for x in [-2.5, 2.5]:
		deco("factory:warning-orange", Vector3(x, 0, 3.2), 0.0, 1.3)

	# The first lift, up to the crusher walk.
	lifts.append(_lift(Vector3(0, 0, -5), 3.5))
	coin_line(Vector3(0, 0.5, -5), Vector3(0, 3.0, -5), 3)

	# The crusher walk: two crushers over a narrow way. The second lags the
	# first, so one dash clears both.
	land(-1, -15, 1, -6, 3.5, 3)
	add_checkpoint(Vector3(0, 3.5, -6.6), Vector3.FORWARD)
	for i in 2:
		var c := Crusher.make(2.4, Vector3(2, 1, 2), 0.0)
		c.down_time = 0.7
		c.rise_time = 0.9
		c.up_time = 0.8
		c.fall_time = 0.2
		c.phase = -0.45 * i / c.cycle()
		add(c, Vector3(0, 3.5, -9.0 - i * 3.5))
		crushers.append(c)
	add_coin(Vector3(0, 4.0, -10.75))

	# The second lift, up to the deck below the stacks.
	lifts.append(_lift(Vector3(0, 3.5, -16), 3.5))
	land(-4, -30, 4, -17, 7.0, 3)
	add_checkpoint(Vector3(3, 7, -18.5), Vector3.FORWARD)
	add_heart(Vector3(-3, 7, -18))
	add_sign("Jump at a wall, then jump again to kick off it. Back and forth, up you go!", Vector3(-2.5, 7, -24.5))
	# The stacks: kick up between them onto the lower one.
	land(-4, -30, 0, -26, 13.0, 6)
	land(1, -30, 2, -26, 14.0, 7)
	coin_line(Vector3(0.5, 8.5, -28), Vector3(0.5, 12.0, -28), 4)
	camera_zone(Vector3(-5, 6, -31), Vector3(5, 16, -16.5), 0.0, 22.0, 11.0)
	if not is_speedrun():
		# Off the racing line: a ledge below the deck's east side.
		ledge(6, -24, 9, -20, 5.5)
		add_gem(GEM, Vector3(8, 5.7, -22.5))
		add(Spring.new(), Vector3(6.6, 5.5, -21))

	# The top: west across three pistons pumping in a wave.
	land(-4, -38, 0, -30, 13.0, 3)
	add_checkpoint(Vector3(-2, 13, -31.5), Vector3.LEFT)
	add_heart(Vector3(-1, 13, -37))
	camera_zone(Vector3(-25, 9, -41), Vector3(0.5, 22, -30.2), 90.0, 26.0, 10.0)
	for i in 3:
		var p := GearsPiston.make(2.0, 0.15 * i)
		_beat(p)
		add(p, Vector3(-6.0 - i * 3.5, 13.0, -34))
		hops.append(p)
		add_coin(Vector3(-6.0 - i * 3.5, 15.6, -34))

	# The finish.
	land(-22, -38, -15, -30, 15.0, 3)
	add_flag(Vector3(-18, 15, -34), Vector3.LEFT)
	piece("factory:robot-arm-a", Vector3(-21, 15, -37), 90.0, 1.4)
	piece("factory:robot-arm-b", Vector3(-21, 15, -31), 90.0, 1.4)
	_scenery()
	finish()


## A piston that rises out of the floor, flush with it when low.
func _lift(at: Vector3, height: float) -> GearsPiston:
	land(int(at.x) - 1, int(at.z) - 1, int(at.x) + 1, int(at.z) + 1, at.y - 0.5, 2)
	var p := GearsPiston.make(height)
	p.housing = false
	_beat(p)
	add(p, at)
	return p


## The course's piston beat: quicker than the island's.
func _beat(p: GearsPiston) -> void:
	p.low_time = 0.8
	p.rise_time = 1.0
	p.high_time = 0.8
	p.sink_time = 1.0


func _scenery() -> void:
	piece("factory:machine", Vector3(-2.2, 0, -2.8), 90.0, 1.2)
	piece("factory:hopper-round", Vector3(2.4, 0, -3.0), 0.0, 1.2)
	piece("factory:machine-window", Vector3(3.2, 7, -21), -90.0, 1.3)
	for at in [Vector3(3.3, 7, -29.4), Vector3(-0.7, 13, -37.3)]:
		deco("factory:warning-traffic", at, 0.0, 1.3)
	for at in [Vector3(-3.3, 7, -22.5), Vector3(3.3, 7, -25.5)]:
		piece("factory:box-large", at, 90.0, 1.3)
