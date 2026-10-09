class_name SpookyHollow
extends Island
## Spooky Hollow's island, at dusk: the gate yard where the hero lands, the
## graveyard terrace to the north with the bell tower, the Night Keeper's
## knoll behind it, the murky swamp to the west, the pumpkin patch to the
## south-west and the chapel yard to the east.
##
## Stars: Hazel's four lanterns, the silver coins among the graves, the
## chapel ghosts, the top of the bell tower and the lost grave below the
## chapel cliffs. Two hidden gems (a swamp islet and a strong crate on the
## knoll), plus one in each course.

const SILVER_TIME := 40.0
const LANTERN_STAR := "spooky/lanterns"
const GHOST_STAR := "spooky/ghosts"
const GHOST_STAR_AT := Vector3(15.5, 0.4, 3.0)

var hazel: Islander
var lanterns: Array[SpookyLantern] = []
var lanterns_lit := 0
var ghosts: Array[SpookyGhost] = []
var silver: SilverRush
var _ghost_star_given := false


func _init() -> void:
	super()
	title = "Spooky Hollow"
	spawn = Vector3(0, 0, 10)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_gate_yard()
	_graveyard()
	_tower()
	_knoll()
	_swamp()
	_pumpkin_patch()
	_chapel_yard()
	_lost_grave()
	# The Skyway: back to Pirate Cove from the pumpkin patch, on to Snack
	# Valley from the chapel yard.
	add_skyway_gates(Vector3(-25, 0, 3.6), Vector3.RIGHT, Vector3(25, 0, -2), Vector3.LEFT)
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "graveyard", "at": Vector3(1, 1, -6), "face": Vector3.FORWARD},
		{"name": "swamp", "at": Vector3(-14, -1, -1), "face": Vector3.LEFT},
		{"name": "tower", "at": Vector3(21, 6, -17), "face": Vector3.FORWARD},
	]


# --- The gate yard (where the hero lands) ------------------------------------

func _gate_yard() -> void:
	land(-12, -4, 10, 14, 0, 3)
	add_checkpoint(Vector3(-2, 0, 11), Vector3.FORWARD)
	add_sign("Ghosts are too spiky to jump on. Crouch in the air to ground pound them.", Vector3(2.5, 0, 9))
	# The gate and the yard's iron fence.
	SpookyProps.fence(self, Vector3(-12, 0, 13.8), Vector3(-2, 0, 13.8))
	SpookyProps.fence(self, Vector3(2, 0, 13.8), Vector3(10, 0, 13.8))
	SpookyProps.lamp(self, Vector3(-2.6, 0, 12.6))
	SpookyProps.lamp(self, Vector3(2.6, 0, 12.6))
	for z in [11.0, 8.5, 6.0, 3.5, 1.0, -1.5]:
		deco("grave:road", Vector3(0, 0.01, z), z * 31.0, 2.4)
	# Two ramps up to the graveyard terrace.
	ramp(Vector3(-1, 0, -3), Vector3.FORWARD)
	ramp(Vector3(1, 0, -3), Vector3.FORWARD)
	coin_line(Vector3(0, 0.3, 6), Vector3(0, 0.3, 0), 4)
	coin_ring(Vector3(6, 0, 5), 1.6, 8)
	# Old graves in the yard's corners.
	SpookyProps.stone_row(self, Vector3(-10, 0, 1), Vector3(-4, 0, 1), 3, 0.0, 1)
	SpookyProps.stone_row(self, Vector3(4, 0, -1), Vector3(8.5, 0, -1), 3, 0.0, 4)
	SpookyProps.pine(self, Vector3(-10.5, 0, 12), "grave:pine-crooked")
	SpookyProps.pine(self, Vector3(8.5, 0, 9), "grave:pine-fall")
	deco("grave:bench", Vector3(-7, 0, 12.6), 180.0, 2.0)
	deco("grave:pumpkin-carved", Vector3(-1.6, 0, 12.4), 0.0, 2.0)
	deco("grave:pumpkin-tall-carved", Vector3(1.6, 0, 12.4), 0.0, 2.0)
	add_heart(Vector3(8.5, 0, 12.5))
	# Hazel the bunny wants the lanterns lit.
	hazel = Islander.make("animal-bunny", "Hazel", [], 0.4)
	hazel.facing = Vector3(1, 0, 0.4).normalized()
	hazel.on_talk = _talk_hazel
	add(hazel, Vector3(-5, 0, 7))


