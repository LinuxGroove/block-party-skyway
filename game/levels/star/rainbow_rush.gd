class_name RainbowRush
extends StarCourse
## Star Road course 1, Sunny Isles meets Frosty Peaks: a saw alley and a
## wave of spikes, a rainbow path onto an icy bridge swept by two spinners,
## sliding platforms, a snowy shelf with spikes where the course turns
## west, ice blocks that drop when stood on, saws sliding across a strip of
## ice, and a rainbow ramp up to the flag.

const STAR := "star/rainbow_rush"
const GEM := "star/gem_rainbow_rush"


func _init() -> void:
	super()
	title = "Rainbow Rush"
	cloud_center = Vector3(-15, 0, -35)
	cloud_spread = 70.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "The Star Road starts here! Jump the saws and spikes, then mind the ice.")
	for x in [-2.5, 2.5]:
		deco("flowers", Vector3(x, 0, 3))
	tree(Vector3(-2.4, 0, -4.6), "tree")
	tree(Vector3(2.4, 0, -4.6), "tree-pine-snow")

	# The saw alley: two saws slide across, then a wave of spikes.
	land(-2, -21, 2, -6, 0, 3)
	add(Saw.make(Vector3(3.2, 0, 0), 1.6, 0.0), Vector3(-1.6, 0, -10))
	add(Saw.make(Vector3(-3.2, 0, 0), 1.6, 0.5), Vector3(1.6, 0, -14))
	for i in 4:
		add(SpikeTrap.make(i * 0.1), Vector3(-1.5 + i, 0, -18))
	for z in [-8.0, -12.0, -16.0, -20.0]:
		add_coin(Vector3(0, 0.6, z))
	for z in [-7.0, -11.0, -15.0, -19.0]:
		deco("fence-low-straight", Vector3(-2.1, 0, z), 90.0)
		deco("fence-low-straight", Vector3(2.1, 0, z), 90.0)

	# A rainbow path onto the icy bridge.
	rainbow_path(Vector3(0, 0, -20.5), Vector3(0, 0, -26.5))
	add_checkpoint(Vector3(-1.2, 0, -19.6), Vector3.FORWARD)
	land(-2, -42, 2, -26, -1, 2, "snow")
	ice(-2, -42, 2, -26, 0)
	add_sign("Ice! Hard to stop on. Wait for the arms to pass, then go.", Vector3(1.6, 0, -20.4))
	# Two spinners on snowy posts sweep across it, turning opposite ways.
	land(3, -31, 4, -30, 0, 3, "snow")
	land(-4, -38, -3, -37, 0, 3, "snow")
	add(Spinner.make(4, 100.0), Vector3(3.5, 0, -30.5))
	var s2 := Spinner.make(4, -100.0)
	s2.phase = 180.0
	add(s2, Vector3(-3.5, 0, -37.5))
	for z in [-29.0, -33.0, -37.0, -41.0]:
		add_coin(Vector3(0, 0.5, z))

	# Off the racing line: a ledge below the end of the bridge, with a spring.
	if not is_speedrun():
		ledge(4, -43, 7, -39, -2.0, "snow")
		add_gem(GEM, Vector3(5.8, -1.8, -40.0))
		add(Spring.new(), Vector3(4.6, -2.0, -41.8))
		add_heart(Vector3(6.2, -2.0, -42.2))

	# A snowy landing, then platforms sliding over the gap.
	land(-3, -48, 3, -42, 0, 3, "snow")
	add_checkpoint(Vector3(-1.6, 0, -43.5), Vector3.FORWARD)
	deco("holiday:snowman", Vector3(2.3, 0, -46.8), 200.0, 1.0)
	deco("holiday:present-a-cube", Vector3(-2.4, 0, -47.3), 15.0, 1.2)
	for z in [-50.5, -55.0]:
		add(MovingPlatform.make(Vector3(4, 0, 0), 3.6, 0.0, Vector3(2, 0.4, 3)), Vector3(-2, 0, z))
	add_coin(Vector3(0, 1.1, -50.5))
	add_coin(Vector3(0, 1.1, -55.0))

	# The turn: a snowy landing, and a high shelf to the west.
	land(-4, -66, 4, -58, 0, 3, "snow")
	land(-14, -66, -4, -58, 2.5, 5, "snow")
	add_checkpoint(Vector3(1.5, 0, -60), Vector3.LEFT)
	add_sign("Too high? Crouch, then jump. Or jump twice.", Vector3(2.5, 0, -64), Vector3.LEFT)
	camera_zone(Vector3(-90, -10, -76), Vector3(-1, 20, -57), 90.0, 30.0, 10.0)
	tree(Vector3(-13, 2.5, -65), "tree-pine-snow")
	tree(Vector3(-13, 2.5, -59), "tree-snow")
	# Two rows of spikes across the shelf.
	for x in [-8.0, -11.0]:
		for i in 4:
			add(SpikeTrap.make(0.3 * i + (0.5 if x < -9.0 else 0.0)), Vector3(x, 2.5, -63.5 + i))
	for x in [-6.0, -9.5, -12.8]:
		add_coin(Vector3(x, 3.0, -62))

	# Ice blocks that drop a moment after you land: keep moving.
	add_sign("These ice blocks drop when you land. Keep hopping!", Vector3(-5.2, 2.5, -59), Vector3.LEFT)
	for i in 6:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-moving-blue", 0.5), Vector3(-16.5 - i * 3.5, 2.5, -62))
		add_coin(Vector3(-16.5 - i * 3.5, 3.6, -62))

	# A snowy step, then saws sliding across a strip of ice.
	land(-41, -64, -37, -60, 2.5, 2, "snow")
	add_checkpoint(Vector3(-39, 2.5, -63.2), Vector3.LEFT)
	add_heart(Vector3(-38, 2.5, -60.8))
	land(-55, -64, -41, -60, 1.5, 2, "snow")
	ice(-55, -64, -41, -60, 2.5)
	for i in 3:
		add(Saw.make(Vector3(0, 0, 3.2), 1.5, 0.33 * i), Vector3(-43.5 - i * 4.0, 2.5, -63.6))
		add_coin(Vector3(-45.5 - i * 4.0, 3.0, -62))

	# A rainbow ramp up to the finish.
	rainbow_path(Vector3(-54.5, 2.5, -62), Vector3(-62.5, 4.0, -62))
	land(-71, -67, -62, -57, 4.0, 4)
	goal(Vector3(-67, 4.0, -62), Vector3.LEFT)
	for z in [-66.0, -58.0]:
		tree(Vector3(-70, 4.0, z), "tree-pine")
	coin_line(Vector3(-56, 2.8, -62), Vector3(-61, 3.7, -62), 3)
	glow(Vector3(-24, 7, -70), 2.0)
	glow(Vector3(-48, 8, -54), 1.6, Color("ffb3f0"))
	glow(Vector3(6, 6, -36), 1.6, Color("ffb3f0"))
	add(StarRainbow.make(16.0, 90.0, 0.5), Vector3(-86, -4, -62))
	finish()
