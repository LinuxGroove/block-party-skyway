class_name MoonHop
extends Level
## Course 1 of Star Station, all in moon gravity: crater hops, falling moon
## rocks, a wall to double jump, a gap only a long jump crosses in one go,
## a spinner to float over, then lifts out to the west and the flag. The
## camera turns west with the course.
##
## Adventure: coins, a heart, a hidden gem on an asteroid below the long
## gap (with a spring back up) and checkpoints; the flag gives the star.
## Speedrun: just the course and the clock.

const STAR := "station/moonhop"
const GEM := "station/gem_moonhop"
## The lifts out west: x of each, and where in its rise it starts.
const LIFTS := [[-9.0, 0.0], [-15.0, 0.33], [-21.0, 0.66]]


func _init() -> void:
	super()
	title = "Moon Hop"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 10.0, false]
	gravity_scale = 0.6


func build() -> void:
	# The start pad.
	land(-3, -4, 3, 4, 0, 3)
	StationDeco.panels(self, -3, -4, 3, 4, 0.0)
	add_sign("Moon gravity all the way: jumps float, and a long jump goes a very long way!", Vector3(-2, 0, 1.5))
	deco("arrows", Vector3(0, 0, -3), 0.0, 2.0)
	StationDeco.prop(self, "computer-system", Vector3(2.2, 0, 2.5), -90.0, 1.4)

	# Crater hops, each a little higher.
	land(-2, -12, 2, -9, 0.5, 2, "snow")
	land(1, -20, 5, -16, 1.5, 2, "snow")
	land(-3, -28, 1, -24, 3.0, 2, "snow")
	piece("station:rocks", Vector3(1.4, 0.5, -11.4), 20.0, 1.2)
	piece("station:skip-rocks", Vector3(4.2, 1.5, -16.6), 70.0, 1.2)
	for at in [Vector3(0, 2.6, -6.5), Vector3(1.8, 3.4, -14.0), Vector3(0, 4.8, -22.0)]:
		add_coin(at)

	# Moon rocks that drop soon after you land: keep hopping.
	for z in [-32.5, -37.0, -41.5]:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-moving-blue", 0.6), Vector3(-1, 3.0, z))
		add_coin(Vector3(-1, 4.6, z + 2.2))
	add_sign("Moon rocks drop soon after you land on them. Keep hopping!", Vector3(0.3, 3.0, -25.5), Vector3.BACK)

	# A rest, then a wall: double jump, high jump, or take the spring.
	land(-4, -52, 4, -45, 3.0, 3)
	StationDeco.panels(self, -4, -50, 4, -46, 3.0, "floor-panel-straight")
	add_checkpoint(Vector3(-2.5, 3.0, -46.5), Vector3.FORWARD)
	land(-4, -60, 4, -52, 7.5, 6, "snow")
	add(Spring.new(), Vector3(2.8, 3.0, -50.6))
	add_sign("Too high? Jump twice, crouch and jump, or take the spring.", Vector3(-3.2, 3.0, -49), Vector3(1, 0, 1).normalized())
	coin_line(Vector3(-1, 7.6, -54), Vector3(-1, 7.6, -58), 3)

	# The long gap. A rock in the middle is the slow way across.
	ledge(-4, -68, -2, -66, 6.5, "snow")
	add_sign("A long jump crosses in one go: run, crouch, jump!", Vector3(3.2, 7.5, -57), Vector3(-1, 0, 1).normalized())
	coin_line(Vector3(1.5, 9.5, -63), Vector3(1.5, 9.5, -70), 3)

	# The far side, with a spinner to float over.
	land(-4, -90, 4, -73, 6.0, 3, "snow")
	add_checkpoint(Vector3(-2.5, 6.0, -74.5), Vector3.FORWARD)
	add(Spinner.make(3, 75.0), Vector3(-1, 6.0, -81))
	for at in [Vector3(3, 6, -88.5), Vector3(-3.3, 6, -76.6)]:
		piece("station:rocks", at, fmod(at.z * 25.0, 360.0), 1.3)
	add_coin(Vector3(2, 7.6, -80.5))
	if not is_speedrun():
		# Off the racing line: an asteroid below the gap's east side.
		ledge(8, -71, 11, -68, 3.0, "snow")
		add_gem(GEM, Vector3(9.8, 3.2, -70.2))
		add_heart(Vector3(9.8, 3.0, -68.6))
		add(Spring.new(), Vector3(8.6, 3.0, -68.6))

	# Out west on the lifts, to the flag.
	camera_zone(Vector3(-40, -4, -96), Vector3(-3.5, 20, -79), 90.0, 28.0, 10.0)
	for l in LIFTS:
		add(MovingPlatform.make(Vector3(0, 2.5, 0), 3.0, l[1], Vector3(2, 0.4, 2), "platform"), Vector3(l[0], 5.0, -86))
		add_coin(Vector3(l[0], 9.6, -86))
	land(-32, -90, -24, -82, 6.0, 3)
	StationDeco.panels(self, -32, -90, -24, -82, 6.0, "floor-detail")
	add_flag(Vector3(-29, 6.0, -86), Vector3.LEFT)
	for z in [-89.0, -83.0]:
		StationDeco.prop(self, "structure-barrier-high", Vector3(-31, 6.0, z), 0.0, 1.8)
	StationDeco.space(self)
	finish()
