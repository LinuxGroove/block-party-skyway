class_name SawMillSprint
extends Level
## Course 1 of Sunny Isles: stepping stones, a saw alley, sliding platforms,
## a high shelf, a long gap and the mill's conveyor belts, then the flag.
## It runs north, then turns west at the shelf, where the camera turns with
## it.
##
## Adventure: coins, a heart, a hidden gem off the racing line and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "sunny/sawmill"
const GEM := "sunny/gem_sawmill"


func _init() -> void:
	super()
	title = "Saw Mill Sprint"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]
	music = "res://assets/kenney/audio/music/swinging_pants.ogg"


func build() -> void:
	var adventure := not is_speedrun()
	# The start pad.
	land(-3, -6, 3, 4, 0, 3)
	add(_sign("Hold Run to go faster. Jump the gaps!", Vector3.BACK), Vector3(-2, 0, 1))
	deco("arrows", Vector3(0, 0, -4.5), 0.0, 2.0)
	for x in [-2.5, 2.5]:
		deco("flowers", Vector3(x, 0, 3))

	# Stepping stones, each a little higher.
	land(-1, -10, 1, -8, 0.5, 2)
	land(-2, -14, 0, -12, 1.0, 2)
	land(0, -18, 2, -16, 1.5, 2)
	if adventure:
		for at in [Vector3(0, 1.4, -7), Vector3(0, 1.6, -9), Vector3(-1, 2.0, -11), Vector3(-1, 2.2, -13), Vector3(1, 2.6, -15), Vector3(1, 2.8, -17)]:
			add(Pickup.make("coin"), at)

	# Saw alley: two saws sweep across, then a wave of spike traps.
	land(-3, -34, 3, -20, 1.5, 3)
	add(Saw.make(Vector3(5, 0, 0), 2.4, 0.0), Vector3(-2.5, 1.5, -24))
	add(Saw.make(Vector3(-5, 0, 0), 2.4, 0.25), Vector3(2.5, 1.5, -28))
	for i in 5:
		add(SpikeTrap.make(i * 0.12), Vector3(-2 + i, 1.5, -31.5))
	deco("fence-straight", Vector3(-2.5, 1.5, -33.6), 0.0)
	deco("fence-straight", Vector3(2.5, 1.5, -33.6), 0.0)
	if adventure:
		add(_checkpoint(Vector3.FORWARD), Vector3(-2, 1.5, -21))
		for z in [-22, -26, -30]:
			add(Pickup.make("coin"), Vector3(0, 1.6, z))
		# Off the racing line: a ledge below the alley's east side.
		ledge(5, -30, 8, -27, -0.5)
		add(Pickup.make("gem", GEM, found_gems.has(GEM)), Vector3(7, -0.5, -28.5))
		add(Pickup.make("heart"), Vector3(5.6, -0.5, -29.3))
		add(Spring.new(), Vector3(5.6, -0.5, -27.6))

	# Sliding platforms over the gap, side by side, so only the jump on
	# needs timing.
	for z in [-37.0, -41.5]:
		add(MovingPlatform.make(Vector3(4, 0, 0), 4.0, 0.0, Vector3(2, 0.4, 3)), Vector3(-2, 1.5, z))
	if adventure:
		add(Pickup.make("coin"), Vector3(0, 2.6, -39.25))
		add(Pickup.make("coin"), Vector3(0, 2.6, -43.75))

	# The turn: the course heads west from here, up the high shelf.
	land(-4, -52, 4, -45, 1.5, 3)
	land(-12, -52, -4, -45, 4.0, 6)
	add(Spring.new(), Vector3(-3.0, 1.5, -46.2))
	add(_sign("Too high? Crouch, then jump. Or jump twice.", Vector3.BACK), Vector3(2.5, 1.5, -46))
	camera_zone(Vector3(-46, -12, -60), Vector3(-1, 20, -38), 90.0, 30.0, 10.0)
	if adventure:
		add(_checkpoint(Vector3.LEFT), Vector3(1, 1.5, -48.5))
		add(_checkpoint(Vector3.LEFT), Vector3(-6, 4.0, -46))
		for x in [-6, -8, -10]:
			add(Pickup.make("coin"), Vector3(x, 4.1, -48.5))

	# The long gap, with a stepping stone in the middle for the slow way.
	ledge(-16, -50, -14, -48, 3.0)
	add(_sign("Running? Crouch, then jump for a long jump.", Vector3.LEFT), Vector3(-11, 4.0, -46))

	# The mill: conveyor belts in the middle push back towards the start;
	# the sides are quicker but the spikes come up.
	land(-34, -52, -19, -45, 3.0, 3)
	add(Conveyor.make(10, Vector3.RIGHT, 3.0), Vector3(-31, 3.0 - 0.33, -48.5))
	for i in 6:
		add(SpikeTrap.make(i * 0.15), Vector3(-21.5 - i * 1.8, 3.0, -46.0))
		add(SpikeTrap.make(0.5 + i * 0.15), Vector3(-21.5 - i * 1.8, 3.0, -51.0))
	if adventure:
		for x in [-23, -26, -29]:
			add(Pickup.make("coin"), Vector3(x, 3.5, -48.5))

	# The finish.
	land(-42, -53, -34, -44, 3.0, 3)
	var flag := FinishFlag.new()
	flag.facing = Vector3.LEFT
	add(flag, Vector3(-38, 3.0, -48.5))
	for z in [-52.5, -44.5]:
		tree(Vector3(-41, 3.0, z), "tree-pine")
	finish()


func _sign(text: String, face: Vector3) -> SignPost:
	var s := SignPost.new()
	s.text = text
	s.facing = face
	return s


func _checkpoint(face: Vector3) -> Checkpoint:
	var c := Checkpoint.new()
	c.facing = face
	return c
