class_name IceRinkRush
extends Level
## Course 1 of Frosty Peaks: a slippery lane with snowmen rolling snowballs
## across it, a hop over ice floes too slick to stop on, the big rink full
## of skating penguins (heading west, where the camera turns), a flight of
## icy steps and a row of crumbling snow shelves to the flag.
##
## Adventure: coins, hearts, a hidden gem below the turn and checkpoints;
## the flag gives the star. Speedrun: just the course and the clock.

const STAR := "frosty/icerink"
const GEM := "frosty/gem_icerink"


func _init() -> void:
	super()
	title = "Ice Rink Rush"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	# The start pad.
	land(-3, -6, 3, 4, 0, 3, "snow")
	add_sign("Ice is slippery! Jump from it to keep your speed, and hop over the snowballs.", Vector3(-2, 0, 1))
	add_sign("Don't stop on the ice floes: keep hopping!", Vector3(2, 0, 1))
	add_checkpoint(Vector3(-1.5, 0, -3.5), Vector3.FORWARD)
	for x in [-2.4, 2.4]:
		deco("holiday:candy-cane-red", Vector3(x, 0, -5.4), 0.0, 2.5)

	# The lane: two snowmen roll snowballs across it.
	FrostyBuild.ice(self, -2, -28, 2, -6, 0.0)
	land(-5, -12, -3, -10, 0, 2, "snow")
	add(FrostyThrower.snowman(Vector3.RIGHT, 2.2, 0.0, 5.0), Vector3(-4, 0, -11))
	land(3, -21, 5, -19, 0, 2, "snow")
	add(FrostyThrower.snowman(Vector3.LEFT, 2.4, 0.5, 5.0), Vector3(4, 0, -20))
	for z in [-8, -14, -17, -23, -26]:
		add_coin(Vector3(0, 0.1, z))

	# Ice floes over the gap.
	for z in [-30, -35, -40]:
		FrostyBuild.ice(self, -1, z - 3, 1, z, 0.0)
		add_coin(Vector3(0, 1.4, z + 1))

	# The turn: the course heads west across the rink from here.
	land(-4, -51, 4, -45, 0, 3, "snow")
	add_checkpoint(Vector3(2.5, 0, -47), Vector3.LEFT)
	camera_zone(Vector3(-50, -10, -60), Vector3(1.5, 20, -43.5), 90.0, 30.0, 10.0)
	if not is_speedrun():
		# Off the racing line: a ledge below the east edge, a spring back up.
		ledge(5, -51, 9, -46, -2.5, "snow")
		add_gem(GEM, Vector3(7.8, -2.3, -49.8))
		add_heart(Vector3(7.8, -2.5, -47))
		add(Spring.new(), Vector3(5.7, -2.5, -48.5))

	# The rink, with boards along both sides and penguins skating across.
	FrostyBuild.ice(self, -34, -51, -4, -45, 0.0)
	land(-34, -52, -4, -51, 0.8, 1, "snow")
	land(-34, -45, -4, -44, 0.8, 1, "snow")
	for i in 4:
		var x := -10.0 - i * 6.0
		add(Critter.make("animal-penguin", Vector3(0, 0, 4.6), 2.6 + i * 0.3, i * 0.3), Vector3(x, 0, -50.3))
	for x in [-7, -13, -19, -25, -31]:
		add_coin(Vector3(x, 0.1, -48))
	add_heart(Vector3(-16, 0.8, -44.5))

	# Off the rink, over a row of spikes, onto the icy steps.
	land(-42, -54, -34, -42, 0, 3, "snow")
	for i in 4:
		add(SpikeTrap.make(i * 0.1), Vector3(-35.5, 0, -46.5 - i))
	add_checkpoint(Vector3(-40.5, 0, -44), Vector3.FORWARD)
	camera_zone(Vector3(-43, -10, -100), Vector3(-33.5, 20, -52), 0.0, 30.0, 10.0, false, 1)
	for i in 3:
		var z := -55 - i * 4
		FrostyBuild.ice(self, -40, z - 3, -36, z, 1.0 + i)
		add_coin(Vector3(-38, 2.2 + i, z - 1.5))

	# A terrace, then snow shelves that crumble once stood on.
	land(-42, -71, -34, -67, 4.0, 3, "snow")
	add_checkpoint(Vector3(-40.5, 4.0, -68.5), Vector3.FORWARD)
	for z in [-73.5, -77.5, -81.5]:
		add(FallingPlatform.make(Vector3(2, 0.5, 2), "block-snow-low"), Vector3(-38, 4.0, z))
		add_coin(Vector3(-38, 5.2, z))

	# The finish.
	land(-42, -92, -34, -84, 4.0, 3, "snow")
	add_flag(Vector3(-38, 4.0, -88), Vector3.FORWARD)
	for x in [-41, -35]:
		tree(Vector3(x, 4.0, -91), "holiday:tree-decorated-snow", 1.3)
	_trim()
	finish()


## Snowmen, presents and lanterns round the edges.
func _trim() -> void:
	for at in [Vector3(-2.5, 0, 3.4), Vector3(2.5, 0, 3.4), Vector3(3.3, 0, -50.4), Vector3(-41.3, 0, -53.3), Vector3(-34.7, 0, -42.7), Vector3(-41.3, 4.0, -84.7), Vector3(-34.7, 4.0, -84.7)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for at in [Vector3(-3.5, 0, -46), Vector3(-41, 0, -42.8), Vector3(-35, 4.0, -67.8)]:
		deco("holiday:" + FrostyBuild.PRESENTS[int(absf(at.x + at.z)) % 4], at, at.x * 30.0, 1.6)
	deco("holiday:snowman-hat", Vector3(-41, 4.0, -67.8), 30.0, 1.3)
	for x in range(-33, -4, 3):
		deco("holiday:lights-colored", Vector3(x + 0.5, 0.8, -51.6), 0.0, 2.0)
		deco("holiday:lights-colored", Vector3(x + 0.5, 0.8, -44.4), 180.0, 2.0)
