class_name ToyTrainExpress
extends Level
## Course 3 of Frosty Peaks: rides on giant toy trains. Board one at the
## start and ride north to the next platform, cross three lines of trains
## shuttling side to side (only when they stop in a row), head west (where
## the camera turns) over spikes and a snowball lane, ride another train
## north over a gap, and climb a stack of presents up to the station and the
## flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge reached by riding a
## crossing train to its far end, and checkpoints; the flag gives the star.
## Speedrun: just the course and the clock.

const STAR := "frosty/toytrain"
const GEM := "frosty/gem_toytrain"
## The crossing trains share a beat, so they stop in a row together.
const LANE_PHASE := 7.8
## And the second ride's, so it's in when a quick runner gets there.
const LOCAL_PHASE := 8.8

## The train from the start (for tests).
var express: FrostyTrain
## The three crossing trains, south to north.
var lanes: Array[FrostyTrain] = []
## The second train to ride.
var local: FrostyTrain


func _init() -> void:
	super()
	title = "Toy Train Express"
	spawn = Vector3(4, 1, 3)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The start, beside the train.
	land(1, -8, 7, 6, 1.0, 3, "snow")
	add_sign("Hop on the toy train and ride it. Step off when it stops!", Vector3(6.2, 1.0, 0.5))
	express = add(FrostyTrain.make(Vector3.FORWARD, 20.0, ["loco", "wagon", "wagon"], 4.0, 2.5), Vector3(0, 0.15, -10.55)) as FrostyTrain
	rails(Vector3(0, 0, 0.5), Vector3(0, 0, -30.6))
	for z in [-9, -13, -17, -21]:
		add_coin(Vector3(0, 1.7, z))

	# The far platform, and three lines of trains to cross.
	land(-7, -31, -1, -18, 1.0, 3, "snow")
	add_checkpoint(Vector3(-5.5, 1.0, -20.5), Vector3.FORWARD)
	add_heart(Vector3(-6, 1.0, -26))
	add_sign("Wait for all three trains to stop in a row, then run across them!", Vector3(-6.3, 1.0, -29.2))
	for i in 3:
		var z := -32.0 - 2.0 * i
		var dir := Vector3.RIGHT if i % 2 == 0 else Vector3.LEFT
		var nose := Vector3(1.3 if i % 2 == 0 else -9.3, 0.15, z)
		lanes.append(add(FrostyTrain.make(dir, 12.0, ["loco", "wagon", "wagon"], 2.5, 1.5, LANE_PHASE), nose) as FrostyTrain)
		rails(Vector3(-22, 0, z), Vector3(14.5, 0, z))
	add_coin(Vector3(-4, 1.6, -34))
	if not is_speedrun():
		# Off the racing line: ride the first crossing train to its far end.
		ledge(8, -31, 12, -28, 1.0, "snow")
		add_gem(GEM, Vector3(10.6, 1.2, -29.4))
		add_heart(Vector3(8.8, 1.0, -28.7))

	# Across, and west.
	land(-12, -48, 0, -37, 1.0, 3, "snow")
	add_checkpoint(Vector3(-1.5, 1.0, -39.5), Vector3.LEFT)
	add_heart(Vector3(-1.2, 1.0, -46.6))
	coin_line(Vector3(-6, 1.6, -43.5), Vector3(-10, 1.6, -43.5), 3)
	camera_zone(Vector3(-56, -6, -56), Vector3(0.5, 20, -37.3), 90.0, 30.0, 10.0)

	# A row of spikes, and a snowman rolling snowballs across the way.
	land(-26, -47, -12, -40, 1.0, 3, "snow")
	for i in 7:
		add(SpikeTrap.make(i * 0.08), Vector3(-15.5, 1.0, -46.5 + i))
	add(FrostyThrower.snowman(Vector3.BACK, 2.2, 0.3, 5.0), Vector3(-21.5, 1.0, -46.2))
	add_coin(Vector3(-15.5, 2.6, -43.5))
	add_coin(Vector3(-21.5, 2.6, -43.5))

	# Another train, north over the gap.
	land(-34, -47, -26, -40, 1.0, 3, "snow")
	add_checkpoint(Vector3(-26.8, 1.0, -41), Vector3.LEFT)
	local = add(FrostyTrain.make(Vector3.FORWARD, 18.0, ["loco", "wagon", "wagon"], 3.5, 2.0, LOCAL_PHASE), Vector3(-35, 0.15, -50.55)) as FrostyTrain
	rails(Vector3(-35, 0, -39.6), Vector3(-35, 0, -68.6))
	for z in [-50, -54, -58]:
		add_coin(Vector3(-35, 1.7, z))

	# Up a stack of presents to the station.
	land(-34, -74, -24, -58, 1.0, 3, "snow")
	add_checkpoint(Vector3(-25.5, 1.0, -59.5), Vector3.FORWARD)
	add_heart(Vector3(-25.4, 1.0, -72.6))
	camera_zone(Vector3(-56, -6, -100), Vector3(-10, 30, -56), 0.0, 30.0, 10.0, false, 1)
	FrostyBuild.present(self, Vector3(-29, 1.0, -67.5), 2.4, 1.4, 0)
	FrostyBuild.present(self, Vector3(-29, 1.0, -70.8), 2.4, 2.8, 1, 15.0)
	add_coin(Vector3(-29, 3.0, -67.5))
	add_coin(Vector3(-29, 4.4, -70.8))
	land(-40, -90, -22, -74, 4.5, 6, "snow")
	add_flag(Vector3(-29, 4.5, -81), Vector3.FORWARD)
	add(FrostyTrain.make(Vector3.FORWARD, 0.0, ["loco", "wagon"]), Vector3(-37.5, 4.65, -86))
	rails(Vector3(-37.5, 4.5, -75), Vector3(-37.5, 4.5, -88))
	FrostyBuild.cabin(self, -26, -89, 2, 2, 4.5, Vector3.LEFT)
	_trim()
	finish()