func _talk_hazel() -> void:
	if found_stars.has(LANTERN_STAR) or lanterns_lit >= lanterns.size():
		speak("Hazel", ["Look at the Hollow glow! The ghosts keep to the chapel now."])
	elif lanterns_lit == 0:
		speak("Hazel", [
			"Oh dear, oh dear. The four big lanterns went out, and the Hollow gets so dark at night.",
			"One is on a tomb in the graveyard, one out in the swamp, one on the hay in the pumpkin patch, and one up on the Keeper's knoll.",
			"Could you light them? Just touch each one.",
		])
	else:
		speak("Hazel", ["%d of %d lanterns lit. It's looking brighter already!" % [lanterns_lit, lanterns.size()]])


## A lantern for Hazel's request.
func _add_lantern(at: Vector3) -> void:
	var l := SpookyLantern.new()
	l.is_lit = found_stars.has(LANTERN_STAR)
	add(l, at)
	l.lit.connect(_on_lantern_lit)
	lanterns.append(l)
	if l.is_lit:
		lanterns_lit += 1


func _on_lantern_lit(_l: SpookyLantern) -> void:
	lanterns_lit += 1
	if lanterns_lit < lanterns.size():
		say("%d of %d lanterns lit" % [lanterns_lit, lanterns.size()])
		return
	hazel.cheer()
	speak("Hazel", ["All four lanterns, burning bright! Here, I found this in the pumpkin patch."], _give_lantern_star)


func _give_lantern_star() -> void:
	add_star(LANTERN_STAR, hazel.position + Vector3(1.2, 0.4, 0.6))


# --- The graveyard terrace ---------------------------------------------------

func _graveyard() -> void:
	land(-12, -24, 26, -4, 1, 4)
	add_checkpoint(Vector3(-3, 1, -6), Vector3.FORWARD)
	SpookyProps.lamp(self, Vector3(-2.5, 1, -5))
	SpookyProps.lamp(self, Vector3(2.5, 1, -5))
	SpookyProps.lamp(self, Vector3(-1.5, 1, -17), "all")
	# Rows of graves either side of the path.
	for row in 3:
		var z := -8.0 - row * 3.0
		SpookyProps.stone_row(self, Vector3(-10.5, 1, z), Vector3(-3, 1, z), 4, 0.0, row)
		SpookyProps.stone_row(self, Vector3(3, 1, z), Vector3(9, 1, z), 3, 0.0, row + 2)
	for z in [-7.0, -10.0, -13.0, -16.0, -19.0]:
		deco("grave:road", Vector3(0, 1.01, z), z * 17.0, 2.4)
	# The door to Crypt Creep, in front of a mausoleum.
	SpookyProps.mausoleum(self, Vector3(-8, 1, -21.6), 0.0, 1.8)
	add_course_door("crypt_creep", Vector3(-8, 1, -18.2))
	SpookyProps.lamp(self, Vector3(-11, 1, -18), "single", 90.0)
	# A tomb with one of Hazel's lanterns on top.
	var top := SpookyProps.tomb(self, Vector3(5, 1, -20), 90.0, 2.6)
	_add_lantern(Vector3(5, top, -20))
	SpookyProps.pine(self, Vector3(9, 1, -22), "grave:pine-crooked")
	SpookyProps.pine(self, Vector3(-11, 1, -6), "grave:pine")
	SpookyProps.fence(self, Vector3(-12, 1, -23.8), Vector3(-5, 1, -23.8))
	SpookyProps.fence(self, Vector3(-12, 1, -23.8), Vector3(-12, 1, -9))
	coin_line(Vector3(0, 1.3, -8), Vector3(0, 1.3, -15), 4)
	# Zombies shuffle about among the graves.
	add(Critter.chaser("grave:character-zombie", 4.0, 2.2, 1.05), Vector3(-6, 1, -14.5))
	add(Critter.chaser("grave:character-zombie", 4.0, 2.2, 1.05), Vector3(6, 1, -16))
	# Old Moss knows the Hollow's secrets.
	var moss := Islander.make("animal-koala", "Old Moss", [
		"The bell tower? Hop up the tomb, then the ledges. At the top, kick from wall to wall.",
		"They say there's a lost grave down below the chapel cliffs, out to the south-east.",
		"The Night Keeper won't open his door until you've found five stars here.",
	], 0.4)
	moss.facing = Vector3(-0.3, 0, 1).normalized()
	add(moss, Vector3(5.5, 1, -6.5))


