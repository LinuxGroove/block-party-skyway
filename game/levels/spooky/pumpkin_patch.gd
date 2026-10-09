class_name SpookyPumpkinPatch
extends Level
## Course 3 of Spooky Hollow: a pumpkin farm in the Hollow. Run north up
## the field while big pumpkins roll down the rows out of the hay, turn west
## and hop giant pumpkins bobbing in the swamp ditch (they sink, so keep
## going), then turn north past a zombie in the gate (jump on it) and two
## pacing vampires to the flag. The camera turns west over the ditch.
##
## Adventure: coins, a heart, checkpoints, and a hidden gem on the hay
## stack in the field's far corner, reached by a spring. Speedrun: the
## course and the clock.

const STAR := "spooky/pumpkin_patch"
const GEM := "spooky/gem_pumpkin_patch"
## The rows the pumpkins roll down, and the ditch's water.
const ROWS := [-9.0, -14.0, -19.0]
const DITCH_Y := -1.0

var rollers: Array[SpookyPumpkinRoller] = []
var bobbers: Array[SpookyBobbingPumpkin] = []
var gatekeeper: Critter
var vampires: Array[Critter] = []


func _init() -> void:
	super()
	title = "Pumpkin Patch"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


func build() -> void:
	_field()
	_ditch()
	_lane()
	finish()


# --- The field: pumpkins roll down the rows ------------------------------------

func _field() -> void:
	land(-3, -4, 3, 4, 0, 3)
	land(-5, -32, 5, -4, 0, 3)
	land(5, -26, 8, -4, 0, 2)
	add_sign("Pumpkins roll down the rows. Wait for a gap, or jump them as they come.", Vector3(-2, 0, 1.5))
	SpookyProps.lamp(self, Vector3(2.4, 0, 3.2))
	SpookyProps.fence(self, Vector3(-3, 0, 4), Vector3(-3, 0, -4), "grave:fence", 0.8, 1.0)
	SpookyProps.fence(self, Vector3(3, 0, 4), Vector3(3, 0, -4), "grave:fence", 0.8, 1.0)
	# Hay walls down both sides: the pumpkins come out of gaps in the east one
	# and squash against the west one.
	_hay_wall(-5, -26, -4, -4, 2)
	var from := -24.0
	for z in [-19.0, -14.0, -9.0]:
		_hay_wall(4, from, 5, z - 0.8, 2)
		from = z + 0.8
	_hay_wall(4, from, 5, -4, 2)
	for i in ROWS.size():
		var z: float = ROWS[i]
		# Each row rolls a moment after the one before, so a runner can follow
		# the pumpkins up the field.
		var roller := SpookyPumpkinRoller.roll(Vector3.LEFT, 2.4, fposmod(-0.29 * i, 1.0))
		add(roller, Vector3(5.8, 0, z))
		rollers.append(roller)
		SpookyProps.pumpkins(self, Vector3(6.2, 0, z - 1.6), Vector3(7.6, 0, z + 1.6), 5, i + 2)
		deco("grave:pumpkin-carved", Vector3(6.6, 0, z), -90.0, 3.0)
		SpookyProps.glow(self, Vector3(6.4, 1.0, z), 1.2, 4.0)
	# The crop between the rows, either side of the path.
	for z in [-6.5, -11.5, -16.5, -21.5]:
		SpookyProps.pumpkins(self, Vector3(-3.6, 0, z - 0.6), Vector3(-1.8, 0, z + 0.6), 3, int(-z))
		SpookyProps.pumpkins(self, Vector3(1.8, 0, z - 0.6), Vector3(3.4, 0, z + 0.6), 3, int(-z) + 1)
		add_coin(Vector3(0, 0.3, z))
	for z in [-6.5, -16.5]:
		SpookyProps.glow(self, Vector3(0, 2.2, z), 1.0, 6.0)
	# The far corner: a hay stack with the gem on top, and a spring up.
	_hay_wall(3, -26, 5, -24, 2)
	add_gem(GEM, Vector3(4.0, 1.75, -25.0))
	add(Spring.new(), Vector3(2.1, 0, -24.4))
	add_heart(Vector3(-3.4, 0, -24.6))


# --- The ditch: giant pumpkins bob in the swamp --------------------------------

