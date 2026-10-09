class_name StarPlaza
extends Island
## The Star Road's hub, Stardust Plaza: a gold plaza high above the clouds
## at night, with a spire in the middle and a ring of eight pads joined by
## rainbow paths, each pad with a door to one of the eight courses and a few
## trophies from the worlds that course mixes. The Skyway arrives from Star
## Station at the south.
##
## Stars: the eight courses, the silver coin lap round the ring, and the top
## of the spire. One hidden gem below the north path, plus one in each
## course.

const SILVER_TIME := 21.0
## The ring's eight pads, clockwise from the south-east, in course order:
## courses 1 to 4 up the east side, 5 to 8 up the west.
const PADS := [Vector3(7, 0, 17), Vector3(17, 0, 7), Vector3(17, 0, -7), Vector3(7, 0, -17),
	Vector3(-7, 0, 17), Vector3(-17, 0, 7), Vector3(-17, 0, -7), Vector3(-7, 0, -17)]
## Where each pad's door stands and which way it faces (towards its path).
const DOORS := [
	[Vector3(7, 0, 19), Vector3.FORWARD], [Vector3(19, 0, 7), Vector3.LEFT],
	[Vector3(19, 0, -7), Vector3.LEFT], [Vector3(7, 0, -19), Vector3.BACK],
	[Vector3(-7, 0, 19), Vector3.FORWARD], [Vector3(-19, 0, 7), Vector3.RIGHT],
	[Vector3(-19, 0, -7), Vector3.RIGHT], [Vector3(-7, 0, -19), Vector3.BACK],
]
const SPIRE_TOP := 16.0
const GEM_LEDGE := -3.5

var silver: SilverRush
var pebble: Islander
var truffle: Islander
var gate: SkywayGate


func _init() -> void:
	super()
	title = "Stardust Plaza"
	spawn = Vector3(0, 0, 23.5)
	spawn_facing = Vector3.FORWARD


func add_environment() -> void:
	super()
	var s := StarSky.new()
	s.spread = 70.0
	add_child(s)


func build() -> void:
	_plaza()
	_spire()
	_ring()
	_landing()
	_scenery()
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "spire", "at": Vector3(9, 0, 9), "face": Vector3(-1, 0, -1)},
		{"name": "ring", "at": Vector3(-12, 0, 12), "face": Vector3(1, 0, -1)},
		{"name": "top", "at": Vector3(0, SPIRE_TOP, 0.5), "face": Vector3.BACK},
	]


# --- The plaza ---------------------------------------------------------------

func _plaza() -> void:
	# An octagon: a square with four short arms.
	land(-7, -7, 7, 7, 0, 4)
	land(-9, -4, -7, 4, 0, 4)
	land(7, -4, 9, 4, 0, 4)
	land(-4, -9, 4, -7, 0, 4)
	land(-4, 7, 4, 9, 0, 4)
	add_checkpoint(Vector3(-2, 0, 7.5), Vector3.FORWARD)
	add_sign("The Star Road: eight courses with every world's tricks, all mixed up. The hardest in the Sky Isles!", Vector3(2.5, 0, 8), Vector3.BACK)
	add_heart(Vector3(-7.5, 0, 0))
	add_heart(Vector3(7.5, 0, 0))
	for c in [Vector3(-5.5, 0, -5.5), Vector3(5.5, 0, -5.5)]:
		coin_ring(c, 1.0, 5)
	# The silver lap: a coin on every pad, round the ring before time's up.
	var spots := []
	for p in PADS:
		spots.append(p + (Vector3.ZERO - p).normalized() * 1.2)
	silver = add_silver_rush("star/silver", Vector3(-5, 0, 6), spots, SILVER_TIME)
	add_sign("Step on the button, then run the ring: a silver coin on every pad.", Vector3(-6.3, 0, 6.3), Vector3.BACK)
	# Friends from the Sky Isles, here to cheer.
	pebble = add_islander("animal-penguin", "Pebble", [
		"You made it to the Star Road! The chicks wanted to see the stars up close.",
		"Every door here leads to a course with tricks from all the worlds at once. They're the hardest in the Sky Isles.",
		"Take your time. Every flag on the way is a checkpoint.",
	], Vector3(4, 0, 5), Vector3(0.3, 0, 1).normalized())
	for i in 3:
		var chick := RigCharacter.create(Kit.scene("animal-chick"), 0.22)
		chick.position = Vector3(5.2 + i * 0.6, 0, 5.6 + (i % 2) * 0.5)
		chick.rotation.y = 0.4 * i
		add_child(chick)
		chick.play("dance")
	truffle = add_islander("animal-hog", "Truffle", [
		"Step on the button and run the whole ring. A silver coin on every pad, and not much time!",
		"I dropped something shiny off the north path. It's still down there, twinkling.",
		"See the star on top of the spire? Up the ledges round it, then kick between the walls.",
	], Vector3(-4, 0, 3.5), Vector3(-0.2, 0, 1).normalized(), 0.4)