# --- The bell tower ----------------------------------------------------------

func _tower() -> void:
	land(16, -21, 20, -17, 12, 11, "snow")
	# Up the tomb, over to the east ledge, onto the sinking slab, then kick
	# up between the tower and the wall beside it.
	land(16, -17, 18, -15, 3.5, 3, "snow")
	ledge(20, -18, 22, -16, 6, "snow")
	add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.9), Vector3(21, 7, -21.5))
	land(16, -23, 20, -22, 11.5, 11, "snow")
	ledge(16, -22, 20, -21, 7, "snow")
	add_star("spooky/tower", Vector3(18, 12.2, -19))
	SpookyProps.glow(self, Vector3(18, 13.5, -19), 1.6, 6.0)
	for at in [Vector3(16.4, 12, -20.6), Vector3(19.6, 12, -20.6), Vector3(16.4, 12, -17.4), Vector3(19.6, 12, -17.4)]:
		deco("grave:pillar-large", at, 0.0, 1.6)
	add_coin(Vector3(17, 3.8, -16))
	coin_line(Vector3(21, 6.3, -17.5), Vector3(21, 6.3, -16.5), 2)
	add_sign("Jump at a wall, then jump again to kick off it.", Vector3(14.5, 1, -15), Vector3(0, 0, 1))
	# The door into the Haunted Tower.
	add_course_door("haunted_tower", Vector3(13.6, 1, -19), Vector3.LEFT)
	SpookyProps.lamp(self, Vector3(13.6, 1, -22.5), "single", 90.0)
	SpookyProps.lamp(self, Vector3(22.5, 1, -13), "double")
	camera_zone(Vector3(12, 0, -24), Vector3(26, 16, -14), 30.0, 22.0, 12.0, false, 1)
	camera_zone(Vector3(15, 6, -24), Vector3(24, 16, -20.6), 90.0, 16.0, 11.0, false, 2)
	add(Critter.chaser("grave:character-skeleton", 3.5, 2.0, 1.05), Vector3(23, 1, -8))


# --- The Night Keeper's knoll ------------------------------------------------

func _knoll() -> void:
	land(-4, -36, 10, -24, 2, 5)
	ramp(Vector3(3, 1, -23), Vector3.FORWARD)
	add_checkpoint(Vector3(7.5, 2, -26.5), Vector3.FORWARD)
	SpookyProps.mausoleum(self, Vector3(3, 2, -33.8), 0.0, 2.0)
	add_boss_door(Vector3(3, 2, -30.6))
	SpookyProps.lamp(self, Vector3(0.2, 2, -29.4), "single", 90.0)
	SpookyProps.lamp(self, Vector3(5.8, 2, -29.4), "single", -90.0)
	deco("grave:shovel-dirt", Vector3(7, 2, -31), 30.0, 2.0)
	deco("grave:fire-basket", Vector3(-1.5, 2, -32), 0.0, 2.2)
	SpookyProps.glow(self, Vector3(-1.5, 2.8, -32), 1.2, 4.0)
	_add_lantern(Vector3(-1.5, 2, -26.5))
	# Behind a pine at the back, a strong crate with a gem in it.
	SpookyProps.pine(self, Vector3(-2.6, 2, -33.6), "grave:pine-crooked")
	add(Breakable.make("crate-strong", "gem:spooky/gem_knoll"), Vector3(-3, 2, -35.2))
	SpookyProps.pine(self, Vector3(9, 2, -35), "grave:pine")
	SpookyProps.fence(self, Vector3(-4, 2, -24.2), Vector3(1.5, 2, -24.2))
	SpookyProps.fence(self, Vector3(4.5, 2, -24.2), Vector3(10, 2, -24.2))
	add(Critter.make("grave:character-vampire", Vector3(0, 0, 6), 5.0, 0.0, 1.05), Vector3(-3.4, 2, -32))


