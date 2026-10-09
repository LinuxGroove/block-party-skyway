class_name CastleSpireClimb
extends Level
## Course 3 of Sky Castle: up and up to the top of the spire. Stairs to the
## first terrace, a wall-kick chimney between two towers, a jump to the next
## terrace and past a flail, crumbling stones that step up into the sky, a
## dash past a ballista to a spring up to a high terrace, a second chimney,
## and a last jump to the flag at the foot of the spire. Falling drops you
## onto the terrace below.
##
## Adventure: coins, a heart, checkpoints, and a gem on a ledge off the third
## terrace with a spring back. Speedrun: just the climb and the clock.

const P := preload("res://game/levels/castle/castle_parts.gd")

const STAR := "castle/spire"
const GEM := "castle/gem_spire"
## The terraces' heights, bottom to top.
const T1 := 2.5
const T2 := 9.0
const T3 := 13.5
const T4 := 18.0
const T5 := 24.5
## The crumbling stones between the second and third terraces.
const STEPS := [Vector3(1.0, 10.2, -24), Vector3(-0.6, 11.4, -27), Vector3(1.0, 12.6, -30)]

## Where the ballista's bolts cross the third terrace.
const LANE_Z := -36.0

## The tops of the towers you kick up to.
var chimney_tops: Array[float] = []
var flail: Spinner
var ballista: CastleBallista


func _init() -> void:
	super()
	title = "Spire Climb"
	spawn = Vector3(0, 0, 3)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 32.0, 9.5, false]


func build() -> void:
	# The start, and stairs to the first terrace.
	land(-4, -2, 4, 5, 0, 4)
	add_sign("Climb the spire! Jump at a wall, then jump again to kick off it.", Vector3(-2.6, 0, 1.2))
	for at in [Vector3(-3, 0, 4), Vector3(3, 0, 4)]:
		P.tree(self, at, false, 1.6)
	P.stairs(self, Vector3(0, 0, -4 + 0.82 * T1 / 0.67), Vector3.FORWARD, T1, 3.0)

	# The first terrace and the first chimney.
	land(-5, -12, 5, -4, T1, 5, "snow")
	_chimney(Vector3(0, T1, -10))
	coin_line(Vector3(0, T1 + 1.5, -10), Vector3(0, T1 + 5.5, -10), 3)
	camera_zone(Vector3(-4, T1 - 1, -12), Vector3(3, T1 + 9, -7.5), 0.0, 18.0, 11.0, false, 1)

	# The second terrace, a jump north from the tower top.
	land(-5, -22, 5, -14, T2, 6, "snow")
	add_checkpoint(Vector3(-3, T2, -16), Vector3.FORWARD)
	add_heart(Vector3(3.5, T2, -15.5))
	add_sign("These stones crumble once you're on them. Keep jumping!", Vector3(-4, T2, -15.2))
	flail = Spinner.make(2, 90.0, "spike-block")
	flail.height = 0.7
	add(flail, Vector3(-1.5, T2, -18.5))
	coin_line(Vector3(0, T2 + 1.2, -12.2), Vector3(0, T2 + 0.6, -13.6), 2)

	# Crumbling stones up to the third terrace.
	for at in STEPS:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-snow-low", 0.55), at)
		add_coin((at as Vector3) + Vector3.UP * 0.5)

	# The third terrace, and a spring up to the fourth.
	land(-4, -40, 5, -32, T3, 5, "snow")
	add_checkpoint(Vector3(-2.5, T3, -33.5), Vector3.FORWARD)
	var spring := Spring.new()
	spring.power = 20.0
	add(spring, Vector3(0, T3, -38.2))
	add_sign("Bounce on the spring, then steer onto the terrace above.", Vector3(3, T3, -34))
	ballista = CastleBallista.make(Vector3.RIGHT, 2.4)
	ballista.bolt_range = 9.0
	add(ballista, Vector3(-3.3, T3, LANE_Z))
	coin_line(Vector3(0, T3 + 2.5, -39.5), Vector3(0, T3 + 5.0, -40.5), 2)
	if not is_speedrun():
		# Off the terrace's east side, a jump away: the gem, and a spring back.
		ledge(8, -37, 11, -34, T3 - 1.0, "snow")
		add_gem(GEM, Vector3(10, T3 - 1.0, -35.8))
		add(Spring.new(), Vector3(8.7, T3 - 1.0, -34.7))

	# The fourth terrace and the second chimney.
	land(-4, -50, 4, -41, T4, 4, "snow")
	add_checkpoint(Vector3(2.5, T4, -42.5), Vector3.FORWARD)
	_chimney(Vector3(0, T4, -46))
	coin_line(Vector3(0, T4 + 1.5, -46), Vector3(0, T4 + 5.5, -46), 3)
	camera_zone(Vector3(-4, T4 - 1, -48), Vector3(3, T4 + 9, -43.5), 0.0, 18.0, 11.0, false, 1)

	# The top: the flag at the foot of the spire.
	land(-5, -59, 5, -49, T5, 4, "snow")
	add_flag(Vector3(0, T5, -53), Vector3.FORWARD)
	P.tower(self, Vector3(0, T5, -56.5), 3.5, 2, "spire")
	for x in [-4.0, 4.0]:
		P.pennant(self, Vector3(x, T5, -50), 0.0, 2.0)
	P.banner(self, Vector3(0, T5 + 5.5, -54.7), Vector3.BACK, true, 1.8)
	P.cloud_sea(self, Vector3(0, 0, -28), 12.0, 70.0, -16.0, -8.0, 50, 31)
	finish()


## Two towers on a terrace, a metre apart, to kick up between: a wide one on
## the west and a narrow one on the east, both with floors to land on. No
## roofs, so they don't hide the hero on the terrace beyond.
func _chimney(foot: Vector3) -> void:
	chimney_tops.append(P.tower(self, foot + Vector3(-2, 0, 0), 3.0, 2, "walk", true, true))
	P.tower(self, foot + Vector3(1.5, 0, 0), 2.0, 3, "walk", true, true)
