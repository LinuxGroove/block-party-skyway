class_name GiftStackClimb
extends Level
## Course 4 of Frosty Peaks: once round a giant tree, up the presents piled
## under it. A spring onto the first present, crumbling snow shelves up the
## east side, a snowball lane and a kick up between two tall presents on
## the north side, and a sliding block of snow down the west side to the
## top present and the flag. The camera looks in at the tree from outside,
## turning at each corner.
##
## Adventure: coins, hearts, a hidden gem on a ledge below the east side (a
## spring bounces you back up) and checkpoints; the flag gives the star.
## Speedrun: just the course and the clock.

const STAR := "frosty/giftstack"
const GEM := "frosty/gem_giftstack"
## Where the sliding block of snow starts, and how far it goes.
const LIFT_HOME := Vector3(-10, 11.3, -3)
const LIFT_TRAVEL := Vector3(0, 0, 8)
const LIFT_PERIOD := 5.0
const LIFT_PHASE := 0.44

## The sliding block on the west side (for tests).
var lift: MovingPlatform


func _init() -> void:
	super()
	title = "Gift Stack Climb"
	spawn = Vector3(-5, 0, 13)
	spawn_facing = Vector3.RIGHT
	camera_base = [0.0, 30.0, 10.0, false]


func build() -> void:
	# The tree, on its island, and the yard in front where the climb starts.
	land(-8, -8, 8, 7, 0, 4, "snow")
	tree(Vector3.ZERO, "holiday:tree-decorated-snow", 8.0)
	land(-13, 7, 8, 18, 0, 3, "snow")
	add_sign("Climb the presents all the way round the tree, up to the top!", Vector3(-3.4, 0, 16), Vector3.BACK)
	add(FrostyThrower.snowman(Vector3.BACK, 2.4, 0.2, 5.0), Vector3(-0.5, 0, 6.2))
	coin_line(Vector3(-3, 0.8, 12.5), Vector3(3, 0.8, 11.5), 4)
	add(Spring.new(), Vector3(5.6, 0, 10.5))

	# The east side: the first present, then snow shelves that crumble.
	land(8, 8, 12, 12, 0, 3, "snow")
	FrostyBuild.gift(self, Vector3(8, 0, 8), Vector3(12, 3.5, 12), 0)
	add_checkpoint(Vector3(11, 3.5, 11.2), Vector3.FORWARD)
	camera_zone(Vector3(7.5, 2.5, -7.6), Vector3(28, 30, 16), 90.0, 30.0, 10.0, false, 1)
	var shelves := [[5.0, 4.0], [1.5, 4.6], [-2.0, 5.2], [-5.5, 5.8]]
	for sh in shelves:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-snow-low"), Vector3(10, sh[1], sh[0]))
		add_coin(Vector3(10, sh[1] + 1.2, sh[0]))
	if not is_speedrun():
		# Off the racing line: a ledge below the first present, and a spring
		# back up onto it.
		ledge(13, 4, 17, 9, 1.0, "snow")
		add_gem(GEM, Vector3(16, 1.2, 4.8))
		add_heart(Vector3(16.2, 1.0, 8.3))
		add(Spring.new(), Vector3(14.2, 1.0, 8.0))

	# The north side: a long present with a snowman on it, and two tall ones
	# to kick up between.
	land(8, -12, 12, -8, 0, 3, "snow")
	FrostyBuild.gift(self, Vector3(8, 0, -12), Vector3(12, 3.4, -8), 1)
	FrostyBuild.gift(self, Vector3(8, 3.4, -11.6), Vector3(11.6, 6.3, -8), 0)
	add_checkpoint(Vector3(11, 6.3, -11), Vector3.LEFT)
	camera_zone(Vector3(-6.6, 5.0, -30), Vector3(28, 30, -7.8), 180.0, 30.0, 10.0, false, 1)
	land(-2, -12, 8, -8, 0, 3, "snow")
	FrostyBuild.gift(self, Vector3(-2, 0, -12), Vector3(8, 6.3, -8), 0)
	add(FrostyThrower.snowman(Vector3.FORWARD, 2.2, 0.0, 5.0), Vector3(4.5, 6.3, -8.5))
	add_heart(Vector3(7.4, 6.3, -11.4))
	add_sign("Jump at one present, then kick off it to the other, and up you go.", Vector3(2.6, 6.3, -11.4), Vector3.FORWARD)
	FrostyBuild.gift(self, Vector3(-2, 6.3, -10), Vector3(0, 10.8, -8), 1)
	FrostyBuild.gift(self, Vector3(1, 6.3, -10), Vector3(2, 11.3, -8), 0)
	coin_line(Vector3(0.5, 7.6, -9), Vector3(0.5, 10.6, -9), 3)

	# The west side: across to the corner present, then ride the sliding
	# block of snow over the gap.
	land(-12, -12, -8, -8, 0, 3, "snow")
	FrostyBuild.gift(self, Vector3(-12, 0, -12), Vector3(-4.5, 5.8, -5), 1)
	FrostyBuild.gift(self, Vector3(-11.6, 5.8, -11.6), Vector3(-4.5, 11.3, -5), 0)
	add_checkpoint(Vector3(-10.6, 11.3, -10.6), Vector3.BACK)
	camera_zone(Vector3(-30, 9.0, -30), Vector3(-4.6, 30, 30), 270.0, 30.0, 10.0, false, 1)
	lift = add(MovingPlatform.make(LIFT_TRAVEL, LIFT_PERIOD, LIFT_PHASE, Vector3(3, 0.5, 3), "block-snow-low"), LIFT_HOME) as MovingPlatform
	coin_line(Vector3(-10, 12.5, -0.5), Vector3(-10, 12.5, 3.5), 3)

	# The top: a snowman rolls snowballs across, and the flag on the last
	# present.
	FrostyBuild.gift(self, Vector3(-12, 0, 7), Vector3(-7, 6.0, 13), 0)
	FrostyBuild.gift(self, Vector3(-11.6, 6.0, 7), Vector3(-7.4, 11.3, 12.6), 1)
	add(FrostyThrower.snowman(Vector3.RIGHT, 2.4, 0.5, 5.0), Vector3(-11.2, 11.3, 8.6))
	FrostyBuild.gift(self, Vector3(-11, 11.3, 10.2), Vector3(-8, 12.3, 12.4), 0)
	add_flag(Vector3(-9.5, 12.3, 11.4), Vector3.BACK)
	_trim()
	finish()