# --- The swamp ---------------------------------------------------------------

func _swamp() -> void:
	SpookyProps.swamp(self, -34, -26, -12, 2, -1.4)
	# Hummocks to hop along, and two sinking logs.
	land(-16, -3, -12, 1, -1, 2)
	land(-23, -9, -19, -3, -1, 2)
	add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.7), Vector3(-24.5, -1, -10))
	add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.7), Vector3(-27.5, -1, -12))
	land(-34, -18, -29, -9, -1, 2)
	_add_lantern(Vector3(-20, -1, -7.5))
	add_course_door("ghost_bridge", Vector3(-32.6, -1, -13.5), Vector3.RIGHT)
	add_checkpoint(Vector3(-30.5, -1, -10.2), Vector3.RIGHT)
	SpookyProps.lamp(self, Vector3(-30, -1, -16.6), "single")
	SpookyProps.lamp(self, Vector3(-13, -1, 0.2), "single")
	# Far out to the north, a gem for long jumpers.
	ledge(-32, -26, -30, -24, -0.6)
	add_gem("spooky/gem_swamp", Vector3(-31, -0.5, -25))
	coin_line(Vector3(-31, -0.7, -17), Vector3(-31, -0.3, -22), 3)
	var murk := Islander.make("animal-beaver", "Murk", [
		"Mind the logs. They sink as soon as you stand on them.",
		"See the little islet way out north of the bridge door? Run, crouch and jump. A long jump gets you there.",
		"The Ghost Bridge door is over on the far bank. Ghosts drift all over that bridge.",
	], 0.4)
	murk.facing = Vector3(1, 0, 0.5).normalized()
	add(murk, Vector3(-21.5, -1, -4.5))
	for at in [Vector3(-33, -1, -10), Vector3(-15, -1, -2.4), Vector3(-19.6, -1, -3.6)]:
		SpookyProps.pine(self, at, "grave:pine-crooked", 1.4)
	deco("grave:trunk", Vector3(-30, -1, -9.6), 0.0, 2.0)
	deco("grave:rocks", Vector3(-32.5, -1, -17), 0.0, 1.6)


# --- The pumpkin patch -------------------------------------------------------

func _pumpkin_patch() -> void:
	land(-26, 2, -12, 16, 0, 3)
	add_checkpoint(Vector3(-15, 0, 9), Vector3.LEFT)
	add_course_door("pumpkin_patch", Vector3(-24.4, 0, 9), Vector3.RIGHT)
	SpookyProps.pumpkins(self, Vector3(-24, 0, 3), Vector3(-14, 0, 15), 34, 3)
	SpookyProps.fence(self, Vector3(-26, 0, 15.8), Vector3(-12, 0, 15.8), "grave:fence", 0.8)
	SpookyProps.lamp(self, Vector3(-22, 0, 5), "double")
	SpookyProps.lamp(self, Vector3(-14, 0, 3.5), "single")
	# The hay stack with a lantern on top: a bale, then two.
	for at in [Vector3(-17.5, 0, 5), Vector3(-16.1, 0, 5), Vector3(-16.1, 0.84, 5)]:
		deco("grave:hay-bale-bundled", at, 0.0, 2.3)
	solid(Vector3(-18.2, 0, 4.5), Vector3(-16.8, 0.8, 5.5))
	solid(Vector3(-16.8, 0, 4.5), Vector3(-15.4, 1.6, 5.5))
	_add_lantern(Vector3(-16.1, 1.6, 5))
	# Silver coins among the graves: step on the button and race round.
	silver = add_silver_rush("spooky/silver", Vector3(-19.5, 0, 12), SILVER_SPOTS, SILVER_TIME)
	add_sign("Step on the button, then find eight silver coins before time runs out.", Vector3(-21.5, 0, 13.4))
	var turnip := Islander.make("animal-pig", "Turnip", [
		"Best pumpkins in the Sky Isles, these. Mind the skeletons, they trample them.",
		"Folk say silver coins turn up all over the Hollow when you press that button.",
		"The Pumpkin Patch door leads to my big field. Pumpkins roll down the rows there!",
	], 0.4)
	turnip.facing = Vector3(-1, 0, -0.3).normalized()
	add(turnip, Vector3(-13.5, 0, 12.5))
	add(Critter.make("grave:character-skeleton", Vector3(0, 0, 5), 4.5, 0.0, 1.05), Vector3(-20, 0, 6))
	add(Critter.make("grave:character-skeleton", Vector3(5, 0, 0), 5.0, 0.5, 1.05), Vector3(-22, 0, 14))
	coin_ring(Vector3(-19, 0, 9), 1.5, 6)
	add_heart(Vector3(-13, 0, 15))