func _ditch() -> void:
	add_checkpoint(Vector3(-3.6, 0, -27.4), Vector3.LEFT)
	SpookyProps.lamp(self, Vector3(-4.4, 0, -31.4), "single")
	SpookyProps.lamp(self, Vector3(4.4, 0, -31.4), "single")
	SpookyProps.fence(self, Vector3(-4, 0, -32), Vector3(5, 0, -32), "grave:fence", 0.8, 1.0)
	SpookyProps.swamp(self, -22, -34, -5, -24, DITCH_Y)
	add_sign("These pumpkins sink. Keep hopping!", Vector3(-3.6, 0, -30.4), Vector3.LEFT)
	for i in 4:
		# A wave: each pumpkin rises as the hero comes off the one before.
		var p := SpookyBobbingPumpkin.bob(2.1, 4.0, fposmod(-0.2 * i, 1.0))
		add(p, Vector3(-7.6 - 3.6 * i, 0.5, -29))
		bobbers.append(p)
		add_coin(Vector3(-7.6 - 3.6 * i, 1.6, -29))
	for at in [Vector3(-9.5, 0, -25.4), Vector3(-15, 0, -32.6), Vector3(-6.5, 0, -33), Vector3(-19.5, 0, -25.6)]:
		SpookyProps.reeds(self, at + Vector3.UP * DITCH_Y, int(at.x))
	camera_zone(Vector3(-30, -4, -35), Vector3(-1, 10, -26.5), 90.0, 28.0, 10.0)


# --- The lane: past the zombie in the gate to the flag -------------------------

func _lane() -> void:
	land(-28, -34, -20, -24, 0.5, 3)
	land(-27, -58, -21, -34, 0.5, 3)
	add_checkpoint(Vector3(-21.6, 0.5, -26.6), Vector3.LEFT)
	SpookyProps.pine(self, Vector3(-27, 0.5, -25), "grave:pine-crooked", 1.5)
	SpookyProps.lamp(self, Vector3(-27.2, 0.5, -33), "double", 90.0)
	# The gate, with a zombie standing in it: jump on it to get by.
	SpookyProps.fence(self, Vector3(-27, 0.5, -38), Vector3(-25.1, 0.5, -38), "grave:iron-fence", 1.4, 1.0)
	SpookyProps.fence(self, Vector3(-22.9, 0.5, -38), Vector3(-21, 0.5, -38), "grave:iron-fence", 1.4, 1.0)
	deco("grave:iron-fence-border-column", Vector3(-25.1, 0.5, -38), 0.0, 2.0)
	deco("grave:iron-fence-border-column", Vector3(-22.9, 0.5, -38), 0.0, 2.0)
	gatekeeper = Critter.chaser("grave:character-zombie", 2.5, 1.6, 1.1)
	add(gatekeeper, Vector3(-24, 0.5, -38))
	add_sign("A zombie in the gate! Jump on it.", Vector3(-26.2, 0.5, -35.2))
	# Two vampires pace across the lane.
	vampires.append(add(Critter.make("grave:character-vampire", Vector3(5, 0, 0), 3.2, 0.0, 1.1), Vector3(-26.5, 0.5, -43)) as Critter)
	vampires.append(add(Critter.make("grave:character-vampire", Vector3(-5, 0, 0), 3.2, 0.3, 1.1), Vector3(-21.5, 0.5, -47.5)) as Critter)
	for z in [-41.0, -45.25, -49.5]:
		add_coin(Vector3(-24, 0.8, z))
	SpookyProps.stone_row(self, Vector3(-26.6, 0.5, -41), Vector3(-26.6, 0.5, -49), 3, 90.0, 1)
	SpookyProps.stone_row(self, Vector3(-21.4, 0.5, -41), Vector3(-21.4, 0.5, -49), 3, -90.0, 4)
	add_heart(Vector3(-21.6, 0.5, -51))
	# The flag, under the farm's old crypt, lit by carved pumpkins.
	add_flag(Vector3(-24, 0.5, -52), Vector3.FORWARD)
	SpookyProps.mausoleum(self, Vector3(-24, 0.5, -56), 0.0, 1.5)
	for x in [-26.4, -21.6]:
		deco("grave:pumpkin-tall-carved", Vector3(x, 0.5, -54.2), 0.0, 3.2)
		SpookyProps.glow(self, Vector3(x, 1.6, -54.2), 1.4, 5.0)
	SpookyProps.pumpkins(self, Vector3(-26.8, 0.5, -57.6), Vector3(-25.8, 0.5, -54.8), 3, 7)
	SpookyProps.pumpkins(self, Vector3(-22.2, 0.5, -57.6), Vector3(-21.2, 0.5, -54.8), 3, 8)


## A wall of hay bales from (x0, z0) to (x1, z1), `layers` bales high, solid.
func _hay_wall(x0: float, z0: float, x1: float, z1: float, layers: int) -> void:
	var along_z := (z1 - z0) >= (x1 - x0)
	var length := (z1 - z0) if along_z else (x1 - x0)
	var n := maxi(1, roundi(length / 1.4))
	var step := length / n
	for layer in layers:
		for i in n:
			var u := (i + 0.5) * step
			var at := Vector3((x0 + x1) / 2.0, layer * 0.86, z0 + u) if along_z else Vector3(x0 + u, layer * 0.86, (z0 + z1) / 2.0)
			var turn := (90.0 if along_z else 0.0) + float((i * 5 + layer * 3) % 7) - 3.0
			deco("grave:hay-bale-bundled" if (i + layer) % 3 else "grave:hay-bale", at, turn, 2.3)
	solid(Vector3(x0, 0, z0), Vector3(x1, layers * 0.86, z1))
