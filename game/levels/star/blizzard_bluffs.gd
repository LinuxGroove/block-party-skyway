class_name BlizzardBluffs
extends StarCourse
## Star Road course 5, Frosty Peaks meets Gear Works: ice floes in a cross
## wind, a snowfield of spike traps, an icy bridge with saws and a gust,
## then four updrafts blown by big fans up a stair of snowy bluffs
## (penguins on one, ice and wind on another, spikes on the last), and a
## tailwind that carries you over the final gap to the flag.

const STAR := "star/blizzard_bluffs"
const GEM := "star/gem_blizzard_bluffs"
## The ice floes' centres; the wind blows across each, turn about.
const FLOES := [Vector3(0, 0, -10), Vector3(0, 0, -16), Vector3(0, 0, -22)]
const CROSSWIND := 8.0
const SPIKE_ROWS := [-30.0, -34.5]
## The icy bridge, and the saws sliding across it.
const BRIDGE_END := -56.0
const SAWS := [-44.0, -51.5]
## The bluffs: [near z, far z, top]. An updraft rises in the gap before
## each one, from a fan on a ledge.
const BLUFFS := [[-59.0, -67.0, 6.0], [-70.0, -78.0, 12.0], [-81.0, -87.0, 18.0], [-90.0, -100.0, 24.0]]
const UPDRAFT := 48.0
const TAILWIND := 20.0
const FINISH := Vector3(0, 21.0, -114.5)


func _init() -> void:
	super()
	title = "Blizzard Bluffs"
	cloud_center = Vector3(0, 0, -55)
	cloud_spread = 70.0


## Where the fan at the foot of the updraft before bluff `i` stands, a
## little below the ground you jump from.
static func updraft_foot(i: int) -> Vector3:
	var near: float = BLUFFS[i][0]
	var below := -2.0 if i == 0 else float(BLUFFS[i - 1][2]) - 2.0
	return Vector3(0, below, near + 1.5)


