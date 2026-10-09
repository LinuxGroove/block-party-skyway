class_name PirateRiggingRun
extends Level
## Course 4 of Pirate Cove: a run high in the rigging of three ships moored
## in a line, from the fort's wall to the flagship's stern. Planks strung
## between the masts' tops with a parrot about, a plank that gives way, a
## gust between the ships to ride, a double jump up to a wide top where a
## loose boom swings round the mast, a cargo crate swinging over to the
## flagship, another parrot, and a drop to the flag on its stern. Fall to a
## deck and a spring there throws you back up to the rigging.
##
## Adventure: coins, a heart, a hidden gem on the first ship's stern (with a
## spring back up) and checkpoints; the flag gives the star. Speedrun: just
## the course and the clock.

const STAR := "pirate/riggingrun"
const GEM := "pirate/gem_riggingrun"
const SEA := PirateBuild.SEA
## The ships' size, and how deep they sit.
const S := 1.5
const KEEL := SEA - 0.9
## Where each ship sits, and where its masts stand from its middle.
const SHIP_Z := [-16.0, -43.0, -69.0]
const FORE := 6.3
const MAIN := -0.5
const MIZZEN := -8.0
## The height of the rigging: the lowest tops.
const ALOFT := 6.0
## The ships' foredecks and stern castles.
const FOREDECK := 2.8 * S + KEEL
const STERN := 3.5 * S + KEEL

var parrots: Array[Critter] = []
var boom: Spinner
var gust: WindZone
var crate: MovingPlatform


func _init() -> void:
	super()
	title = "Rigging Run"
	spawn = Vector3(0, ALOFT, 1)
	spawn_facing = Vector3.FORWARD
	camera_base = [35.0, 26.0, 11.0, false]


