class_name GearsIsle
extends Island
## Gear Works' island, for Adventure: a floating factory of steel decks.
## The yard in the middle (Bolt's cog machine, and Scamp the fox running
## rings round it), the assembly hall up on the north terrace (two course
## doors and The Big Press's door), the crane yard across a conveyor bridge
## to the east, the belt works down to the west, and the loading dock to the
## south with two more course doors and the Skyway gates.
##
## Stars: Bolt's three lost cogs, the shift switch's timed steps, the top of
## the crane tower, a secret ledge off the end of belt seven, and catching
## Scamp. Two hidden gems (a strong crate behind the hall, and the end of an
## old pipe), plus one in each course.

const SWITCH_TIME := 10.0
## Scamp's loop round the yard.
const SCAMP_PATH := [Vector3(-7, 0, -5), Vector3(8, 0, -5), Vector3(8, 0, 7), Vector3(-7, 0, 7)]

var bolt: Islander
var cogs: Array[GearsCog] = []
var cogs_home := 0
var shift_switch: GearsTimedBridge
var scamp: GearsRunaway


func _init() -> void:
	super()
	title = "Gear Works"
	spawn = Vector3(0, 0, 9)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_yard()
	_terrace()
	_crane_yard()
	_belt_works()
	_dock()
	finish()


## Views for the screenshot tool, beyond the arrival shot.
func shots() -> Array:
	return [
		{"name": "crane", "at": Vector3(18, 0, 2), "face": Vector3.FORWARD},
		{"name": "belts", "at": Vector3(-16, -1, 9), "face": Vector3.LEFT},
		{"name": "hall", "at": Vector3(0, 2, -12), "face": Vector3.FORWARD},
	]


func collect_star(id: String) -> void:
	super(id)
	if id == "gears/switch":
		shift_switch.hold()


# --- The yard (where the hero lands) -----------------------------------------

func _yard() -> void:
	land(-12, -8, 12, 12, 0, 3)
	add_checkpoint(Vector3(-3, 0, 10.5), Vector3.FORWARD)
	coin_ring(Vector3(0, 0, 1), 2.0, 8)
	add_heart(Vector3(10.5, 0, 10.5))
	# Bolt's cog machine, in the north-west corner.
	piece("factory:machine-bed", Vector3(-10.5, 0, -6.5), 0.0, 2.0)
	solid(Vector3(-12, 0, -8), Vector3(-7.5, 2.6, -5.0))
	bolt = add_islander("animal-beaver", "Bolt", [], Vector3(-8.5, 0, -3.5), Vector3(0.6, 0, 1).normalized())
	bolt.on_talk = _talk_bolt
	var cog_spots := [Vector3(-32, -0.6, -6), Vector3(24, 6.4, 2), Vector3(-20, 3.0, -8)]
	var shuttle := add(MovingPlatform.make(Vector3(-6, 0, 0), 5.0, 0.0, Vector3(2, 0.4, 2)), Vector3(-30, -1, -6)) as MovingPlatform
	for i in 3:
		var c := GearsCog.new()
		c.home = Vector3(-11.6 + i * 1.1, 2.65, -5.6)
		c.level = self
		if found_stars.has("gears/cogs"):
			c.position = c.home
			c.is_home = true
			add_child(c)
		elif i == 0:
			# The first cog rides the shuttle in the belt works.
			c.position = Vector3(0, 0.05, 0)
			shuttle.add_child(c)
		else:
			c.position = cog_spots[i]
			add_child(c)
		c.found.connect(_on_cog_home)
		cogs.append(c)
	if found_stars.has("gears/cogs"):
		cogs_home = 3
	# Scamp the fox, who took the shift star and won't stand still.
	scamp = GearsRunaway.new()
	scamp.path = SCAMP_PATH
	scamp.lines = ["Fine, fine, you're quicker than me. I only wanted to see it shine."]
	add(scamp, Vector3(4, 0, -1))
	if found_stars.has("gears/scamp"):
		scamp.settle()
	else:
		scamp.caught.connect(_on_scamp_caught)
	# Robots trundling about.
	add(GearsBot.box_bot(Vector3(0, 0, -4)), Vector3(10.5, 0, 6))
	add(GearsBot.box_bot(Vector3(5, 0, 0), 0.0, 5.0, 0.3), Vector3(-10, 0, 3))
	# Scenery round the edges, clear of Scamp's loop.
	for at in [Vector3(-11.3, 0, 11.3), Vector3(11.3, 0, -7.3), Vector3(-11.3, 0, 7.5)]:
		deco("factory:warning-orange", at, 0.0, 1.4)
	for at in [Vector3(10.6, 0, -6.8), Vector3(10.6, 0, -5.4), Vector3(10.6, 0.82, -6.1)]:
		_box(at, 1.5)
	piece("factory:hopper-high-round", Vector3(-11, 0, 9.5), 0.0, 1.5)
	solid(Vector3(-11.8, 0, 8.7), Vector3(-10.2, 2.2, 10.3))
	piece("factory:robot-arm-a", Vector3(-6.5, 0, -7.2), 180.0, 1.4)
	piece("factory:robot-arm-b", Vector3(5.5, 0, -7.2), 180.0, 1.4)
	for x in [-10.5, -8.5, 6.5, 8.5]:
		deco("factory:indicator-special-lines", Vector3(x, 0.01, 11.5), 0.0, 1.0)
	# A big cog set in the floor, and Scamp's track round it.
	_emblem(Vector3(0, 0, 1), 7.0)
	for i in SCAMP_PATH.size():
		var a: Vector3 = SCAMP_PATH[i]
		var b: Vector3 = SCAMP_PATH[(i + 1) % SCAMP_PATH.size()]
		GearsDecor.strip(self, a, b)
		GearsDecor.arrow(self, (a + b) / 2.0 + Vector3.UP * 0.01, b - a)