## Toy train rails from `a` to `b` (a straight line along x or z), their
## tops 0.15 over the y given.
func rails(a: Vector3, b: Vector3) -> void:
	var along := b - a
	var n := maxi(1, int(roundf(along.length() / 4.0)))
	var step := along / n
	var turn := 0.0 if absf(along.x) > absf(along.z) else 90.0
	for i in n:
		var at := a + step * (i + 0.5) + Vector3(0, -0.05, 0)
		FrostyBuild.put(self, "holiday:trainset-rail-detailed-straight", at, turn, Vector3(step.length() / 0.5, 5.0, 6.5))


## Lanterns, trees, candy canes and presents round the edges.
func _trim() -> void:
	for at in [Vector3(1.6, 1.0, 5.4), Vector3(6.4, 1.0, 5.4), Vector3(1.6, 1.0, -7.4), Vector3(-1.6, 1.0, -18.6), Vector3(-0.6, 1.0, -37.6), Vector3(-33.4, 1.0, -58.6), Vector3(-39.4, 4.5, -74.6), Vector3(-22.6, 4.5, -74.6)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for at in [Vector3(-6.3, 1.0, -18.7), Vector3(-11.2, 1.0, -47.2), Vector3(-39, 4.5, -89), Vector3(-24.5, 1.0, -58.6)]:
		tree(at, "holiday:tree-decorated-snow", 1.3)
	for at in [Vector3(6.2, 1.0, -7.2), Vector3(-6.2, 1.0, -22.5), Vector3(-25.2, 1.0, -46.2), Vector3(-33.2, 1.0, -40.8), Vector3(-23.6, 4.5, -81.5), Vector3(-33.4, 1.0, -73.4)]:
		deco("holiday:" + FrostyBuild.PRESENTS[int(absf(at.x + at.z)) % 4], at, at.z * 40.0, 1.6)
	for x in [-12.5, -25.5]:
		deco("holiday:candy-cane-red", Vector3(x, 1.0, -40.4), 0.0, 2.5)
		deco("holiday:candy-cane-green", Vector3(x, 1.0, -46.6), 0.0, 2.5)
	deco("holiday:snowman", Vector3(5.8, 1.0, -3.5), -40.0, 1.2)
	deco("holiday:reindeer", Vector3(-32, 4.5, -88), 0.0, 1.6)
	tree(Vector3(-11.3, 1.0, -37.8), "tree-pine-snow-small")