# --- The spire: the hard climb -----------------------------------------------

func _spire() -> void:
	land(-2, -2, 2, 2, SPIRE_TOP, int(SPIRE_TOP), "snow")
	# A step at the foot, then ledges round the corners, each a double jump
	# above the last.
	land(2, 2, 5, 5, 1.5, 2, "snow")
	land(2, -5, 5, -2, 4.0, 1, "snow")
	land(-5, -5, -2, -2, 6.5, 1, "snow")
	land(-5, 2, -2, 5, 9.0, 1, "snow")
	# The chimney: a floor between the spire and a fin, to kick up between.
	land(-2, 2, 1, 3, 9.0, 1, "snow")
	land(-1, 3, 1, 4, SPIRE_TOP - 0.5, 7, "snow")
	add_star("star/spire", Vector3(0, SPIRE_TOP + 0.1, 0))
	add_sign("Up the spire: double jump from ledge to ledge, then kick between the walls at the top.", Vector3(4, 0, 6.5), Vector3.BACK)
	coin_line(Vector3(3.5, 1.6, 3.5), Vector3(3.5, 4.1, -3.5), 3)
	coin_line(Vector3(-3.5, 6.6, -3.5), Vector3(-3.5, 9.1, 3.5), 3)
	add(StarGlow.make(3.0, Color("ffd84a"), true), Vector3(0, SPIRE_TOP + 3.5, 0))
	camera_zone(Vector3(-6, 1.0, -6), Vector3(6, 22, 6), 0.0, 26.0, 12.0, true, 1)


# --- The ring of pads and its rainbow paths ----------------------------------

func _ring() -> void:
	for i in PADS.size():
		var p: Vector3 = PADS[i]
		var x := int(p.x)
		var z := int(p.z)
		if absi(z) == 17 and z > 0:
			continue
		land(x - 3, z - 3, x + 3, z + 3, 0, 3)
	# The south pads and the stretch between them are one terrace.
	land(-10, 14, 10, 20, 0, 3)
	for i in DOORS.size():
		var d: Array = DOORS[i]
		add_course_door(COURSE_ORDER[i], d[0], d[1])
	# Paths out from the plaza.
	for p in PADS:
		var dir := Vector3(signf(p.x), 0, signf(p.z))
		if absf(p.z) > absf(p.x):
			_path(Vector3(6 * dir.x, 0, 6.5 * dir.z), Vector3(6 * dir.x, 0, 14.5 * dir.z))
		else:
			_path(Vector3(6.5 * dir.x, 0, 6 * dir.z), Vector3(14.5 * dir.x, 0, 6 * dir.z))
	_path(Vector3(0, 0, 8.5), Vector3(0, 0, 14.5))
	# Round the ring (the south side is the terrace).
	_path(Vector3(-4.5, 0, -17), Vector3(4.5, 0, -17))
	for s in [-1.0, 1.0]:
		_path(Vector3(s * 17, 0, -4.5), Vector3(s * 17, 0, 4.5))
		_path(Vector3(s * 9, 0, -15), Vector3(s * 15, 0, -9))
		_path(Vector3(s * 15, 0, 9), Vector3(s * 9, 0, 15))
	for p in PADS:
		coin_ring(p, 1.8, 6)
	# The hidden gem, on a ledge below the north path, with a spring back.
	ledge(-2, -23, 2, -19, GEM_LEDGE)
	add_gem("star/gem_hub", Vector3(0.6, GEM_LEDGE + 0.2, -21.8))
	add(Spring.new(), Vector3(-1.0, GEM_LEDGE, -19.7))
	coin_line(Vector3(-1.4, GEM_LEDGE + 0.2, -22.4), Vector3(1.4, GEM_LEDGE + 0.2, -22.4), 3)