func _talk_bolt() -> void:
	if cogs_home >= 3:
		speak("Bolt", ["Listen to her hum! Best machine on the island, now it's got all its cogs."])
	elif cogs_home == 0:
		speak("Bolt", [
			"Oh, bother. My cog machine shook itself to bits and three golden cogs went flying.",
			"One's riding the shuttle out past the belt works, one's up over the big fan in the crane yard...",
			"...and one landed on the boiler house roof. Touch them and they'll spin right back here.",
		])
	else:
		speak("Bolt", ["%d of 3 cogs back. She's nearly purring!" % cogs_home])


func _on_cog_home(_c: GearsCog) -> void:
	cogs_home += 1
	if cogs_home < 3:
		say("%d of 3 cogs back" % cogs_home)
		return
	bolt.cheer()
	speak("Bolt", ["All three! Hear that? And look what she spat out. That's yours."], _give_cog_star)


func _give_cog_star() -> void:
	add_star("gears/cogs", bolt.position + Vector3(1.2, 0.4, 0.8))


func _on_scamp_caught() -> void:
	speak("Scamp", ["Alright, alright! You caught me. Here, take the star back."], _give_scamp_star)


func _give_scamp_star() -> void:
	add_star("gears/scamp", scamp.position + Vector3(0, 0.4, 1.2))


# --- The north terrace: the assembly hall ------------------------------------

