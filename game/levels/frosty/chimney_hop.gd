class_name ChimneyHop
extends Level
## Course 2 of Frosty Peaks: over the rooftops of a snowy street. A spring
## up onto the first roof, a run along the ridges (hopping a chimney), a
## double jump up to a higher house, a snowball lane on a terrace, a kick up
## between two tall chimneys, then west (where the camera turns) over snow
## shelves that crumble and up three chimney pots, to the flag on the
## square.
##
## Adventure: coins, hearts, a hidden gem on a ledge beside the terrace and
## checkpoints; the flag gives the star. Speedrun: just the course and the
## clock.

const STAR := "frosty/chimneys"
const GEM := "frosty/gem_chimneys"


func _init() -> void:
	super()
	title = "Chimney Hop"
	spawn = Vector3(0, 0, 10)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 10.0, false]


func build() -> void:
	# The street, and the spring up onto the first roof.
	land(-4, -13, 4, 12, 0, 3, "snow")
	add_sign("Bounce up onto the roofs and run along them. Don't fall between the houses!", Vector3(-2.5, 0, 9))
	add(FrostyThrower.snowman(Vector3.LEFT, 2.2, 0.4, 5.0), Vector3(3.3, 0, 4))
	add_checkpoint(Vector3(2.5, 0, -1), Vector3.FORWARD)
	add_coin(Vector3(0, 1.6, 4))
	add(Spring.new(), Vector3(0, 0, -4.3))
	FrostyBuild.cabin(self, -2, -12, 2, 3, 0.0, Vector3.LEFT)
	coin_line(Vector3(0, 3.8, -7), Vector3(0, 3.8, -11), 3)

	# The second house, with a chimney on its ridge to hop.
	land(-3, -22, 3, -14, 0, 3, "snow")
	FrostyBuild.cabin(self, -2, -21, 2, 3, 0.0, Vector3.RIGHT, false)
	chimney(Vector3(0, 3.0, -19), 2)
	add_coin(Vector3(0, 5.6, -19))

	# Up to a higher house: a double jump.
	land(-3, -30, 3, -22, 2.0, 5, "snow")
	FrostyBuild.cabin(self, -2, -29, 2, 2, 2.0, Vector3.LEFT)
	add_heart(Vector3(-2.4, 2.0, -23))
	coin_line(Vector3(0, 5.0, -20.5), Vector3(0, 6.2, -23.5), 3)

	# The terrace: a snowman rolls snowballs across, and two tall chimneys
	# stand at the far end to kick up between.
	land(-3, -40, 3, -32, 4.0, 3, "snow")
	add_checkpoint(Vector3(-2, 4.0, -33), Vector3.FORWARD)
	add(FrostyThrower.snowman(Vector3.LEFT, 2.4, 0.2, 5.0), Vector3(2.4, 4.0, -35.5))
	add_sign("Jump at one chimney, then kick off it to the other, and up you go.", Vector3(-2.3, 4.0, -37), Vector3.RIGHT)
	stack(-2, -40, 2, 2, 4.0, 8.5)
	stack(1, -40, 1, 2, 4.0, 9.0)
	coin_line(Vector3(0.5, 5.0, -39), Vector3(0.5, 8.0, -39), 4)
	if not is_speedrun():
		# Off the racing line: a ledge beside the terrace, a spring back up.
		ledge(4, -40, 7, -36, 2.5, "snow")
		add_gem(GEM, Vector3(6, 2.7, -38.8))
		add(Spring.new(), Vector3(4.6, 2.5, -36.6))
		add_heart(Vector3(6.2, 2.5, -36.7))

	# Across to a house whose roof looks west over the shelves.
	land(-3, -51, 3, -43, 4.0, 5, "snow")
	FrostyBuild.cabin(self, -2, -50, 2, 3, 4.0, Vector3.RIGHT)
	camera_zone(Vector3(-50, -4, -60), Vector3(-1.4, 24, -40), 90.0, 30.0, 10.0)
	for x in [-4.8, -8.8, -12.8]:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-snow-low"), Vector3(x, 6.0, -47))
		add_coin(Vector3(x, 7.2, -47))

	# Up three chimney pots, then down to the square and the flag.
	for i in 3:
		stack(-18 - i * 4, -48, 2, 2, 4.0, 6.6 + i * 0.6)
		add_coin(Vector3(-17 - i * 4, 7.8 + i * 0.6, -47))
	land(-42, -53, -29, -41, 6.0, 4, "snow")
	add_checkpoint(Vector3(-31, 6.0, -43), Vector3.LEFT)
	add_flag(Vector3(-35.5, 6.0, -47), Vector3.LEFT)
	tree(Vector3(-39.5, 6.0, -47), "holiday:tree-decorated-snow", 1.6)
	_trim()
	finish()


## A brick chimney `bricks` metres tall on a roof, its foot at `at`, with a
## cap of snow.
func chimney(at: Vector3, bricks: int) -> void:
	for i in bricks:
		piece("brick", at + Vector3(0, i, 0), 0.0, 2.0)
	piece("block-snow-low", at + Vector3(0, bricks, 0), 0.0, 0.95)
	solid(at + Vector3(-0.5, -1.0, -0.5), at + Vector3(0.5, bricks + 0.47, 0.5))


## A tall brick stack `w` by `d` metres from (x, z), from `y` up to `top`,
## capped with snow.
func stack(x: int, z: int, w: int, d: int, y: float, top: float) -> void:
	var cap := top - 0.47
	var h := int(ceilf(cap - y))
	for i in w:
		for j in d:
			for k in h:
				piece("brick", Vector3(x + i + 0.5, cap - h + k, z + j + 0.5), 0.0, 2.0)
			piece("block-snow-low", Vector3(x + i + 0.5, cap, z + j + 0.5), 0.0, 0.95)
	solid(Vector3(x, y, z), Vector3(x + w, top, z + d))


## Lanterns, presents and snowmen in the yards.
func _trim() -> void:
	for at in [Vector3(-2.6, 0, -13), Vector3(2.6, 0, -21.6), Vector3(-29.6, 6.0, -41.6), Vector3(-29.6, 6.0, -52.4), Vector3(-3.4, 0, 11.4), Vector3(3.4, 0, 11.4)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for at in [Vector3(2.5, 0, -4), Vector3(2.4, 0, -15), Vector3(2.5, 2.0, -22.6), Vector3(-2.4, 4.0, -43.6), Vector3(-40, 6.0, -42)]:
		deco("holiday:" + FrostyBuild.PRESENTS[int(absf(at.x * 3.0 + at.z)) % 4], at, at.z * 25.0, 1.6)
	deco("holiday:snowman-hat", Vector3(-2.5, 0, -2.5), 20.0, 1.3)
	deco("holiday:snowman", Vector3(2.4, 4.0, -43.8), -30.0, 1.2)
	deco("holiday:reindeer", Vector3(-40, 6.0, -51.5), 60.0, 1.6)
	for at in [Vector3(-2.5, 0, -14.6), Vector3(2.5, 2.0, -29.4)]:
		tree(at, "tree-pine-snow-small")
