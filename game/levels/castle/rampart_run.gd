class_name CastleRampartRun
extends Level
## Course 1 of Sky Castle: along the top of the castle walls. Up the stairs,
## over a crumbled gap, past a spinning flail, round a bastion and west over
## a broken stretch (ride the stone or long jump it), north across a bastion
## under ballista fire, over crumbling stones and on to the flag. The
## course runs north, then west, then north again; the camera turns with it.
##
## Adventure: coins, a heart, checkpoints, and a gem on a ledge below the
## walls with a spring back up. Speedrun: just the walls and the clock.

const P := preload("res://game/levels/castle/castle_parts.gd")

const STAR := "castle/ramparts"
const GEM := "castle/gem_ramparts"
## The walls' scale, and the height of their walkways.
const SCALE := 3.0
const WALK := P.WALK * SCALE
## Where the ballista's bolts cross the third bastion.
const LANE_Z := -48.0

var flail: Spinner
var last_flail: Spinner
var ferry: MovingPlatform
var ballista: CastleBallista


func _init() -> void:
	super()
	title = "Rampart Run"
	spawn = Vector3(0, 0, 3)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The start, in a little courtyard at the foot of the walls.
	land(-4, -2, 4, 5, 0, 4)
	add_sign("Run along the castle walls. Jump the gaps and the spinning flail!", Vector3(-2.6, 0, 1.2))
	for at in [Vector3(-3, 0, 4), Vector3(3, 0, 4)]:
		P.tree(self, at, false, 1.6)
	deco("flowers", Vector3(2.8, 0, 0.5), 30.0, 1.2)
	P.stairs(self, Vector3(0, 0, -6 + 0.82 * WALK / 0.67), Vector3.FORWARD, WALK, 3.0)

	# The first wall, then a crumbled gap.
	P.rampart(self, Vector3(0, 0, -6), Vector3(0, 0, -18), SCALE)
	coin_line(Vector3(0, WALK, -8), Vector3(0, WALK, -16), 4)
	P.rampart(self, Vector3(0, 0, -21), Vector3(0, 0, -30), SCALE)
	add_coin(Vector3(0, WALK + 1.6, -19.5))

	# A flail spins on the second wall: jump its arm as it comes round.
	flail = Spinner.make(2, 90.0, "spike-block")
	flail.height = 0.7
	add(flail, Vector3(0, WALK, -25.5))
	if not is_speedrun():
		# Off the wall's east side: a ledge with the gem, and a spring back up.
		ledge(2, -27, 5, -22, 0.0, "snow")
		add_gem(GEM, Vector3(4, 0.0, -26))
		add_coin(Vector3(4, 0.1, -23.2))
		add(Spring.new(), Vector3(2.7, 0.0, -24.5))

	# The first bastion: the walls turn west.
	P.bastion(self, Vector3(0, WALK, -33), 6, [Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1)])
	add_checkpoint(Vector3(-1.6, WALK, -31.2), Vector3.LEFT)
	camera_zone(Vector3(-16, 0, -36), Vector3(3.5, 14, -29.5), 90.0, 30.0, 9.5)

	# A broken stretch: ride the stone across, or long jump it.
	P.rampart(self, Vector3(-3, 0, -33), Vector3(-6, 0, -33), SCALE)
	ferry = MovingPlatform.make(Vector3(-3.6, 0, 0), 4.0, 0.0, Vector3(2, 0.5, 2), "block-snow-low")
	add(ferry, Vector3(-7.2, WALK, -33))
	add_sign("Ride the stone across. Running? Crouch, then jump for a long jump.", Vector3(-1.4, WALK, -34.6), Vector3.RIGHT)
	P.rampart(self, Vector3(-12, 0, -33), Vector3(-15, 0, -33), SCALE)
	coin_line(Vector3(-7, WALK + 1.2, -33), Vector3(-11, WALK + 1.2, -33), 3)

	# The second bastion: north from here.
	P.bastion(self, Vector3(-18, WALK, -33), 6, [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)])
	add_heart(Vector3(-16.2, WALK, -35))
	P.rampart(self, Vector3(-18, 0, -36), Vector3(-18, 0, -45), SCALE)
	add_checkpoint(Vector3(-18, WALK, -37.5), Vector3.FORWARD)
	coin_line(Vector3(-18, WALK, -39), Vector3(-18, WALK, -43), 3)

	# The third bastion, under fire from the ballista on its battery.
	P.bastion(self, Vector3(-18, WALK, -48), 6, [Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)])
	land(-13, -50, -9, -46, WALK, 4, "snow")
	ballista = CastleBallista.make(Vector3.LEFT, 2.6)
	ballista.bolt_range = 13.0
	add(ballista, Vector3(-10.6, WALK, LANE_Z))
	add_sign("A ballista! Wait for a bolt to fly past, then run.", Vector3(-16.6, WALK, -43.4), Vector3.LEFT)
	P.pennant(self, Vector3(-9.6, WALK, -46.6), 0.0, 1.6)

	# The last wall crumbles away: keep running over the falling stones.
	P.rampart(self, Vector3(-18, 0, -51), Vector3(-18, 0, -54), SCALE)
	for z in [-55.5, -58.0, -60.5]:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-snow-low", 0.5), Vector3(-18, WALK, z))
		add_coin(Vector3(-18, WALK + 0.4, z))
	# One more flail, turning the other way, guards the last wall.
	P.rampart(self, Vector3(-18, 0, -62), Vector3(-18, 0, -71), SCALE)
	last_flail = Spinner.make(2, -90.0, "spike-block")
	last_flail.height = 0.7
	add(last_flail, Vector3(-18, WALK, -66.5))
	coin_line(Vector3(-17.2, WALK, -63.5), Vector3(-17.2, WALK, -69.5), 3)

	# The finish, on the last bastion.
	P.bastion(self, Vector3(-18, WALK, -75), 8, [Vector2(1, -1), Vector2(-1, -1)], 5)
	add_flag(Vector3(-18, WALK, -75.5), Vector3.FORWARD)
	P.banner(self, Vector3(-20.0, WALK - 0.2, -71.0), Vector3.BACK, false, 2.0)
	P.banner(self, Vector3(-16.0, WALK - 0.2, -71.0), Vector3.BACK, false, 2.0)
	P.cloud_sea(self, Vector3(-8, 0, -34), 10.0, 70.0, -16.0, -8.0, 50, 11)
	finish()