func _terrace() -> void:
	land(-12, -26, 12, -8, 2, 5)
	# Hazard-yellow steps up from the yard.
	for x in [-1, 1]:
		ramp(Vector3(x, 0, -3), Vector3.FORWARD, "snow")
		ramp(Vector3(x, 1, -7), Vector3.FORWARD, "snow")
	land(-2, -8, 2, -4, 1, 1, "snow")
	coin_line(Vector3(0, 0.4, -2), Vector3(0, 2.0, -8.5), 4)
	add_checkpoint(Vector3(3.5, 2, -10), Vector3.BACK)
	add_course_door("belt_rush", Vector3(-7, 2, -19))
	add_course_door("piston_climb", Vector3(7, 2, -19))
	add_boss_door(Vector3(0, 2, -21.5))
	# The hall's back wall, with the press looming behind the boss door.
	for x in range(-12, 12, 2):
		if absi(x) > 2:
			piece("factory:structure-wall", Vector3(x + 0.5, 2, -25.5), 0.0, 1.0)
			piece("factory:structure-wall", Vector3(x + 1.5, 2, -25.5), 0.0, 1.0)
	solid(Vector3(-12, 2, -26), Vector3(12, 5, -25))
	piece("factory:machine-fortified", Vector3(0, 2, -24.6), 180.0, 2.6)
	solid(Vector3(-1.6, 2, -26), Vector3(1.6, 5.5, -23.2))
	# The foreman.
	add_islander("animal-koala", "Gauge", [
		"The Big Press has gone haywire. It slams down wherever the floor lights up!",
		"When it gets stuck after a big slam, that's your chance. Jump on top and ground pound it.",
		"And if you see Scamp, he took the shift star. Run! He's quick, but you're quicker.",
	], Vector3(-3.5, 2, -13), Vector3(0.4, 0, 1).normalized())
	# A strong crate tucked away behind the boxes, with a hidden gem.
	for at in [Vector3(9.4, 2, -23.2), Vector3(10.6, 2, -23.2), Vector3(10.0, 2.82, -23.2), Vector3(8.4, 2, -24.4)]:
		_box(at, 1.5)
	add(Breakable.make("crate-strong", "gem:gears/gem_crate"), Vector3(10.6, 2, -24.5))
	# A cog bot rolls along the front of the hall.
	add(GearsBot.cog_bot(Vector3(8, 0, 0), 4.0), Vector3(-4, 2, -15.5))
	add_sign("Rolling cogs are too spiky to jump on. Crouch in the air to ground pound them.", Vector3(-9.5, 2, -11), Vector3(0.5, 0, 1).normalized())
	# Conveyor lines down the sides, carrying boxes.
	for side in [-11.0, 11.0]:
		for z in range(-22, -9, 2):
			piece("factory:conveyor-long", Vector3(side, 2, z + 1), 90.0, 1.0)
		for z in [-20.5, -15.0, -11.5]:
			piece("factory:box-small", Vector3(side, 2.4, z), 90.0, 1.3)
		solid(Vector3(side - 0.6, 2, -22), Vector3(side + 0.6, 2.4, -9))
	coin_line(Vector3(-5, 2, -17), Vector3(5, 2, -17), 5)
	# A walkway up to the press's door, marks before the course doors, and
	# big cogs turning behind the hall.
	GearsDecor.strip(self, Vector3(0, 2, -9), Vector3(0, 2, -19))
	for x in [-7.0, 7.0]:
		deco("factory:indicator-special-area", Vector3(x, 2.02, -17.2), 0.0, 1.8)
	add(GearsBigCog.make(7.0, 0.0, 10.0), Vector3(-7.5, 2, -26.4))
	add(GearsBigCog.make(5.0, 0.0, -14.0, "factory:cog-c"), Vector3(-2.5, 2, -26.6))
	add(GearsBigCog.make(6.0, 0.0, 12.0, "factory:cog-b"), Vector3(7.5, 2, -26.4))


# --- The crane yard, across the conveyor bridge -------------------------------

func _crane_yard() -> void:
	land(16, -12, 28, 6, 0, 3, "snow")
	# The conveyor bridge carries you back towards the yard: run against it.
	add(Conveyor.make(4, Vector3.LEFT, 2.5), Vector3(16, -0.33, 0))
	add_sign("Conveyor belts carry you along. Run against this one to cross.", Vector3(10.5, 0, 1.6), Vector3.RIGHT)
	add_checkpoint(Vector3(17.5, 0, 3.5), Vector3.RIGHT)
	# The crane tower: a high jump, a piston up, then kick up between the
	# stacks to the top.
	land(19, -3, 21, -1, 2.5, 3)
	land(21, -3, 23, -1, 2.0, 3)
	var piston := add(GearsPiston.make(3.5), Vector3(22, 2.5, -2)) as GearsPiston
	piston.housing = false
	land(18, -8, 26, -4, 6.0, 7)
	land(18, -8, 22, -6, 12.0, 6)
	land(23, -8, 24, -6, 13.0, 7.0)
	add_star("gears/crane", Vector3(20, 12.2, -7))
	add_sign("Ride the piston up, then jump at a wall and kick off it, back and forth, up between the stacks.", Vector3(18, 0, -0.5), Vector3.BACK)
	coin_line(Vector3(22.5, 7.0, -7), Vector3(22.5, 10.5, -7), 4)
	coin_line(Vector3(22, 3.5, -2), Vector3(22, 5.5, -2), 3)
	camera_zone(Vector3(17, -1, -12), Vector3(28, 14, 0), 0.0, 22.0, 12.0, false, 1)
	piece("factory:crane", Vector3(26.5, 0, -10), 90.0, 3.0)
	# The big fan: it blows you up to the cog floating over it.
	add(GearsFan.make(6.0, 42.0), Vector3(24, 0, 2))
	add_sign("Fans blow you upward. Stand over one and float, then steer.", Vector3(21.5, 0, 4.5), Vector3.BACK)
	add_heart(Vector3(27, 0, 5))
	add(GearsBot.box_bot(Vector3(0, 0, 4)), Vector3(18, 0, -11))
	for at in [Vector3(27.2, 0, -1.5), Vector3(27.2, 0, -0.2), Vector3(27.2, 0.82, -0.85)]:
		_box(at, 1.5)
	for at in [Vector3(16.5, 0, 5.5), Vector3(27.5, 0, 5.5), Vector3(16.5, 0, -11.5)]:
		deco("factory:warning-traffic", at, 0.0, 1.4)
	# Cogs turning in the deck's east side.
	add(GearsBigCog.make(6.0, 90.0, 9.0), Vector3(28.7, -3.0, 1))
	add(GearsBigCog.make(4.0, 90.0, -13.5, "factory:cog-c"), Vector3(28.7, -2.0, -4.5))
	GearsDecor.strip(self, Vector3(17, 0, 1), Vector3(17, 0, -9))


