class_name GearsCrusherRow
extends Level
## Course 4 of Gear Works: a corridor of crushers slamming in a wave, a
## timed bridge over the drop, then a turn west between two rows of
## crushers beating out of step (pick the one that's up), and a last
## crusher to ride up to the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge beside the bridge,
## and checkpoints; the flag gives the star. Speedrun: just the course and
## the clock.

const STAR := "gears/crusher_row"
const GEM := "gears/gem_crusher_row"
## Seconds the corridor's wave lags from one crusher to the next: about a
## run from one to the next, so one well-timed dash clears them all.
const WAVE := 0.55
## Where each pair of crushers in the rows stands, west of the bridge.
const PAIRS := [-8.0, -13.0, -18.0]
## The two lanes through the rows: south and north.
const LANES := [-46.0, -48.0]

## The corridor's crushers, south to north.
var corridor: Array[Crusher] = []
## The rows' crushers, by pair then lane (south, north).
var rows: Array = []
## The last crusher, the lift up to the flag.
var lift: Crusher
var bridge: GearsTimedBridge


func _init() -> void:
	super()
	title = "Crusher Row"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The start pad.
	land(-3, -4, 3, 4, 0, 3)
	add_sign("Crushers slam down. Wait for one to lift, then run under!", Vector3(-2, 0, 1))
	for x in [-2.5, 2.5]:
		deco("factory:warning-orange", Vector3(x, 0, 3.2), 0.0, 1.3)

	# The corridor: four crushers slamming in a wave that runs north.
	land(-1, -24, 1, -4, 0, 3)
	for i in 4:
		var c := _crusher(2.6)
		c.phase = -WAVE * i / c.cycle()
		add(c, Vector3(0, 0.02, -7.0 - i * 4.0))
		corridor.append(c)
	for z in [-9.0, -13.0, -17.0, -21.0]:
		add_coin(Vector3(0, 0.5, z))

	# The bridge: step on the button and steps slide out over the drop.
	land(-3, -32, 3, -24, 0, 3)
	add_checkpoint(Vector3(-0.8, 0, -25.4), Vector3.FORWARD)
	add_heart(Vector3(-2.2, 0, -30.5))
	add_sign("Step on the button and a bridge slides out. Be quick!", Vector3(-2.2, 0, -27.5))
	bridge = GearsTimedBridge.new()
	bridge.button_at = Vector3(2.0, 0, -25.6)
	bridge.steps = [Vector3(0, 0, -34), Vector3(0, 0, -38), Vector3(0, 0, -42)]
	bridge.seconds = 6.0
	bridge.label = "Bridge"
	add(bridge, Vector3.ZERO)
	for at in bridge.steps:
		add_coin(at + Vector3(0, 0.6, 0))
	if not is_speedrun():
		# Off the racing line: a ledge below the bridge's east side, with a
		# spring up to the far deck.
		ledge(3, -43, 7, -37, -2.0)
		add_gem(GEM, Vector3(5, -1.8, -39))
		add(Spring.new(), Vector3(5.4, -2.0, -42.2))

	# The far deck, and the turn west.
	land(-3, -50, 7, -44, 0, 3)
	add_checkpoint(Vector3(-0.8, 0, -45.6), Vector3.LEFT)
	add_heart(Vector3(5.5, 0, -48.5))
	add_sign("Two rows of crushers, out of step. Run under the one that's up!", Vector3(1.5, 0, -45.2), Vector3.LEFT)
	camera_zone(Vector3(-34, -6, -53), Vector3(8, 14, -43.6), 90.0, 28.0, 10.0)

	# The rows: in each pair one crusher is up while the other is down, and
	# the beat moves west about as fast as you weave.
	land(-21, -49, -3, -45, 0, 3)
	var lags := [0.0, -0.33, -0.66]
	for k in PAIRS.size():
		var pair: Array[Crusher] = []
		for lane in 2:
			var c := _crusher(2.4)
			# The lane the beat favours is up as you reach it; the other is
			# half a beat away.
			var favoured := 0 if k % 2 == 0 else 1
			c.phase = lags[k] + (0.0 if lane == favoured else 0.5)
			add(c, Vector3(PAIRS[k], 0.02, LANES[lane]))
			pair.append(c)
		rows.append(pair)
	for x in [-10.5, -15.5]:
		add_coin(Vector3(x, 0.5, -47))

	# The lift: hop on the last crusher while it's down and ride it up.
	land(-25, -50, -21, -44, 0, 3)
	add_checkpoint(Vector3(-21.6, 0, -45.4), Vector3.LEFT)
	add_sign("Hop on a crusher while it's down, and ride it up!", Vector3(-21.8, 0, -49.2), Vector3.LEFT)
	lift = Crusher.make(3.0, Vector3(2, 1, 2), 0.0)
	lift.down_time = 1.2
	lift.rise_time = 1.4
	lift.up_time = 1.4
	lift.fall_time = 0.25
	add(lift, Vector3(-23.5, 0.02, -47))
	add_coin(Vector3(-23.5, 4.6, -47))

	# The finish.
	land(-32, -51, -25, -43, 3.5, 3)
	add_flag(Vector3(-29, 3.5, -47), Vector3.LEFT)
	piece("factory:robot-arm-a", Vector3(-31, 3.5, -50), 90.0, 1.4)
	piece("factory:robot-arm-b", Vector3(-31, 3.5, -44), 90.0, 1.4)
	_scenery()
	finish()


## A crusher on the course's beat.
func _crusher(height: float) -> Crusher:
	var c := Crusher.make(height, Vector3(2, 1, 2), 0.0)
	c.down_time = 0.6
	c.rise_time = 0.9
	c.up_time = 0.8
	c.fall_time = 0.2
	return c


func _scenery() -> void:
	GearsDecor.strip(self, Vector3(0, 0, 3), Vector3(0, 0, -3))
	GearsDecor.arrow(self, Vector3(0, 0, -2.6), Vector3.FORWARD)
	GearsDecor.strip(self, Vector3(0, 0, -45.6), Vector3(0, 0, -47.6))
	GearsDecor.arrow(self, Vector3(-1.2, 0, -47), Vector3.LEFT)
	GearsDecor.strip(self, Vector3(-26, 3.5, -47), Vector3(-31, 3.5, -47))
	for c in [[Vector3(3.7, -3, -28), 6.0, 90.0], [Vector3(-3.7, -2.5, -29), 5.0, 90.0], [Vector3(7.7, -3, -47), 6.0, 90.0], [Vector3(-32.7, 0.5, -47), 6.0, 90.0]]:
		add(GearsBigCog.make(c[1], c[2], 11.0), c[0])
	piece("factory:machine", Vector3(-2.2, 0, -2.6), 90.0, 1.2)
	piece("factory:hopper-round", Vector3(2.4, 0, -2.8), 0.0, 1.2)
	for at in [Vector3(2.4, 0, -31.3), Vector3(-2.4, 0, -24.7), Vector3(6.4, 0, -44.7)]:
		deco("factory:warning-traffic", at, 0.0, 1.3)
	for at in [Vector3(-2.3, 0, -49.2), Vector3(-24.3, 0, -44.7)]:
		piece("factory:box-large", at, 0.0, 1.3)