const SILVER_SPOTS := [
	Vector3(-8, 0, 10), Vector3(-23, 0, 14.5), Vector3(-21, -1, -4), Vector3(-11, 1, -21.5),
	Vector3(8.5, 2, -33), Vector3(24, 1, -6), Vector3(24, 0, 8.5), Vector3(8, 0, 12),
]


# --- The chapel yard, to the east --------------------------------------------

func _chapel_yard() -> void:
	land(10, -4, 26, 10, 0, 3)
	ramp(Vector3(18, 0, -3), Vector3.FORWARD)
	add_checkpoint(Vector3(12, 0, 0), Vector3.RIGHT)
	SpookyProps.mausoleum(self, Vector3(21, 0, 4), -90.0, 2.4)
	SpookyProps.lamp(self, Vector3(17, 0, 0.6), "single", 90.0)
	SpookyProps.lamp(self, Vector3(17, 0, 7.4), "single", 90.0)
	SpookyProps.lamp(self, Vector3(11, 0, -3.2), "single")
	add_sign("Three ghosts haunt the chapel. Ground pound them all!", Vector3(12, 0, 6), Vector3.RIGHT)
	SpookyProps.stone_row(self, Vector3(12, 0, 8.5), Vector3(16, 0, 8.5), 3, 0.0, 2)
	SpookyProps.pine(self, Vector3(24.2, 0, 9.2), "grave:pine-fall-crooked", 1.4)
	SpookyProps.fence(self, Vector3(14, 0, -3.8), Vector3(17, 0, -3.8))
	SpookyProps.fence(self, Vector3(19, 0, -3.8), Vector3(26, 0, -3.8))
	# The chapel ghosts: pound all three for a star.
	for g in [[Vector3(12.5, 0.5, 2.5), Vector3(4, 0, 0), 4.5, 0.0], [Vector3(14.5, 0.5, 6.8), Vector3(0, 0, -5), 5.0, 0.3], [Vector3(24.8, 0.5, 0.5), Vector3(0, 0, 7), 6.0, 0.6]]:
		var ghost := SpookyGhost.drift(g[1], g[2], g[3])
		add(ghost, g[0])
		ghosts.append(ghost)
	if found_stars.has(GHOST_STAR):
		_ghost_star_given = true
		add_star(GHOST_STAR, GHOST_STAR_AT)
	coin_line(Vector3(11, 0.3, -2), Vector3(15, 0.3, -2), 4)


func _physics_process(_delta: float) -> void:
	if _ghost_star_given or ghosts.is_empty():
		return
	for g in ghosts:
		if is_instance_valid(g) and not g.defeated:
			return
	_ghost_star_given = true
	say("The chapel ghosts are gone!")
	add_star(GHOST_STAR, GHOST_STAR_AT)


# --- The lost grave, below the chapel cliffs ---------------------------------

func _lost_grave() -> void:
	ledge(26, 11, 28, 13, -1)
	ledge(29, 14, 31, 16, -2)
	land(30, 18, 35, 23, -3, 2)
	add_star("spooky/lost_grave", Vector3(33.5, -2.8, 20))
	SpookyProps.stone(self, Vector3(33.5, -3, 21.6), 4, 0.0, 2.2)
	deco("grave:grave-border", Vector3(33.5, -2.98, 20.2), 0.0, 1.8)
	SpookyProps.lamp(self, Vector3(31, -3, 22.2), "single")
	SpookyProps.pine(self, Vector3(34.4, -3, 18.8), "grave:pine-crooked", 1.3)
	deco("grave:candle-multiple", Vector3(32.5, -3, 21.5), 0.0, 2.0)
	coin_line(Vector3(27, -0.7, 12), Vector3(30, -1.7, 15), 3)