# --- The belt works, down to the west ----------------------------------------

func _belt_works() -> void:
	land(-28, -10, -12, 10, -1, 3)
	ramp(Vector3(-13, -1, 6), Vector3.RIGHT)
	add_checkpoint(Vector3(-15, -1, 3), Vector3.LEFT)
	# The shift switch: the steps slide out for ten seconds.
	shift_switch = GearsTimedBridge.new()
	shift_switch.button_at = Vector3(-16, -1, 8)
	shift_switch.steps = [Vector3(-18.5, 0.2, 8), Vector3(-21, 1.4, 8), Vector3(-23.5, 2.6, 8), Vector3(-26, 3.8, 8), Vector3(-26, 5.0, 5.5)]
	shift_switch.seconds = SWITCH_TIME
	shift_switch.label = "Shift switch"
	add(shift_switch, Vector3.ZERO)
	land(-27, 1, -25, 4, 6.2, 7.2)
	add_star("gears/switch", Vector3(-26, 6.4, 2.5))
	if found_stars.has("gears/switch"):
		shift_switch.hold()
	add_sign("Step on the switch and steps slide out for ten seconds. Climb to the top!", Vector3(-14.5, -1, 9), Vector3(-0.3, 0, 1).normalized())
	# The boiler house: a crusher's top makes a lift up to the roof.
	land(-22, -10, -18, -6, 3.0, 4)
	add(Crusher.make(3.0, Vector3(2, 1, 2)), Vector3(-17, -1, -8))
	add_sign("Crushers slam down. Don't get caught under one... but the top makes a fine lift.", Vector3(-14.5, -1, -6), Vector3.RIGHT)
	piece("factory:pipe-large", Vector3(-21, 3.0, -9), 0.0, 1.0)
	piece("factory:pipe-large", Vector3(-21, 4.0, -9), 0.0, 1.0)
	piece("factory:hopper-round", Vector3(-19, 3.0, -9), 0.0, 1.2)
	# The shuttle out past the west edge carries Bolt's first cog.
	add_sign("Something golden rides the shuttle out west.", Vector3(-27, -1, -4), Vector3.RIGHT)
	# An old pipe sticks out over the edge, with a gem at the end.
	for i in 3:
		piece("factory:pipe-large-long", Vector3(-29 - i * 2, -2, -1.5), 0.0, 1.0)
	solid(Vector3(-34, -1.5, -2), Vector3(-28, -1, -1))
	ledge(-37, -3, -34, 0, -1)
	add_gem("gears/gem_pipe", Vector3(-35.5, -0.8, -1.5))
	# Nell knows the island.
	add_islander("animal-cow", "Nell", [
		"That old pipe out west? Nobody's walked it in years. Mind your step.",
		"The crusher by the boiler house is noisy, but you can ride on top of it.",
	], Vector3(-15, -1, -1.5), Vector3.RIGHT)
	add(GearsBot.box_bot(Vector3.ZERO, 5.0), Vector3(-24, -1, -3))
	add_heart(Vector3(-27, -1, 9))
	coin_line(Vector3(-17, -1, 0), Vector3(-25, -1, 0), 5)
	for at in [Vector3(-27.3, -1, -9.3), Vector3(-12.7, -1, -9.3)]:
		deco("factory:warning-orange", at, 0.0, 1.4)
	GearsDecor.strip(self, Vector3(-14, -1, 3), Vector3(-26, -1, 3))
	GearsDecor.arrow(self, Vector3(-16.5, -1, 6.2), Vector3.LEFT)
	add(GearsBigCog.make(5.0, 90.0, -10.0, "factory:cog-b"), Vector3(-28.7, -3.5, 6.5))
	# Belts along the north side, carrying boxes.
	for x in range(-27, -17, 2):
		piece("factory:conveyor-long", Vector3(x + 1, -1, -9.4), 0.0, 1.0)
	for x in [-26.0, -22.5]:
		piece("factory:box-small", Vector3(x, -0.6, -9.4), 0.0, 1.3)
	solid(Vector3(-27, -1, -10), Vector3(-17, -0.6, -8.8))