func build() -> void:
	start_pad(-3, -6, 3, 4, "Fans blow hard up here. Lean into the wind, and ride the updrafts.", "snow")
	tree(Vector3(-2.4, 0, -4.6), "tree-snow")
	tree(Vector3(2.4, 0, -4.6), "tree-pine-snow")
	deco("holiday:snowman", Vector3(2.3, 0, 3.0), 200.0, 1.0)

	# Ice floes, each with a fan blowing across it.
	for i in FLOES.size():
		var c: Vector3 = FLOES[i]
		var side := 1.0 if i % 2 == 0 else -1.0
		ice(-2, int(c.z) - 2, 2, int(c.z) + 2, 0)
		add(WindZone.make(Vector3(10, 4, 4), Vector3(side, 0, 0) * CROSSWIND), c + Vector3(0, -0.5, 0))
		_fan_post(Vector3(-3.5 * side, 0, c.z), Vector3(side, 0, 0))
		add_coin(c + Vector3(0, 0.5, 0))
	add_sign("Wind! It pushes you sideways on the ice, so steer against it.", Vector3(-2.0, 0, -5.0))

	# A snowfield with two rows of spike traps.
	land(-4, -40, 4, -26, 0, 4, "snow")
	add_checkpoint(Vector3(-3.0, 0, -27.0), Vector3.FORWARD)
	add_heart(Vector3(3.0, 0, -27.0))
	for r in SPIKE_ROWS.size():
		var z: float = SPIKE_ROWS[r]
		for i in 8:
			add(SpikeTrap.make(0.08 * i + 0.5 * r), Vector3(-3.5 + i, 0, z))
		add_coin(Vector3(0, 1.6, z))
	tree(Vector3(-3.4, 0, -38.8), "tree-pine-snow")
	tree(Vector3(3.4, 0, -38.6), "tree-snow")

	# An icy bridge: two saws sliding across, and a gust between them.
	land(-2, int(BRIDGE_END), 2, -40, -1, 2, "snow")
	ice(-2, int(BRIDGE_END), 2, -40, 0)
	for k in SAWS.size():
		var z: float = SAWS[k]
		var dir := 1.0 if k == 0 else -1.0
		add(Saw.make(Vector3(3.2 * dir, 0, 0), 1.7, 0.4 * k), Vector3(-1.6 * dir, 0, z))
	add(WindZone.make(Vector3(10, 4, 3), Vector3.LEFT * CROSSWIND * 0.75), Vector3(0, -0.5, -48.0))
	_fan_post(Vector3(3.5, 0, -48.0), Vector3.LEFT)
	for z in [-42.0, -47.5, -53.5]:
		add_coin(Vector3(0, 0.5, z))
	add_sign("Saws on the ice! Wait for a gap, then go.", Vector3(-2.6, 0, -39.0))

	# Four updrafts up a stair of bluffs.
	for i in BLUFFS.size():
		var foot := updraft_foot(i)
		var top: float = BLUFFS[i][2]
		add(WindZone.make(Vector3(3, top + 1.0 - foot.y, 3), Vector3.UP * UPDRAFT), foot)
		ledge(-2, int(foot.z - 1.5), 2, int(foot.z + 1.5), foot.y, "snow")
		var fan := StarFan.make(Vector3.UP, 1.1)
		fan.rise = top + 2.0 - foot.y
		add(fan, foot)
		coin_line(Vector3(0, top - 1.0, foot.z), Vector3(0, top + 2.0, foot.z - 1.2), 3)
		land(-4, int(BLUFFS[i][1]), 4, int(BLUFFS[i][0]), top - (1.0 if i == 1 else 0.0), 5, "snow")
	add_sign("Updrafts! Jump into the air above a fan and it lifts you up.", Vector3(-1.6, 0, -55.0))
	# Off the racing line: the gem on the first fan. The wind holds you
	# up, so pound down through it.
	if not is_speedrun():
		add_gem(GEM, updraft_foot(0) + Vector3(0.9, 0.4, 0.6))

	# The first bluff: penguins waddling across.
	var a: Array = BLUFFS[0]
	for k in 2:
		var dir := 1.0 if k == 0 else -1.0
		add(Critter.make("animal-penguin", Vector3(6.0 * dir, 0, 0), 3.2, 0.5 * k), Vector3(-3.0 * dir, a[2], -61.5 - 2.6 * k))
	add_checkpoint(Vector3(-3.2, a[2], -59.8), Vector3.FORWARD)
	deco("holiday:present-b-cube", Vector3(3.3, a[2], -66.3), 20.0, 1.2)

	# The second bluff: ice, with wind blowing across.
	var b: Array = BLUFFS[1]
	ice(-4, int(b[1]), 4, int(b[0]), b[2])
	add(WindZone.make(Vector3(9, 4, 6), Vector3.RIGHT * CROSSWIND * 0.75), Vector3(0, b[2] - 0.5, -74))
	_fan_post(Vector3(-4.6, b[2], -74), Vector3.RIGHT)

	# The third: a rest, and a checkpoint.
	var c3: Array = BLUFFS[2]
	add_checkpoint(Vector3(-3.2, c3[2], -81.8), Vector3.FORWARD)
	add_heart(Vector3(3.0, c3[2], -82.0))
	tree(Vector3(3.2, c3[2], -86.0), "tree-pine-snow")

	# The top bluff: a row of spikes, then a tailwind over the last gap.
	var d: Array = BLUFFS[3]
	for i in 8:
		add(SpikeTrap.make(0.1 * i), Vector3(-3.5 + i, d[2], -95.0))
	add(WindZone.make(Vector3(6, 8, 8), Vector3.FORWARD * TAILWIND), Vector3(0, d[2] - 5.0, -104))
	for x in [-3.0, 3.0]:
		add(StarFan.make(Vector3.FORWARD, 0.9), Vector3(x, d[2] + 1.1, -100.4))
	add_sign("A tailwind! Jump into it and let it carry you over.", Vector3(-2.6, d[2], -91.0))
	coin_line(Vector3(0, d[2] + 1.5, -102.0), Vector3(0, FINISH.y + 1.0, -108.5), 4)

	# The flag, on a snowy peak.
	land(-5, -119, 5, -108, FINISH.y, 4, "snow")
	goal(FINISH, Vector3.FORWARD)
	for x in [-4.0, 4.0]:
		tree(Vector3(x, FINISH.y, -117.5), "holiday:tree-decorated-snow", 1.0)
	deco("holiday:reindeer", Vector3(3.6, FINISH.y, -111.0), 210.0, 1.4)
	glow(Vector3(-8, 8, -36), 1.8)
	glow(Vector3(8, 20, -72), 1.6, Color("ffb3f0"))
	glow(Vector3(-7, 30, -112), 2.0)
	add(StarRainbow.make(16.0, 0.0, 0.5), Vector3(0, 10, -131))
	finish()


## A fan on a snowy post at `at`, blowing along `facing` (a grid
## direction across the course).
func _fan_post(at: Vector3, facing: Vector3) -> void:
	var px := floori(at.x)
	land(px, floori(at.z) - 1, px + 1, floori(at.z) + 1, at.y, 3, "snow")
	add(StarFan.make(facing, 0.9), at + Vector3(0, 1.15, 0))