func _path(from: Vector3, to: Vector3) -> void:
	add(StarBridge.make(to - from), from)


# --- The Skyway landing, from Star Station -----------------------------------

func _landing() -> void:
	land(-3, 20, 3, 28, 0, 3)
	gate = add_skyway_gate("station", Vector3(0, 0, 26.5), Vector3.FORWARD)
	add_checkpoint(Vector3(2, 0, 22.5), Vector3.FORWARD)
	# The Skyway itself, running back down towards Star Station.
	var way := StarBridge.make(Vector3(0, -14, 60))
	way.solid = false
	add(way, Vector3(0, 0, 28))
	coin_line(Vector3(0, 0, 21.5), Vector3(0, 0, 19.5), 2)


# --- Scenery and the worlds' trophies ----------------------------------------

func _scenery() -> void:
	add(StarRainbow.make(26.0, 0.0, 0.7), Vector3(0, -6, -24))
	add(StarRainbow.make(5.5, 0.0, 0.25), Vector3(0, -1.5, 20))
	for i in 12:
		var a := TAU * (i + 0.5) / 12.0
		var at := Vector3(cos(a) * 25.0, 3.0 + 3.0 * (i % 3), sin(a) * 25.0)
		add(StarGlow.make(1.6 + 0.4 * (i % 2), Color("ffd84a") if i % 3 else Color("ffb3f0")), at)
	_trophies()


## A few pieces from each world on each pad, by the course behind its door:
## one each side of the door, facing the plaza.
func _trophies() -> void:
	var looks := [
		["tree", 1.2, "holiday:snowman-hat", 1.3],
		["pirate:cannon", 0.8, "grave:gravestone-cross", 1.6],
		["food:cake-birthday", 2.4, "factory:hopper-round", 1.0],
		["castle:tower-square", 1.2, "station:computer-system", 1.2],
		["holiday:tree-decorated-snow", 1.0, "factory:cog-a", 1.3],
		["grave:crypt-small", 1.0, "castle:flag-banner-long", 1.0],
		["food:cupcake", 2.5, "grave:pumpkin-tall-carved", 2.0],
		["pirate:flag-pirate", 0.8, "station:container-tall", 1.2],
	]
	for i in DOORS.size():
		var at: Vector3 = DOORS[i][0]
		var face: Vector3 = DOORS[i][1]
		var side := face.cross(Vector3.UP)
		var turn := rad_to_deg(atan2(face.x, face.z))
		var look: Array = looks[i]
		for k in 2:
			var spot := at + side * (2.4 if k == 0 else -2.4) + face * 0.2
			var model: String = look[k * 2]
			var size: float = look[k * 2 + 1]
			if model.begins_with("tree") or model.contains(":tree"):
				tree(spot, model, size)
			else:
				deco(model, spot, turn, size)
				solid(spot + Vector3(-0.45, 0, -0.45), spot + Vector3(0.45, 1.0, 0.45))
		deco("flowers", at + face * 3.2 + side * 1.6, turn)
		deco("flowers", at + face * 3.2 - side * 1.6, turn + 90.0)
	# A roof for the castle tower, and a glow over the last door.
	var tower: Vector3 = DOORS[3][0] + DOORS[3][1].cross(Vector3.UP) * 2.4 + DOORS[3][1] * 0.2
	deco("castle:tower-square-top-roof", tower + Vector3.UP * 1.31 * 1.2, 0.0, 1.2)
	add(StarGlow.make(1.2), DOORS[7][0] + Vector3.UP * 3.6)


## The courses behind the eight doors, in door order (see PADS).
const COURSE_ORDER := ["rainbow_rush", "cannon_crypts", "sugar_gears", "moon_ramparts",
	"blizzard_bluffs", "haunted_heights", "bounce_hollow", "starlight_finale"]