# --- The loading dock, to the south ------------------------------------------

func _dock() -> void:
	land(-8, 14, 16, 24, 0, 3)
	ledge(-2, 12, 2, 14, 0, "snow")
	add_checkpoint(Vector3(0, 0, 15.5), Vector3.BACK)
	add_course_door("fan_tower", Vector3(-3, 0, 21.5), Vector3.FORWARD)
	add_course_door("crusher_row", Vector3(5, 0, 21.5), Vector3.FORWARD)
	# The Skyway, back to Snack Valley and on to Sky Castle.
	add_skyway_gates(Vector3(-6.5, 0, 17.5), Vector3.RIGHT, Vector3(14.5, 0, 16), Vector3.LEFT)
	add_islander("animal-elephant", "Rivet", [
		"The Skyway gates are at either end of the dock. Snack Valley one way, Sky Castle the other.",
		"See belt seven, over there? It runs right off the edge. Nobody dares ride it to the end.",
	], Vector3(1.5, 0, 17.5), Vector3.BACK)
	# Belt seven runs off the edge, onto a hidden ledge with a fan back up.
	add(Conveyor.make(5, Vector3.BACK, 3.0), Vector3(10.5, -0.33, 19))
	for at in [Vector3(9.0, 0, 18.6), Vector3(12.0, 0, 18.6)]:
		deco("factory:warning-orange", at, 0.0, 1.2)
	ledge(8, 24, 15, 29, -4.5)
	add_star("gears/belt", Vector3(10.5, -4.3, 27.3))
	add(GearsFan.make(5.5, 42.0), Vector3(13.5, -4.5, 25.6))
	camera_zone(Vector3(7, -7, 23.5), Vector3(16, -1, 30), 0.0, 24.0, 9.0, false, 2)
	# Crates of coins and the dock's machinery.
	for at in [Vector3(-6, 0, 22.5), Vector3(-5, 0, 22.8), Vector3(-6.3, 0, 21.5)]:
		add(Breakable.make("crate", "coins:2"), at)
	for at in [Vector3(14.5, 0, 22.8), Vector3(13.2, 0, 22.8)]:
		_box(at, 1.5)
	piece("factory:hopper-high-square", Vector3(1, 0, 23), 0.0, 1.5)
	solid(Vector3(0.2, 0, 22.2), Vector3(1.8, 2.2, 23.8))
	coin_line(Vector3(-4, 0, 18.5), Vector3(4, 0, 18.5), 5)
	GearsDecor.strip(self, Vector3(0, 0, 15.2), Vector3(0, 0, 19.2))
	for x in [-3.0, 5.0]:
		deco("factory:indicator-special-area", Vector3(x, 0.02, 20.2), 0.0, 1.8)
	add(GearsBigCog.make(5.0, 0.0, 11.0), Vector3(-3.5, -2.5, 24.6))
	add(GearsBigCog.make(3.5, 0.0, -15.0, "factory:cog-c"), Vector3(1.2, -1.75, 24.6))


# --- Pieces ------------------------------------------------------------------

## A big cog set flush into the floor, `size` metres across.
func _emblem(at: Vector3, size: float) -> void:
	var m := Kit.model("factory:cog-e")
	m.scale = Vector3(size, 0.2, size)
	m.position = at + Vector3.UP * 0.006
	add_child(m)

## A stacked shipping box (Factory Kit), solid.
func _box(at: Vector3, scale := 1.5) -> void:
	piece("factory:box-large", at, 0.0, scale)
	var half := Vector3(0.55, 0, 0.5) * scale
	solid(at - half, at + half + Vector3.UP * 0.55 * scale)
