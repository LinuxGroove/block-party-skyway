class_name VentClimb
extends Level
## Course 3 of Star Station: up the outside of a station tower. A vent
## lifts you to the first ledge, a shuttle carries you over a gap, a second
## vent lifts you again, you kick up a gap between two walls, then cross
## falling platforms west to the flag high above the start. The camera
## turns west for the last stretch.
##
## Adventure: coins, a heart, a hidden gem on a ledge round the back of
## the tower (drift east off the second vent; a spring comes back) and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "station/ventclimb"
const GEM := "station/gem_ventclimb"


func _init() -> void:
	super()
	title = "Vent Climb"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 24.0, 11.0, false]


func build() -> void:
	# The start pad and the first vent.
	land(-3, -10, 3, 4, 0, 3)
	StationDeco.panels(self, -3, -4, 3, 4, 0.0)
	add_sign("Vents blow you upwards. Step in, ride up, then steer onto the ledge.", Vector3(-2, 0, 1.5))
	_vent(Vector3(0, 0, -8.4), 6.0)
	coin_line(Vector3(0, 1.5, -8.4), Vector3(0, 5.5, -8.4), 3)

	# The first ledge, and a shuttle over the gap.
	land(-3, -16, 3, -10, 6, 9)
	add_checkpoint(Vector3(-2, 6, -11), Vector3.FORWARD)
	add(MovingPlatform.make(Vector3(0, 0, -4), 4.0, 0.0, Vector3(2, 0.5, 2), "block-moving-blue"), Vector3(0, 6, -18))
	add_coin(Vector3(0, 7.2, -20))

	# The second ledge and vent.
	land(-3, -32, 3, -24, 6, 2)
	_vent(Vector3(0, 6, -30.4), 5.5)
	coin_line(Vector3(0, 7.5, -30.4), Vector3(0, 10.5, -30.4), 2)
	_supports(Vector3(0, 6, -27), 3)
	if not is_speedrun():
		# Round the back: a ledge off to the east, with a spring back.
		ledge(5, -34, 8, -31, 9)
		add_gem(GEM, Vector3(6.6, 9.2, -32.8))
		add_heart(Vector3(7.3, 9, -31.6))
		add(Spring.new(), Vector3(5.6, 9, -31.6))
		coin_line(Vector3(1.8, 11.5, -29.5), Vector3(4.2, 11, -31.0), 2)

	# The third ledge, and the gap between two walls to kick up.
	land(-3, -38, 3, -32, 11, 5)
	ledge(0, -41, 1, -38, 11)
	add_checkpoint(Vector3(-2, 11, -33), Vector3.FORWARD)
	land(1, -41, 3, -39, 17.5, 8.5)
	add_sign("Jump at a wall, then jump again to kick up between them.", Vector3(-2.2, 11, -36.5), Vector3(1, 0, 1).normalized())
	_supports(Vector3(0, 8, -35), 4)

	# The top ledge, then west over falling platforms to the flag.
	land(-7, -48, 0, -39, 16, 3)
	add_checkpoint(Vector3(-2, 16, -46.5), Vector3.LEFT)
	camera_zone(Vector3(-30, 13, -54), Vector3(0.5, 32, -38.5), 90.0, 26.0, 10.0)
	for x in [-9.5, -13.5, -17.5]:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-moving-blue", 0.7), Vector3(x, 16, -44))
		add_coin(Vector3(x, 17.4, -44))
	land(-26, -48, -19, -40, 16, 3)
	StationDeco.panels(self, -26, -48, -20, -40, 16.0, "floor-detail")
	add_flag(Vector3(-23, 16, -44), Vector3.LEFT)
	StationDeco.prop(self, "structure-barrier-high", Vector3(-25, 16, -47), 0.0, 1.8)
	StationDeco.prop(self, "structure-barrier-high", Vector3(-25, 16, -41), 0.0, 1.8)
	StationDeco.space(self)
	finish()


## A vent in the floor: a grate and an updraft `height` tall from `at`,
## against the face of the ledge it lifts you to.
func _vent(at: Vector3, height: float) -> void:
	add(WindZone.make(Vector3(3, height, 3), Vector3.UP * 50.0), at)
	piece("station:structure-panel", at, 0.0, 3.5)


## Scaffolding under a ledge, `n` frames down from its foot.
func _supports(top: Vector3, n: int) -> void:
	for i in n:
		piece("station:structure", top + Vector3(0, -2.0 - (i + 1) * 2.0, 0), 0.0, 2.0)