func build() -> void:
	PirateBuild.sea(self)
	for i in SHIP_Z.size():
		var z: float = SHIP_Z[i]
		PirateBuild.ship(self, "pirate:ship-pirate-large" if i < 2 else "pirate:ship-large", Vector3(0, KEEL, z), 0.0, S, false)
		# A spring on the foredeck, back up to the foretop.
		add(Spring.new(), Vector3(1.6, FOREDECK, z + FORE - 2.9))

	# The start, on the fort's wall.
	land(-3, -6, 3, 3, ALOFT, 7)
	add_sign("Run the rigging to the flagship! Mind the drop.", Vector3(-2, ALOFT, 1))
	piece("pirate:flag-pirate-high", Vector3(2.3, ALOFT, 2.2), 20.0)
	piece("pirate:cannon", Vector3(-2.2, ALOFT, -4.6), 0.0, 0.8)
	piece("pirate:cannon", Vector3(2.2, ALOFT, -4.6), 0.0, 0.8)

	# The first ship: its foretop, planks to the maintop with a parrot
	# about, and a plank that gives way on the way to the mizzen top.
	var z1: float = SHIP_Z[0]
	_top(Vector3(0, ALOFT, z1 + FORE))
	_planks(Vector3(0, ALOFT, z1 + FORE - 1.5), Vector3(0, ALOFT, z1 + MAIN + 1.5))
	_parrot(Vector3(-3, ALOFT + 0.4, z1 + 2.9))
	coin_line(Vector3(0, ALOFT + 0.1, z1 + 4.5), Vector3(0, ALOFT + 0.1, z1 + 1.5), 3)
	add_sign("Parrots fly about the rigging. Jump on one, or let it pass.", Vector3(-1.1, ALOFT, z1 + FORE + 0.9), Vector3.BACK)
	_top(Vector3(0, ALOFT + 1.5, z1 + MAIN))
	add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(0, ALOFT + 1.5, z1 + (MAIN + MIZZEN) / 2.0))
	_top(Vector3(0, ALOFT + 1.5, z1 + MIZZEN))
	add_checkpoint(Vector3(-1, ALOFT + 1.5, z1 + MIZZEN + 0.5), Vector3.FORWARD)
	if not is_speedrun():
		# Off the racing line: down on the first ship's stern, with a spring
		# back up.
		add_gem(GEM, Vector3(2.3, STERN + 0.2, z1 - 9.0))
		add(Spring.new(), Vector3(-2.4, STERN, z1 - 7.0))

	# A gust between the ships: jump into it and it carries you over.
	var z2: float = SHIP_Z[1]
	var gap_from := z1 + MIZZEN - 1.5
	var gap_to := z2 + FORE + 1.5
	gust = add(WindZone.make(Vector3(3, 5, gap_from - gap_to), Vector3.FORWARD * 8.0), Vector3(0, ALOFT, (gap_from + gap_to) / 2.0)) as WindZone
	add_sign("The wind blows between the ships. Jump into it!", Vector3(1.1, ALOFT + 1.5, z1 + MIZZEN + 1.0), Vector3.BACK)
	coin_line(Vector3(0, ALOFT + 2.5, gap_from - 1.0), Vector3(0, ALOFT + 2.0, gap_to + 1.0), 4)

	# The second ship: a double jump up to its wide maintop, where a loose
	# boom swings round the mast, then down to its mizzen top.
	_top(Vector3(0, ALOFT, z2 + FORE + 1.5), 1, 2)
	add_sign("Jump twice to reach the maintop.", Vector3(-1.1, ALOFT, z2 + FORE + 0.6), Vector3.BACK)
	_top(Vector3(0, ALOFT + 2.5, z2 + MAIN), 2, 2)
	boom = Spinner.make(3, 75.0, "pirate:cannon-ball")
	boom.model_scale = 0.8
	boom.height = 0.55
	add(boom, Vector3(0, ALOFT + 2.5, z2 + MAIN))
	add_heart(Vector3(-1.8, ALOFT + 2.8, z2 + MAIN - 1.8))
	coin_line(Vector3(1.1, ALOFT + 2.6, z2 + MAIN + 2.0), Vector3(1.1, ALOFT + 2.6, z2 + MAIN - 2.0), 3)
	_top(Vector3(0, ALOFT + 1.5, z2 + MIZZEN))
	add_checkpoint(Vector3(-1, ALOFT + 1.5, z2 + MIZZEN + 0.5), Vector3.FORWARD)

	# A cargo crate swings over to the flagship.
	var z3: float = SHIP_Z[2]
	var crate_from := z2 + MIZZEN - 3.0
	crate = add(MovingPlatform.make(Vector3(0, 0, (z3 + FORE + 3.0) - crate_from), 4.0, 0.0, Vector3(2, 0.8, 2), "pirate:crate"), Vector3(0, ALOFT + 1.0, crate_from)) as MovingPlatform
	add_sign("Ride the cargo crate over.", Vector3(1.1, ALOFT + 1.5, z2 + MIZZEN + 1.0), Vector3.BACK)

	# The flagship: its foretop, planks with another parrot, its maintop,
	# then down to the flag on the stern.
	_top(Vector3(0, ALOFT, z3 + FORE))
	_planks(Vector3(0, ALOFT, z3 + FORE - 1.5), Vector3(0, ALOFT, z3 + MAIN + 1.5))
	_parrot(Vector3(3, ALOFT + 0.4, z3 + 2.9))
	coin_line(Vector3(0, ALOFT + 0.1, z3 + 4.5), Vector3(0, ALOFT + 0.1, z3 + 1.5), 3)
	_top(Vector3(0, ALOFT, z3 + MAIN))
	add_flag(Vector3(0, STERN, z3 + MIZZEN + 1.0))
	finish()


## A ship's top: a platform round the mast, `nx` by `nz` boards.
func _top(at: Vector3, nx := 1, nz := 1) -> void:
	var half := Vector3(1.5 * nx, 0, 1.5 * nz)
	for i in nx:
		for j in nz:
			var off := Vector3((i - (nx - 1) / 2.0) * 3.0, 0, (j - (nz - 1) / 2.0) * 3.0)
			piece("pirate:platform", at + off + Vector3.DOWN * 0.28, 0.0, 1.2)
	solid(at - half + Vector3.DOWN * 0.3, at + half)


## Planks strung between two tops, from `a` to `b` (in a line along z).
func _planks(a: Vector3, b: Vector3) -> void:
	var n := maxi(int(ceilf(absf(b.z - a.z) / 2.6)), 1)
	for i in n:
		var z := lerpf(a.z, b.z, (i + 0.5) / n)
		piece("pirate:platform-planks", Vector3(a.x, a.y - 0.3, z))
	solid(Vector3(a.x - 0.95, a.y - 0.3, a.z), Vector3(a.x + 0.95, a.y, b.z))


## A parrot flying back and forth across the planks.
func _parrot(at: Vector3) -> void:
	var p := Critter.make("animal-parrot", Vector3(-6.0 * signf(at.x), 0, 0), 4.0, 0.0, 0.42)
	p.bob = 0.2
	parrots.append(add(p, at) as Critter)