## Presents, candy canes, lanterns and a reindeer round the tree and the
## yard.
func _trim() -> void:
	var gifts := [Vector3(3.5, 0, 3.5), Vector3(-4, 0, 2.5), Vector3(2.5, 0, -4.5), Vector3(-3.5, 0, -3.8), Vector3(5, 0, -1), Vector3(-5.5, 0, -0.5), Vector3(1, 0, 4.8)]
	for i in gifts.size():
		var at: Vector3 = gifts[i]
		deco("holiday:" + FrostyBuild.PRESENTS[i % 4], at, i * 47.0, 3.0 + (i % 3) * 0.6)
	for at in [Vector3(-12.4, 0, 17.4), Vector3(7.4, 0, 17.4), Vector3(-12.4, 0, 7.6)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for x in [-9, -1, 3]:
		deco("holiday:candy-cane-red", Vector3(x, 0, 17.4), 0.0, 2.5)
	deco("holiday:candy-cane-green", Vector3(7.4, 0, 7.6), 0.0, 2.5)
	deco("holiday:reindeer", Vector3(5.5, 0, 15.5), -60.0, 1.6)
	deco("holiday:sled", Vector3(3.8, 0, 16.2), -70.0, 1.6)
	deco("holiday:snowman-hat", Vector3(-11, 0, 15.5), 30.0, 1.3)
	for at in [Vector3(6.5, 0, -6.2), Vector3(7, 0, 5.5), Vector3(-7.2, 0, 4.5)]:
		tree(at, "tree-pine-snow-small")
